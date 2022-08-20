RSpec.shared_context "users" do
  include_context 'roles'
  let(:user) { build(:user) }

  let(:admin_user) { create(:user, role: admin_role)}
  let(:manager_user) { create(:user, role: manager_role)}
  let(:regular_user) { create(:user, role: user_role)}
end
