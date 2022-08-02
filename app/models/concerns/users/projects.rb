module Users
  module Projects
    extend ActiveSupport::Concern

    included do
      has_many :project_users
      has_many :projects, through: :project_users

      def project_role(project)
        projectroles = user_projects.where(project: project)
        return nil unless projectroles.any?

        projectroles.limit(1).first.project_role
      end

      def member?(project)
        project_role(project).present?
      end

      def project_owner?(project)
        project_role(project).owner?
      end

      def project_management?(project)
        project_role(project).management?
      end

      def project_internal?(project)
        project_role(project).internal?
      end

    end
  end
end
