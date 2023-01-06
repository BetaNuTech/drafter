RSpec.shared_context "users" do
  include_context 'roles'
  let(:user) { build(:user) }

  let(:admin_user) { create(:user, role: admin_role)}
  let(:executive_user) { create(:user, role: executive_role)}
  let(:regular_user) { create(:user, role: user_role)}
end
