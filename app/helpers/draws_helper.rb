module DrawsHelper

  def draw_state_badge(draw)
    content_tag(:span, class: "badge bg-#{draw.state_css_class}") do
      draw.state.titleize
    end
  end

  def project_cost_cost_type_options
    ProjectCost.cost_types.to_a.map{|ct| [ct[0].capitalize, ct[0]]}
  end

  def prohect_cost_options(project: nil, draw_cost:)
    project_costs = ( project || project_cost&.project )&.project_costs&.order(name: :asc) || []
    options_from_collection_for_select( draw_costs, 'id', 'name', project_cost&.id)
  end
end
