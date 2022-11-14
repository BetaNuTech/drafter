module DrawsHelper

  def draw_state_badge(draw)
    content_tag(:span, class: "badge bg-#{draw.state_css_class}") do
      draw.state.titleize
    end
  end

  def project_cost_cost_type_options
    ProjectCost.cost_types.to_a.map{|ct| [ct[0].capitalize, ct[0]]}
  end

  def project_cost_options(project: nil, project_cost:)
    non_initial_draw = ( project || project_cost&.project ).draws.where("index > 1").first
    if non_initial_draw.nil?
      project_costs = ( project || project_cost&.project )&.project_costs&.drawable&.order(name: :asc) || []
    else   
      project_costs = ( project || project_cost&.project )&.project_costs&.drawable_and_non_initial&.order(name: :asc) || []
    end
    project_cost_options_with_remaining(project_costs, project_cost&.id)
  end

  def change_order_project_cost_options(project: nil, change_order_project_cost:)
    project_costs = ( project || project_cost&.project )&.project_costs&.change_requestable&.order(name: :asc) || []
    options_from_collection_for_select(project_costs, 'id', 'name', change_order_project_cost&.id)
  end

  def draw_document_documenttype_options(draw:, draw_document:)
    documenttypes =  draw.remaining_documents.inject({}){|memo, obj| memo[obj.capitalize] = obj; memo}
    options_for_select(documenttypes, draw_document.documenttype)
  end

  def change_order_funding_options(change_order)
    proposed_amount = change_order.draw_cost.project_cost_overage
    project_costs = change_order.project.project_costs.where.not(id: change_order.draw_cost.project_cost_id).select{|cost| cost.budget_balance >= proposed_amount  }
    project_cost_options_with_remaining(project_costs, change_order.project_cost_id)
  end

  def draw_cost_invoice_remaining_class(draw_cost)
    subtotal = draw_cost.subtotal
    case
    when subtotal == 0.0
      'success'
    when subtotal < 0.0
      'danger'
    else
      'warning'
    end
  end

  def project_cost_options_with_remaining(project_costs, current_value)
    project_cost_options = project_costs.map do |cost|
      balance = cost.budget_balance
      label = "%s (%s)" % [cost.name, number_to_currency(balance)]
      [label, cost.id, {data: {remaining: cost.budget_balance}}]
    end
    options_for_select(project_cost_options, current_value)
  end
end
