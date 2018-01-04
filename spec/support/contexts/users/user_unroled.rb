RSpec.shared_context "unroled user" do
  let(:unroled_user) {
    user = create(:user)
    user.confirm
    user.save
    user
  }
end
