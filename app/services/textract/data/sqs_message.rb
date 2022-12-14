module Textract
  module Data
    class SqsMessage
      require 'json'

      PROPERTIES = %i{type sqs_message_id message_id topic_arn body message timestamp signature_version signature signing_cert_url unsubscribe_url source receipt_handle}
      BODY_PROPERTIES = %i{type message_id topic_arn message timestamp signature_version signature signing_cert_url unsubscribe_url}
      
      attr_accessor *PROPERTIES

      def self.from_api(response)
        return [] unless response.respond_to?(:messages)

        return [] if response.messages.count.zero?

        response.messages.map do |message|
          sqs_message = self.new
          sqs_message.receipt_handle = message.receipt_handle
          sqs_message.sqs_message_id = message.message_id
          sqs_message.body = body = JSON.parse(message.body)
          BODY_PROPERTIES.each do |prop|
            prop_key = prop.to_s.classify
            sqs_message.send("#{prop}=", body[prop_key]) if body.keys.include?(prop_key)
          end
          sqs_message.source = ( sqs_message.topic_arn || '' ).split(':').last
          sqs_message.job_status # memoize job status
          sqs_message
        end
      end

      def valid?
        PROPERTIES.all?{|prop| self.send(prop).present?}
      end

      def job_status
        @job_status ||= TextractJobStatus.from_sqs_message(self)
      end

    end
  end
end
