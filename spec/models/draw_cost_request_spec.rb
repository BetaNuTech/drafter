# == Schema Information
#
# Table name: draw_cost_requests
#
#  id                 :uuid             not null, primary key
#  alert              :integer          default("ok"), not null
#  amount             :decimal(, )      default(0.0), not null
#  approval_due_date  :date
#  approved_at        :datetime
#  audit              :boolean          default(FALSE), not null
#  description        :text
#  plan_change        :boolean          default(FALSE), not null
#  plan_change_reason :text
#  state              :string           default("pending"), not null
#  total              :decimal(, )      default(0.0), not null
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  approver_id        :uuid
#  draw_cost_id       :uuid             not null
#  draw_id            :uuid             not null
#  organization_id    :uuid             not null
#  user_id            :uuid             not null
#
# Indexes
#
#  index_draw_cost_requests_on_draw_cost_id     (draw_cost_id)
#  index_draw_cost_requests_on_draw_id          (draw_id)
#  index_draw_cost_requests_on_organization_id  (organization_id)
#  index_draw_cost_requests_on_user_id          (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (draw_cost_id => draw_costs.id)
#  fk_rails_...  (draw_id => draws.id)
#  fk_rails_...  (organization_id => organizations.id)
#  fk_rails_...  (user_id => users.id)
#
require 'rails_helper'

RSpec.describe DrawCostRequest, type: :model do
  include_context 'sample_projects'

  let(:draw_cost) { create(:draw_cost, draw: sample_project.draws.first) }

  describe 'initialization' do
    it 'creates a draw cost request' do
      draw_cost_request = build(:draw_cost_request, draw_cost: draw_cost) 
      assert(draw_cost_request.save)
    end
  end

  describe 'state machine' do
    describe 'approval event' do
      let(:draw_cost_request) {
        dcr = create(:draw_cost_request, draw_cost: draw_cost, state: 'submitted', approver_id: nil, approved_at: nil)
        create(:draw_cost_submission, draw_cost_request: dcr, state: :approved, amount: 1.0)
        dcr.draw_cost_submissions.reload
        dcr
      }
      let(:user) { sample_project.managers.first }
      describe 'by a specified user' do
        it 'transitions a submitted request to "approved" with a user' do
          draw_cost_request.trigger_event(event_name: 'approve', user: user)
          expect(draw_cost_request.state).to eq('approved')
          expect(draw_cost_request.approver).to eq(user)
          refute(draw_cost_request.approved_at.blank?)
        end
        it 'allows transition from rejected to approved' do
          draw_cost_request.reject!
          expect(draw_cost_request.approver).to be_nil
          expect(draw_cost_request.approved_at).to be_nil
          draw_cost_request.trigger_event(event_name: 'approve', user: user)
          expect(draw_cost_request.state).to eq('approved')
          expect(draw_cost_request.approver).to eq(user)
          refute(draw_cost_request.approved_at.blank?)
        end
      end
      describe 'without a specified user' do
        it 'throws a TransitionError' do
          expect {
            draw_cost_request.approve!
          }.to raise_error DrawCostRequest::TransitionError
          expect(draw_cost_request.state).to eq('submitted')
        end
      end
    end
  end

end
