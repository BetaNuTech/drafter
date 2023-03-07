module Draws
  module Reporting
    extend ActiveSupport::Concern

    included do

      def regenerate_subsequent_draw_reports
        visible_states = %i{internally_approved externally_approved funded}
        subsequent_draws = project.draws.where(index: self.index.., state: visible_states)
        subsequent_draws.each(&:generate_reports)
      end

      def generate_document_packet
        ::Reporting::DrawPacketGenerator.new(draw: self).
          delay(queue: :low_priority).
          call
      end

      def generate_draw_summary_sheet
        ::Reporting::DrawSummaryGenerator.new(draw: self).
          delay(queue: :low_priority).
          call
      end

      def generate_reports
        generate_draw_summary_sheet
      end

      def cleanup_reports
        remove_draw_summary_sheet
        remove_document_packet
      end

      def remove_document_packet
        document_packet.purge_later
      end

      def remove_draw_summary_sheet
        draw_summary_sheet.purge_later
      end
    end

  end
end
