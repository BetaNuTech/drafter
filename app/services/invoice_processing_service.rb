class InvoiceProcessingService
  ATTEMPTS_MAX = 4
  attr_reader :invoice, :errors

  class InvalidStateError < StandardError; end
  class MissingDocumentError < StandardError; end

  def initialize(service=:textract)
    @service = service
  end

  def errors?
    @errors.any?
  end

  def start_analysis(invoice)
    return false unless invoice.submitted?

    return false unless invoice.document.attached?

    invoice.init_ocr_data
    invoice.trigger_event(event_name: 'process')

    attempt = invoice.ocr_data.dig('meta', 'attempts')
    if ATTEMPTS_MAX < attempt
      invoice.trigger_event(event_name: 'fail_processing')
      SystemEvent.log(description: 'Exceeded maximum invoice processing attempts', event_source: invoice, incidental: invoice.rproject, severity: :error)
      return false
    end

    attempt += 1
    invoice.ocr_data['meta']['last_attempt'] ||= Time.current.to_s
    invoice.ocr_data['meta']['attempts'] ||= attempt
    invoice.save

    #jobid = Textract::Api::Analyzer.new.analyze_document(invoice.ocr_data['meta'])
    # if jobid.present?
    #  invoice.ocr_data['meta']['jobid'] = jobid
    #  invoice.save
    # else
    #  invoice.trigger_event(event_name: 'fail_processing_attempt')
    #  SystemEvent.log(description: "Invoice processing attempt #{attempt} failed", event_source: invoice, incidental: invoice.rproject, severity: :warn)
    #  invoice.save
    #  return false
    # end
    #return jobid
  end

  def get_analysis(invoice)
    # TODO
  end

  private

  

  def reset_errors
    @errors = []
  end
end
