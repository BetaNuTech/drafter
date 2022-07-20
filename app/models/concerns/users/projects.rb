module Users
  module Projects
    extend ActiveSupport::Concern

    included do
      has_many :project_users
      has_many :projects, through: :project_users
    end
  end
end
