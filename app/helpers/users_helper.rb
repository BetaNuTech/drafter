module UsersHelper

  def role_options_for_select(user)
    policy_options = policy(user).roles_for_select
    options_for_select(policy_options, user&.role_id)
  end

  def organization_options_for_select(user)
    policy_options = policy(user).organizations_for_select
    options_for_select(policy_options, user&.organization_id)
  end
end
