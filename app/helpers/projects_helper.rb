module ProjectsHelper
  def project_role_background_class(role)
    {
      owner: 'danger',
      manager: 'warning',
      finance: 'success',
      consultant: 'info',
      developer: 'primary'
    }.fetch(role.slug.to_sym, :developer)
  end
end
