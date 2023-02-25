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
      SystemEvent.log(description: "Added an Invoice for Draw Cost '#{@draw_cost.project_cost.name}'", event_source: @draw_cost, incidental: @project, severity: :warn)
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
      SystemEvent.log(description: "Removed an Invoice for Draw Cost '#{@draw_cost.project_cost.name}'", event_source: @draw_cost, incidental: @project, severity: :warn)
      @draw_cost.invoices.reload
    else
      @errors << 'Error removing invoice'
    end
  end

  def submit
    raise PolicyError.new unless @policy.submit?

    @invoice.trigger_event(event_name: :submit, user: @user)
    if @invoice.submitted?
      SystemEvent.log(description: "Submitted an Invoice for Draw Cost '#{@draw_cost.project_cost.name}'", event_source: @draw_cost, incidental: @project, severity: :warn)
      @draw_cost.invoices.reload
    else
      @errors << 'Error submitting invoice'
    end
  end

  def approve
    raise PolicyError.new unless @policy.approve?

    reset_errors

    unless @invoice.permitted_state_events.include?(:approve)
      @errors << 'Cannot approve invoice at this time'
      return false
    end

    @invoice.trigger_event(event_name: :approve, user: @user)
    if @invoice.approved?
      @invoice.approved_at = Time.current
      @invoice.approver = @user
      @invoice.approved_by_desc = @user.name
      @invoice.save
    end
    SystemEvent.log(description: "Approved an Invoice for Draw Cost '#{@draw_cost.project_cost.name}'", event_source: @draw_cost, incidental: @project, severity: :warn)
    return true
  end

  def reject
    raise PolicyError.new unless @policy.reject?

    reset_errors

    unless @invoice.permitted_state_events.include?(:reject)
      @errors << 'Cannot reject invoice at this time'
      return false
    end

    @invoice.trigger_event(event_name: :reject, user: @user)
    if @invoice.rejected?
      @invoice.approved_at = nil
      @invoice.approver = nil
      @invoice.approved_by_desc = nil
      @invoice.save
    end
    SystemEvent.log(description: "Rejected Invoice for Draw Cost '#{@draw_cost.project_cost.name}'", event_source: @draw_cost, incidental: @project, severity: :warn)
    return true
  end

  def reset_approval
    raise PolicyError.new unless @policy.reset_approval?

    reset_errors

    unless @invoice.permitted_state_events.include?(:reset_approval)
      @errors << 'Cannot reset approval for invoice at this time'
      return false
    end

    @invoice.trigger_event(event_name: :reset_approval, user: @user)
    SystemEvent.log(description: "Reset approval for Invoice for Draw Cost '#{@draw_cost.project_cost.name}'", event_source: @draw_cost, incidental: @project, severity: :warn)
    return true
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
