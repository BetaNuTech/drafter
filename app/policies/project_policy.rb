class ProjectPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      case user
      when -> (u) { u.admin? || u.executive? }
        scope
      else
        user.projects
      end
    end
  end

  def index?
    return false unless user

    privileged_user?
  end

  def new?
    privileged_user?
  end

  def create?
    new?
  end

  def show?
    privileged_user? || user.member?(record)
  end

  def project_tasks?
    show?
  end

  def edit?
    privileged_user? || user.project_owner?(record)
  end

  def update?
    edit?
  end

  def destroy?
    user.admin? || user.project_owner?(record)
  end

  def add_member?
    edit? || user.project_management?(record)
  end

  def remove_member?
    add_member?
  end

  def allowed_params
    case user
    when ->(u) { u.admin? || u.executive? }
      Project::ALLOWED_PARAMS
    when -> (u) { u.project_manager?(record) }
      Project::ALLOWED_PARAMS
    else
      []
    end
  end

end
