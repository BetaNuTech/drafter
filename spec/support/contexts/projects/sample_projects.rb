require './spec/support/project_spec_helper'
RSpec.configure do |c|
  c.include ProjectSpecHelper
end

RSpec.shared_context 'sample_projects' do
  include_context 'projects'
  include_context 'project_roles'

  let(:sample_project) {
    project = create(:project)

    # Other Organization
    other_organization = create(:organization)

    # Add Users
    project_owner = create(:user, role: executive_role)
    add_project_user(user: project_owner, project: project, role: owner_project_role)

    project_manager = create(:user, role: executive_role)
    add_project_user(user: project_manager, project: project, role: manager_project_role)

    project_finance = create(:user, role: user_role)
    add_project_user(user: project_finance, project: project, role: finance_project_role)

    project_consultant = create(:user, role: user_role)
    add_project_user(user: project_consultant, project: project, role: consultant_project_role)

    project_developer = create(:user, role: user_role)
    add_project_user(user: project_developer, project: project, role: developer_project_role)

    project_developer2 = create(:user, role: user_role, organization: other_organization)
    add_project_user(user: project_developer2, project: project, role: developer_project_role)

    # Add Draws 
    ProjectCostSample.load_seed_data
    user = project.developers.first
    draw_service = DrawService.new(user:, project: )
    draw_service.create({name: 'Test Draw', amount: 123456.0})

    project.reload
    project
  }

  let(:sample_draw) {
    user = project.developers.first
    draw_service = DrawService.new(user: , project: )
    draw_service.create({name: 'Test Draw 2', amount: 123456.0})
  }
  let(:sample_draw_cost) { sample_draw.draw_costs.first }
  let(:sample_draw_cost_request) {
    #user = sample_project.developers.first
    #service = Projects::DrawCostRequestService.new(user: user, draw_cost: sample_draw_cost)
    #service.create_request({amount: 1})
  }

  before do
    sample_project
  end

end
