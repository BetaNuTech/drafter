module Clickup
  module Api
    class Configuration
      ENV_PREFIX = 'CLICKUP'
      PROPERTIES = [ :api_token ]

      attr_reader *PROPERTIES
      attr_reader :errors

      # Initialize using ENVVARS or with a provided Hash with keys matching PROPERTIES
      def initialize(source=:credentials)
        @errors = []
        case source
        when :env
          load_env_settings
        when :credentials
          load_rails_credentials
        when Hash
          load_hash_settings(source)
        end
        @valid, @errors = validate_settings
        @valid
      end

      def to_h
        PROPERTIES.inject({}){|memo, obj| memo[obj] = self.send(obj); memo }
      end

      def valid?
        @valid
      end

      private

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

      def load_hash_settings(data)
        @errors = []
        @api_token = data.fetch(:api_token, nil)
      end

      def load_env_settings
        @errors = []
        @api_token = get_prefixed_env(:api_token)
      end

      def get_prefixed_env(var)
        val = ENV.fetch("#{ENV_PREFIX}_#{var.to_s.upcase}", nil)
        return val
      end

      def load_rails_credentials
        @api_token = Rails.application.credentials.dig(:clickup, application_env, :api_token)
      end

      # Returns Array: [isValid, errorsArr]
      def validate_settings
        errors = []
        PROPERTIES.each do |prop|
          if !( defined?(prop) && self.send(prop).present? )
            errors << "Missing: #{prop.to_s}"
          end
        end
        return [errors.empty?, errors]
      end
    end
  end
end
