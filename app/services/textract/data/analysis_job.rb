module Textract
  module Data
    class AnalysisJob
      attr_accessor :job_id, :status, :record, :data

      def self.from_sqs_message(sqs_message)
        job = self.new
        job.job_id = sqs_message.job_status.job_id
        job.status = sqs_message.job_status.status
        job.record = sqs_message.job_status.record
        job
      end
    end
  end
end
