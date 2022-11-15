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
    @change_order_policy = ChangeOrderPolicy.new(@user, @change_order)
  end

  def errors?
    @errors.any?
  end

  def create(params)
    raise PolicyError.new unless @change_order_policy.create?

    reset_errors

    @change_order = @draw_cost.change_orders.new(sanitize_change_order_params(params))
    @change_order.project_cost = @draw_cost.project_cost

    @change_order.amount = @draw_cost.project_cost_overage

    unless ( @change_order.amount.positive? )
      @errors << 'Draw Cost does not require a change order'
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
    raise PolicyError.new unless @change_order_policy.destroy?

    @change_order.destroy
    SystemEvent.log(description: "Removed Change Order for #{@draw_cost.project_cost.name} Cost for Draw '#{@draw.name}'", event_source: @draw, incidental: @project, severity: :warn)
  end

  #def update(params)
    #raise NotImplementedError
    #raise PolicyError.new unless @change_order_policy.create?

    #reset_errors

    #if @change_order.update(sanitize_change_order_params(params))
      #@draw_cost.change_orders.reload
      #SystemEvent.log(description: "Updated Change Order for #{@draw_cost.project_cost.name} Cost for Draw '#{@draw.name}'", event_source: @draw, incidental: @project, severity: :warn)
    #else
      #@errors = @change_order.errors.full_messages
    #end
    #@change_order
  #end

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
    allowed_params = @change_order_policy.allowed_params
    if params.is_a?(ActionController::Parameters)
      params.permit(*allowed_params)
    else
      params.select{|k,v| allowed_params.include?(k.to_sym) }
    end
  end
end