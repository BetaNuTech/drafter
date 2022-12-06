class InvoiceProcessingService

  attr_reader :invoice, :errors

  def initialize(invoice)
    @invoice = invoice
    @errors = []
  end

  def errors?
    @errors.any?
  end

  def start_analysis
    # TODO
  end

  def get_analysis
    # TODO
  end

  private

  def reset_errors
    @errors = []
  end
end
