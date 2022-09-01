class DrawCostRequestPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      case user
      when -> (u) { u.administrator? }
        scope
      else
        # DrawCostRequests for the user's assigned projects
        scope.includes(:draw).where(draws: {project: user.projects})
      end
    end
  end

  def index?
    user.administrator? || user.member?(record.project)
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
    user == record.user ||
      user.admin? ||
      user.project_internal?(record.project) ||
      ( user.project_developer?(record.project) &&
       user.organization_id == record.organization_id)
  end

  def edit?
    user == record.user ||
      user.admin? ||
      user.project_internal?(record.project) ||
      ( user.project_developer?(record.project) &&
       user.organization_id == record.organization_id)
  end

  def update?
    edit?
  end

  def submit?
    edit?
  end

  def destroy?
    user == record.user ||
      user.admin? ||
      user.project_owner?(record.project)
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
      user.project_developer?(record.project) ||
      user.project_management?(record.project) ||
      user.project_owner?(record.project)
  end

  def remove_document?
    record.user == user || add_document?
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
      DrawCostRequest::ALLOWED_PARAMS
    when -> (u) { u.project_owner?(record.project) }
      DrawCostRequest::ALLOWED_PARAMS
    when -> (u) { u.project_developer?(record.project) }
      DrawCostRequest::ALLOWED_PARAMS
    else
      []
    end
  end

end
