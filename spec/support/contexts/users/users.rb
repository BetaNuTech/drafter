RSpec.shared_context "users" do
  include_context 'roles'
  let(:user) { build(:user) }
end
