class ProjectUserPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope
    end
  end

  def index?
    return false unless user
    user.admin? || user.executive?
  end

  def new?
    index?
  end

  def create?
    new?
  end

  def show?
    index?
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
    [:id, :user_id, :project_role_id]
  end

end
