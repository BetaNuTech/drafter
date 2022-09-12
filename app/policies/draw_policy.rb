class DrawPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      case user
      when -> (u) { u.admin? }
        scope
      else
        scope.where(project: user.projects)
      end
    end
  end

  def index?
    user.admin? || user.member?(record.project)
  end

  def new?
    user.admin? || user.project_management?(record.project)
  end

  def create?
    new?
  end

  def show?
    user.admin? || user.member?(record.project)
  end

  def edit?
    new?
  end

  def update?
    edit?
  end

  def destroy?
    user.admin? || user.project_owner?(record.project)
  end

  def set_reference?
    record.approved?
  end

  def new_request?(organization)
    !record.active_requests_for?(organization) &&
      ( user.admin? ||
        user.project_owner?(record.project) ||
        user.project_developer?(record.project) )
  end

  def allowed_params
    allow_params = Draw::ALLOWED_PARAMS
    if record.approved?
      allow_params << :reference
    end
    case user
    when -> (u) { u.administrator? }
      allow_params
    when -> (u) { u.project_management?(record.project) }
      allow_params
    else
      []
    end
  end
end
