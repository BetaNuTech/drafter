require 'rails_helper'

RSpec.describe DrawsController, type: :controller do
  include_context 'draw_service'
  render_views

  let(:valid_draw_attributes) { { amount: 1234.56, name: 'Draw 1', notes: 'Draw notes for test here' } }

  let(:project) { sample_project }
  before(:each) { project }
  let(:complete_draw) {
    user = sample_project.developers.first
    sample_draw
    sample_draw_cost
    invoice_service = InvoiceService.new(user: user, draw_cost: sample_draw_cost)
    invoice_service.create(amount: sample_draw_cost.total, description: 'Sample invoice')
    sample_draw_cost.reload
    DrawDocument.documenttypes.keys.each do |ddt|
      doc_service = DrawDocumentService.new(draw: sample_draw, user: user)
      doc_service.create({documenttype: ddt, notes: "#{ddt} document note"})
    end
    sample_draw.reload
    sample_draw
  }

  describe '#new' do
    describe 'as a developer' do
      let(:user) { sample_project.developers.first }
      it 'should display the new draw form' do
        Draw.destroy_all
        sign_in user
        get :new, params: { project_id: project.id }
        expect(response).to render_template(:new)
      end
    end
  end

  describe '#create' do
    describe 'as a developer' do
      let(:user) { project.developers.first }
      it 'should create a new draw for the project' do
        Draw.destroy_all
        sign_in user
        expect {
          post :create, params: {draw: valid_draw_attributes, project_id: project.id}
        }.to change{Draw.count}
        expect(response).to be_redirect
      end
    end
  end

  describe '#show' do
    describe 'as the project developer' do
      let(:user) { project.developers.first }
      let(:draw) { sample_draw }

      it 'should render the show template' do
        sign_in user
        get :show, params: {id: draw.id, project_id: project.id }
        expect(response).to render_template(:show)
      end
    end
  end

  describe '#edit' do
    describe 'as the project developer' do
      let(:user) { developer_user }
      let(:draw) { sample_draw }

      it 'should display the edit form' do
        sign_in user
        get :edit, params: {id: draw.id, project_id: project.id }
        expect(response).to render_template(:edit)
      end
    end
  end

  describe '#update' do
    let(:valid_attrs) { {amount: 777.77, name: 'New Name', notes: 'New notes'} }
    describe 'as the project developer' do
      let(:user) { developer_user }
      let(:draw) { sample_draw }
      it 'should update the draw' do
        sign_in user
        patch :update, params: {id: draw.id, project_id: project.id, draw: valid_attrs}
        expect(response).to be_redirect
        draw.reload
        expect(draw.amount).to eq(valid_attrs[:amount])
      end
    end
  end #update

  describe '#destroy' do
    describe 'as the project developer' do
      let(:user) { developer_user }
      let(:draw) { sample_draw }
      it 'should transition the draw to "withdrawn"' do
        sign_in user
        assert(draw.pending?)
        delete :destroy, params: { id: draw.id, project_id: project.id }
        expect(response).to be_redirect
        draw.reload
        assert(draw.withdrawn?)
      end
    end

  end #destroy

  describe '#submit' do
    describe 'as the project developer' do
      let(:user) { developer_user }
      let(:draw) { complete_draw }
      describe 'with a fully populated draw' do
        it 'should submit the draw and dependent draw costs' do
          assert(draw.draw_costs.all?(&:pending?))
          sign_in user
          post :submit, params: {project_id: draw.project_id, draw_id: draw.id }
          expect(response).to be_redirect
          draw.reload
          assert(draw.submitted?)
          assert(draw.draw_costs.all?(&:submitted?))
        end
      end
      describe 'with a partially populated draw' do
        it 'should not allow transition to submitted' do
          draw.draw_documents.destroy_all
          draw.reload
          sign_in user
          post :submit, params: {project_id: draw.project_id, draw_id: draw.id }
          expect(response).to be_redirect
          draw.reload
          assert(draw.pending?)
          assert(draw.draw_costs.all?(&:pending?))
        end
      end
    end

    describe '#approve_internal' do
      let(:approver) { sample_project.managers.first }
      let(:developer) { sample_project.developers.first }
      let(:draw) {
        complete_draw.state = 'submitted'
        complete_draw.save
        complete_draw.draw_costs.update_all(state: :approved)
        complete_draw.draw_documents.update_all(state: :approved)
        complete_draw.reload
        complete_draw
      }
      describe 'with a full populated and submitted draw and approved draw costs' do
        describe 'as a manager' do
          it 'should internally approve the draw' do
            sign_in approver
            post :approve_internal, params: {project_id: draw.project_id, draw_id: draw.id}
            expect(response).to be_redirect
            draw.reload
            assert(draw.internally_approved?)
            expect(draw.approver).to eq(approver)
          end
        end
        describe 'as a developer' do
          it 'should not approve the draw' do
            developer
            assert(developer.project_developer?(draw.project))
            sign_in developer
            assert(draw.submitted?)
            assert(developer.project_developer?(draw.project))
            post :approve_internal, params: {project_id: draw.project_id, draw_id: draw.id}
            expect(response).to be_redirect
            draw.reload
            refute(draw.internally_approved?)
          end
        end
      end
      describe 'with an incomplete draw' do
        it 'should not approve draw' do
          draw = complete_draw
          draw.draw_costs.update_all(state: :submitted)
          draw.reload
          sign_in approver
          post :approve_internal, params: {project_id: draw.project_id, draw_id: draw.id}
          draw.reload
          refute(draw.internally_approved?)
        end
      end
    end # Approve internal

    describe '#reject' do
      let(:approver) { sample_project.managers.first }
      let(:developer) { sample_project.developers.first }
      let(:draw) {
        complete_draw.state = 'submitted'
        complete_draw.save!
        complete_draw.draw_costs.update_all(state: :approved)
        complete_draw.draw_documents.update_all(state: :approved)
        complete_draw.reload
        complete_draw
      }
      describe 'with a full populated and submitted draw and approved draw costs' do
        describe 'as a manager' do
          it 'should internally reject the draw' do
            sign_in approver
            expect(draw.state).to eq('submitted')
            post :reject, params: {project_id: draw.project_id, draw_id: draw.id}
            draw.reload
            assert(draw.rejected?)
            expect(draw.approver).to be_nil
          end
        end
        describe 'as a developer' do
          it 'should not reject the draw' do
            developer
            assert(developer.project_developer?(draw.project))
            sign_in developer
            expect(draw.state).to eq('submitted')
            assert(developer.project_developer?(draw.project))
            post :reject, params: {project_id: draw.project_id, draw_id: draw.id}
            draw.reload
            expect(draw.state).to eq('submitted')
          end
        end
      end
      describe 'with an incomplete draw' do
        it 'should reject the draw' do
          draw = complete_draw
          draw.state = 'submitted'
          draw.save!
          draw.draw_costs.update_all(state: :submitted)
          draw.reload
          assert(draw.submitted?)
          sign_in approver
          post :reject, params: {project_id: draw.project_id, draw_id: draw.id}
          draw.reload
          assert(draw.rejected?)
        end
      end
    end # Reject internal
  end

end
