require 'rails_helper'

RSpec.describe NotesController, type: :controller do
  include_context "users"
  render_views

  let(:valid_attributes) { attributes_for(:note) }
  let(:invalid_attributes) { {content: 'foobar'}}

  describe "GET #index" do
    describe "as an unauthenticated user" do
      it "should fail and redirect" do
        get :index
        expect(response).to be_redirect
      end
    end

    describe "as an unroled user" do
      it "should fail and redirect" do
        sign_in unroled_user
        get :index
        expect(response).to be_redirect
      end
    end

    describe "as an agent" do
      it "should fail and redirect" do
        sign_in agent
        get :index
        expect(response).to be_redirect
      end
    end

    describe "as an operator" do
      it "should succeed" do
        sign_in operator
        get :index
        expect(response).to be_success
      end
    end

    describe "as an administrator" do
      it "should succeed" do
        sign_in administrator
        get :index
        expect(response).to be_success
      end
    end

  end

  describe "GET #new" do
    describe "as an unauthenticated user" do
      it "should fail and redirect" do
        get :new
        expect(response).to be_redirect
      end
    end

    describe "as an unroled user" do
      it "should fail and redirect" do
        sign_in unroled_user
        get :new
        expect(response).to be_redirect
      end
    end

    describe "as an agent" do
      it "should succeed" do
        sign_in agent
        get :new
        expect(response).to be_success
      end
    end

    describe "as an operator" do
      it "should succeed" do
        sign_in operator
        get :new
        expect(response).to be_success
      end
    end

    describe "as an administrator" do
      it "should succeed" do
        sign_in administrator
        get :new
        expect(response).to be_success
      end
    end
  end

  describe "POST #create" do
    describe "as an unauthenticated user" do
      it "should fail and redirect" do
        post :create, params: {note: valid_attributes}
        expect(response).to be_redirect
      end

      it "should not create a Note" do
        expect{
          post :create, params: {note: valid_attributes}
        }.to_not change{Note.count}
      end
    end

    describe "as a unroled user" do
      before do
        sign_in unroled_user
      end

      it "should fail and redirect" do
        post :create, params: {note: valid_attributes}
        expect(response).to be_redirect
      end

      it "should not create a Note" do
        expect{
          post :create, params: {note: valid_attributes}
        }.to_not change{Note.count}
      end

    end

    describe "as an agent" do
      before do
        sign_in agent
      end

      it "should succeed" do
        post :create, params: {note: valid_attributes}
        expect(response).to be_redirect
      end

      it "should create a Note" do
        expect{
          post :create, params: {note: valid_attributes}
        }.to change{Note.count}.by(1)
      end
    end

    describe "as an operator" do
      before do
        sign_in operator
      end

      it "should create a Note with valid attributes" do
        expect{
          post :create, params: {note: valid_attributes}
        }.to change{Note.count}.by(1)
      end
    end

    describe "as an administrator" do
      before do
        sign_in administrator
      end

      it "should create a Note with valid attributes" do
        expect{
          post :create, params: {note: valid_attributes}
        }.to change{Note.count}.by(1)
      end

      it "should create a Note assigned to the creator" do
        post :create, params: {note: valid_attributes}
        expect(Note.last.user).to eq(administrator)
      end
    end
  end

  describe "GET #show" do
    let(:note) { create(:note) }

    describe "as an unauthenticated user" do
      it "should fail and redirect" do
        get :show, params: {id: note.id}
        expect(response).to be_redirect
      end
    end

    describe "as an unroled user" do
      it "should fail and redirect" do
        sign_in unroled_user
        get :show, params: {id: note.id}
        expect(response).to be_redirect
      end
    end

    describe "as an agent" do
      it "should succeed" do
        sign_in agent
        get :show, params: {id: note.id}
        expect(response).to be_success
      end
    end

    describe "as an operator" do
      it "should succeed" do
        sign_in operator
        get :show, params: {id: note.id}
        expect(response).to be_success
      end
    end

    describe "as an administrator" do
      it "should succeed" do
        sign_in administrator
        get :show, params: {id: note.id}
        expect(response).to be_success
      end
    end
  end

  describe "GET #edit" do

    let(:note) { create(:note) }

    describe "as an unauthenticated user" do
      it "should fail and redirect" do
        get :edit, params: {id: note.id}
        expect(response).to be_redirect
      end
    end

    describe "as an unroled user" do
      it "should fail and redirect" do
        sign_in unroled_user
        get :edit, params: {id: note.id}
        expect(response).to be_redirect
      end
    end

    describe "as an agent" do
      it "should fail and redirect" do
        sign_in agent
        get :edit, params: {id: note.id}
        expect(response).to be_redirect
      end
    end

    describe "as an operator" do
      it "should succeed" do
        sign_in operator
        get :edit, params: {id: note.id}
        expect(response).to be_success
      end
    end

    describe "as an administrator" do
      it "should succeed" do
        sign_in administrator
        get :edit, params: {id: note.id}
        expect(response).to be_success
      end
    end
  end

  describe "PUT #update" do
    let(:note) { create(:note) }
    let(:updated_attributes) { {content: 'foobar12'}}

    describe "as an unauthenticated user" do
      it "should fail and redirect" do
        expect{
          put :update, params: {id: note.id, note: updated_attributes}
          expect(response).to be_redirect
          note.reload
        }.to_not change{note.content}
      end
    end

    describe "as an unroled user" do
      it "should fail and redirect" do
        sign_in unroled_user
        expect{
          put :update, params: {id: note.id, note: updated_attributes}
          expect(response).to be_redirect
          note.reload
        }.to_not change{note.content}
      end
    end

    describe "as an agent" do
      it "should fail and redirect" do
        sign_in agent
        expect{
          put :update, params: {id: note.id, note: updated_attributes}
          expect(response).to be_redirect
          note.reload
        }.to_not change{note.content}
      end
    end

    describe "as an operator" do
      it "should succeed" do
        sign_in operator
        expect{
          put :update, params: {id: note.id, note: updated_attributes}
          expect(response).to be_redirect
          note.reload
        }.to change{note.content}
      end
    end

    describe "as an administrator" do
      before do
        note
        sign_in administrator
      end

      it "should succeed" do
        expect{
          put :update, params: {id: note.id, note: updated_attributes}
          expect(response).to be_redirect
          note.reload
        }.to change{note.content}
      end
    end
  end

  describe "DELETE #destroy" do

    let(:note) { create(:note) }

    before do
      note
    end

    describe "as an unauthenticated user" do
      it "should fail and redirect" do
        expect {
          delete :destroy, params: {id: note.id}
          expect(response).to be_redirect
        }.to_not change{Note.count}
      end
    end

    describe "as an unroled user" do
      it "should fail and redirect" do
        sign_in unroled_user
        expect {
          delete :destroy, params: {id: note.id}
          expect(response).to be_redirect
        }.to_not change{Note.count}
      end
    end

    describe "as an agent" do
      it "should fail and redirect" do
        sign_in agent
        expect {
          delete :destroy, params: {id: note.id}
          expect(response).to be_redirect
        }.to_not change{Note.count}
      end
    end

    describe "as an operator" do
      it "should succeed" do
        sign_in operator
        expect {
          delete :destroy, params: {id: note.id}
          expect(response).to be_redirect
        }.to change{Note.count}.by(-1)
      end
    end

    describe "as an administrator" do
      it "should succeed" do
        sign_in administrator
        expect {
          delete :destroy, params: {id: note.id}
          expect(response).to be_redirect
        }.to change{Note.count}.by(-1)
      end
    end
  end

end