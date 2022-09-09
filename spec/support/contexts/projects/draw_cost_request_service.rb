RSpec.shared_context "draw_cost_request_service" do
  include_context 'users'
  include_context 'sample_projects'

  let(:project) { sample_project }
  let(:user) { project.owners.first }
  let(:draw) { project.draws.first }
  let(:draw_cost) { draw.draw_costs.first }
  let(:admin_user) { create(:user, role: admin_role) }
  let(:owner_user) { project.owners.first }
  let(:manager_user) { project.managers.first }
  let(:finance_user) { project.finance.first }
  let(:consultant_user) { project.consultants.first }
  let(:developer_user) { project.developers.first }
  let(:developer_user_other_organization) { project.developers.select{|u| u.organization_id != developer_user.organization_id}.first }
  let(:non_project_user) { create(:user, role: user_role) }
  let(:valid_draw_cost_request_attributes) {
    {
      amount: 12345.67,
      description: 'Test description',
      plan_change: true,
      plan_change_reason: 'Test reason'
    }
  }
  let(:invalid_draw_cost_request_attributes) {
    {
      amount: nil,
      description: 'Invalid draw cost request',
    }
  }

end
