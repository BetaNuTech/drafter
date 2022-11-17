require 'rails_helper'

RSpec.describe InvoicesController, type: :controller do
  include_context 'sample_projects'
  render_views

  let(:valid_invoice_attributes) {
    {
      amount: 1234.56,
      description: 'test description'
    }
  }
  let(:draw_cost) { sample_draw_cost }

  describe '#new' do
    describe 'as a developer' do
      let(:user) { sample_project.developers.first }
      it 'should render the new invoice form' do
        sign_in user
        get :new, params: {draw_cost_id: draw_cost.id}
        expect(response).to render_template(:new)
      end
    end
  end

  describe '#create' do
    describe 'as a developer' do
      let(:user) { sample_project.developers.first }
      it 'should create a new invoice' do
        sign_in user
        expect {
          post :create, params: {draw_cost_id: draw_cost.id, invoice: valid_invoice_attributes}
        }.to change{Invoice.count}
        expect(response).to be_redirect
      end
    end
  end

  describe '#edit' do
    describe 'as a developer' do
      let(:user) { sample_project.developers.first }
      it 'should render the edit form' do
        invoice = draw_cost.invoices.create!(amount: 123.45, user: user)
        sign_in user
        get :edit, params: {draw_cost_id: draw_cost.id, id: invoice.id}
        expect(response).to render_template(:edit)
      end
    end
  end

  describe '#update' do
    let(:new_invoice_attributes) { {amount: 777.0} }
    describe 'as a developer' do
      let(:user) { sample_project.developers.first }
      let(:invoice) { draw_cost.invoices.create!(amount: 123.45, user: user) }
      before(:each) { invoice }
      it 'should update the invoice' do
        sign_in user
        patch :update, params: {draw_cost_id: draw_cost.id, id: invoice.id, invoice: new_invoice_attributes}
        expect(response).to be_redirect
        invoice.reload
        expect(invoice.amount).to eq(new_invoice_attributes[:amount])
      end
    end
  end

  describe '#destroy' do
    describe 'as a developer' do
      let(:user) { sample_project.developers.first }
      let(:invoice) { draw_cost.invoices.create!(amount: 123.45, user: user) }
      before(:each) { invoice }
      it 'should remove the invoice' do
        assert(invoice.pending?)
        sign_in user
        delete :destroy, params: {draw_cost_id: draw_cost.id, id: invoice.id}
        expect(response).to be_redirect
        invoice.reload
        assert(invoice.removed?)
      end
    end
  end

  describe '#approve' do
    let(:invoice) { submitted_draw_cost.invoices.create!(amount: 123.45, user: user, state: :submitted) }
    let(:invoice2) { submitted_draw_cost.invoices.create!(amount: 123.45, user: user, state: :submitted) }
    let(:submitted_draw_cost) {
      draw_cost.state = 'submitted'
      draw_cost.save!
      draw_cost
    }
    before do
      draw_cost.draw.state = 'submitted'
      draw_cost.draw.save!
    end
    describe 'as a manager' do
      let(:user) { sample_project.managers.first }
      it 'should approve the invoice' do
        assert(invoice.submitted?)
        sign_in user
        post :approve, params: {draw_cost_id: submitted_draw_cost.id, invoice_id: invoice.id}
        expect(response).to be_redirect
        invoice.reload
        assert(invoice.approved?)
        expect(invoice.approver).to eq(user)
      end
      it 'will approve the draw cost if all invoices are approved' do
        invoice.state = 'approved'
        invoice.save
        submitted_draw_cost.reload

        assert(invoice.approved?)
        assert(invoice2.submitted?)
        assert(submitted_draw_cost.submitted?)

        sign_in user
        post :approve, params: {draw_cost_id: submitted_draw_cost.id, invoice_id: invoice2.id}
        invoice2.reload
        submitted_draw_cost.reload
        assert(invoice2.approved?)
        assert(submitted_draw_cost.approved?)
      end
    end
    describe 'as a developer' do
      let(:user) { sample_project.developers.first }
      it 'should not approve the invoice' do
        assert(invoice.submitted?)
        sign_in user
        post :approve, params: {draw_cost_id: submitted_draw_cost.id, invoice_id: invoice.id}
        expect(response).to be_redirect
        invoice.reload
        refute(invoice.approved?)
      end
    end
  end

  describe '#reject' do
    let(:invoice) { draw_cost.invoices.create!(amount: 123.45, user: user, state: :submitted) }
    let(:invoice2) { draw_cost.invoices.create!(amount: 123.45, user: user, state: :submitted) }
    before do
      draw_cost.draw.state = 'submitted'
      draw_cost.draw.save!
    end
    describe 'as a manager' do
      let(:user) { sample_project.managers.first }
      it 'should reject the invoice' do
        assert(invoice.submitted?)
        sign_in user
        post :reject, params: {draw_cost_id: draw_cost.id, invoice_id: invoice.id}
        expect(response).to be_redirect
        invoice.reload
        assert(invoice.rejected?)
        expect(invoice.approver).to be_nil
      end
    end
    describe 'as a developer' do
      let(:user) { sample_project.developers.first }
      it 'should not reject the invoice' do
        assert(invoice.submitted?)
        sign_in user
        post :reject, params: {draw_cost_id: draw_cost.id, invoice_id: invoice.id}
        expect(response).to be_redirect
        invoice.reload
        assert(invoice.submitted?)
      end
    end
  end

end
