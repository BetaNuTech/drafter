module ProjectTasksHelper

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
end
