module Textract
  module Api
    class Base
      attr_reader :configuration
      attr_accessor :debug, :dry_run

      # Initialize with an optional Clickup::Configuration instance
      def initialize(conf=nil)
        @debug = false
        @configuration = conf || Textract::Api::Configuration.new
        @request_id = nil
        @dry_run = false
      end
    end
  end
end
