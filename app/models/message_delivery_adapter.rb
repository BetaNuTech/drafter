# == Schema Information
#
# Table name: message_delivery_adapters
#
#  id              :uuid             not null, primary key
#  message_type_id :uuid             not null
#  slug            :string           not null
#  name            :string           not null
#  description     :text
#  active          :boolean          default(TRUE), not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#

class MessageDeliveryAdapter < ApplicationRecord
  ### Class Concerns/Extensions
  include Seeds::Seedable

  ### Constants
  ### Associations
  belongs_to :message_type

  ### Validations
  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true
  validates_inclusion_of :active, in: [true, false]
  validates :api_token, presence: true, uniqueness: true

  ## Scopes
  scope :active, -> { where(active: true) }

  # Callbacks
  before_validation :assign_api_token

  ### Class Methods

  ### Instance Methods

  def assign_api_token
    self.api_token ||= Digest::SHA256.hexdigest(Time.now.to_s + rand.to_s)[0..31]
  end
end