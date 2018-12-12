class ProspectStats
  attr_reader :options

  def initialize(options={})
    @options = options
    @voyager_source = LeadSource.where(slug: 'YardiVoyager').first
  end

  def property_stats
    Property.order(name: 'asc').map do |property|
      {
        "Name": property.name,
        "ID": property_voyager_id(property),
        "Stats": {
          "Prospects10": prospect_count_all(property, 10),
          "Prospects30": prospect_count_all(property, 30),
          "Prospects180": prospect_count_all(property, 180),
          "Prospects365": prospect_count_all(property, 365),
          "Closings10": closing_rate(property, 10),
          "Closings30": closing_rate(property, 30),
          "Closings180": closing_rate(property, 180),
          "Closings365": closing_rate(property, 365),
          "Conversions10": conversion_rate(property, 10),
          "Conversions30": conversion_rate(property, 30),
          "Conversions180": conversion_rate(property, 180),
          "Conversions365": conversion_rate(property, 365)
        }
      }
    end.compact
  end

  def agent_stats
    User.includes(:profile).order("user_profiles.last_name ASC, user_profiles.first_name ASC").map do |user|
      next unless user.leads.count > 0
      {
        "Name": user.name,
        "ID": user.id,
        "Stats": {
          "Prospects10": prospect_count_all(user, 10),
          "Prospects30": prospect_count_all(user, 30),
          "Prospects180": prospect_count_all(user, 180),
          "Prospects365": prospect_count_all(user, 365),
          "Closings10": closing_rate(user, 10),
          "Closings30": closing_rate(user, 30),
          "Closings180": closing_rate(user, 180),
          "Closings365": closing_rate(user, 365),
          "Conversions10": conversion_rate(user, 10),
          "Conversions30": conversion_rate(user, 30),
          "Conversions180": conversion_rate(user, 180),
          "Conversions365": conversion_rate(user, 365)
        }
      }
    end.compact
  end

  def team_stats
    Team.order(name: 'asc').map do |team|
      next unless team.leads.count > 0
      {
        "Name": team.name,
        "ID": team.id,
        "Stats": {
          "Prospects10": prospect_count_all(team, 10),
          "Prospects30": prospect_count_all(team, 30),
          "Prospects180": prospect_count_all(team, 180),
          "Prospects365": prospect_count_all(team, 365),
          "Closings10": closing_rate(team, 10),
          "Closings30": closing_rate(team, 30),
          "Closings180": closing_rate(team, 180),
          "Closings365": closing_rate(team, 365),
          "Conversions10": conversion_rate(team, 10),
          "Conversions30": conversion_rate(team, 30),
          "Conversions180": conversion_rate(team, 180),
          "Conversions365": conversion_rate(team, 365)
        }
      }
    end.compact
  end

  private

  def property_voyager_id(property)
    raise "Missing LeadSource: 'YardiVoyager'" unless @voyager_source.present?
    return property.listing_code(@voyager_source)
  end

  def prospect_count_all(skope, window)
    return prospect_count_all_scope(skope, window).count
  end

  def prospect_count_all_scope(skope, window)
    return skope.leads.
      joins("INNER JOIN lead_transitions ON lead_transitions.lead_id = leads.id").
      where("( lead_transitions.last_state != 'none' OR ( lead_transitions.last_state = 'none' AND lead_transitions.current_state NOT IN (#{Lead::CLOSED_STATES.map{|s| "'#{s}'"}.join(',')})) ) AND (leads.created_at BETWEEN ? AND ?)", window.days.ago, DateTime.now)
  end

  def prospect_count(skope, window)

  end

  def conversion_rate(skope, window)
    count = skope.leads.includes(:lead_transitions).
      where(lead_transitions: {
        current_state: 'application',
        created_at: window.days.ago..DateTime.now
      }).count
    return calculate_lead_pctg(count, skope, window)
  end

  def closing_rate(skope, window)
    count = skope.leads.includes(:lead_transitions).
      where(lead_transitions: {
        current_state: 'movein',
        created_at: window.days.ago..DateTime.now
      }).count
    return calculate_lead_pctg(count, skope, window)
  end

  def calculate_lead_pctg(count, skope, window)
    if count > 0
      rate = (count.to_f / prospect_count_all(skope,window).to_f).round(3)
    else
      rate = 0.0
    end
    return rate
  end

end
