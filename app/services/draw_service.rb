class DrawService
  class PolicyError < StandardError; end

  attr_reader :user, :draw, :project, :organization, :errors, :policy

  def initialize(user:, project: nil, draw: nil)
    raise ActiveRecord::RecordNotFound unless (project.present? || draw.present?)

    @errors = []
    @user = user
    @project = project || draw&.project
    @organization = @user.organization
    @draw = draw || Draw.new(project: @project, organization: @organization, user: @user)
    @policy = DrawPolicy.new(@user, @draw)

    raise PolicyError.new unless @policy.index?
  end

  def errors?
    @errors.present?
  end

  def create(params)
    raise PolicyError.new unless @policy.create?

    reset_errors
    @project.draws.reload
    @draw = Draw.new(project: @project, user: @user, organization: @organization)
    @draw.attributes = sanitize_params(params)
    if @draw.save
      SystemEvent.log(description: "Added Draw '#{@draw.index}' for Project '#{@project.name}'", event_source: @project, incidental: @current_user, severity: :warn)
      @project.draws.reload
    else
      @errors = @draw.errors.full_messages
    end
    @draw
  end

  def update(params)
    raise PolicyError unless @policy.update?

    reset_errors

    unless @draw.update(sanitize_params(params))
      @errors = @draw.errors.full_messages
    end
    @project.draws.reload

    @draw
  end

  def withdraw
    raise PolicyError unless @policy.withdraw?

    if @draw.permitted_state_events.include?(:withdraw)
      @draw.trigger_event(event_name: :withdraw, user: @user)
      SystemEvent.log(description: "Removed Draw '#{@draw.index}' for Project '#{@project.name}'", event_source: @project, incidental: @current_user, severity: :warn)
      @project.draws.reload
      return true
    else
      return false
    end
  end

  def approve_internal?
    raise PolicyError unless @policy.approve_internal?

    if @draw.permitted_state_events.include?(:approve)
      @draw.trigger_event(event_name: :approve_internal, user: @user)
      SystemEvent.log(description: "Internally Approved Draw '#{@draw.index}' for Project '#{@project.name}'", event_source: @project, incidental: @current_user, severity: :warn)
      @project.draws.reload
      return true
    else
      return false
    end
  end

  def reject_internal?
    raise PolicyError unless @policy.reject_internal?

    if @draw.permitted_state_events.include?(:reject)
      @draw.trigger_event(event_name: :reject_internal, user: @user)
      SystemEvent.log(description: "Rejected Draw '#{@draw.index}' for Project '#{@project.name}'", event_source: @project, incidental: @current_user, severity: :warn)
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

  def sanitize_params(params)
    allowed_params = @policy.allowed_params
    if params.is_a?(ActionController::Parameters)
      params.permit(*allowed_params)
    else
      params.select{|k,v| allowed_params.include?(k.to_sym) }
    end
  end

end
