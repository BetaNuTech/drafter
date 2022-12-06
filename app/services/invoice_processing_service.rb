class InvoiceProcessingService
  attr_reader :invoice, :errors

  def initialize(service=:textract)
    @service = service
  end

  def errors?
    @errors.any?
  end

  def start_analysis(invoice)
    # TODO
    # Initialize the Textract API
    key = invoice.document.attachment.blob.key
    name = invoice.document.attachment.blob.filename.to_s
  end

  def get_analysis(invoice)
    # TODO
  end

  private

  def reset_errors
    @errors = []
  end
end
