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
    DrawCostSample.load_seed_data
    draw_service = Projects::DrawService.new(current_user: project_owner, project: project)
    draw_service.create({name: 'Test Draw 1'})

    project.reload
    project
  }

  before do
    sample_project
  end

end
