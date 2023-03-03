# == Schema Information
#
# Table name: draws
#
#  id                               :uuid             not null, primary key
#  amount                           :decimal(, )      default(0.0), not null
#  approved_at                      :datetime
#  index                            :integer          default(1), not null
#  invoice_auto_approvals_completed :boolean          default(FALSE)
#  notes                            :text
#  reference                        :string
#  state                            :string           default("pending"), not null
#  created_at                       :datetime         not null
#  updated_at                       :datetime         not null
#  approver_id                      :uuid
#  organization_id                  :uuid             not null
#  project_id                       :uuid             not null
#  user_id                          :uuid             not null
#
# Indexes
#
#  draws_assoc_idx                 (project_id,user_id,organization_id,approver_id,state)
#  draws_auto_approval_idx         (state,invoice_auto_approvals_completed)
#  index_draws_on_approver_id      (approver_id)
#  index_draws_on_organization_id  (organization_id)
#  index_draws_on_project_id       (project_id)
#  index_draws_on_user_id          (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (approver_id => users.id)
#  fk_rails_...  (organization_id => organizations.id)
#  fk_rails_...  (project_id => projects.id)
#  fk_rails_...  (user_id => users.id)
#
require 'rails_helper'

RSpec.describe Draw, type: :model do
  include_context 'projects'
  include_context 'sample_draws'
  include_context 'organizations'

  describe 'initialization' do
    it 'creates a new draw' do
      expect {
        create(:draw, project: project1)
      }.to change{Draw.count}.by(1)
    end
  end

  describe 'naming/index' do
    before(:each) { Draw.destroy_all }
    it 'returns the next draw number' do
      draw1 = create(:draw, project: sample_project, index: 1, organization: organization1)
      draw2 = create(:draw, project: sample_project, index: 2, organization: organization1)
      draw3 = Draw.new(amount: 123.45, project: sample_project, organization: organization1, user: sample_project.developers.first )
      expect(draw3.next_index).to eq(3)
      expect(draw3.index).to eq(3)
    end
    it 'prevents creation of a draw with the same index as another visible draw for this project' do
      draw1 = create(:draw, project: sample_project, index: 1, organization: organization1)
      draw2 = create(:draw, project: sample_project, index: 2, organization: organization1)
      draw3 = Draw.new(amount: 123.45, project: sample_project, organization: organization1, user: sample_project.developers.first )
      draw3.index = 2
      refute(draw3.save)
      draw2.state = 'withdrawn'
      draw2.save!
      assert(draw3.save)
    end
  end

  describe 'budget' do
    it 'returns budget variance'
    it 'returns if over budget'
  end

  describe 'helpers' do
    include_context 'sample_draws'

    describe 'clean draws' do
      let(:project_cost) { draw_cost.project_cost }
      let(:funding_source) { contingency_project_cost }
      let(:contingency_project_cost) {
        cost = create(:project_cost, project: sample_project, name: 'Sample Contingency', total: 100000.0)
        sample_project.project_costs.reload
        cost
      }
      let(:change_order) {
        service = ChangeOrderService.new(user: developer_user, draw_cost: draw_cost)
        service.create({funding_source_id: contingency_project_cost.id, amount: 1000.0})
        service.change_order
      }

      it 'returns if the Draw is "clean"' do
        draw
        draw_cost.total = draw_cost.project_cost.total * 2.0
        draw_cost.save!
        draw.reload
        assert(draw.clean?)

        developer_user
        change_order
        draw.reload
        assert(change_order.contingency?)
        refute(draw.clean?)
      end
    end # clean draws
  end # helpers

  describe 'state machine' do
    describe 'on submit' do
      it 'creates draw document approve tasks' do
        draw_cost_invoices
        draw_documents
        draw.state = 'pending'
        draw.save!
        draw.reload
        expect(draw.draw_documents.count).to eq(3)
        expect(ProjectTask.where(origin: draw_documents).count).to eq(0)
        draw.trigger_event(event_name: :submit)
        expect(ProjectTask.where(origin: draw_documents).count).to eq(3)
      end
    end

    describe 'on withdraw' do
      describe 'project tasks' do
        let(:user) { sample_project.developers.first }
        let(:draw_document) { DrawDocument.create!(draw: draw, user: user) }
        let(:pending_document_tasks) {
          Array.new(1) {
            ProjectTaskServices::Generator.call(origin: draw_document, action: :approve)
          }
        }
        let(:invoice) { draw_cost_invoices.first }
        let(:pending_invoice_tasks) {
          Array.new(1) {
            ProjectTaskServices::Generator.call(origin: invoice, action: :approve)
          }
        }

        it 'archives any draw document project tasks' do
          ProjectTask.destroy_all
          pending_document_tasks
          draw_document.project_tasks.reload
          expect(draw_document.project_tasks.pending.count).to eq(1)
          expect(draw_document.project_tasks.archived.count).to eq(0)
          draw.trigger_event(event_name: :withdraw)
          draw.reload
          draw_document.reload
          expect(draw_document.project_tasks.pending.count).to eq(0)
          expect(draw_document.project_tasks.archived.count).to eq(1)
        end
        it 'archives any invoice project tasks' do
          pending_invoice_tasks
          invoice.reload
          expect(invoice.project_tasks.pending.count).to eq(1)
          expect(invoice.project_tasks.archived.count).to eq(0)
          draw.trigger_event(event_name: :withdraw)
          draw.reload
          invoice.reload
          expect(invoice.project_tasks.pending.count).to eq(0)
          expect(invoice.project_tasks.archived.count).to eq(1)
        end
      end
    end #withdraw

    describe 'on reject' do
      before do
        draw_cost_invoices.update_all(state: :rejected)
        draw_documents.each{|doc| doc.update(state: :rejected)}
        draw.reload
        draw.update(state: 'submitted')
        draw.reload
      end
      describe 'notifications' do
        it 'should send a notification email' do
          assert(draw.permitted_state_events.include?(:reject))
          expect{
            draw.trigger_event(event_name: :reject)
          }.to change{ActionMailer::Base.deliveries.count}.by(1)
          draw.reload
          assert(draw.rejected?)
        end
      end
    end # reject

    describe 'on internal approval' do
      before do
        draw_cost_invoices.update_all(state: :approved)
        draw_documents.each{|doc| doc.update(state: :approved)}
        draw.draw_costs.update_all(state: :approved)
        draw.reload
        draw.update(state: 'submitted')
        draw.reload
      end
      describe 'notifications' do
        it 'should send a notification email' do
          assert(draw.permitted_state_events.include?(:approve))
          expect{
            draw.trigger_event(event_name: :approve)
          }.to change{ActionMailer::Base.deliveries.count}.by(1)
          draw.reload
          assert(draw.approved?)
        end
      end
    end # approval

    describe 'on funding' do
      before do
        draw_cost_invoices.update_all(state: :approved)
        draw_documents.each{|doc| doc.update(state: :approved)}
        draw.draw_costs.update_all(state: :approved)
        draw.reload
        draw.update(state: :externally_approved) 
        draw.reload
      end
      describe 'notifications' do
        it 'should send a notification email' do
          assert(draw.permitted_state_events.include?(:fund))
          expect{
            draw.trigger_event(event_name: :fund)
          }.to change{ActionMailer::Base.deliveries.count}.by(1)
          draw.reload
          assert(draw.approved?)
        end
      end
    end # approval

  end

  describe 'invoice auto approval' do
      let(:invoice0) { create(:invoice, draw_cost: draw_cost2, state: :processed, amount: 1000.0, manual_approval_required: false, description: 'invoice0') }
      let(:invoice1) { create(:invoice, draw_cost: draw_cost, state: :processed, amount: 1000.0, manual_approval_required: false, description: 'invoice1') }
      let(:invoice2) { create(:invoice, draw_cost: draw_cost, state: :processed, amount: 2000.0, manual_approval_required: true, description: 'invoice2') }
      let(:invoice3) { create(:invoice, draw_cost: draw_cost, state: :processed, amount: 3000.0, manual_approval_required: false, description: 'invoice3') }
      let(:invoice4) { create(:invoice, draw_cost: draw_cost, state: :processed, amount: 4000.0, manual_approval_required: false, description: 'invoice4') }
      let(:invoice5) { create(:invoice, draw_cost: draw_cost, state: :processed, amount: 5000.0, manual_approval_required: false, description: 'invoice5') }
      let(:invoice6) { create(:invoice, draw_cost: draw_cost, state: :processed, amount: 6000.0, manual_approval_required: false, description: 'invoice6') }
      let(:invoice7) { create(:invoice, draw_cost: draw_cost, state: :processed, amount: 7000.0, manual_approval_required: false, description: 'invoice7') }
      let(:invoice8) { create(:invoice, draw_cost: draw_cost, state: :processed, amount: 8000.0, manual_approval_required: false, description: 'invoice8') }
      let(:invoice9) { create(:invoice, draw_cost: draw_cost, state: :processed, amount: 9000.0, manual_approval_required: false, description: 'invoice9') }
      let(:invoice10) { create(:invoice, draw_cost: draw_cost, state: :processed, amount: 10000.0, manual_approval_required: false, audit: false, description: 'invoice10') }
      let(:invoice11) { create(:invoice, draw_cost: draw_cost, state: :processed, amount: 10000.0, manual_approval_required: false, audit: true, description: 'invoice11') }
      let(:invoice12) { create(:invoice, draw_cost: draw_cost, state: :processed, amount: 10000.0, manual_approval_required: true, description: 'invoice12') }

      let(:invoices) {
        [ invoice0, invoice1, invoice2, invoice3, invoice4, invoice5, invoice6, invoice7,
          invoice8, invoice9, invoice10, invoice11, invoice12 ]
      }

      before do
        draw_documents
        draw_cost
        draw_cost2
        Invoice.destroy_all
        invoices
        draw_cost.total = draw_cost.invoice_total
        draw_cost.save!
        pc1 = draw_cost.project_cost
        pc1 = draw_cost.project_cost
        pc1.total = draw_cost.total
        pc1.save!
        pc2 = draw_cost2.project_cost
        pc2.total = draw_cost2.total
        pc2.save!
        draw_cost2.total = draw_cost2.invoice_total
        draw_cost2.save!
        draw.reload
      end

      describe 'with a submitted draw' do
        before do
          draw.update(state: :submitted)
        end
        it 'marks invoices for manual approval and automatically approves the rest' do
          ProjectTask.destroy_all
          assert(Invoice.approved.count.zero?)
          expect(draw.invoices.where(manual_approval_required: true).count).to eq(2)
          Draw.invoice_auto_approval
          draw.reload
          assert(draw.invoice_auto_approvals_completed)
          expect(ProjectTask.count).to be >= 3
          expect(draw.invoices.where(manual_approval_required: true).count).to eq(ProjectTask.count)
          refute(draw.invoices.approved.count.zero?)
        end
      end

      describe 'without a submitted draw' do
        before do
          draw.update(state: :pending)
        end
        it 'does not process invoices' do
          ProjectTask.destroy_all
          assert(Invoice.approved.count.zero?)
          expect(draw.invoices.where(manual_approval_required: true).count).to eq(2)
          Draw.invoice_auto_approval
          draw.reload
          refute(draw.invoice_auto_approvals_completed)
          expect(draw.invoices.where(manual_approval_required: true).count).to eq(2)
          assert(draw.invoices.approved.count.zero?)
        end
      end
  end

  describe 'creating approval tasks' do
    let(:invoice0) { create(:invoice, draw_cost: draw_cost2, state: :approved, amount: 1000.0, manual_approval_required: false, description: 'invoice0') }
    let(:invoice1) { create(:invoice, draw_cost: draw_cost, state: :rejected, amount: 1000.0, manual_approval_required: false, description: 'invoice1') }
    let(:invoices) { [ invoice0, invoice1 ]}
    let(:draw_task) { Pro}

    before do
      invoices
      draw.reload
    end

    describe 'when the draw is submitted' do
      before do
        draw.update(state: :submitted)
      end

      describe 'when it has no project tasks and has approved or rejected tasks' do
        it 'should create a draw approval project task' do
          assert(draw.project_tasks.none?)
          Draw.create_approval_tasks
          draw.reload
          expect(draw.project_tasks.count).to eq(1)
        end
      end

      describe 'when it has a project task' do
        before do
          draw.create_task(action: :approve)
          draw.reload
        end
        it 'does not create a new project task' do
          expect(draw.project_tasks.count).to eq(1)
          Draw.create_approval_tasks
          draw.reload
          expect(draw.project_tasks.count).to eq(1)
        end
      end

      describe 'when it has a pending invoice pending approval' do
        before do
          invoice0.update(state: :pending)
          draw.reload
        end
        it 'does not create a new project task' do
          expect(draw.project_tasks.count).to eq(0)
          Draw.create_approval_tasks
          draw.reload
          expect(draw.project_tasks.count).to eq(0)
        end
      end

      describe 'when it has an invoice pending approval' do
        before do
          invoice0.update(state: :submitted)
          draw.reload
        end
        it 'does not create a new project task' do
          expect(draw.project_tasks.count).to eq(0)
          Draw.create_approval_tasks
          draw.reload
          expect(draw.project_tasks.count).to eq(0)
        end
      end

    end
  end

end
