class ProjectCostPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      case user
      when -> (u) { u.admin? }
        scope
      when -> (u) { u.executive? }
        scope
      else
        scope.where(project_id: user.projects.pluck(:id))
      end
    end
  end

  def index?
    privileged_user? || user.project_internal?(project)
  end

  def new?
    privileged_user? || user.project_management?(project)
  end

  def create?
    new?
  end

  def show?
    privileged_user? || user.project_internal?(project)
  end

  def edit?
    privileged_user? || user.project_management?(project)
  end

  def update?
    edit?
  end

  def destroy?
    record.draw_costs.empty? &&
    ( privileged_user? || user.project_management?(project) )
  end
  
  def approve?
    user.admin? ||
      user.project_internal?(project)
  end

  def reject?
    raise 'Not implemented'
  end

  def allowed_params
    case user
    when -> (u) { u.admin? }
      ProjectCost::ALLOWED_PARAMS
    when -> (u) { u.executive? }
      ProjectCost::ALLOWED_PARAMS
    when -> (u) { u.project_management?(record.project) }
      ProjectCost::ALLOWED_PARAMS
    else
      []
    end
  end

end
