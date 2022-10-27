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
          draws: { project: user.projects,
                   organization_id: user.organization_id }
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
        user.project_owner?(record.project) ||
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
      user.project_owner?(record.project) ||
      ( user.project_developer?(record.project) &&
       user.organization_id == record.organization.id) )
  end

  def withdraw?
    record.permitted_state_events.include?(:withdraw) &&
    destroy?
  end

  def approve?
    privileged_user? ||
      user.project_management?(record.project) ||
      ( user.project_finance?(record.project) && record&.draw_cost.clean? )
  end

  def reject?
    privileged_user? ||
      user.project_management?(record.project) ||
      user.project_owner?(record.project) ||
      user.project_finance?(record.project)
  end

  def add_document?
    privileged_user? ||
      ( user.project_developer?(record.project) &&
       user.organization_id == record.organization.id)
      user.project_management?(record.project) ||
      user.project_owner?(record.project)
  end

  def approve_document?
    privileged_user? ||
      user.project_management?(record.project) ||
      user.project_owner?(record.project)
  end

  def reject_document?
    approve_document?
  end

  def allowed_params
    case user
    when -> (u) { u.admin? }
      DrawCost::ALLOWED_PARAMS
    when -> (u) { u.project_owner?(record.project) }
      DrawCost::ALLOWED_PARAMS
    when -> (u) { ( u.project_developer?(record.project) && u.organization_id == record.organization.id) }
      DrawCost::ALLOWED_PARAMS
    else
      []
    end
  end

end
