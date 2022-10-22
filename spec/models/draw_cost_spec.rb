# == Schema Information
#
# Table name: draw_costs
#
#  id              :uuid             not null, primary key
#  approved_at     :datetime
#  state           :string           default("pending"), not null
#  total           :decimal(, )      default(0.0), not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  approver_id     :uuid
#  draw_id         :uuid             not null
#  project_cost_id :uuid             not null
#
# Indexes
#
#  draw_costs_assoc_idx                 (draw_id,project_cost_id,approver_id)
#  draw_costs_draw_state_idx            (draw_id,state)
#  index_draw_costs_on_draw_id          (draw_id)
#  index_draw_costs_on_project_cost_id  (project_cost_id)
#
# Foreign Keys
#
#  fk_rails_...  (approver_id => users.id)
#  fk_rails_...  (draw_id => draws.id)
#  fk_rails_...  (project_cost_id => project_costs.id)
#
require 'rails_helper'

RSpec.describe DrawCost, type: :model do
  include_context 'sample_projects'

  let(:user) { sample_project.developers.first }
  let(:uploaded_file) {Rack::Test::UploadedFile.new("#{Rails.root}/spec/fixtures/files/sample_document_1.pdf", 'application/pdf')}
  let(:draw) { sample_project.draws.first}
  let(:draw_cost) {
    create(:draw_cost, draw: draw, project_cost: sample_project.project_costs.first, total: 12345.67, state: 'pending')
  }
  let(:invoices) {
    draw_cost.invoices.create!(amount: '1234.56', description: 'Test invoice 1', document: uploaded_file, user:)
    draw_cost.invoices.create!(amount: '1234.56', description: 'Test invoice 1', document: uploaded_file, user:)
    draw_cost.invoices
  }

  describe 'initialization' do
    it 'creates a DrawCost' do
      draw_cost = build(:draw_cost, draw: draw, project_cost: sample_project.project_costs.first)
      assert(draw_cost.save)
    end
  end

  describe 'view helpers' do
    it 'returns the css class for the cost type' do
      draw_cost = build(:draw_cost, draw: sample_project.draws.first)
      expect(draw_cost.state_css_class).to eq('secondary')
    end
  end

  describe 'state machine' do
    describe 'submission' do
      it 'will not transition to submitted if there are no invoices' do
        assert(draw_cost.pending?)
        draw_cost.trigger_event(event_name: :submit, user: )
        draw_cost.save
        draw_cost.reload
        refute(draw_cost.submitted?)
      end
      it 'automatically submits pending invoices' do
        invoices
        draw_cost.reload
        draw_cost.trigger_event(event_name: :submit, user: )
        draw_cost.save
        draw_cost.reload
        assert(draw_cost.submitted?)
      end
    end
  end
  
end
