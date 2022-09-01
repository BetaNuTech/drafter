# == Schema Information
#
# Table name: draw_cost_documents
#
#  id                   :uuid             not null, primary key
#  approval_due_date    :date
#  approved_at          :datetime
#  documenttype         :integer          default("other"), not null
#  notes                :text
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  approver_id          :uuid
#  draw_cost_request_id :uuid             not null
#  user_id              :uuid
#
# Indexes
#
#  index_draw_cost_documents_on_approver_id           (approver_id)
#  index_draw_cost_documents_on_draw_cost_request_id  (draw_cost_request_id)
#  index_draw_cost_documents_on_user_id               (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (approver_id => users.id)
#  fk_rails_...  (draw_cost_request_id => draw_cost_requests.id)
#  fk_rails_...  (user_id => users.id)
#
FactoryBot.define do
  factory :draw_cost_document do
    user { nil }
    draw_cost_request { create(:draw_cost_request) }
    notes { Faker::Lorem.paragraph(sentences: 2) }
    documenttype { 1 }
    approval_due_date { Date.current + rand(15).days }
    approved_at { nil}
    approver { nil }
  end
end
