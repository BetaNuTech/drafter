# == Schema Information
#
# Table name: projects
#
#  id          :uuid             not null, primary key
#  active      :boolean          default(TRUE), not null
#  budget      :decimal(, )      default(0.0), not null
#  description :text
#  name        :string           not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
class Project < ApplicationRecord
  ALLOWED_PARAMS = [:id, :name, :description, :budget].freeze

  include Projects::Users

  validates :name, presence: true

  def events
    SystemEvent.where(event_source: self).
      or(SystemEvent.where(incidental: self))
  end
end
