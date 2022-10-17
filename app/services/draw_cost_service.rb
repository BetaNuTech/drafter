class DrawCostService

  attr_reader :user, :draw, :draw_cost, :project, :organization, :errors

  def initialize(user:, draw:, draw_cost: nil)
    @user = user
    @draw = draw
    @errors = []
    @project = @draw.project
    @organization = @draw.organization
    @draw_cost = draw_cost || DrawCost.new(draw: @draw)
    @draw_cost_policy = DrawCostPolicy.new(@user, @draw_cost)
  end

  def errors?
    @errors.present?
  end

  def create(params)
    raise PolicyError.new unless @draw_cost_policy.create?

    reset_errors

    @draw_cost = @draw.draw_costs.new(sanitize_draw_cost_params(params))
    @draw_cost.draw = @draw
    if @draw_cost.save
      @draw.draw_costs.reload
      SystemEvent.log(description: "Added #{@draw_cost.project_cost.name} Cost for Draw '#{@draw.name}'", event_source: @draw.project, incidental: @current_user, severity: :warn)
    else
      @errors = @draw_cost.errors.full_messages
    end
  end

  def update(params)
    raise PolicyError.new unless @draw_cost_policy.create?

    reset_errors

    if @draw_cost.update(sanitize_draw_cost_params(params))
      @draw.draw_costs.reload
      SystemEvent.log(description: "Updated #{@draw_cost.project_cost.name} Cost for Draw '#{@draw.name}'", event_source: @draw.project, incidental: @current_user, severity: :warn)
    else
      @errors = @draw_cost.errors.full_messages
    end
  end

  private

  def reset_errors
    @errors = []
  end

  def sanitize_draw_cost_params(params)
    allowed_params = @draw_cost_policy.allowed_params
    if params.is_a?(ActionController::Parameters)
      params.permit(*allowed_params)
    else
      params.select{|k,v| allowed_params.include?(k.to_sym) }
    end
  end

  
end
