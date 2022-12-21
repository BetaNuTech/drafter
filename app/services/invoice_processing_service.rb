class InvoiceProcessingService
  class InvoiceProcessingServiceError < StandardError; end
  class InvalidAnalyzerError < InvoiceProcessingServiceError; end
  class InvalidStateError < InvoiceProcessingServiceError; end
  class MissingDocumentError < InvoiceProcessingServiceError; end

  ATTEMPTS_MAX = 5
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
    raise InvalidStateError.new('Invoice must be in submitted state for analysis') unless (force || invoice.submitted?)

    raise MissingDocumentError.new('Invoice has no attached document') unless invoice.document.attached?

    invoice.init_ocr_data

    attempt = invoice.ocr_data.dig('meta', 'attempts')
    if ATTEMPTS_MAX < attempt
      invoice.trigger_event(event_name: 'fail_processing')
      SystemEvent.log(description: 'Exceeded maximum invoice processing attempts', event_source: invoice, incidental: invoice.project, severity: :error)
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
        invoice.trigger_event(event_name: 'fail_processing_attempt') unless invoice.processing_failed?
        description = "External service error processing document"
        SystemEvent.log(description: , event_source: invoice, incidental: invoice.project, severity: :error)
      end

      successful_jobs.each do |job|
        invoice = job.record
        process_invoice_analysis(invoice: invoice, analysis_job_data: job.data)

        if invoice.processing? && job.data.is_total_present
          invoice.trigger_event(event_name: :complete_processing)
        else
          invoice.trigger_event(event_name: :fail_processing)
        end

        generate_annotated_preview(invoice: invoice) if invoice.processed?
      end
    end
  end

  def get_analysis(invoice:)
    job_id = ( invoice.ocr_data || {} ).dig('meta', 'jobid')
    return nil if job_id.nil?

    @service.get_analysis(job_id:, expected_total: invoice.amount)
  end

  def process_invoice_analysis(invoice:, analysis_job_data:)
    invoice.init_ocr_data
    invoice.ocr_data['analysis'] = analysis_job_data.to_h

    if analysis_job_data.is_total_present
      invoice.ocr_amount = analysis_job_data.total
    else
      invoice.audit = true
    end
    invoice.save
  end

  def generate_annotated_preview(invoice:)
    # TODO
  end

  private

  def submit_analysis_request(invoice:, requestid:)
    jobid = @service.analyze_document(metadata: invoice.ocr_data['meta'], requestid:)
    if jobid.present?
      invoice.ocr_data['meta']['jobid'] = jobid
      invoice.save
      jobid
    else
      invoice.trigger_event(event_name: 'fail_processing_attempt')
      attempt = invoice.ocr_data['meta']['attempt']
      SystemEvent.log(description: "Invoice processing attempt #{attempt} failed", event_source: invoice, incidental: invoice.project, severity: :warn)
      nil
    end
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
