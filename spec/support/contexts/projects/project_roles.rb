RSpec.shared_context "project_roles" do
  let(:owner_project_role) { create(:owner_project_role) }
  let(:manager_project_role) { create(:manager_project_role) }
  let(:finance_project_role) { create(:finance_project_role) }
  let(:investor_project_role) { create(:investor_project_role) }
  let(:developer_project_role) { create(:developer_project_role) }

  before(:each) do
    owner_project_role
    manager_project_role
    finance_project_role
    investor_project_role
    developer_project_role
  end
end
