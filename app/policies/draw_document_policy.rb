class DrawDocumentPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      case user
      when -> (u) { u.admin? || u.executive? }
        scope
      else
        scope.includes(:project).where(projects: {id: user.projects.pluck(:id)})
      end
    end
  end

  def index?
    privileged_user? || user.member?(record.project)
  end

  def new?
    record.draw.allow_document_changes? &&
      ( privileged_user? ||
        user.project_developer?(record.project) ||
        user.project_internal?(record.project) )
  end

  def create?
    new?
  end

  def show?
    privileged_user? ||
      user.member?(record.project) 
  end

  def edit?
    record.draw.allow_document_changes? &&
      ( privileged_user? ||
        user.project_internal?(record.project) ||
        user.project_developer?(record.project))
  end

  def update?
    edit?
  end

  def destroy?
    record.draw.allow_document_changes? &&
      ( privileged_user? ||
        user.project_owner?(record.project) ||
        user.project_developer?(record.project) )
  end

  def approvals?
    user.admin? ||
      user.project_internal?(record.project)
  end

  def approve?
    approvals? && record.permitted_state_events.include?(:approve)
  end

  def reject?
    approvals? && record.permitted_state_events.include?(:reject)
  end

  def reset_approval?
    approvals? && record.permitted_state_events.include?(:reset_approval)
  end

  def allowed_params
    DrawDocument::ALLOWED_PARAMS
  end
end
