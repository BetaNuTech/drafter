class DrawPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      case user
      when -> (u) { u.admin? || u.executive? }
        scope
      else
        scope.where(project: user.projects)
      end
    end
  end

  def index?
    privileged_user? || user.member?(record.project)
  end

  def new?
    record.project.allow_new_draw? &&
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
    privileged_user? ||
      user.project_internal?(record.project) ||
      ( ( record.pending? || record.rejected? ) &&
          user.project_developer?(record.project) ) 
  end

  def update?
    edit?
  end

  def destroy?
    return false unless record.permitted_state_events.include?(:withdraw)
  
    if record.state == 'funded'
      user.admin?
    else
      privileged_user? ||
        user.project_owner?(record.project) ||
        ( user.project_developer?(record.project) &&
          %w{pending submitted rejected}.include?(record.state) )
    end
  end

  def withdraw?
    destroy?
  end

  def submit?
    record.permitted_state_events.include?(:submit) &&
      ( privileged_user? ||
        user.project_owner?(record.project) ||
        user.project_developer?(record.project) )
  end

  def set_reference?
    record.funded? && user.project_internal?(record.project)
  end

  def approve?
    record.permitted_state_events.include?(:approve) &&
    ( user.admin? ||
      user.project_management?(record.project) ||
      (record.clean? && user.project_finance?(record.project)) )
  end

  def approve_but_blocked?
    !approve? &&
    record.permitted_state_events.include?(:approve) &&
    ( !record.clean? && user.project_finance?(record.project) ) 
  end

  # def approve_internal?
  #   record.permitted_state_events.include?(:approve_internal) &&
  #   ( user.admin? ||
  #     user.project_management?(record.project) ||
  #     (record.clean? && user.project_finance?(record.project)) )
  # end

  # def approve_internal_but_blocked?
  #   !approve_internal? &&
  #   record.permitted_state_events.include?(:approve_internal) &&
  #   ( !record.clean? && user.project_finance?(record.project) ) 
  # end

  # def approve_external?
  #   record.permitted_state_events.include?(:approve_external) &&
  #   ( user.admin? ||
  #     user.project_internal?(record.project) )
  # end

  def reject?
    return false unless record.permitted_state_events.include?(:reject)
  
    if record.state == 'funded'
      user.admin?
    else
      user.admin? ||
        user.project_management?(record.project) ||
        user.project_finance?(record.project)
    end
  end

  def fund?
    record.permitted_state_events.include?(:fund) &&
    ( user.admin? ||
      user.project_internal?(record.project))
  end

  def download_packet?
    record.document_packet.attached? &&
    ( privileged_user? || user.member?(record.project) )
  end

  def download_summary_sheet?
    record.draw_summary_sheet.attached? &&
    ( privileged_user? || user.member?(record.project) )
  end

  def allowed_params
    allow_params = Draw::ALLOWED_PARAMS
    case user
    when -> (u) { u.admin? || u.executive? }
      allow_params << :organization_id
      allow_params << :reference if record.funded?
      allow_params
    when -> (u) { u.project_internal?(record.project) }
      allow_params << :organization_id
      allow_params << :reference if record.funded?
      allow_params
    else
      allow_params
    end
  end
end
