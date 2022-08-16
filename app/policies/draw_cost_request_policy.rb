class DrawCostRequestPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      case user
      when -> (u) { u.administrator? }
        scope
      else
        # DrawCostRequests for the user's assigned projects
        scope.includes(:draw).where(draws: {project: user.projects})
      end
    end
  end

  def index?
    user.administrator? || user.member?(record.project)
  end

  def new?
    user.administrator? ||
      user.project_management?(record.project) ||
      user.project_role(record.project)&.developer?
  end

  def create?
    new?
  end

  def show?
    user.administrator? || user.member?(record.project)
  end

  def edit?
    user == record.user ||
      user.administrator? ||
      user.project_management?(record.project) ||
      user.project_developer?(record.project)
  end

  def update?
    edit?
  end

  def destroy?
    user == record.user ||
      user.administrator? ||
      user.project_management?(record.project)
  end

  def allowed_params
    # TODO
    case user
    when -> (u) { u.administrator? }
      DrawCostRequest::ALLOWED_PARAMS
    when -> (u) { u.member?(record.project) }
      DrawCostRequest::ALLOWED_PARAMS
    else
      []
    end
  end

end
