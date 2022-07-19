# == Schema Information
#
# Table name: users
#
#  id                     :uuid             not null, primary key
#  active                 :boolean          default(TRUE), not null
#  confirmation_sent_at   :datetime
#  confirmation_token     :string
#  confirmed_at           :datetime
#  current_sign_in_at     :datetime
#  current_sign_in_ip     :string
#  email                  :string           default(""), not null
#  encrypted_password     :string           default(""), not null
#  failed_attempts        :integer          default(0), not null
#  last_sign_in_at        :datetime
#  last_sign_in_ip        :string
#  locked_at              :datetime
#  remember_created_at    :datetime
#  reset_password_sent_at :datetime
#  reset_password_token   :string
#  sign_in_count          :integer          default(0), not null
#  timezone               :string           default("Central Time (US & Canada)"), not null
#  unconfirmed_email      :string
#  unlock_token           :string
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  organization_id        :uuid
#  role_id                :uuid
#
# Indexes
#
#  index_users_on_confirmation_token    (confirmation_token) UNIQUE
#  index_users_on_email                 (email) UNIQUE
#  index_users_on_reset_password_token  (reset_password_token) UNIQUE
#  index_users_on_role_id               (role_id)
#  index_users_on_unlock_token          (unlock_token) UNIQUE
#
require 'rails_helper'

RSpec.describe User, type: :model do
  include_context 'users'

  describe 'Initialization' do
    it 'create a new user record' do
      user_count = User.count
      assert(user.valid?)
      assert(user.save)
      assert(user.id.present?)
      expect(User.count).to be > user_count
    end

  end

  describe 'Profiles' do
    it 'creates a new user record with a profile' do
      user.save
      expect(user.profile).to be_a(UserProfile)
    end
  end

  describe 'Roles' do
    it 'creates a new user with a role' do
      user.save
      expect(user.role).to be_a(Role)
    end
  end

  describe 'Organizations' do
    it 'has an optional organization' do
      expect(user.organization).to be_a(Organization)
      assert(user.valid?)
      user.organization = nil
      assert(user.valid?)
      assert(user.save)
    end
  end
end
