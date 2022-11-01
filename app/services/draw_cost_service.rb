class DrawCostService
  class PolicyError < StandardError; end

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
      SystemEvent.log(description: "Added #{@draw_cost.project_cost.name} Cost for Draw '#{@draw.name}'", event_source: @draw, incidental: @project, severity: :warn)
    else
      @errors = @draw_cost.errors.full_messages
    end
  end

  def update(params)
    raise PolicyError.new unless @draw_cost_policy.create?

    reset_errors

    if @draw_cost.update(sanitize_draw_cost_params(params))
      @draw.draw_costs.reload
      SystemEvent.log(description: "Updated #{@draw_cost.project_cost.name} Cost for Draw '#{@draw.name}'", event_source: @draw, incidental: @project, severity: :warn)
    else
      @errors = @draw_cost.errors.full_messages
    end
  end

  def withdraw
    raise PolicyError.new unless @draw_cost_policy.destroy?

    SystemEvent.log(description: "Removed #{@draw_cost.project_cost.name} Cost for Draw '#{@draw.name}'", event_source: @draw, incidental: @project, severity: :warn)
    @draw_cost.withdraw!
    @draw_cost.draw.draw_costs.reload
  end

  def submit
    raise PolicyError.new unless @draw_cost_policy.submit?

    @draw_cost.transaction do
      @draw_cost.trigger_event(event_name: :submit, user: @user)
    end
    if @draw_cost.submitted?
      SystemEvent.log(description: "Submitted Draw Cost '#{@draw_cost.project_cost.name}'", event_source: @draw_cost, incidental: @project, severity: :warn)
      @draw.draw_costs.reload
    else
      @errors << 'Error submitting Draw Cost'
    end
    @draw_cost.draw.draw_costs.reload
  end

  def approve
    raise PolicyError.new(user_role_desc + ' cannot approve draw cost') unless @draw_cost_policy.approve?

    @draw_cost.trigger_event(event_name: :approve, user: @user)
    if @draw_cost.submitted?
      SystemEvent.log(description: "Approved Draw Cost '#{@draw_cost.project_cost.name}'", event_source: @draw_cost, incidental: @project, severity: :warn)
      @draw.draw_costs.reload
    else
      @errors << 'Error approving Draw Cost'
    end
    @draw_cost.draw.draw_costs.reload
  end

  private

  def user_role_desc
    @user.full_role_desc(@project)
  end

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
