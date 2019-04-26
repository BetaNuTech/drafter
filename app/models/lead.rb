# == Schema Information
#
# Table name: leads
#
#  id                  :uuid             not null, primary key
#  user_id             :uuid
#  lead_source_id      :uuid
#  title               :string
#  first_name          :string
#  last_name           :string
#  referral            :string
#  state               :string
#  notes               :text
#  first_comm          :datetime
#  last_comm           :datetime
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  property_id         :uuid
#  phone1              :string
#  phone2              :string
#  fax                 :string
#  email               :string
#  priority            :integer          default("low")
#  phone1_type         :string           default("Cell")
#  phone2_type         :string
#  phone1_tod          :string
#  phone2_tod          :string
#  dob                 :datetime
#  id_number           :string
#  id_state            :string
#  remoteid            :string
#  middle_name         :string
#  conversion_date     :datetime
#  call_log            :json
#  call_log_updated_at :datetime
#  classification      :integer
#  follow_up_at        :datetime
#

class Lead < ApplicationRecord

  ### Class Concerns/Extensions
  audited
  include Leads::EngagementPolicy
  include Leads::StateMachine
  include Leads::Priority
  include Leads::Search
  include Leads::Messaging
  include Leads::CallLog
  include Leads::Duplicates
  include Leads::Export

  ### Constants
  ALLOWED_PARAMS = [:lead_source_id, :property_id, :title, :first_name, :middle_name, :last_name, :referral, :state, :notes, :first_comm, :last_comm, :phone1, :phone1_type, :phone1_tod, :phone2, :phone2_type, :phone2_tod, :dob, :id_number, :id_state, :email, :fax, :user_id, :priority, :transition_memo, :classification, :follow_up_at]
  PRIVILEGED_PARAMS = [:lead_source_id, :user_id, :state, :id, :property_id]
  PHONE_TYPES = ["Cell", "Home", "Work"]
  PHONE_TOD = [ "Any Time", "Morning", "Afternoon", "Evening"]

  ### Attributes

  ### Enums
  enum classification: { lead: 0, vendor: 1, resident: 2, duplicate: 3, other: 4 }

  ### Associations
  has_one :preference, class_name: 'LeadPreference', dependent: :destroy
  accepts_nested_attributes_for :preference
  belongs_to :source, class_name: 'LeadSource', foreign_key: 'lead_source_id', required: false
  belongs_to :property, required: false
  has_one :team, through: :property
  belongs_to :user, required: false
  has_many :comments, class_name: "Note", as: :notable, dependent: :destroy
  has_many :scheduled_actions, as: :target, dependent: :destroy
  has_many :transitions, class_name: 'LeadTransition'

  ### Scopes
  scope :ordered_by_created, -> {order(created_at: "ASC")}
  scope :is_lead, -> { where(classification: ['lead', nil])}
  scope :high_priority, -> { order(priority: 'desc').limit(5) }
  scope :for_team, -> (team) {
      join_sql = "INNER JOIN properties on leads.property_id = properties.id INNER JOIN teams on properties.team_id = teams.id"
      joins(join_sql).where(teams: {id: team.id})
  }

  ### Validations
  validates :first_name, presence: true
	validates :phone1, presence: true, unless: ->(lead){ lead.phone2.present? || lead.email.present? }
	validates :email, presence: true, unless: ->(lead){ lead.phone1.present? || lead.phone2.present? }
  validates :remoteid, uniqueness: { scope: :property_id, case_sensitive: false }, if: -> {remoteid.present?}

  ### Callbacks
  before_validation :format_phones

  ### Class Methods

  def self.for_agent(agent)
    where(user_id: agent.id)
  end

  def self.reparse(lead)
    if lead.lead_source_id.present? && lead.property_id.present? && lead.preference.try(:raw_data).present?
      creator = Leads::Creator.new(
        data: JSON.parse(lead.preference.raw_data).with_indifferent_access,
        token: lead.source.api_token )
      new_lead = creator.execute
      new_lead.validate
      return new_lead
    else
      return Lead.new
    end
  end

  ### Instance Methods

  def is_lead?
    classification.nil? || classification == 'lead'
  end

  def all_tasks_completed?
    return( ignore_incomplete_tasks || !scheduled_actions.pending.exists? )
  end

  def users_for_lead_assignment(default: nil)
    users = ( property.present? ? property.agents : User.team_agents )&.by_name_asc || []
    users = ( users.to_a + [user] ).compact
    users = [default].compact if users.empty?
    users.uniq!
    return users
  end

  def imported?
    return self.remoteid.present?
  end

  def name
    [title, first_name, middle_name, last_name].join(' ')
  end

  def priority_value
    self.class.priorities[self.priority]
  end

  def shortid
    id.to_s.gsub('-','')[0..19]
  end

  # TODO
  def walk_in?
    false
  end

  def agent
    user || property.try(:managers).try(:first)
  end

  private

  def format_phones
    self.phone1 = PhoneNumber.format_phone(self.phone1) if self.phone1.present?
    self.phone2 = PhoneNumber.format_phone(self.phone2) if self.phone2.present?
  end

end
