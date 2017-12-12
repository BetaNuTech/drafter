require 'rails_helper'

RSpec.describe PropertiesController, type: :controller do

  # This should return the minimal set of attributes required to create a valid
  # Property. As you add validations to Property, be sure to
  # adjust the attributes here as well.
  let(:valid_attributes) {
    attributes_for(:property)
  }

  let(:invalid_attributes) {
    attributes_for(:property, name: nil)
  }

  # This should return the minimal set of values that should be in the session
  # in order to pass any filters (e.g. authentication) defined in
  # PropertiesController. Be sure to keep this updated too.
  let(:valid_session) { {} }

  describe "GET #index" do
    it "returns a success response" do
      property = Property.create! valid_attributes
      get :index, params: {}, session: valid_session
      expect(response).to be_success
    end
  end

  describe "GET #show" do
    it "returns a success response" do
      property = Property.create! valid_attributes
      get :show, params: {id: property.to_param}, session: valid_session
      expect(response).to be_success
    end
  end

  describe "GET #new" do
    it "returns a success response" do
      get :new, params: {}, session: valid_session
      expect(response).to be_success
    end
  end

  describe "GET #edit" do
    it "returns a success response" do
      property = Property.create! valid_attributes
      get :edit, params: {id: property.to_param}, session: valid_session
      expect(response).to be_success
    end
  end

  describe "POST #create" do
    context "with valid params" do
      it "creates a new Property" do
        expect {
          post :create, params: {property: valid_attributes}, session: valid_session
        }.to change(Property, :count).by(1)
      end

      it "redirects to the created property" do
        post :create, params: {property: valid_attributes}, session: valid_session
        expect(response).to redirect_to(Property.last)
      end
    end

    context "with invalid params" do
      it "returns a success response (i.e. to display the 'new' template)" do
        post :create, params: {property: invalid_attributes}, session: valid_session
        expect(response).to be_success
      end
    end
  end

  describe "PUT #update" do
    context "with valid params" do
      let(:new_attributes) {
        attributes_for(:property, name: 'foobar')
      }

      it "updates the requested property" do
        property = Property.create! valid_attributes
        expect{
          put :update, params: {id: property.to_param, property: new_attributes}, session: valid_session
          property.reload
        }.to change(property, :name)
      end

      it "redirects to the property" do
        property = Property.create! valid_attributes
        put :update, params: {id: property.to_param, property: valid_attributes}, session: valid_session
        expect(response).to redirect_to(property)
      end
    end

    context "with invalid params" do
      it "returns a success response (i.e. to display the 'edit' template)" do
        property = Property.create! valid_attributes
        put :update, params: {id: property.to_param, property: invalid_attributes}, session: valid_session
        expect(response).to be_success
      end
    end
  end

  describe "DELETE #destroy" do
    it "destroys the requested property" do
      property = Property.create! valid_attributes
      expect {
        delete :destroy, params: {id: property.to_param}, session: valid_session
      }.to change(Property, :count).by(-1)
    end

    it "redirects to the properties list" do
      property = Property.create! valid_attributes
      delete :destroy, params: {id: property.to_param}, session: valid_session
      expect(response).to redirect_to(properties_url)
    end
  end

end
