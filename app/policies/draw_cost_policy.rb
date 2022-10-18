class DrawCostPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      case user
      when -> (u) { u.admin? }
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
    user.admin? || user.member?(record.project)
  end

  def new?
    user.admin? ||
      user.project_owner?(record.project) ||
      user.project_developer?(record.project)
  end

  def create?
    new?
  end

  def show?
    user.admin? ||
      user.project_internal?(record.project) ||
      ( user.project_developer?(record.project) &&
       user.organization_id == record.organization.id)
  end

  def edit?
    user.admin? ||
      user.project_internal?(record.project) ||
      ( user.project_developer?(record.project) &&
       user.organization_id == record.organization.id)
  end

  def update?
    edit?
  end

  def submit?
    edit?
  end

  def destroy?
    user.admin? ||
      user.project_owner?(record.project) ||
      ( user.project_developer?(record.project) &&
       user.organization_id == record.organization.id)
  end

  def withdraw?
    destroy?
  end

  def approve?
    user.admin? ||
      user.project_management?(record.project) ||
      ( user.project_finance?(record.project) && record&.draw_cost.clean? )
  end

  def reject?
    user.admin? ||
      user.project_management?(record.project) ||
      user.project_owner?(record.project) ||
      user.project_finance?(record.project)
  end

  def add_document?
    user.admin? ||
      ( user.project_developer?(record.project) &&
       user.organization_id == record.organization.id)
      user.project_management?(record.project) ||
      user.project_owner?(record.project)
  end

  def approve_document?
    user.admin? ||
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
