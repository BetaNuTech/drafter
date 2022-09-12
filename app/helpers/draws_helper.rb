module DrawsHelper

  def draw_state_badge(draw)
    content_tag(:span, class: "badge bg-#{draw.state_css_class}") do
      draw.state.titleize
    end
  end

  def draw_cost_cost_type_options
    DrawCost.cost_types.to_a.map{|ct| [ct[0].capitalize, ct[0]]}
  end

  def draw_cost_options(project: nil, draw_cost:)
    draw_costs = ( project || draw_cost&.project )&.draw_costs&.order(name: :asc) || []
    options_from_collection_for_select( draw_costs, 'id', 'name', draw_cost&.id)
  end
end
