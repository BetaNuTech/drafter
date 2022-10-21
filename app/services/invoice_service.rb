class InvoiceService
  class PolicyError < StandardError; end

  attr_reader :user, :draw_cost, :invoice, :project, :organization, :errors

  def initialize(user:, draw_cost:, invoice: nil)
    @errors = []
    @user = user
    @draw_cost = draw_cost
    @project = @draw_cost.project
    @organization = @draw_cost.organization
    @invoice = invoice || Invoice.new(draw_cost: @draw_cost)
    @policy = InvoicePolicy.new(@user, @invoice)
  end

  def errors?
    @errors.any?
  end

  def create(params)
    raise PolicyError.new unless @policy.create? 

    reset_errors

    @invoice = Invoice.new(sanitize_params(params))
    @invoice.draw_cost = @draw_cost
    @invoice.user = @user
    if @invoice.save
      SystemEvent.log(description: "Added Invoice for Draw Cost '#{@draw_cost.project_cost.name}'", event_source: @project, incidental: @current_user, severity: :warn)
      @draw_cost.invoices.reload
    else
      @errors = @invoice.errors.full_messages
    end
    @invoice
  end

  def update(params)
    raise PolicyError.new unless @policy.update?

    reset_errors

    unless @invoice.update(sanitize_params(params))
      @errors = @invoice.errors.full_messages
    end
    @invoice
  end

  def remove
    raise PolicyError.new unless @policy.remove?

    reset_errors

    @invoice.trigger_event(event_name: :remove, user: @user)
    if @invoice.removed?
      SystemEvent.log(description: "Removed Invoice for Draw Cost '#{@draw_cost.project_cost.name}'", event_source: @project, incidental: @current_user, severity: :warn)
      @draw_cost.invoices.reload
    else
      @errors << 'Error removing invoice'
    end
  end

  private

  def reset_errors
    @errors = []
  end

  def sanitize_params(params)
    allowed_params = @policy.allowed_params
    if params.is_a?(ActionController::Parameters)
      params.permit(*allowed_params)
    else
      params.select{|k,v| allowed_params.include?(k.to_sym) }
    end
  end
  
end
