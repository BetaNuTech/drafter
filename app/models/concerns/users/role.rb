module Users
  module Role
    extend ActiveSupport::Concern

    included do
      belongs_to :role, required: false

      ### System Roles
      def admin?
        role&.admin?
      end

      def executive?
        role&.executive?
      end

      def administrator?
        admin? || executive?
      end

      def user?
        role&.user?
      end

    end
  end
end
