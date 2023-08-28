module Users
  module Projects
    extend ActiveSupport::Concern

    included do
      has_many :project_users
      has_many :projects, through: :project_users

      def project_role(project)
        project_role_assocs = project_users.where(project: project)
        return nil unless project_role_assocs.any?

        project_role_assocs.limit(1).first.project_role
      end

      def member?(project)
        project_role(project).present?
      end

      def project_owner?(project)
        project_role(project)&.owner?
      end

      def project_management?(project)
        project_role(project)&.management?
      end

      def project_finance?(project)
        project_role(project)&.finance?
      end

      def project_internal?(project)
        project_role(project)&.internal?
      end

      def project_external?(project)
        project_role(project)&.external?
      end

      def project_developer?(project)
        project_role(project)&.developer?
      end

      def project_investor?(project)
        project_role(project)&.investor?
      end

    end
  end
end
