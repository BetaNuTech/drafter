
module Users
  module Profile
    extend ActiveSupport::Concern

    included do
      after_initialize do
        build_profile unless profile.present?
      end

      has_one :profile, class_name: 'UserProfile', dependent: :destroy, required: false
      accepts_nested_attributes_for :profile

      delegate :name_prefix, to: :profile, allow_nil: true
      delegate :first_name, to: :profile, allow_nil: true
      delegate :last_name, to: :profile, allow_nil: true
      delegate :name_suffix, to: :profile, allow_nil: true
      delegate :title, to: :profile, allow_nil: true
      delegate :company, to: :profile, allow_nil: true
      delegate :notes, to: :profile, allow_nil: true
      delegate :phone, to: :profile, allow_nil: true

      def full_name
        [name_prefix, first_name, last_name, name_suffix].join(' ')
      end

      def name
        [first_name, last_name, name_suffix].join(' ')
      end
    end
  end
end
