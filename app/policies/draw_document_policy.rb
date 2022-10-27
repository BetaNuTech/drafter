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
        user.project_management?(record.project) )
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
        user.project_management?(record.project) ||
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

  def approve_internal?
    raise 'TODO'
    privileged_user? ||
      user.project_internal?(record.project)
    # TODO invoices approved?
  end

  def allowed_params
    DrawDocument::ALLOWED_PARAMS
  end
end
