module ProjectTasksHelper
  PROJECT_TASK_STATE_CLASS_MAPPING = {
    new: :secondary,
    needs_review: :info,
    needs_consult: :info,
    rejected: :danger,
    approved: :success,
    archived: :warning
  }.freeze

  def project_task_origin_url(project_task)
    origin = project_task.origin
    case origin
      when Invoice, DrawDocument
        if origin.respond_to?(:document) && origin.document.attached?
          rails_blob_path(origin.document)
        else
          url_for([ project_task.project, project_task.origin.draw ])
        end
      else
        '#'
    end
  end

  def project_task_due_class(project_task)
    now = Date.current
    case project_task.due_at
    when (now + 1.day)..(now + 2.days)
      'warning'
    when (now + 1.day)..(now)
      'danger'
    else
      'success'
    end
  end

  def project_task_state_class(project_task)
    PROJECT_TASK_STATE_CLASS_MAPPING.fetch(project_task.state.to_sym, :secondary).to_s
  end
end
