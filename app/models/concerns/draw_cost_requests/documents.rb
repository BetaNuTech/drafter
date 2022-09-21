module DrawCostRequests
  module Documents
    extend ActiveSupport::Concern

    included do
      has_many :draw_cost_documents, dependent: :destroy

      REQUIRED_DOCUMENTS = [:budget, :application, :waiver].freeze

      def document_attached?(doctype)
        return false unless REQUIRED_DOCUMENTS.include?(doctype.to_sym)

        draw_cost_documents.public_send(doctype).any?
      end

      def all_documents_attached?
        REQUIRED_DOCUMENTS.all? do |doctype|
          document_attached?(doctype)
        end
      end

      def documents_pending_approval
        draw_cost_documents.where(approved_at: nil)
      end
    end
  end
end
