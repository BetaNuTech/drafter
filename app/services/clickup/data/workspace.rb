module Clickup
  module Data
    class Workspace
      require 'nokogiri'

      attr_accessor :remoteid, :name

      # Teams == Workspaces
      def self.from_Workspaces(data)
        self.from_api_response(response: data, method: 'Workspaces')
      end

      def self.from_api_response(response:, method:)
        root_node = nil

        case response
        when String
          begin
            data = JSON(response)
          rescue => e
            raise Clickup::Data::Error.new("Invalid Team (Workspaces) JSON: #{e}")
          end
        when Hash
          data = response
        else
          raise Clickup::Data::Error.new("Invalid Team (Workspaces) data. Should be JSON string or Hash")
        end

        begin
          # Handle Error
          if data["err"].present?
            err_msg = data["err"].to_s
            raise Clickup::Data::Error.new(err_msg)
          end

          # Extract Workspaces Data
          root_node = data["teams"]

        rescue => e
          raise Clickup::Data::Error.new("Invalid Team (Workspaces) data schema: #{e}")
        end

        raw_workspaces = root_node.map{|record| Workspace.from_workspace_node(record)}.flatten

        return raw_workspaces
      end

      def self.from_workspace_node(data)
        workspace = Workspace.new
        workspace.name = data["name"] || 'Unknown'
        workspace.remoteid = data["id"]
        return workspace
      end
    end
  end
end
