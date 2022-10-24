class DrawPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      case user
      when -> (u) { u.admin? || u.executive? }
        scope
      else
        scope.where(project: user.projects)
      end
    end
  end

  def index?
    privileged_user? || user.member?(record.project)
  end

  def new?
    record.project.allow_new_draw? &&
      ( privileged_user? ||
        user.project_developer?(record.project) ||
        user.project_management?(record.project) )
  end

  def create?
    new?
  end

  def show?
    privileged_user? ||
      user.member?(record.project) 
  end

  def edit?
    privileged_user? ||
      user.project_management?(record.project) ||
      ( ( record.pending? || record.rejected? ) &&
          user.project_developer?(record.project) ) 
  end

  def update?
    edit?
  end

  def destroy?
    record.permitted_state_events.include?(:withdraw) &&
      ( privileged_user? ||
        user.project_owner?(record.project) ||
        user.project_developer?(record.project) )
  end

  def withdraw?
    destroy?
  end

  def submit?
    record.permitted_state_events.include?(:submit) &&
      ( privileged_user? ||
        user.project_owner?(record.project) ||
        user.project_developer?(record.project) )
  end

  def set_reference?
    record.approved?
  end

  def approve_internal?
    raise 'TODO'
    privileged_user? ||
      user.project_internal?(record.project)
    # TODO invoices approved?
  end

  def new_request?(organization)
    ( privileged_user? ||
      user.project_owner?(record.project) ||
      user.project_developer?(record.project) )
  end

  def allowed_params
    allow_params = Draw::ALLOWED_PARAMS
    case user
    when -> (u) { u.admin? || u.executive? }
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
