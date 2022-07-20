class ProjectPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      case user
      when -> (u) { u.admin? }
        scope
      when -> (u) { u.executive? }
        scope
      else
        # TODO
        Project.where("1=0")
      end
    end
  end

  def index?
    return false unless user

    user.admin? || user.executive?
  end

  def new?
    user.admin? || user.executive?
  end

  def create?
    new?
  end

  def show?
    user.admin? || user.executive?
  end

  def edit?
    user.admin? || user.executive?
  end

  def update?
    edit?
  end

  def destroy?
    user.admin? || user.executive?
  end

  def add_member?
    user.admin? || user.executive?
  end

  def allowed_params
    case user
    when ->(u) { u.admin? }
      Project::ALLOWED_PARAMS
    when ->(u) { u.corporate? }
      Project::ALLOWED_PARAMS
    else
      []
    end
  end

end
