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
    record&.draw_cost&.allow_invoice_changes? &&
      ( user.admin? ||
       user.project_owner?(record.project) ||
       user.project_developer?(record.project)
      ) 
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
        record.organization == user.organization)
  end

  def edit?
    record&.draw_cost&.allow_invoice_changes? &&
      record.pending? && (
      user == record.user ||
        user.admin? ||
        user.project_owner?(record.project) ||
        user.project_management?(record.project) ||
        user.project_finance?(record.project) ||
        ( user.project_developer?(record.project) &&
          record.organization == user.organization)
      )
  end

  def update?
    edit?
  end
  
  def destroy?
    record&.draw_cost&.allow_invoice_changes? &&
    ( user == record.user ||
      user.admin? ||
      user.project_owner?(record.project) )
  end

  def remove?
    destroy?
  end

  def submit?
    record.pending? && edit?
  end

  def approve?
    # TODO: invoice processing and remove submitted? condition below
    ( record.submitted? || record.processed? ) &&
    user.admin? ||
      user.project_owner?(record.project) ||
      user.project_management?(record.project) ||
      user.project_finance?(record.project)
  end

  def reject?
    # TODO: invoice processing and remove submitted? condition below
    ( record.submitted? || record.processed? ) &&
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

end