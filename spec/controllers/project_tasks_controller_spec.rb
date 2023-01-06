require 'rails_helper'

RSpec.describe ProjectTasksController, type: :controller do
  include_context 'sample_draws'
  include_context 'users'
  render_views

  let(:project) { sample_project }
  let(:submitted_draw) {
    draw.state = 'submitted'
    draw.save
    draw_cost.state = 'submitted'
    draw_cost.save
    draw_cost_invoices.each{|dci| dci.state = 'submitted'; dci.save! }
    draw_cost.reload
    draw.reload
    draw
  }
  let(:invoice) { submitted_draw.invoices.first }
  let(:invoice_task) {
    task = ProjectTaskServices::Generator.call(origin: invoice, action: :verify)
    task.trigger_event(event_name: :submit_for_review)
    task
  }
  let(:document_task) {
    task = ProjectTaskServices::Generator.call(origin: invoice, action: :verify)
    task.trigger_event(event_name: :submit_for_consult)
    task
  }

  describe '#verify' do
    describe 'as an internal project user' do
      let(:user) { project.managers.first }

      it 'should mark the task as verified' do
        sign_in user
        expect(invoice_task.state).to eq('needs_review')
        post :verify, params: { id: invoice_task.id }
        assert(response.redirect?)
        invoice_task.reload
        expect(invoice_task.state).to eq('verified')
      end
    end
    describe 'as a developer in the project' do
      let(:user) { project.developers.first }
      it 'should not mark the task as verified' do
        sign_in user
        expect(invoice_task.state).to eq('needs_review')
        post :verify, params: { id: invoice_task.id }
        assert(response.redirect?)
        invoice_task.reload
        expect(invoice_task.state).to_not eq('verified')
      end
    end
    describe 'as a privileged user' do
      let(:user) { executive_user }

      it 'should mark the task as verified' do
        sign_in user
        expect(invoice_task.state).to eq('needs_review')
        post :verify, params: { id: invoice_task.id }
        assert(response.redirect?)
        invoice_task.reload
        expect(invoice_task.state).to eq('verified')
      end
    end
    describe 'as a non-privileged user outside of project'

  end
  
end
