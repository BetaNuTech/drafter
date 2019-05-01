module ApplicationHelper
  def short_date(datetime)
    datetime.present? ? datetime.strftime('%m-%d') : nil
  end

  def short_time(datetime)
    datetime.present? ? datetime.strftime('%l:%M%p') : nil
  end

  def short_datetime(datetime)
    datetime.present? ? datetime.strftime('%m-%d %l:%M%p') : nil
  end

  def long_datetime(datetime)
    datetime.present? ? datetime.strftime('%B %e, %Y at %l:%M%p') : nil
  end

  def long_date(datetime)
    datetime.present? ? datetime.strftime('%B %e, %Y') : nil
  end

  def glyph(type)
    _text, glyph_class = GLYPHS.fetch(type.to_s.gsub('_','-'),'')
    content_tag(:span, ' ', {class: glyph_class, "aria-hidden": true})
  end

  def select_glyph(val)
    options_for_select(GLYPHS.keys.map{|g| [g,g]}, val)
  end

  def nav_active_class(path)
    request.path.match(path) ? 'btn-success btn-nav-active' : 'btn-primary'
  end

  def nav_active_dropdown_class(path)
    request.path.match(path) ? 'btn-success' : 'btn-primary'
  end

  def select_state(val)
    options_for_select(us_states, val)
  end

  def navbar_cache_key
    [current_user, current_user.try(:messages).try(:unread).try(:size)]
  end

  def action_and_reason(record)
    return "" unless record.present?
    content_tag(:small) do
      content_tag(:span) do
        concat content_tag(:span, record&.lead_action&.name)
        if record&.reason&.present?
          if record&.lead_action&.present?
            concat content_tag(:span, ' &rarr; '.html_safe)
          end
          concat content_tag(:span, record&.reason&.name)
        end
      end
    end
  end
end
