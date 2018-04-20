module LeadsHelper
  def titles_for_select(val)
    options_for_select(%w{Ms. Mrs. Mr. Mx. Dr.}, val)
  end

  def display_preference_option(pref_attr)
    case pref_attr
    when Date,DateTime,ActiveSupport::TimeWithZone
      short_date(pref_attr)
    when String,Numeric
      pref_attr
    else
      pref_attr.present? ? 'Y' : 'No preference'
    end
  end

  def sources_for_select(lead_source_id)
    options_from_collection_for_select(LeadSource.active.order('name asc'), 'id', 'name', lead_source_id)
  end

  def properties_for_select(property_id)
    options_from_collection_for_select(Property.active.order('name asc'), 'id', 'name', property_id)
  end

  def state_toggle(lead)
    render partial: "leads/state_toggle", locals: { lead: lead }
  end

  def trigger_lead_state_event(lead:, event_name:)
    success = false
    if policy(lead).allow_state_event_by_user?(event_name)
      success = lead.trigger_event(event_name: event_name, user: current_user)
    end
    return success
  end

  def users_for_select(lead)
    options_from_collection_for_select(User.all, 'id', 'name', lead.user_id)
  end

  def priorities_for_select(lead)
    options_for_select(Lead.priorities.to_a.map{|p| [p[0].capitalize, p[0]]}, lead.priority)
  end

  def lead_priority_icon(lead)
    return "(?)" unless lead.present? && lead.priority.present?

    priority = lead.priority.to_sym
    icon_settings = {
      zero: {icon_count: 1, color: 'gray'},
      low: {icon_count: 2, color: 'black'},
      medium: {icon_count: 3, color: 'yellow'},
      high: {icon_count: 4, color: 'orange'},
      urgent: {icon_count: 5, color: 'red'}
    }

    container_class = "lead_priority_icon_#{priority}"
    color = icon_settings[priority][:color]
    count = icon_settings[priority][:icon_count]

    return tag.span(class: container_class, style: "opacity: 1 !important; color: '#{color}'") do
      count.times do
        concat(glyph(:fire))
      end
    end
  end
  
  def lead_state_label(lead)
    tag.span(class: 'label label-info') do
      lead.state.try(:titlecase)
    end
  end

end
