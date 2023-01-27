class ProjectTaskPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      case user
      when -> (u) { u.admin? || u.executive? }
        scope
      else
        ProjectTask.where(project: user.projects)
      end
    end
  end

  def index?
    return false
    #return false unless user

    #privileged_user?
  end

  def new?
    return false
    #privileged_user? || user.projects.any?
  end

  def create?
    return false
    #new?
  end

  def show?
    privileged_user? || user.project_internal?(record.project)
  end

  def edit?
    return false
    #show?
  end

  def update?
    return false
    #edit?
  end

  def destroy?
    return false
    #privileged_user?
  end

  def approve?
    privileged_user? || user.project_internal?(record.project)
  end

  def reject?
    approve?
  end

  def archive?
    approve?
  end

end
