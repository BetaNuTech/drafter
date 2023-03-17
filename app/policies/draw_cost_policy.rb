class DrawCostPolicy < ApplicationPolicy
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
        scope.includes(:draw).where(
          draws: { project: user.projects }
        )
      else
        # DrawCostRequests for the user's assigned projects
        scope.includes(:draw).where(draws: {project: user.projects})
      end
    end
  end

  def index?
    privileged_user? || user.member?(record.project)
  end

  def new?
    record.draw.allow_draw_cost_changes? &&
      ( privileged_user? ||
        user.project_internal?(record.project) ||
        user.project_developer?(record.project) )
  end

  def create?
    new?
  end

  def show?
    privileged_user? ||
      user.project_internal?(record.project) ||
      user.project_developer?(record.project)
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

  def submit?
    record.permitted_state_events.include?(:submit) &&
      edit?
  end

  def destroy?
    record.draw.allow_draw_cost_changes? &&
      ( privileged_user? ||
        user.project_developer?(record.project) ||
        user.project_internal?(record.project) )
  end

  def withdraw?
    record.permitted_state_events.include?(:withdraw) &&
      destroy?
  end

  def approvals?
    user.admin? ||
      user.project_internal?(record.project)
  end

  def approve?
    record.permitted_state_events.include?(:approve) &&
      approvals?
  end

  def reject?
    record.permitted_state_events.include?(:reject) &&
      approvals?
  end

  def add_document?
    privileged_user? ||
      user.project_developer?(record.project)
      user.project_internal?(record.project)
  end

  def approve_document?
    privileged_user? ||
      user.project_internal?(record.project)
  end

  def reject_document?
    approve_document?
  end

  def add_change_order?
    update? && record.requires_change_order? && record.allow_new_change_order?
  end

  def allowed_params
    case user
    when -> (u) { u.admin? }
      DrawCost::ALLOWED_PARAMS
    when -> (u) { u.executive? }
      DrawCost::ALLOWED_PARAMS
    when -> (u) { u.project_internal?(record.project) }
      DrawCost::ALLOWED_PARAMS
    when -> (u) { u.project_developer?(record.project) }
      DrawCost::ALLOWED_PARAMS
    else
      []
    end
  end

end
