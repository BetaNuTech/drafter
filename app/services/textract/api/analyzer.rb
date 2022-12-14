module Textract
  module Api
    class Analyzer < Base
      require 'aws-sdk-textract'
      require 'aws-sdk-sqs'

      class TextractApiError < StandardError; end;

      TEXTRACT_CLIENT = Aws::Textract::Client
      SQS_CLIENT = Aws::SQS::Client
      MAX_MESSAGES = 10

      def analyze_document(metadata:, requestid:)
        client_params = textract_client_parameters
        request_params = request_parameters(metadata:, requestid:)
        if @debug
          puts "*** Textract::Api::Analyzer: Textract API Client: Params: #{client_params.inspect}"
          puts "*** Textract::Api::Analyzer: Textract API Request: start_expense_analysis: Params: #{request_params.inspect}"
        end
        if @dry_run
          puts '*** Textract::Api::Analyzer: DRY RUN: skipping Textract API Call'
          return nil
        end
        client = TEXTRACT_CLIENT.new(client_params)
        response = client.start_expense_analysis(request_params)
        puts "*** Textract Response: #{response.inspect}" if @debug
        response[:job_id]
      rescue => e
        raise TextractApiError.new("#{e.class.to_s}: #{e.to_s}")
      end

      def process_completion_queue(allow_class, &block)
        loop do
          messages = get_completed_items.select{|message| message.job_status.record.is_a?(allow_class)}
          break if messages.empty?

          successful_job_messages = messages.select{|message| message.job_status.ok? } 
          failed_job_messages = messages.select{|message| message.job_status.failed? }

          failed_jobs = []
          failed_job_messages.each do |sqs_message|
            job = Textract::Data::AnalysisJob.from_sqs_message(sqs_message)
            failed_jobs << job
          end

          successful_jobs = []
          successful_job_messages.each do |sqs_message|
            job = Textract::Data::AnalysisJob.from_sqs_message(sqs_message)
            job.data = get_textract_analysis(job_id: job.job_id, expected_total: job.record&.amount)
            successful_jobs << job
          end

          yield(successful_jobs, failed_jobs)

          failed_job_messages.each do |sqs_message|
            delete_sqs_message(sqs_message)
          end

          successful_job_messages.each do |sqs_message|
            delete_sqs_message(sqs_message)
          end
        end
      end

      def get_completed_items
        client = SQS_CLIENT.new(sqs_client_parameters) 
        response = client.receive_message(queue_url: @configuration.sqs_url, max_number_of_messages: MAX_MESSAGES)
        items = Textract::Data::SqsMessage.from_api(response)
        items
      end

      def get_textract_analysis(job_id:, expected_total:)
        client = TEXTRACT_CLIENT.new(textract_client_parameters)
        response = client.get_expense_analysis(job_id:).to_h
        analysis = Textract::Data::AnalysisJobData.from_api(response:, job_id:, expected_total:)
        analysis
      end

      def delete_sqs_message(sqs_message)
        client = TEXTRACT_CLIENT.new(textract_client_parameters)
        client.delete_message(queue_url: @configuration.sqs_url, reciept_handle: sqs_message.receipt_handle)
      end

      private

      def sqs_client_parameters
        {
          region: @configuration.region,
          credentials: @configuration.aws_credentials
        }
      end

      def textract_client_parameters
        {
          region: @configuration.region,
          credentials: @configuration.aws_credentials
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
