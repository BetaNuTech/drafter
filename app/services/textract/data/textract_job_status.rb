module Textract
  module Data
    class TextractJobStatus
      PROPERTIES = %i{job_id status api job_tag timestamp document_location_object document_location_bucket}.freeze

      attr_accessor *PROPERTIES
      attr_reader :record

      def self.from_sqs_message(sqs_message)
        jobstatus = self.new
        
        message = JSON.parse sqs_message.message
        document_data = message.fetch('DocumentLocation')

        jobstatus.job_id = message.fetch('JobId',nil)
        jobstatus.status = message.fetch('Status',nil) == 'SUCCEEDED' ? :succeeded : :failed
        jobstatus.api = message.fetch('API', nil)
        jobstatus.job_tag = message.fetch('JobTag', nil)
        jobstatus.timestamp = Time.at( message.fetch('Timestamp', 1000).to_i / 1000 )
        jobstatus.document_location_object = document_data.fetch('S3ObjectName','')
        jobstatus.document_location_bucket = document_data.fetch('S3Bucket','')

        jobstatus
      end

      def record
        @record ||=
          begin
            record_class, record_id = @job_tag.split('--')
            record_class.constantize.where(id: record_id).first
          rescue
            nil
          end
      end

      def valid?
        PROPERTIES.all?{|prop| self.send(prop).present?}
      end

      def ok?
        :succeeded == status
      end

      def failed?
        !ok?
      end

    end
  end
end
