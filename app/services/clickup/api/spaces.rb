module Clickup
  module Api
    class Spaces < Base

      def getSpaces
        request_options = {
          resource: 'space',
          parameters: ["archived=false"]
        }
        begin
          response = getData(request_options)
          spaces = Clickup::Data::Space.from_Spaces(response.parsed_response)
        rescue => e
          msg = "#{format_request_id} Clickup::Api::Spaces encountered an error fetching data. #{e}"
          Rails.logger.error msg
          return []
        end
        return spaces
      end

    end
  end
end
