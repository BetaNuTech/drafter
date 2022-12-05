module Clickup
  module Api
    class Folders < Base

      def getFolders(space_id:)
        request_options = {
          resource: "space/#{space_id}/folder",
          parameters: ["archived=false"]
        }
        begin
          response = getData(request_options)
          folders = Clickup::Data::Folder.from_Folders(response.parsed_response)
        rescue => e
          msg = "#{format_request_id} Clickup::Api::Folders encountered an error fetching data. #{e}"
          Rails.logger.error msg
          return []
        end
        return folders
      end

    end
  end
end
