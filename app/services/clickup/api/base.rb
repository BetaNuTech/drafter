module Clickup
  module Api
    class Base
      require 'json'
      include HTTParty
      attr_reader :configuration
      attr_accessor :debug

      # Initialize with an optional Clickup::Configuration instance
      def initialize(conf=nil)
        @debug = false
        @configuration = conf || Clickup::Api::Configuration.new(:credentials)
        @request_id = nil
      end

      def request_headers(content_length:)
        {
          'Content-Type' => 'application/json; charset=utf-8',
          'Content-Length' => content_length.to_s,
          'Authorization' => @configuration.api_token
        }
      end

      def getData(options, dry_run: false)
        url = "%{api_root}/%{resource}" % {api_root: api_root, resource: options[:resource]}
        parameters = options[:parameters]
        if parameters.present? && parameters.count > 0
          url = add_uri_parameters(url, parameters)
        end
        if options[:body].present?
          body = options[:body].to_json
        else 
          body = "" 
        end
        headers = request_headers(content_length: body.length)

        if @debug
          msg = " * Request URL:\n" + url
          puts msg
          Rails.logger.debug msg
          msg =  " * Request Headers:\n" + headers.to_a.map{|h| "#{h[0]}: #{h[1]}"}.join("\n")
          puts msg
          Rails.logger.debug msg
          msg = " * Request Body:\n" + body
          puts msg
          Rails.logger.debug msg
        end
        if dry_run
          result = 'Dry Run: no request sent'
        else
          result = fetch_data(url: url, body: body, headers: headers)
        end
        if @debug
          msg = " * Response:\n" + result.to_s
          puts msg
          Rails.logger.debug msg
        end
        return result
      end

      def postData(options, dry_run: false)
        url = "%{api_root}/%{resource}" % {api_root: api_root, resource: options[:resource]}
        parameters = options[:parameters]
        if parameters.present? && parameters.count > 0
          url = add_uri_parameters(url, parameters)
        end
        if options[:body].present?
          body = options[:body].to_json
        else 
          body = "" 
        end
        headers = request_headers(content_length: body.length)

        if @debug
          msg = " * Request URL:\n" + url
          puts msg
          Rails.logger.debug msg
          msg =  " * Request Headers:\n" + headers.to_a.map{|h| "#{h[0]}: #{h[1]}"}.join("\n")
          puts msg
          Rails.logger.debug msg
          msg = " * Request Body:\n" + body
          puts msg
          Rails.logger.debug msg
        end
        if dry_run
          result = 'Dry Run: no request sent'
        else
          result = post_data(url: url, body: body, headers: headers)
        end
        if @debug
          msg = " * Response:\n" + result.to_s
          puts msg
          Rails.logger.debug msg
        end
        return result
      end

      def putData(options, dry_run: false)
        url = "%{api_root}/%{resource}" % {api_root: api_root, resource: options[:resource]}
        parameters = options[:parameters]
        if parameters.present? && parameters.count > 0
          url = add_uri_parameters(url, parameters)
        end
        if options[:body].present?
          body = options[:body].to_json
        else 
          body = "" 
        end
        headers = request_headers(content_length: body.length)

        if @debug
          msg = " * Request URL:\n" + url
          puts msg
          Rails.logger.debug msg
          msg =  " * Request Headers:\n" + headers.to_a.map{|h| "#{h[0]}: #{h[1]}"}.join("\n")
          puts msg
          Rails.logger.debug msg
          msg = " * Request Body:\n" + body
          puts msg
          Rails.logger.debug msg
        end
        if dry_run
          result = 'Dry Run: no request sent'
        else
          result = put_data(url: url, body: body, headers: headers)
        end
        if @debug
          msg = " * Response:\n" + result.to_s
          puts msg
          Rails.logger.debug msg
        end
        return result
      end

      def deleteData(options, dry_run: false)
        url = "%{api_root}/%{resource}" % {api_root: api_root, resource: options[:resource]}
        parameters = options[:parameters]
        if parameters.present? && parameters.count > 0
          url = add_uri_parameters(url, parameters)
        end
        if options[:body].present?
          body = options[:body].to_json
        else 
          body = "" 
        end
        headers = request_headers(content_length: body.length)

        if @debug
          msg = " * Request URL:\n" + url
          puts msg
          Rails.logger.debug msg
          msg =  " * Request Headers:\n" + headers.to_a.map{|h| "#{h[0]}: #{h[1]}"}.join("\n")
          puts msg
          Rails.logger.debug msg
          msg = " * Request Body:\n" + body
          puts msg
          Rails.logger.debug msg
        end
        if dry_run
          result = 'Dry Run: no request sent'
        else
          result = delete_data(url: url, body: body, headers: headers)
        end
        if @debug
          msg = " * Response:\n" + result.to_s
          puts msg
          Rails.logger.debug msg
        end
        return result
      end

      def fetch_data(url:, body:, headers: {}, options: {})
        @request_id = Digest::SHA1.hexdigest(rand(Time.now.to_i).to_s)[0..11]
        data = nil
        retries = 0
        begin
          start_time = Time.now
          Rails.logger.warn "Clickup::Api Requesting Data at #{url}, #{format_request_id}"
          data = HTTParty.get(url, body: body, headers: headers)
          elapsed = ( Time.now - start_time ).round(2)
          Rails.logger.warn "Clickup::Api Completed request in #{elapsed}s #{format_request_id} "
        rescue Net::ReadTimeout => e
          if retries < 3
            retries += 1
            msg = "Clickup::Api encountered a timeout fetching data from #{url}. Retry #{retries} of 3 #{format_request_id}"
            Rails.logger.error msg
            sleep(5)
            retry
          else
            msg = "Clickup::Api giving up fetching data from #{url} #{format_request_id}"
            Rails.logger.error msg
            raise e
          end
        end
        return data
      end

      def post_data(url:, body:, headers: {}, options: {})
        @request_id = Digest::SHA1.hexdigest(rand(Time.now.to_i).to_s)[0..11]
        data = nil
        retries = 0
        begin
          start_time = Time.now
          Rails.logger.warn "Clickup::Api Sending Data at #{url}, #{format_request_id}"
          data = HTTParty.post(url, body: body, headers: headers)
          elapsed = ( Time.now - start_time ).round(2)
          Rails.logger.warn "Clickup::Api Completed request in #{elapsed}s #{format_request_id} "
        rescue Net::ReadTimeout => e
          if retries < 3
            retries += 1
            msg = "Clickup::Api encountered a timeout sending data to #{url}. Retry #{retries} of 3 #{format_request_id}"
            Rails.logger.error msg
            sleep(5)
            retry
          else
            msg = "Clickup::Api giving up sending data to #{url} #{format_request_id}"
            Rails.logger.error msg
            raise e
          end
        end
        return data
      end

      def put_data(url:, body:, headers: {}, options: {})
        @request_id = Digest::SHA1.hexdigest(rand(Time.now.to_i).to_s)[0..11]
        data = nil
        retries = 0
        begin
          start_time = Time.now
          Rails.logger.warn "Clickup::Api Sending Data at #{url}, #{format_request_id}"
          data = HTTParty.put(url, body: body, headers: headers)
          elapsed = ( Time.now - start_time ).round(2)
          Rails.logger.warn "Clickup::Api Completed request in #{elapsed}s #{format_request_id} "
        rescue Net::ReadTimeout => e
          if retries < 3
            retries += 1
            msg = "Clickup::Api encountered a timeout sending data to #{url}. Retry #{retries} of 3 #{format_request_id}"
            Rails.logger.error msg
            sleep(5)
            retry
          else
            msg = "Clickup::Api giving up sending data to #{url} #{format_request_id}"
            Rails.logger.error msg
            raise e
          end
        end
        return data
      end

      def delete_data(url:, body:, headers: {}, options: {})
        @request_id = Digest::SHA1.hexdigest(rand(Time.now.to_i).to_s)[0..11]
        data = nil
        retries = 0
        begin
          start_time = Time.now
          Rails.logger.warn "Clickup::Api Deleting Data at #{url}, #{format_request_id}"
          data = HTTParty.delete(url, body: body, headers: headers)
          elapsed = ( Time.now - start_time ).round(2)
          Rails.logger.warn "Clickup::Api Completed request in #{elapsed}s #{format_request_id} "
        rescue Net::ReadTimeout => e
          if retries < 3
            retries += 1
            msg = "Clickup::Api encountered a timeout sending data to #{url}. Retry #{retries} of 3 #{format_request_id}"
            Rails.logger.error msg
            sleep(5)
            retry
          else
            msg = "Clickup::Api giving up sending data to #{url} #{format_request_id}"
            Rails.logger.error msg
            raise e
          end
        end
        return data
      end

      def config
        return @configuration.to_h
      end

      def api_root
        return "https://api.clickup.com/api/v2"
      end

      def format_request_id
        return "[Request ID: #{@request_id}]"
      end

      def add_uri_parameters(url, parameters)
        url += '?'
        parameters.each_with_index do |parameter, index|
          url += parameter
          if index < parameters.count - 1
            url += '&'
          end
        end
        return url
      end

    end
  end
end
