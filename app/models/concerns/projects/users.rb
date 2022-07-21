module Projects
  module Users
    extend ActiveSupport::Concern

    included do
      has_many :project_users, dependent: :destroy
      has_many :users, through: :project_users

      def role_for(user)
        project_users.where(user_id: user.id).limit(1).first.role
      end

      def owners
        project_users.where(project_role_id: ProjectRole.owner.id)
      end

      def available_users
        current_members = users.pluck(&:id)
        User.active.where.not(id: current_members).ordered_by_name
      end

    end
  end
end
