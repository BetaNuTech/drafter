module DrawCostRequests
  module Documents
    extend ActiveSupport::Concern

    included do
      has_many :draw_cost_documents, dependent: :destroy

      REQUIRED_DOCUMENTS = [:budget, :application, :waiver]

      def all_documents_attached?
        # TODO
      end

      def documents_pending_approval
        # TODO
      end
    end
  end
end
