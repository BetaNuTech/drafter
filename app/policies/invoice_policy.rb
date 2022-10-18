class InvoicePolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      case user
      when -> (u) { u.admin? }
        scope
      when -> (u) { u.executive? }
        scope
      else
        scope.includes(draw_cost: [:draw]).where(
          draws: { project: u.projects, organization_id: u.organization_id }
        )
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
      user.project_owner?(record.project) ||
      user.project_management?(record.project) ||
      user.project_finance?(record.project) ||
      ( user.project_developer?(record.project) &&
        record.draw_cost_request.organization == user.organization)
  end

  def edit?
    user == record.user ||
      user.admin? ||
      user.project_owner?(record.project) ||
      user.project_management?(record.project) ||
      user.project_finance?(record.project) ||
      ( user.project_developer?(record.project) &&
        record.draw_cost_request.organization == user.organization)
  end

  def update?
    edit?
  end
  
  def destroy?
    user == record.user ||
      user.admin? ||
      user.project_owner?(record.project)
  end

  def submit?
    edit?
  end

  def remove?
    destroy?
  end

  def approve?
    user.admin? ||
      user.project_owner?(record.project) ||
      user.project_management?(record.project) ||
      user.project_finance?(record.project)
  end

  def reject?
    approve?
  end

  def allowed_params
    case user
    when -> (u) { u.admin? }
      DrawCostSubmission::ALLOWED_PARAMS + [:multi_invoice]
    when -> (u) { u.project_owner?(record.project) }
      DrawCostSubmission::ALLOWED_PARAM + [:multi_invoice]
    when -> (u) { u.project_developer?(record.project) }
      DrawCostSubmission::ALLOWED_PARAMS
    else
      []
    end
  end

end
