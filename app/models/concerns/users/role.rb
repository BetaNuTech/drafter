module Users
  module Role
    extend ActiveSupport::Concern

    included do
      belongs_to :role, required: false

      ### System Roles
      def admin?
        role&.admin? || false
      end

      def executive?
        role&.executive? || false
      end

      def administrator?
        admin? || executive?
      end

      def user?
        role&.user? || false
      end

    end
  end
end
