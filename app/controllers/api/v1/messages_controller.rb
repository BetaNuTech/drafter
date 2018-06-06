module Api
  module V1
    class MessagesController < ApiController
      before_action :validate_message_adapter_token

      def create
        message_data = params
        log_message_data(message_data)
        receiver = Messages::Receiver.new(data: message_data, token: api_token)
        @message = receiver.execute
        response_data = receiver.response
        render plain: response_data[:body],
               status: response_data[:status],
               format: response_data[:format]
      end


      private

      def log_message_data(data)
        if ( ENV.fetch("DEBUG_MESSAGE_API", "false").downcase != 'false' )
          Rails.logger.warn "[#{DateTime.now} MESSAGE API] #{data.inspect}"
        end
      end

      def validate_message_adapter_token
        validate_source_token(source: MessageDeliveryAdapter, token: api_token)
      end
    end
  end
end
