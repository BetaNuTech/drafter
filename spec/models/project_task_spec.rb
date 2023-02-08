# == Schema Information
#
# Table name: project_tasks
#
#  id                     :uuid             not null, primary key
#  approver_name          :string
#  assignee_name          :string
#  attachment_url         :string
#  completed_at           :datetime
#  description            :text             not null
#  due_at                 :datetime
#  name                   :string           not null
#  notes                  :text
#  origin_type            :string
#  preview_url            :string
#  remote_last_checked_at :datetime
#  remote_updated_at      :datetime
#  remoteid               :string
#  reviewed_at            :datetime
#  state                  :string           default("new"), not null
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  approver_id            :uuid
#  assignee_id            :uuid
#  origin_id              :uuid
#  project_id             :uuid             not null
#
# Indexes
#
#  idx_project_tasks_general           (project_id,assignee_id,approver_id,state)
#  idx_project_tasks_origin            (origin_type,origin_id)
#  idx_project_tasks_remote            (remoteid,remote_updated_at,remote_last_checked_at)
#  index_project_tasks_on_approver_id  (approver_id)
#  index_project_tasks_on_assignee_id  (assignee_id)
#  index_project_tasks_on_origin       (origin_type,origin_id)
#  index_project_tasks_on_project_id   (project_id)
#
# Foreign Keys
#
#  fk_rails_...  (approver_id => users.id)
#  fk_rails_...  (assignee_id => users.id)
#  fk_rails_...  (project_id => projects.id)
#
require 'rails_helper'

RSpec.describe ProjectTask, type: :model do
  include_context 'sample_draws'

  before(:each) {
    invoices
    sample_project.reload
  }

  let(:sample_project_task) {
    assignee = sample_project.developers.first
    build(:project_task,
            project: sample_project,
            origin: invoices.first,
            assignee: assignee,
            assignee_name: assignee.name
       )
  }

  describe 'initialization' do
    let(:object) { sample_project_task }
    it 'initializes a ProjectTask' do
      assert(object.save)
    end
  end # End initialization test

  describe 'validations' do
    let(:object) { sample_project_task }

    it 'validates the presence of name' do
      assert(object.valid?)
      object.name = nil
      refute(object.valid?)
    end

    it 'validates the presence of description' do
      assert(object.valid?)
      object.description = nil
      refute(object.valid?)
    end
  end # End validations test

end
