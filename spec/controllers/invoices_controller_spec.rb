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

end
