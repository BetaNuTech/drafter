module Clickup
  module Data
    class Space
      require 'nokogiri'

      attr_accessor :remoteid, :name

      def self.from_Spaces(data)
        self.from_api_response(response: data, method: 'Spaces')
      end

      def self.from_api_response(response:, method:)
        root_node = nil

        case response
        when String
          begin
            data = JSON(response)
          rescue => e
            raise Clickup::Data::Error.new("Invalid Space JSON: #{e}")
          end
        when Hash
          data = response
        else
          raise Clickup::Data::Error.new("Invalid Space data. Should be JSON string or Hash")
        end

        begin
          # Handle Error
          if data["err"].present?
            err_msg = data["err"].to_s
            raise Clickup::Data::Error.new(err_msg)
          end

          # Extract Spaces Data
          root_node = data["spaces"]

        rescue => e
          raise Clickup::Data::Error.new("Invalid Spaces data schema: #{e}")
        end

        raw_spaces = root_node.map{|record| Space.from_space_node(record)}.flatten

        return raw_spaces
      end

      def self.from_space_node(data)
        space = Space.new
        space.remoteid = data["id"]
        space.name = data["name"] || 'Unknown'
        return space
      end
    end
  end
end
