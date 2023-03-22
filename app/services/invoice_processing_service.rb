class InvoiceProcessingService
  require 'vips'

  class InvoiceProcessingServiceError < StandardError; end
  class InvalidAnalyzerError < InvoiceProcessingServiceError; end
  class InvalidStateError < InvoiceProcessingServiceError; end
  class MissingDocumentError < InvoiceProcessingServiceError; end

  #ANNOTATION_COLOR = [70.0,190.0,60.0,100.0].freeze # a shade of green
  ANNOTATION_COLOR = [0.0, 255.0, 0.0, 100.0].freeze # a shade of green
  ANALYSIS_ATTEMPTS_MAX = 5

  attr_reader :invoice, :errors, :service_name, :service

  def initialize(backing_service: :textract, dry_run: false, debug: false)
    @service_name = backing_service
    @service = analyzer_service(@service_name)
    @service.dry_run = dry_run
    @service.debug = debug
  end

  def errors?
    @errors.any?
  end

  # Start analysis of provided invoice
  def start_analysis(invoice:, force: false)
    return false unless (force || invoice.submitted?)

    raise MissingDocumentError.new('Invoice has no attached document') unless invoice.document.attached?


    # Fail if there are already processing errors
    if invoice.has_processing_errors?
      invoice.trigger_event(event_name: 'fail_processing')
      return false
    end

    invoice.init_ocr_data

    attempt = invoice.ocr_data.dig('meta', 'attempts')
    if ANALYSIS_ATTEMPTS_MAX < attempt
      invoice.trigger_event(event_name: 'fail_processing')
      SystemEvent.log(description: Invoice::MAX_ATTEMPT_ERROR, event_source: invoice, incidental: invoice.project, severity: :error)
      return false
    end

    invoice.trigger_event(event_name: 'process') if invoice.submitted?

    attempt += 1
    requestid = SecureRandom.hex
    timestamp = Time.current.to_s
    job_tag = "Invoice--#{invoice.id}"
    request = { attempt:, requestid:, job_tag: ,timestamp: }

    invoice.ocr_data['meta']['service'] = @service_name
    invoice.ocr_data['meta']['attempts'] = attempt
    invoice.ocr_data['meta']['last_attempt'] = timestamp
    invoice.ocr_data['meta']['job_tag'] = job_tag
    invoice.ocr_data['meta']['requests'] ||= []
    invoice.ocr_data['meta']['requests']  << request
    invoice.save

    submit_analysis_request(invoice:, requestid:)
  rescue => e
    invoice.trigger_event(event_name: 'fail_processing_attempt')
    description = "Error starting analysis of invoice: #{e.class.to_s}: #{e.to_s}"
    SystemEvent.log(description: , event_source: invoice, incidental: invoice.project, severity: :error)
  end

  # Process completed document analysis data for 'processing' invoices
  def process_completion_queue
    @service.process_completion_queue(Invoice) do |successful_jobs, failed_jobs|
      failed_jobs.each do |job|
        invoice = job.record
        description = "External OCR service error processing Invoice document"
        SystemEvent.log(description: , event_source: invoice, incidental: invoice.project, severity: :error)
        invoice.trigger_event(event_name: 'fail_processing_attempt')
      end

      successful_jobs.each do |job|
        process_analysis_job_data(invoice: job.record, analysis_job_data: job.data)
      end
    end
  end

  def process_analysis_job_data(invoice:, analysis_job_data: nil, reprocess: false)
    if reprocess
      analysis = invoice.ocr_data&.fetch('analysis')
    else
      analysis = analysis_job_data&.to_h&.with_indifferent_access
    end

    unless analysis.present?
      description = "Failed to process invoice OCR analysis due to missing analysis data"
      SystemEvent.log(description: , event_source: invoice, incidental: invoice.project, severity: :error)
      invoice.trigger_event(event_name: :fail_processing) unless reprocess
      return invoice
    end

    process_invoice_analysis(invoice: invoice, analysis_job_data: analysis, reprocess:)
    invoice.reload

    if analysis['is_total_present']
      page_found = analysis['page_number'].to_i > 0
      if page_found
        generate_annotated_preview(invoice: invoice)
        invoice.annotated_preview.reload
      else
        description = "Could not generate Invoice preview because the page containing the total was not found"
        SystemEvent.log(description: , event_source: invoice, incidental: invoice.project, severity: :warn)
      end
      invoice.trigger_event(event_name: :complete_processing)
    else
      invoice.trigger_event(event_name: :fail_processing)
    end

    invoice
  end

  def get_analysis(invoice:)
    job_id = ( invoice.ocr_data || {} ).dig('meta', 'jobid')
    return nil if job_id.nil?

    @service.get_analysis(job_id:, expected_total: invoice.amount)
  end


  def generate_annotated_preview(invoice:)
    analysis = invoice.ocr_data.fetch('analysis',nil)

    unless analysis.present?
      description = "Invoice preview generation failed due to missing analysis data"
      SystemEvent.log(description: , event_source: invoice, incidental: invoice.project, severity: :error)
      return false
    end

    unless invoice.document.attached?
      description = "Invoice preview generation failed due to missing document"
      SystemEvent.log(description: , event_source: invoice, incidental: invoice.project, severity: :error)
      return false
    end

    page = analysis['page_number'].to_i - 1 # zero-indexed page
    if page < 0
      description = "Invoice preview generation failed because the page containing the total was not found"
      SystemEvent.log(description: , event_source: invoice, incidental: invoice.project, severity: :error)
    end

    invoice.document.blob.open do |tempfile|
      pdf_page_image = Vips::Image.new_from_file(tempfile.path, access: :sequential, page: page)

      width, height = pdf_page_image.size
      if ( width.zero? || height.zero? )
        description = "Invoice preview generation failed due to invalid page size"
        SystemEvent.log(description: , event_source: invoice, incidental: invoice.project, severity: :error)
        return false
      end

      box_width, box_height, box_left, box_top = analysis['bounding_box'].values_at('width', 'height', 'left', 'top')
      if [box_width, box_height, box_left, box_top].any?{|val| val.nil? || val.zero?}
        description = "Invoice preview generation failed due to invalid total bounding box specification returned from OCR service"
        SystemEvent.log(description: , event_source: invoice, incidental: invoice.project, severity: :error)
        return false
      end

      box_width = (box_width * width) + 10 
      box_left = (box_left * width) - 5
      box_height = (box_height * height) + 10 
      box_top = (box_top * height) - 5

      border_color = ANNOTATION_COLOR
      pdf_page_image = pdf_page_image.draw_rect(border_color, box_left, box_top, box_width, box_height)
      annotated_page_data = pdf_page_image.write_to_buffer '.jpg[Q=90]'
      invoice.annotated_preview.attach(io: StringIO.new(annotated_page_data), filename: 'annotated_preview.jpg')
      invoice.update(ocr_processed: Time.current)
      true
    end
  rescue => e
    invoice.trigger_event(event_name: 'fail_processing_attempt') unless invoice.processing_failed?
    description = "Error generating invoice preview: " + e.to_s
    SystemEvent.log(description: , event_source: invoice, incidental: invoice.project, severity: :error)
    return false
  end

  private

  def submit_analysis_request(invoice:, requestid:)
    jobid = @service.analyze_document(metadata: invoice.ocr_data['meta'], requestid:)
    if jobid.present?
      invoice.ocr_data['meta']['jobid'] = jobid
      invoice.save
      invoice.delay(run_at: 1.minute.from_now, queue: Invoice::PROCESSING_QUEUE).process_analysis
      jobid
    else
      invoice.trigger_event(event_name: 'fail_processing_attempt')
      attempt = invoice.ocr_data['meta']['attempt']
      SystemEvent.log(description: "Invoice processing attempt #{attempt} failed", event_source: invoice, incidental: invoice.project, severity: :warn)
      nil
    end
  end

  def process_invoice_analysis(invoice:, analysis_job_data: nil, reprocess: false)
    if reprocess
      analysis = invoice.ocr_data['analysis']
    else
      invoice.init_ocr_data
      analysis = invoice.ocr_data['analysis'] = analysis_job_data.to_h.with_indifferent_access
    end

    if analysis['is_total_present']
      page_found = analysis['page_number'].to_i > 0
      amount_match = analysis['total'] == invoice.amount
      invoice.manual_approval_required = !amount_match || !page_found
      invoice.ocr_amount = analysis['total'] unless reprocess
    else
      description = "OCR service could not identify an Invoice total"
      SystemEvent.log(description: , event_source: invoice, incidental: invoice.project, severity: :warn)
      invoice.manual_approval_required = true
    end

    invoice.save
    invoice
  end

  def analyzer_service(service)
    case service
    when :textract
      Textract::Api::Analyzer.new
    else
      raise InvalidAnalyzerError.new("#{service} is not a supported invoice document analyser")
    end
  end

  def reset_errors
    @errors = []
  end
end
