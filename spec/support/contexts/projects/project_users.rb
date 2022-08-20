require './spec/support/project_spec_helper'
RSpec.configure do |c|
  c.include ProjectSpecHelper
end

RSpec.shared_context 'project_users' do
  include_context 'projects'
  include_context 'project_roles'

  let(:project1_owner) {
    user = create(:user)
    add_project_user(user: user, project: project1, role: owner_project_role)
  }
  let(:project1_manager) {
    user = create(:user)
    add_project_user(user: user, project: project1, role: manager_project_role)
  }
  let(:project1_finance) {
    user = create(:user)
    add_project_user(user: user, project: project1, role: finance_project_role)
  }
  let(:project1_consultant) {
    user = create(:user)
    add_project_user(user: user, project: project1, role: consultant_project_role)
  }
  let(:project1_developer) {
    user = create(:user)
    add_project_user(user: user, project: project1, role: developer_project_role)
  }

  before do
    project1_owner
    project1_manager
    project1_finance
    project1_consultant
    project1_developer
  end

end
