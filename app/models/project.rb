class Project < ApplicationRecord
  ALLOWED_PARAMS = [:id, :name, :description, :budget].freeze

  validates :name, presence: true

  def users
    # TODO
    User.all
  end
end
