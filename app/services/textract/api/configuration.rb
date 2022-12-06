module Textract
  module Api
    class Configuration

      PROPERTIES = %i{access_key_id secret_access_key bucket region sns_topic_arn topic_arn}.freeze

      attr_reader *PROPERTIES
      attr_reader :errors

      def initialize(source=:credentials)
        @errors = []
        @valid = false
        case source
        when :credentials
          load_rails_credentials
        when Hash
          load_hash_settings(source)
        end
        @valid, @errors = validate_settings
        @valid
      end

      def valid?
        @valid
      end

      def errors?
        @errors.any?
      end

      private

      def reset_errors
        @errors = []
      end

      def application_env
        @application_env ||=
          begin
            if Rails.env.development?
              :development
            else
              ( ENV.fetch('APPLICATION_ENV','production') == 'production' ) ? :production : :staging
            end
          end
      end

      def load_rails_credentials
        config = Rails.application.credentials.dig(:aws, :textract, application_env)
        load_hash_settings(config)
      end

      def load_hash_settings(data)
        @access_key_id = data.fetch(:access_key_id)
        @secret_access_key = data.fetch(:secret_access_key)
        @bucket = data.fetch(:bucket)
        @region = data.fetch(:region)
        @sns_topic_arn = data.fetch(:sns_topic_arn)
        @topic_arn = data.fetch(:topic_arn)

        true
      end

      # Returns Array: [isValid, errorsArr]
      def validate_settings
        reset_errors

        PROPERTIES.each do |prop|
          if !( defined?(prop) && self.send(prop).present? )
            @errors << "Missing: #{prop.to_s}"
          end
        end
        return [errors?, @errors]
      end

    end
  end
end
