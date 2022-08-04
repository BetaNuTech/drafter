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

  def breadcrumbs_tag
    return '' unless defined?(@breadcrumbs)

    content_tag(:nav, 'aria-label': 'breadcrumb', class: 'breadcrumbs', style: '--bs-breadcrumb-divider: \'>\';') do
      concat(content_tag(:ol, class: 'breadcrumb') do
        @breadcrumbs.each do |crumb|
          classes = ['breadcrumb-item']
          classes << 'active' if crumb.active
          options = {class: classes.join(' ')}
          options['aria-current'] = 'page' if crumb.active
          concat(content_tag(:li, options) do
            if crumb.active
              crumb.label
            else
              link_to(crumb.label, crumb.url, {turbo_frame: '_top'})
            end
          end)
        end
      end)
    end
  end

end
