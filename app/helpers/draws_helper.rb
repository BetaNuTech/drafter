module DrawsHelper

  def draw_state_badge(draw)
    content_tag(:span, class: "badge bg-#{draw.state_css_class}") do
      draw.state.titleize
    end
  end

  def project_cost_cost_type_options
    ProjectCost.cost_types.to_a.map{|ct| [ct[0].capitalize, ct[0]]}
  end

  def project_cost_options(draw: , project_cost:)
    project = draw.project || project_cost&.project
    return '' if project.nil?
    non_initial_draw = project.draws.where("index > 1").first
    used_project_costs = draw.draw_costs.visible.pluck(:project_cost_id)
    used_project_costs = used_project_costs - [ project_cost.id ] if project_cost.present?
    project_costs = project.project_costs || ProjectCost.none
    if non_initial_draw.nil?
      project_costs = project_costs.drawable
    else   
      project_costs = project_costs.drawable_and_non_initial
    end
    project_costs = project_costs.where.not(id: used_project_costs)
    project_costs = project_costs.order(name: :asc)
    project_cost_options_with_remaining(project_costs, project_cost&.id, draw)
  end

  def draw_document_documenttype_options(draw:, draw_document:)
    return '' if draw.nil? || draw_document.nil?
    documenttypes =  draw.remaining_documents.inject({}){|memo, obj| memo[obj.capitalize] = obj; memo}
    options_for_select(documenttypes, draw_document.documenttype)
  end

  def change_order_funding_options(change_order)
    return '' if change_order.nil?

    project_cost_options_with_remaining(change_order.possible_project_costs_for_funding,
                                        change_order.project_cost_id)
  end

  def draw_cost_invoice_remaining_class(draw_cost)
    return 'warning' if draw_cost.nil?

    balance = draw_cost.subtotal
    case
    when balance == 0.0
      'success'
    when balance < 0.0
      'danger'
    else
      'warning'
    end
  end

  def project_cost_options_with_remaining(project_costs, current_value, draw=nil)
    return '' if project_costs.nil?

    project_cost_options = project_costs.map do |cost|
      remaining_balance = draw.present? ? cost.balance_available_for_draw(draw) : cost.budget_balance
      label = "%s (%s)" % [cost.name, number_to_currency(remaining_balance)]
      [label, cost.id, {data: {remaining: remaining_balance}}]
    end
    options_for_select(project_cost_options, current_value)
  end

  def displayed_invoice_state_name(invoice:, user:)
    return 'unknown_state' if invoice.nil? || user.nil?
    return invoice.state if user.admin?

    case invoice.state
    when 'processed', 'processing_failed'
      'submitted'
    else
      invoice.state
    end
  end

  def draw_action_issues(draw)
    proposed_action = nil
    issues = []
    case draw.state.to_sym
    when :pending, :rejected
      draw.enumerate_submit_problems
      proposed_action = 'Submitted'
    when :submitted
      draw.enumerate_approval_problems
      proposed_action = 'Approved'
    else
      return false
    end

    issues = draw.state_errors
    return false unless issues.present?

    {action: proposed_action, issues:}
  end
end
