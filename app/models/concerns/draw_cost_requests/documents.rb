module DrawCostRequests
  module Documents
    extend ActiveSupport::Concern

    included do
      has_many_attached :documents
    end
  end
end
