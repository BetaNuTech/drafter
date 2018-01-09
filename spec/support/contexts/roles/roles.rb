RSpec.shared_context "roles" do
  let(:administrator_role) { create(:administrator_role) }
  let(:operator_role) { create(:operator_role) }
  let(:agent_role) { create(:agent_role) }
  let(:other_role) { create(:other_role)}
end
