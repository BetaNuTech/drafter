module Textract
  module Api
    class Analyzer < Base
      require 'aws-sdk-textract'

      class TextractApiError < StandardError; end;

      CLIENT = Aws::Textract::Client

      def analyze_document(metadata:, requestid:)
        client_params = client_parameters
        request_params = request_parameters(metadata:, requestid:)
        if @debug
          puts "*** Textract::Api::Analyzer: Textract API Client: Params: #{client_params.inspect}"
          puts "*** Textract::Api::Analyzer: Textract API Request: start_expense_analysis: Params: #{request_params.inspect}"
        end
        if @dry_run
          puts '*** Textract::Api::Analyzer: DRY RUN: skipping Textract API Call'
          return nil
        end
        client = CLIENT.new(client_params)
        response = client.start_expense_analysis(request_params)
        puts "*** Textract Response: #{response.inspect}" if @debug
        response[:job_id]
      rescue => e
        raise TextractApiError.new("#{e.class.to_s}: #{e.to_s}")
      end

      def process_completed_items(&block)
        # TODO
      end

      #private

      def client_parameters
        {
          region: @configuration.region,
          credentials: Aws::Credentials.new(@configuration.access_key_id, @configuration.secret_access_key)
        }
      end

      def request_parameters(metadata:, requestid:)
        {
          document_location: {
            s3_object: {
              bucket: @configuration.bucket,
              name: metadata.fetch('key', nil),
            },
          },
          client_request_token: requestid,
          job_tag: metadata.fetch('job_tag', nil),
          notification_channel: {
            sns_topic_arn: @configuration.sns_topic_arn,
            role_arn: @configuration.role_arn,
          }
        }
      end
    end
  end
end
