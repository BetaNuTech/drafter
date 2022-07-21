module ApplicationHelper

  def role_badge_color_class(role)
    case role.slug
    when 'admin'
      'danger'
    when 'executive'
      'info'
    when 'user'
      'success'
    else
      'dark'
    end
  end

  def event_severity_color_class(event)
    {
      debug: 'light',
      info: 'info',
      warn: 'warning',
      error: 'danger',
      fatal: 'danger',
      unknown: 'light'
    }.fetch(event.severity.to_sym, 'unknown')
  end

  def full_datetime(time)
    time&.strftime("%m/%d/%Y at %l:%M %p")
  end

end
