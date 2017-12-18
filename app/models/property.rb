# == Schema Information
#
# Table name: properties
#
#  id           :uuid             not null, primary key
#  name         :string
#  address1     :string
#  address2     :string
#  address3     :string
#  city         :string
#  state        :string
#  zip          :string
#  country      :string
#  organization :string
#  contact_name :string
#  phone        :string
#  fax          :string
#  email        :string
#  units        :integer
#  notes        :text
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  active       :boolean          default(TRUE)
#

class Property < ApplicationRecord
  ALLOWED_PARAMS = [:name, :address1, :address2, :address3, :city, :state, :zip, :country, :organization, :contact_name, :phone, :fax, :email, :units, :notes, :active]

  ## Associations
  has_many :leads
  has_many :listings,
    class_name: 'PropertyListing',
    dependent: :destroy
  accepts_nested_attributes_for :listings, reject_if: proc{|attributes| attributes['code'].blank? && attributes['description'].blank? }

  ### Validations
  validates :name, presence: true, uniqueness: true

  ## Scopes
  scope :active, -> { where(active: true) }

  # Return array of all possible PropertyListings for this property.
  def present_and_possible_listings
    return ( listings + missing_listings ).sort_by{|l| l.source.name}
  end

  # Return an array of PropertyListings which are not present for
  # this property
  def missing_listings
    LeadSource.where.not(id: [listings.map(&:source_id)]).map do |source|
      PropertyListing.new(property_id: self.id, source_id: source.id, active: false)
    end
  end
end
