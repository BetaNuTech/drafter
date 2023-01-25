class ProjectTaskService
  attr_reader :project_task, :errors

  PERMITTED_EVENTS = %i{verify reject archive}

  def initialize(project_task=nil)
    @project_task = project_task
    @errors = []
  end

  def generate(origin:, assignee:, action:)
    ProjectTaskServices::Generator.call(origin:, assignee:, action:)
  end

  def trigger_event(event_name)
    reset_errors

    unless PERMITTED_EVENTS.include?(event_name.to_sym)
      @errors << "#{event_name} is not a valid Project Task event"
      return false
    end

    public_send(event_name)
  end

  def verify
    reset_errors
    origin = project_task.origin

    if project_task.permitted_state_events.include?(:verify) && origin.permitted_state_events.include?(:approve)
      origin.trigger_event(event_name: :approve)
      project_task.trigger_event(event_name: :verify)
    else
      @errors << "Can't approve this %{origin_state} %{origin_class}" % {
        origin_state: origin.state.humanize,
        origin_class: origin.class.name.titleize
      }
      return project_task
    end
    project_task.reload
  end

  def reject
    reset_errors
    origin = project_task.origin

    if project_task.permitted_state_events.include?(:reject) && origin.permitted_state_events.include?(:reject)
      origin.trigger_event(event_name: :reject)
      project_task.trigger_event(event_name: :reject)
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
    else
      @errors << "Can't reject this %{origin_state} %{origin_class}" % {
        origin_state: origin.state.humanize,
        origin_class: origin.class.name.titleize
      }
    end
    project_task.reload
  end

  def errors?
    @errors.any?
  end

  private

  def reset_errors
    @errors = []
  end

end
