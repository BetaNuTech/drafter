require_relative './adapters/action_mailer'

module Messages
  module Adapters
    # List valid/enabled adapter classes Here
    ### IMPORTANT: Values in the VALID array correspond directly to
    # the MessageDeliveryAdapter record "slug"s
    SUPPORTED = ['ActionMailer']

    # Does the provided source match a valid Lead Adapter Source
    def self.supported_source?(source)
      SUPPORTED.include?(source)
    end
  end
end
