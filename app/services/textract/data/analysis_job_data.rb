module Textract
  module Data
    class AnalysisJobData
      require 'json'

      PROPERTIES = %i{is_total_present total page_number bounding_box confidence job_id}.freeze
      CONFIDENCE_MIN = 95.0
      TYPE_KEY = "TOTAL"

      attr_accessor *PROPERTIES

      def self.from_hash(hash: {})
        self.process_data(data: hash, data_type: :hash)
      end

      def self.from_api(response:, job_id:, expected_total: nil)
        case expected_total
        when String
          expected_total_f = expected_total.tr('^0-9.', '').to_f
        when Numeric
          expected_total_f = expected_total.to_f
        else  
          expected_total_f = 0.0
        end
        self.process_data(data: response, data_type: :api, job_id: job_id, expected_total: expected_total_f)
      end

      def self.process_data(data:, data_type:, job_id:, expected_total:)
        case data_type
        when :hash
          self.set_properties_from_hash(data: data)
        when :api
          self.process_api_response(response: data, job_id: job_id, expected_total: expected_total)
        else  
          analysis_job_data = AnalysisJobData.new
          analysis_job_data.is_total_present = false
          analysis_job_data.job_id = job_id
          return analysis_job_data
        end
      end

      def self.set_properties_from_hash(data:)
        analysis_job_data = AnalysisJobData.new
        analysis_job_data.is_total_present  = data.fetch(:is_total_present)
        analysis_job_data.total             = data.fetch(:total)
        analysis_job_data.page_number       = data.fetch(:page_number)
        analysis_job_data.bounding_box      = data.fetch(:bounding_box)
        analysis_job_data.confidence        = data.fetch(:confidence)
        analysis_job_data.job_id            = data.fetch(:job_id)

        return analysis_job_data
      end

      def self.process_api_response(response:, job_id:, expected_total:)
        case response
        when String
          begin
            data = JSON.parse(response).symbolize_keys
          rescue => e
            raise Textract::Data::Error.new("Invalid API Response Data: #{e}")
          end
        when Hash
          data = response.symbolize_keys
        else
          if response.respond_to?(:to_h)
            data = response.to_h.symbolize_keys
          else
            raise Textract::Data::Error.new("Unknown API Response Data Type")
          end
        end

        return self.process_json_data(data: data, job_id: job_id, expected_total: expected_total)
      end

      def self.process_json_data(data:, job_id:, expected_total:)
        # Pull out all TOTAL Types which that meet minimum Type, Label, AND Value Confidence Scores
        total_fields = []
        documents = data[:expense_documents]
        if documents.present? && documents.kind_of?(Array)
          documents.each do |doc|
            summary_fields = doc[:summary_fields]
            if summary_fields.present? && summary_fields.kind_of?(Array)
              summary_fields.each do |field|
                type = field.dig(:type, :text) || ""
                type_confidence = (field.dig(:type, :confidence) || 0.0).to_f
                label_confidence = (field.dig(:label_detection, :confidence) || 0.0).to_f
                value_confidence = (field.dig(:value_detection, :confidence) || 0.0).to_f
                if type == TYPE_KEY && 
                  type_confidence >= CONFIDENCE_MIN && 
                  label_confidence >= CONFIDENCE_MIN && 
                  value_confidence >= CONFIDENCE_MIN
                  total_fields.append(field)
                end
              end
            end
          end
        end
 
        # Reverse Order (Last TOTAL, on last page, first)
        total_fields_reversed = total_fields.reverse

        # Find Best Match, using expected total AND without
        total_field_picked = nil
        total_field_picked_value = nil
        total_fields_reversed.each do |total_field|
          value_text = total_field.dig(:value_detection, :text) || ""
          if value_text.present?
            value = value_text.tr('^0-9.', '').to_f
            if value == expected_total
              total_field_picked = total_field
              total_field_picked_value = value
              break
            elsif total_field_picked.nil? 
              total_field_picked = total_field
              total_field_picked_value = value
            end
          end  
        end

        # Set Properties
        analysis_job_data = AnalysisJobData.new
        analysis_job_data.job_id = job_id
        if total_field_picked.present?
          analysis_job_data.total            = total_field_picked_value
          analysis_job_data.is_total_present = analysis_job_data.total.present?
          analysis_job_data.page_number      = total_field_picked[:page_number]
          bounding_box = total_field_picked.dig(:value_detection, :geometry, :bounding_box) || {}
          analysis_job_data.bounding_box     = bounding_box
          type_confidence = (total_field_picked.dig(:type, :confidence) || 0.0).to_f
          label_confidence = (total_field_picked.dig(:label_detection, :confidence) || 0.0).to_f
          value_confidence = (total_field_picked.dig(:value_detection, :confidence) || 0.0).to_f
          avg_confidence = (type_confidence + label_confidence + value_confidence) / 3.0
          analysis_job_data.confidence       = avg_confidence
        end

        return analysis_job_data
      end

      def to_h
        out = {}
        PROPERTIES.each do |prop|
          out[prop] = self.send(prop)
        end
        out
      end


    end
  end
end
