class ProjectPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      case user
      when -> (u) { u.admin? }
        scope
      when -> (u) { u.executive? }
        scope
      else
        user.projects
      end
    end
  end

  def index?
    return false unless user

    user.administrator?
  end

  def new?
    user.administrator?
  end

  def create?
    new?
  end

  def show?
    user.administrator? || user.member?(record)
  end

  def edit?
    user.administrator? || user.project_management?(record)
  end

  def update?
    edit?
  end

  def destroy?
    user.administrator?
  end

  def add_member?
    edit?
  end

  def remove_member?
    add_member?
  end

  def allowed_params
    case user
    when ->(u) { u.administrator? }
      Project::ALLOWED_PARAMS
    when -> (u) { u.project_manager?(record) }
      Project::ALLOWED_PARAMS
    else
      []
    end
  end

end
