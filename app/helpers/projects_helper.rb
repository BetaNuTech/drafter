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

  def show_default_project_costs_budget_button?(project)
    !PRODUCTION_MODE && project.project_costs.where(total: [0.0, nil]).any?
  end
end
