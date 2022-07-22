module Users
  module Projects
    extend ActiveSupport::Concern

    included do
      has_many :project_users
      has_many :projects, through: :project_users

      def project_role(project)
        project_role = user_projects.where(project: project)
        return nil unless project_role.any?

        project_role.limit(1).first.project_role
      end

      def member?(project)
        project_role.present?
      end

      def project_owner?(project)
        project_role.owner?
      end

      def project_management?(project)
        project_role.management?
      end

      def project_internal?(project)
        project_role(project).internal?
      end

    end
  end
end
