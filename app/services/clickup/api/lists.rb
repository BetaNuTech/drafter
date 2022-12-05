module Clickup
  module Api
    class Lists < Base

      # Lists from within a folder
      def getLists(folder_id:)
        request_options = {
          resource: "folder/#{folder_id}/list",
          parameters: ["archived=false"]
        }
        begin
          response = getData(request_options)
          lists = Clickup::Data::List.from_Lists(response.parsed_response)
        rescue => e
          msg = "#{format_request_id} Clickup::Api::Lists encountered an error fetching data. #{e}"
          Rails.logger.error msg
          return []
        end
        return lists
      end

      # Lists at the root of the Space, not within a folder
      def getFolderlessLists(space_id:)
        request_options = {
          resource: "space/#{space_id}/list",
          parameters: ["archived=false"]
        }
        begin
          response = getData(request_options)
          lists = Clickup::Data::List.from_Lists(response.parsed_response)
        rescue => e
          msg = "#{format_request_id} Clickup::Api::Lists encountered an error fetching data. #{e}"
          Rails.logger.error msg
          return []
        end
        return lists
      end

    end
  end
end
