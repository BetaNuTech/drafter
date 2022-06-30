# == Schema Information
#
# Table name: user_profiles
#
#  id          :uuid             not null, primary key
#  appsettings :jsonb
#  company     :string
#  first_name  :string
#  last_name   :string
#  name_prefix :string
#  name_suffix :string
#  notes       :text
#  phone       :string
#  title       :string
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  user_id     :uuid
#
class UserProfile < ApplicationRecord
  belongs_to :user
end
