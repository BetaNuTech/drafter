module Clickup
  module Api
    class Workspaces < Base

      def getWorkspaces
        request_options = {
          resource: 'team'
        }
        begin
          response = getData(request_options)
          workspaces = Clickup::Data::Workspace.from_Workspaces(response.parsed_response)
        rescue => e
          msg = "#{format_request_id} Clickup::Api::Workspaces encountered an error fetching data. #{e}"
          Rails.logger.error msg
          return []
        end
        return workspaces
      end

    end
  end
end
