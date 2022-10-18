class DrawCostSubmissionPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      case user
      when -> (u) { u.admin? }
        scope
      when -> (u) { u.executive? }
        scope
      else
        scope.includes(draw_cost_request: { draw_cost: [:draw] }).where(
          draws: {project: user.projects},
          draw_cost_requests: { organization_id: user.organization_id }
        )
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
      user.project_owner?(record.project) ||
      user.project_management?(record.project) ||
      user.project_finance?(record.project) ||
      ( user.project_developer?(record.project) &&
        record.organization == user.organization)
  end

  def edit?
    user == record.user ||
      user.admin? ||
      user.project_owner?(record.project) ||
      user.project_management?(record.project) ||
      user.project_finance?(record.project) ||
      ( user.project_developer?(record.project) &&
        record.organization == user.organization)
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
    user == record.user ||
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
      Invoice::ALLOWED_PARAMS + [:multi_invoice]
    when -> (u) { u.project_owner?(record.project) }
      Invoice::ALLOWED_PARAM + [:multi_invoice]
    when -> (u) { u.project_developer?(record.project) }
      Invoice::ALLOWED_PARAMS
    else
      []
    end
  end

  def project
    record&.draw_cost&.draw&.project
  end

end
