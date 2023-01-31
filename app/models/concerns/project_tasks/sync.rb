module ProjectTasks
  module Sync
    extend ActiveSupport::Concern

    included do
      def create_remote_task
        return true if remoteid.present?

        ProjectTaskServices::Sync.new.
          delay.create_task(self, disposition: new_remote_task_disposition)
      end

      def approve_remote_task
        ProjectTaskServices::Sync.new.
          delay.approve_task(self)
      end

      def reject_remote_task
        ProjectTaskServices::Sync.new.
          delay.reject_task(self)
      end

      def archive_remote_task
        ProjectTaskServices::Sync.new.
          delay.archive_task(self)
      end

      def update_remote_task_status
        ProjectTaskServices::Sync.new.
          delay.push_project_task_state(self)
      end

      def new_remote_task_disposition
        case state
        when 'needs_consult'
          :consult
        else
          :review
        end
      end
    end

  end
end
