module Draws
  module DrawDocuments
    extend ActiveSupport::Concern

    included do
      has_many :draw_documents, dependent: :destroy

      def all_documents_submitted?
        match_states = %i{pending approved}
        submitted_types = draw_documents.where(state: match_states).
                            pluck(:documenttype).
                            uniq.map(&:to_sym)
        ( DrawDocument::REQUIRED_DOCUMENTTYPES.sort - [:other] ) == ( submitted_types.sort - [:other] )
      end

      def all_required_documents_approved?
        all_documents_submitted? &&
          required_documents.all?{|d| d.approved?}
      end

      def remaining_documents
        ( ['other'] + ( DrawDocument.documenttypes.keys.map(&:to_s) - required_documents.pluck(:documenttype) ) ).uniq
      end

      def required_documents
        draw_documents.visible.where(documenttype: DrawDocument::REQUIRED_DOCUMENTTYPES)
      end
    end
  end
end
