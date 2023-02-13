class ProjectTaskService
  attr_reader :project_task, :errors, :changed_at

  PERMITTED_EVENTS = %i{approve reject archive}.freeze
  STATUS_EVENTS = { approved: :approve, rejected: :reject, archived: :archive }.freeze

  def initialize(project_task=nil)
    @project_task = project_task
    @errors = []
    @changed_at = nil
  end

  def generate(origin:, assignee: nil, action:)
    @project_task = ProjectTaskServices::Generator.call(origin:, assignee:, action:)
  end

  def update_status(status)
    return false unless @project_task.present?

    @changed_at = false
    reset_errors
    status_key = status.to_sym

    unless STATUS_EVENTS.keys.include?(status_key)
      @errors << "#{status} is not a valid Project Task status for update"
      return false
    end

    trigger_event(STATUS_EVENTS[status_key])
    project_task
  end

  def errors?
    @errors.any?
  end

  def changed?
    @changed_at.present?
  end


  def trigger_event(event_name)
    reset_errors

    unless PERMITTED_EVENTS.include?(event_name.to_sym)
      @errors << "#{event_name} is not a valid Project Task event"
      return false
    end

    public_send(event_name)
  end

  def approve
    reset_errors
    origin = project_task.origin

    if project_task.permitted_state_events.include?(:approve) && origin.permitted_state_events.include?(:approve)
      origin.trigger_event(event_name: :approve)
      project_task.trigger_event(event_name: :approve)
      @changed_at = Time.current
    else
      @errors << "Can't approve this %{origin_state} %{origin_class}" % {
        origin_state: origin.state.humanize,
        origin_class: origin.class.name.titleize
      }
      return project_task
    end
    project_task.reload

    project_task
  end

  def reject
    reset_errors
    origin = project_task.origin

    if project_task.permitted_state_events.include?(:reject) && origin.permitted_state_events.include?(:reject)
      origin.trigger_event(event_name: :reject)
      project_task.trigger_event(event_name: :reject)
      @changed_at = Time.current
    else
      @errors << "Can't reject this %{origin_state} %{origin_class}" % {
        origin_state: origin.state.humanize,
        origin_class: origin.class.name.titleize
      }
      return project_task
    end
    project_task.reload
  end

  def archive
    reset_errors

    if project_task.permitted_state_events.include?(:archive)
      project_task.trigger_event(event_name: :archive)
      @changed_at = Time.current
    else
      @errors << "Can't reject this %{origin_state} %{origin_class}" % {
        origin_state: origin.state.humanize,
        origin_class: origin.class.name.titleize
      }
    end
    project_task.reload
  end

  private

  def reset_errors
    @errors = []
  end

end
