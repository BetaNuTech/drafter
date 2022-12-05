module Clickup
  module Data
    class List
      require 'nokogiri'

      attr_accessor :remoteid, :name

      def self.from_Lists(data)
        self.from_api_response(response: data, method: 'Lists')
      end

      def self.from_api_response(response:, method:)
        root_node = nil

        case response
        when String
          begin
            data = JSON(response)
          rescue => e
            raise Clickup::Data::Error.new("Invalid List JSON: #{e}")
          end
        when Hash
          data = response
        else
          raise Clickup::Data::Error.new("Invalid List data. Should be JSON string or Hash")
        end

        begin
          # Handle Error
          if data["err"].present?
            err_msg = data["err"].to_s
            raise Clickup::Data::Error.new(err_msg)
          end

          # Extract Lists Data
          root_node = data["lists"]

        rescue => e
          raise Clickup::Data::Error.new("Invalid Lists data schema: #{e}")
        end

        raw_lists = root_node.map{|record| List.from_list_node(record)}.flatten

        return raw_spaces
      end

      def self.from_list_node(data)
        list = List.new
        list.remoteid = data["id"]
        list.name = data["name"] || 'Unknown'
        return list
      end
    end
  end
end
