class DrawPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      case user
      when -> (u) { u.administrator? }
      else
        scope.where(project: user.projects)
      end
    end
  end

  def index?
    user.administrator? || user.member?(record.project)
  end

  def new?
    user.administrator? || user.project_management?(record.project)
  end

  def create?
    new?
  end

  def show?
    new?
  end

  def edit?
    new?
  end

  def update?
    edit?
  end

  def destroy?
    edit?
  end

  def allowed_params
    case user
    when -> (u) { u.administrator? }
      Draw::ALLOWED_PARAMS
    when -> (u) { u.project_management?(record.project) }
      Draw::ALLOWED_PARAMS
    else
      []
    end
  end
end
