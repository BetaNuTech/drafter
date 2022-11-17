class InvoicePolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      case user
      when -> (u) { u.admin? }
        scope
      when -> (u) { u.executive? }
        scope
      else
        scope.includes(draw_cost: [:draw]).where( draws: { project: u.projects })
      end
    end
  end

  def index?
    user.admin? || user.member?(record.project)
  end

  def new?
    record&.draw_cost&.draw&.rejected? ||
    ( record&.draw_cost&.allow_invoice_changes? &&
      ( user.admin? ||
       user.project_internal?(record.project) ||
       user.project_developer?(record.project)) )
  end

  def create?
    new?
  end

  def show?
    user.admin? ||
    user.project_internal?(record.project) ||
    user.project_developer?(record.project)
  end

  def edit?
    record&.draw_cost&.allow_invoice_changes? &&
      record.pending? && (
      user == record.user ||
        user.admin? ||
        user.project_internal?(record.project) ||
        user.project_developer?(record.project)
      )
  end

  def update?
    edit?
  end
  
  def destroy?
    record.permitted_state_events.include?(:remove) &&
      ( user == record.user ||
        user.admin? ||
        user.project_internal?(record.project) ||
        user.project_developer?(record.project)
      )
  end

  def remove?
    destroy?
  end

  def submit?
    record.pending? && edit?
  end

  def approvals?
    user.admin? ||
      user.project_internal?(record.project) ||
      user.project_finance?(record.project)
  end

  def approve?
    record.permitted_state_events.include?(:approve) &&
      approvals?
  end

  def reject?
    record.permitted_state_events.include?(:reject) &&
      approvals?
  end

  def allowed_params
    case user
    when -> (u) { u.admin? }
      Invoice::ALLOWED_PARAMS + [:multi_invoice]
    when -> (u) { u.project_internal?(record.project) }
      Invoice::ALLOWED_PARAMS + [:multi_invoice]
    when -> (u) { u.project_developer?(record.project) }
      Invoice::ALLOWED_PARAMS
    else
      []
    end
  end

end
