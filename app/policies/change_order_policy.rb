class ChangeOrderPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      case user
      when -> (u) { u.admin? }
        scope
      when -> (u) { u.executive? }
        scope
      when -> (u) { u.user? }
        # DrawCostRequests for the user's assigned projects
        #  belonging to the user's assigned organization
        scope.includes(draw_costs: :draw).where(
          draws: { project: user.projects }
        )
      else
        # DrawCostRequests for the user's assigned projects
        scope.includes(draw_costs: :draw).where(draws: {project: user.projects})
      end
    end
  end

  def index?
    privileged_user? || user.member?(record.project)
  end

  def new?
    record.draw_cost.project_cost.change_request_allowed? &&
      record.draw.allow_draw_cost_changes? &&
      ( privileged_user? ||
        user.project_owner?(record.project) ||
        user.project_developer?(record.project) )
  end

  def create?
    new?
  end

  def show?
    privileged_user? || user.member?(record.project)
  end

  def edit?
    record.draw.allow_draw_cost_changes? &&
      ( privileged_user? ||
        user.project_internal?(record.project) ||
         user.project_developer?(record.project) )
  end

  def update?
    edit?
  end

  def destroy?
    record.draw.allow_draw_cost_changes? &&
    ( privileged_user? ||
      user.project_owner?(record.project) ||
       user.project_developer?(record.project) )
  end

  def approvals?
    record.draw_cost.draw.allow_invoice_approvals? &&
    ( user.admin? ||
      user.project_internal?(record.project) ||
      user.project_finance?(record.project) )
  end

  def approve?
    record.permitted_state_events.include?(:approve) &&
      approvals?
  end

  def reject?
    record.permitted_state_events.include?(:reject) &&
      approvals?
  end

  def reset_approval?
    record.permitted_state_events.include?(:reset_approval) &&
      approvals?
  end

  def allowed_params
    case user
    when -> (u) { u.admin? }
      ChangeOrder::ALLOWED_PARAMS
    when -> (u) { u.executive? }
      ChangeOrder::ALLOWED_PARAMS
    when -> (u) { u.project_owner?(record.project) }
      ChangeOrder::ALLOWED_PARAMS
    when -> (u) { u.project_finance?(record.project) }
      ChangeOrder::ALLOWED_PARAMS
    when -> (u) { u.project_developer?(record.project) }
      ChangeOrder::ALLOWED_PARAMS
    else
      []
    end
  end

end
