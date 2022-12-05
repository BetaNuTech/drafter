module Clickup
  module Data
    class Folder
      require 'nokogiri'

      attr_accessor :remoteid, :name

      def self.from_Folders(data)
        self.from_api_response(response: data, method: 'Folders')
      end

      def self.from_api_response(response:, method:)
        root_node = nil

        case response
        when String
          begin
            data = JSON(response)
          rescue => e
            raise Clickup::Data::Error.new("Invalid Folder JSON: #{e}")
          end
        when Hash
          data = response
        else
          raise Clickup::Data::Error.new("Invalid Folder data. Should be JSON string or Hash")
        end

        begin
          # Handle Error
          if data["err"].present?
            err_msg = data["err"].to_s
            raise Clickup::Data::Error.new(err_msg)
          end

          # Extract Folders Data
          root_node = data

        rescue => e
          raise Clickup::Data::Error.new("Invalid Folders data schema: #{e}")
        end

        raw_folders = root_node.map{|record| Folder.from_folder_node(record)}.flatten

        return raw_folders
      end

      def self.from_folder_node(data)
        folder = Folder.new
        folder.remoteid = data["id"]
        folder.name = data["name"] || 'Unknown'
        return folder
      end
    end
  end
end
