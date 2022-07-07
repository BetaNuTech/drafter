module UsersHelper

  def role_options_for_select(user)
    options = [
      ['User', Role.user.id],
      ['Exectutive', Role.executive.id],
      ['Administrator', Role.admin.id]
    ]
    options_for_select(options, user&.role_id)
  end
end
