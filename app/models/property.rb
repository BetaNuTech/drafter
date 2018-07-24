# == Schema Information
#
# Table name: properties
#
#  id              :uuid             not null, primary key
#  name            :string
#  address1        :string
#  address2        :string
#  address3        :string
#  city            :string
#  state           :string
#  zip             :string
#  country         :string
#  organization    :string
#  contact_name    :string
#  phone           :string
#  fax             :string
#  email           :string
#  units           :integer
#  notes           :text
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  active          :boolean          default(TRUE)
#  website         :string
#  school_district :string
#  amenities       :text
#  application_url :string
#

class Property < ApplicationRecord
  ALLOWED_PARAMS = [ :name, :address1, :address2, :address3, :city, :state, :zip,
                    :country, :organization, :contact_name, :phone, :fax, :email,
                    :website, :units, :notes, :school_district, :amenities, :active, :application_url ]
  audited

  ## Associations
  has_many :leads
  has_many :listings,
    class_name: 'PropertyListing',
    dependent: :destroy
  accepts_nested_attributes_for :listings, reject_if: proc{|attributes| attributes['code'].blank? && attributes['description'].blank? }
  has_many :property_agents, dependent: :destroy
  has_many :agents, through: :property_agents, class_name: 'User', source: :user
  has_many :unit_types, dependent: :destroy
  has_many :housing_units, class_name: 'Unit', dependent: :destroy
  has_many :residents, dependent: :destroy
  has_many :engagement_policies, dependent: :destroy

  ### Validations
  validates :name, presence: true, uniqueness: true

  ## Scopes
  scope :active, -> { where(active: true) }

  ## Class Methods

  # Lookup by ID or PropertyListing code
  def self.find_by_code_and_source(code:, source_id: nil)
    if source_id.nil?
      return Property.active.where(id: code).first
    else
      return PropertyListing.includes(:source).
        where( lead_sources: {id: source_id, active: true},
               property_listings: {code: code, active: true}).
        first.try(:property)
    end
  end

  ## Instance Methods

  # Return array of all possible PropertyListings for this property.
  def present_and_possible_listings
    return ( listings + missing_listings ).sort_by{|l| l.source.try(:name) || ''}
  end

  # Return an array of PropertyListings which are not present for
  # this property
  def missing_listings
    LeadSource.where.not(id: [listings.map(&:source_id)]).map do |source|
      PropertyListing.new(property_id: self.id, source_id: source.id, active: false)
    end
  end

  def listing_code(source)
    return nil unless source.present?
    self.listings.where(source_id: source.id).first.try(:code)
  end

  def occupancy_rate
    (housing_units.occupied.count.to_f / [ housing_units.count || 1].min.to_f).round(1) * 100.0
  end

  def primary_agent
    # TODO REFACTOR
    property_agents.first.try(:user)
  end

  # Return the first active manager user with an active assignment to the Property
  def managers
    User.
      includes(:role, property_agents: [:property]).
      where(properties: {id: self.id},
            property_agents: {active: true},
            roles: {slug: Role.manager.slug}).
      order('property_agents.created_at ASC')
  end

  def address(line_break="\n\r")
    [address1, address2, address3, "#{city} #{state} #{zip}"].
      compact.
      select{|c| (c || '').length > 0}.
      join(line_break)
  end

  def address_html
    address("<BR/>")
  end

end
