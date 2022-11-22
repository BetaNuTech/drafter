require './spec/support/project_spec_helper'
RSpec.configure do |c|
  c.include ProjectSpecHelper
end

RSpec.shared_context 'sample_projects' do
  include_context 'projects'
  include_context 'project_roles'

  let(:sample_project) {

    project_owner = create(:user, role: executive_role)

    ProjectCostSample.load_seed_data
    project_service = Projects::Updater.new(project_owner, Project.new)
    project = project_service.create({name: 'test project'})

    # Assign ProjectCosts
    project.project_costs.update_all(total: 5000)

    # Other Organization
    other_organization = create(:organization)

    # Add Users
    add_project_user(user: project_owner, project: project, role: owner_project_role)

    project_manager = create(:user, role: executive_role)
    add_project_user(user: project_manager, project: project, role: manager_project_role)

    project_finance = create(:user, role: user_role)
    add_project_user(user: project_finance, project: project, role: finance_project_role)

    project_investor = create(:user, role: user_role)
    add_project_user(user: project_investor, project: project, role: investor_project_role)

    project_developer = create(:user, role: user_role)
    add_project_user(user: project_developer, project: project, role: developer_project_role)

    project_developer2 = create(:user, role: user_role, organization: other_organization)
    add_project_user(user: project_developer2, project: project, role: developer_project_role)

    # Add Draws 
    user = project.developers.first
    draw_service = DrawService.new(user:, project: )
    draw_service.create({amount: 5000.0})

    project.reload
    project
  }

  let(:sample_project2) {

    project_owner = create(:user, role: executive_role)

    ProjectCostSample.load_seed_data unless ProjectCostSample.any?

    project_service = Projects::Updater.new(project_owner, Project.new)
    project = project_service.create({name: 'test project'})

    # Assign ProjectCosts
    project.project_costs.update_all(total: 5000)

    # Other Organization
    other_organization = create(:organization)

    # Add Users
    add_project_user(user: project_owner, project: project, role: owner_project_role)

    project_manager = create(:user, role: executive_role)
    add_project_user(user: project_manager, project: project, role: manager_project_role)

    project_finance = create(:user, role: user_role)
    add_project_user(user: project_finance, project: project, role: finance_project_role)

    project_investor = create(:user, role: user_role)
    add_project_user(user: project_investor, project: project, role: investor_project_role)

    project_developer = create(:user, role: user_role)
    add_project_user(user: project_developer, project: project, role: developer_project_role)

    # Add Draws 
    user = project.developers.first
    draw_service = DrawService.new(user:, project: )
    draw1 = draw_service.create({amount: 5000.0})
    draw1.state = 'funded'
    draw1.save
    draw_service = DrawService.new(user:, project: )
    draw2 = draw_service.create({amount: 5000.0})

    # Add DrawCosts
    draw2.draw_costs.create!(total: 123.45, draw: sample_draw, project_cost: sample_project_cost)

    project.reload
    project
  }

  let(:sample_draw) {
    sample_project.draws.first
  }
  let(:sample_draw_cost) { 
    sample_draw.draw_costs.create!(total: 123.45, draw: sample_draw, project_cost: sample_project_cost)
  }
  let(:sample_project_cost) {
    sample_project.project_costs.drawable.sample
  }

  before do
    sample_project
  end

end
