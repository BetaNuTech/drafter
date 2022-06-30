module Users
  module Role
    extend ActiveSupport::Concern

    included do
      belongs_to :role, required: false

      ### System Roles
      def admin?
        role.try(:admin?) || false
      end

      def executive?
        role.try(:executive?) || false
      end

      def administrator?
        admin? || executive?
      end

      def user?
        role.try(:user?)
      end

    end
  end
end
