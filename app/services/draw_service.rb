class DrawService
  class PolicyError < StandardError; end

  attr_reader :user, :draw, :project, :organization, :errors, :draw_policy

  def initialize(user:, project: nil, draw: nil)
    raise ActiveRecord::RecordNotFound unless (project.present? || draw.present?)

    @errors = []
    @user = user
    @project = project || draw&.project
    @organization = @user.organization
    @draw = draw || project.draws.new(organization: @organization, user: @user)
    @draw_policy = DrawPolicy.new(@user, @draw)

    raise PolicyError.new unless @draw_policy.index?
  end

  def errors?
    @errors.present?
  end

  def create(params)
    raise PolicyError.new unless @draw_policy.create?

    reset_errors

    @draw = @project.draws.new(sanitize_draw_params(params))
    @draw.user = @user
    @draw.organization ||= @organization
    @draw.index = @draw.next_index
    if @draw.save
      SystemEvent.log(description: "Added Draw '#{@draw.name}' for Project '#{@draw.project.name}'", event_source: @draw.project, incidental: @current_user, severity: :warn)
      @project.draws.reload
    else
      @errors = @draw.errors.full_messages
    end
    @draw
  end

  def update(params)
    raise PolicyError unless @draw_policy.update?

    reset_errors

    unless @draw.update(sanitize_draw_params(params))
      @errors = @draw.errors.full_messages
    end

    @draw
  end

  def withdraw
    raise PolicyError unless @draw_policy.withdraw?

    if @draw.permitted_state_events.include?(:withdraw)
      @draw.trigger_event(event_name: :withdraw, user: @user)
      @draw.reload
      @project.draws.reload
      return true
    else
      return false
    end
  end

  def draws
    DrawPolicy::Scope.new(@user, @project.draws).resolve
  end

  private

  def reset_errors
    @errors = []
  end

  def sanitize_draw_params(params)
    allowed_params = @draw_policy.allowed_params
    if params.is_a?(ActionController::Parameters)
      params.permit(*allowed_params)
    else
      params.select{|k,v| allowed_params.include?(k.to_sym) }
    end
  end

end
