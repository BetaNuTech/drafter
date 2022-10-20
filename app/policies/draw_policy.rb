class DrawPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      case user
      when -> (u) { u.admin? }
        scope
      else
        scope.where(project: user.projects, organization: user.organization)
      end
    end
  end

  def index?
    user.admin? || user.member?(record.project)
  end

  def new?
    record.project.allow_new_draw?(user.organization) &&
      (
        user.admin? ||
          user.project_developer?(record.project) ||
          user.project_management?(record.project) 
      )
  end

  def create?
    new?
  end

  def show?
    user.admin? ||
      user.project_management?(record.project) ||
      ( record.organization.present? &&
          user.organization == record.organization &&
          user.member?(record.project) )
  end

  def edit?
    user.admin? ||
      user.project_management?(record.project) ||
      ( record.organization.present? &&
          user.organization == record.organization &&
          user.member?(record.project) )
  end

  def update?
    edit?
  end

  def destroy?
    user.admin? ||
      user.project_owner?(record.project) ||
      ( record.permitted_state_events.include?(:withdraw) &&
        user.project_developer?(record.project) &&
        own_organization? )
  end

  def withdraw?
    destroy?
  end

  def set_reference?
    record.approved?
  end

  def approve_internal?
    raise 'TODO'
    user.admin? ||
      user.project_internal?(record.project)
    # TODO invoices approved?
  end

  def own_organization?
    user.organization == record.organization
  end

  def new_request?(organization)
    ( user.admin? ||
      user.project_owner?(record.project) ||
      user.project_developer?(record.project) )
  end

  def allowed_params
    allow_params = Draw::ALLOWED_PARAMS
    case user
    when -> (u) { u.administrator? }
      allow_params << :organization_id
      allow_params << :reference if record.funded?
      allow_params
    when -> (u) { u.project_management?(record.project) }
      allow_params << :organization_id
      allow_params << :reference if record.funded?
      allow_params
    when -> (u) { u.project_finance?(record.project) }
      allow_params << :reference if record.funded?
      allow_params
    else
      allow_params
    end
  end
end
