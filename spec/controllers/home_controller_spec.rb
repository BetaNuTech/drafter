require 'rails_helper'

RSpec.describe HomeController, type: :controller do
  include_context 'users'

  render_views

  describe '#home (/)' do
    describe 'as an administrator' do
      let(:user) { admin_user }
      it 'should display the home page' do
        sign_in user
        get :index
        expect(response).to render_template(:index)
      end
    end
    describe 'as a user' do
      let(:user) { regular_user }
      it 'should display the home page' do
        sign_in user
        get :index
        expect(response).to render_template(:index)
      end
    end

  end
end
