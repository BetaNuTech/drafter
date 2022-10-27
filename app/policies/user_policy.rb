class UserPolicy < ApplicationPolicy

  class Scope < Scope
    def resolve
      scope
      case user
      when -> (u) { u.admin?}
        scope
      when -> (u) { u.executive? }
        scope
      when -> (u) { u.user? }
        User.where(id: user.id)
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
    user.admin? || user.executive?
  end

  def edit?
    case user
    when -> (u) { u === record }
      true
    when -> (u) { u.admin? }
      user.role >= record.role
    when -> (u) { u.executive? }
      (user.role >= record.role)
    else
      false
    end
  end

  def update?
    edit?
  end

  def show?
    edit? ||
    user.admin? ||
    property_executive? ||
    team_lead?
   end

  def destroy?
    record&.id.present? &&
    user.admin? && user != record && edit?
  end

  def deactivate?
    user.admin?
  end

  def switch_setting?
    update?
  end

  def impersonate?
    !record.deactivated? && ( user.admin? ) && !record.admin?
  end

  def assign_to_role?
    case user
    when nil
      false
    when ->(u) { user.admin? }
      true
    when -> (u) { u.executive? }
      false
    else
      false
    end
  end

  def assign_to_project_role?
    case user
    when nil
      false
    when ->(u) { user.admin? }
      true
    when -> (u) { u.executive? }
      false
    else
      false
    end
  end

  def assign_to_organization?
    case user
    when nil
      false
    when ->(u) { user.admin? }
      true
    when -> (u) { u.executive? }
      true
    else
      false
    end
  end

  def allowed_params
    valid_user_params = User::ALLOWED_PARAMS
    valid_user_profile_params = [ { profile_attributes: UserProfile::ALLOWED_PARAMS + [ UserProfile::APPSETTING_PARAMS ] } ]
    case user
    when nil
      valid_user_params = []
      valid_user_profile_params = []
    when ->(u) { u.admin? }
      # All valid fields allowed
      # Allow setting feature flags
      valid_user_params = valid_user_params + [:active, :role_id, :organization_id]
      valid_user_profile_params = [ { profile_attributes: UserProfile::ALLOWED_PARAMS + [ UserProfile::FEATURE_PARAMS ] + [ UserProfile::APPSETTING_PARAMS ] } ]
    when ->(u) { u.executive? }
      if user.user?
        # Only allow editing user role accounts
        # Allow deactivating user role accounts
        valid_user_params = valid_user_params + [:active, :organization_id]
      else
        # Disallow editing non-user role accounts
        valid_user_params = []
        valid_user_profile_params = []
      end
    when ->(u) { u.user? }
      unless record == user
        valid_user_params = User::ALLOWED_PARAMS
        valid_user_profile_params = [ { profile_attributes: UserProfile::ALLOWED_PARAMS + [ UserProfile::APPSETTING_PARAMS ] } ]
      end
    else
      # NOOP  
    end

    return(valid_user_params + valid_user_profile_params)
  end

  def may_change_role?(new_role_id=nil)
    return false unless new_role_id.present?
    return false unless user.role.present?
    new_role = Role.where(id: new_role_id).first
    return false unless new_role.present?
    return user.role >= new_role
  end

  def manage_features?
    user&.admin?
  end

  def roles_for_select
    return Role.all.to_a.sort.
      select{|role| user.role.present? ? user.role >= role : false}.
      map{|role| [role.name, role.id]}
  end

  def organizations_for_select
    OrganizationPolicy::Scope.new(user, Organization).resolve.
      order(name: :asc).
      map{|x| [x.name, x.id] }
  end

end
