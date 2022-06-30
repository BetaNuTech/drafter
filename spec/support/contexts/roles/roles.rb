RSpec.shared_context "roles" do
  let(:admin_role) { create(:admin_role) }
  let(:executive_role) { create(:executive_role) }
  let(:user_role) { create(:user_role) }

  before(:each) do
    admin_role
    executive_role
    user_role
  end
end
