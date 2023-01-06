# == Schema Information
#
# Table name: draw_documents
#
#  id                :uuid             not null, primary key
#  approval_due_date :date
#  approved_at       :datetime
#  documenttype      :integer          default("other"), not null
#  notes             :text
#  state             :string           default("pending")
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  approver_id       :uuid
#  draw_id           :uuid             not null
#  user_id           :uuid
#
# Indexes
#
#  draw_documents_assoc_idx              (draw_id,user_id)
#  index_draw_documents_on_approver_id   (approver_id)
#  index_draw_documents_on_documenttype  (documenttype)
#  index_draw_documents_on_draw_id       (draw_id)
#  index_draw_documents_on_state         (state)
#  index_draw_documents_on_user_id       (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (approver_id => users.id)
#  fk_rails_...  (draw_id => draws.id)
#  fk_rails_...  (user_id => users.id)
#
FactoryBot.define do
  factory :draw_document do
    user { nil }
    draw { create(:draw) }
    notes { Faker::Lorem.paragraph(sentence_count: 2) }
    documenttype { 1 }
    approval_due_date { Date.current + rand(15).days }
    approved_at { nil}
    approver { nil }
  end
end
