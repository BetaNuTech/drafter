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
    task = ProjectTaskServices::Generator.call(origin: invoice, action: :approve)
    task.trigger_event(event_name: :submit_for_review)
    task
  }
  let(:document_task) {
    task = ProjectTaskServices::Generator.call(origin: invoice, action: :approve)
    task.trigger_event(event_name: :submit_for_consult)
    task
  }

  describe '#approve' do
    describe 'as an internal project user' do
      let(:user) { project.managers.first }

      it 'should mark the task as approved' do
        sign_in user
        expect(invoice_task.state).to eq('needs_review')
        post :approve, params: { id: invoice_task.id }
        assert(response.redirect?)
        invoice_task.reload
        expect(invoice_task.state).to eq('approved')
      end
    end
    describe 'as a developer in the project' do
      let(:user) { project.developers.first }
      it 'should not mark the task as approved' do
        sign_in user
        expect(invoice_task.state).to eq('needs_review')
        post :approve, params: { id: invoice_task.id }
        assert(response.redirect?)
        invoice_task.reload
        expect(invoice_task.state).to_not eq('approved')
      end
    end
    describe 'as a privileged user' do
      let(:user) { executive_user }

      it 'should mark the task as approved' do
        sign_in user
        expect(invoice_task.state).to eq('needs_review')
        post :approve, params: { id: invoice_task.id }
        assert(response.redirect?)
        invoice_task.reload
        expect(invoice_task.state).to eq('approved')
      end
    end
    describe 'as a non-privileged user outside of project' do
      let(:user) { regular_user }
      it 'should not mark the task as approved' do
        sign_in user
        expect(invoice_task.state).to eq('needs_review')
        expect {
          post :approve, params: { id: invoice_task.id }
        }.to raise_error{ActiveRecord::RecordNotFound}
        invoice_task.reload
        expect(invoice_task.state).to_not eq('approved')
      end
    end

  end # approve

  describe '#update_task' do
    let(:token) { 'XXX' }

    before(:each) do 
      invoice_task.remoteid = 'XXX'
      invoice_task.save
    end

    describe 'as an API user' do
      describe 'when using the "force" parameter' do
        it' should approve the task' do
          expect(invoice_task.state).to eq('needs_review')
          post :update_task, params: { id: invoice_task.remoteid, status: 'approved', token: token, service: 'clickup', force: 'true', format: :json }
          expect(response).to be_successful
          invoice_task.reload
          expect(invoice_task.state).to eq('approved')
          expect(invoice_task.origin.state).to eq('approved')
        end
        it' should reject the task' do
          expect(invoice_task.state).to eq('needs_review')
          post :update_task, params: { id: invoice_task.remoteid, status: 'rejected', token: token, service: 'clickup', force: 'true', format: :json }
          expect(response).to be_successful
          invoice_task.reload
          expect(invoice_task.state).to eq('rejected')
          expect(invoice_task.origin.state).to eq('rejected')
        end
        it' should archive the task' do
          invoice_starting_state = invoice_task.origin.state
          expect(invoice_task.state).to eq('needs_review')
          post :update_task, params: { id: invoice_task.remoteid, status: 'archived', token: token, service: 'clickup', force: 'true', format: :json }
          expect(response).to be_successful
          invoice_task.reload
          expect(invoice_task.state).to eq('archived')
          expect(invoice_task.origin.state).to eq(invoice_starting_state)
        end

        describe 'when not using the "force" parameter' do
          it 'should clear the task remote_updated_at attribute' do
            invoice_task.remote_last_checked_at = Time.current
            invoice_task.save
            expect(invoice_task.state).to eq('needs_review')
            post :update_task, params: { id: invoice_task.remoteid, status: 'approved', token: token, service: 'clickup', format: :json }
            expect(response).to be_successful
            invoice_task.reload
            expect(invoice_task.remote_last_checked_at).to be_nil
            expect(invoice_task.state).to_not eq('approved')
            expect(invoice_task.origin.state).to_not eq('approved')
          end
        end

      end


    end
    describe 'as a logged-in user without a valid token' do
      let(:user) { project.managers.first }
      it 'should fail authentication and do nothing' do
        sign_in user
        invoice_starting_state = invoice_task.origin.state
        expect(invoice_task.state).to eq('needs_review')
        post :update_task, params: { id: invoice_task.remoteid, status: 'archived', token: 'incorrect', service: 'clickup', format: :json }
        expect(response).to_not be_successful
        invoice_task.reload
        expect(invoice_task.state).to eq('needs_review')
        expect(invoice_task.origin.state).to eq(invoice_starting_state)
      end

    end
  end
  
end
