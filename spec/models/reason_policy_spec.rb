require 'rails_helper'

RSpec.describe ReasonPolicy do
  include_context "users"

  describe "policy" do
    let(:reason) { create(:reason) }

    describe "for admins" do
      let(:policy) { ReasonPolicy.new(administrator, reason) }

      it "allows #index" do
        assert policy.index?
      end

      it "allows #new" do
        assert policy.new?
      end

      it "allows #create" do
        assert policy.create?
      end

      it "allows #edit" do
        assert policy.edit?
      end

      it "allows #show" do
        assert policy.show?
      end

      it "allows #update" do
        assert policy.update?
      end

      it "allows #destroy" do
        assert policy.destroy?
      end

      it "allows all params" do
        allowed_params = Reason::ALLOWED_PARAMS
        expect(policy.allowed_params).to eq(allowed_params)
      end
    end

    describe "for agents" do
      let(:policy) { ReasonPolicy.new(agent, reason) }

      it "allows #index" do
        assert policy.index?
      end

      it "disallows #new" do
        refute policy.new?
      end

      it "disallows #create" do
        refute policy.create?
      end

      it "allows #show" do
        assert policy.show?
      end

      it "disallows #edit" do
        refute policy.edit?
      end

      it "disallows #update" do
        refute policy.update?
      end

      it "disallows #destroy" do
        refute policy.destroy?
      end

      it "disallows all params" do
        allowed_params = Reason::ALLOWED_PARAMS
        expect(policy.allowed_params).to be_empty
      end
    end

    describe "for unroled users" do
      let(:policy) { ReasonPolicy.new(unroled_user, reason) }

      it "disallows #index" do
        refute policy.index?
      end

      it "disallows #new" do
        refute policy.new?
      end

      it "disallows #create" do
        refute policy.create?
      end

      it "disallows #show" do
        refute policy.show?
      end

      it "disallows #edit" do
        refute policy.edit?
      end

      it "disallows #update" do
        refute policy.update?
      end

      it "disallows #destroy" do
        refute policy.destroy?
      end

      it "disallows all params" do
        allowed_params = Reason::ALLOWED_PARAMS
        expect(policy.allowed_params).to be_empty
      end
    end


  end
end