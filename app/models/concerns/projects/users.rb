module Projects
  module Users
    extend ActiveSupport::Concern

    included do
      has_many :project_users, dependent: :destroy
      has_many :users, through: :project_users

      def role_for(user)
        project_users.includes(:user).where(user_id: user.id).limit(1).first.role
      end

      def owners
        project_users.includes(:user).where(project_role_id: ProjectRole.owner.id).map(&:user)
      end

      def managers
        project_users.includes(:user).where(project_role_id: ProjectRole.manager.id).map(&:user)
      end

      def finance
        project_users.includes(:user).where(project_role_id: ProjectRole.finance.id).map(&:user)
      end

      def consultants
        project_users.includes(:user).where(project_role_id: ProjectRole.consultant.id).map(&:user)
      end

      def developers
        project_users.includes(:user).where(project_role_id: ProjectRole.developer.id).map(&:user)
      end

      def available_users
        current_members = users.pluck(&:id)
        User.active.where.not(id: current_members).ordered_by_name
      end

      def add_user(user:, role:)
        ProjectUser.create(user: user, project_role: role, project: self)
      end

    end
  end
end
