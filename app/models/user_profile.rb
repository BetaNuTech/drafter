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
# Indexes
#
#  index_user_profiles_on_user_id  (user_id) UNIQUE
#
class UserProfile < ApplicationRecord
  ALLOWED_PARAMS = [:id, :company, :first_name, :last_name, :name_prefix, :name_suffix, :notes, :phone, :title, :user_id]
  FEATURE_PARAMS = []
  APPSETTING_PARAMS = []

  belongs_to :user, required: :false
  before_save :normalize_phone

  def self.format_phone(number, prefixed: false)
    # Strip non-digits
    out = ( number || '' ).to_s.gsub(/[^0-9]/,'')

    if out.length > 10
      # Remove US country code
      if (out[0] == '1')
        out = out[1..-1]
      end
    end

    # Truncate number to 10 digits
    out = out[0..9]

    # Add country code if we want to prefix
    if prefixed
      out = "1" + out
    end

    return out
  end

  def normalize_phone
    if phone.present?
      if detected_prefix = phone.match(/^\+(\d)/)
        self.prefix = detected_prefix[1]
        self.phone = self.class.format_phone(phone, prefixed: false)
      else
        self.phone = self.class.format_phone(phone)
      end
    end
    return self.phone
  end
end
