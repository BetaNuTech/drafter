module Draws
  module DrawDocuments
    extend ActiveSupport::Concern

    included do
      has_many :draw_documents, dependent: :destroy

      def all_documents_submitted?
        required_documents.count == DrawDocument::REQUIRED_DOCUMENTTYPES.count
      end

      def remaining_documents
        ( ['other'] + ( DrawDocument.documenttypes.keys.map(&:to_s) - draw_documents.pluck(:documenttype) ) ).uniq
      end

      def required_documents
        draw_documents.where(documenttype: DrawDocument::REQUIRED_DOCUMENTTYPES)
      end
    end
  end
end
