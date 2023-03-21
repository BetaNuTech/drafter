class ChangeOrderService
  class PolicyError < StandardError; end

  attr_reader :user, :draw_cost, :change_order, :project, :errors

  def initialize(user:, draw_cost: nil, change_order: nil)
    raise ActiveRecord::RecordNotFound unless (draw_cost.present? || change_order.present?)

    if change_order.present?
      @change_order = change_order
      @draw_cost = @change_order.draw_cost
    else
      @draw_cost = draw_cost
      @change_order = ChangeOrder.new(draw_cost: @draw_cost)
    end
    @errors = []
    @user = user
    @draw = @draw_cost.draw
    @project = @draw_cost.project
    @policy = ChangeOrderPolicy.new(@user, @change_order)
  end

  def errors?
    @errors.any?
  end

  def create(params)
    raise PolicyError.new unless @policy.create?

    reset_errors

    @change_order = @draw_cost.change_orders.new(sanitize_change_order_params(params))
    @change_order.project_cost = @draw_cost.project_cost

    provided_amount = @change_order.amount || 0.0
    overage = @draw_cost.project_cost_overage
    @change_order.amount = provided_amount.zero? ? overage : provided_amount

    unless ( @change_order.amount.positive? )
      @errors << 'Amount must be positive'
      return @change_order
    end

    unless @draw_cost.project_cost.change_request_allowed?
      @errors << 'Change Requests are not allowed for this Draw Cost'
      return @change_order
    end

    unless @change_order.funding_source.present?
      @errors << 'Missing Funding Source'
      return @change_order
    end

    unless @change_order.funding_source.change_requestable?
      @errors << 'This Funding Source Project Cost does not allow change requests'
      return @change_order
    end

    if @change_order.save
      @draw_cost.change_orders.reload
      SystemEvent.log(description: "Added Change Order for #{@draw_cost.project_cost.name} Cost for Draw '#{@draw.name}'", event_source: @draw, incidental: @project, severity: :warn)
    else
      @errors = @change_order.errors.full_messages
    end
    @change_order
  end

  def destroy
    raise PolicyError.new unless @policy.destroy?

    @change_order.destroy

    @draw_cost.trigger_event(event_name: :revert_to_pending, user: user) if
      @draw_cost.permitted_state_events.include?(:revert_to_pending)

    SystemEvent.log(description: "Removed Change Order for #{@draw_cost.project_cost.name} Cost for Draw '#{@draw.name}'", event_source: @draw, incidental: @project, severity: :warn)
  end

  def approve
    raise PolicyError.new unless @policy.approve?

    reset_errors

    unless @change_order.permitted_state_events.include?(:approve)
      @errors << 'Cannot approve Change Order at this time'
      return false
    end

    @change_order.trigger_event(event_name: :approve, user: @user)
    SystemEvent.log(description: "Approved a Change Order for Draw Cost '#{@draw_cost.project_cost.name}'", event_source: @draw_cost, incidental: @project, severity: :warn)
    return true
  end

  def reject
    raise PolicyError.new unless @policy.reject?

    reset_errors

    unless @change_order.permitted_state_events.include?(:reject)
      @errors << 'Cannot reject Change Order at this time'
      return false
    end

    @change_order.trigger_event(event_name: :reject, user: @user)
    SystemEvent.log(description: "Rejected a Change Order for Draw Cost '#{@draw_cost.project_cost.name}'", event_source: @draw_cost, incidental: @project, severity: :warn)
    return true
  end

  def reset_approval
    raise PolicyError.new unless @policy.reset_approval?

    reset_errors

    unless @change_order.permitted_state_events.include?(:reset_approval)
      @errors << 'Cannot reset approval for Change Order at this time'
      return false
    end

    @change_order.trigger_event(event_name: :reset_approval, user: @user)
    SystemEvent.log(description: "Reset approval for a Change Order for Draw Cost '#{@draw_cost.project_cost.name}'", event_source: @draw_cost, incidental: @project, severity: :warn)
    return true
  end

  def funds_available?(funding_source)
    0 < funds_available(funding_source)
  end

  def funds_available(funding_source)
    funding_source.budget_balance
  end
  
  private

  def draw_cost_overage
    difference = @draw_cost.project_cost.budget_balance - @draw_cost.total
    difference.negative? ? ( difference * -1.0 ) : 0.0
  end

  def reset_errors
    @errors = []
  end

  def sanitize_change_order_params(params)
    allowed_params = @policy.allowed_params
    if params.is_a?(ActionController::Parameters)
      params.permit(*allowed_params)
    else
      params.select{|k,v| allowed_params.include?(k.to_sym) }
    end
  end
end
