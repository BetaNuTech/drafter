module ProjectsHelper
  def project_role_background_class(role)
    {
      owner: 'danger',
      manager: 'warning',
      finance: 'success',
      investor: 'info',
      developer: 'primary'
    }.fetch(role.slug.to_sym, :developer)
  end
end
