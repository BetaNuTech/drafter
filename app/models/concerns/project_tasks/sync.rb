module ProjectTasks
  module Sync
    extend ActiveSupport::Concern

    included do
      def create_remote_task
        return true if has_remote_task?

        ProjectTaskServices::Sync.new.
          create_task(self, new_remote_task_disposition)
        self.remote_updated_at = Time.current
        self.remote_last_checked_at = Time.current
        save
      end

      def approve_remote_task
        ProjectTaskServices::Sync.new.
          approve_task(self)
        self..remote_updated_at = Time.current
        self..remote_last_checked_at = Time.current
        save
      end

      def reject_remote_task
        ProjectTaskServices::Sync.new.
          reject_task(self)
        self.remote_updated_at = Time.current
        self.remote_last_checked_at = Time.current
        save
      end

      def archive_remote_task
        ProjectTaskServices::Sync.new.
          archive_task(self)
        self.remote_updated_at = Time.current
        self.remote_last_checked_at = Time.current
        save
      end

      def update_remote_task_status
        ProjectTaskServices::Sync.new.
          push_project_task_state(self)
        self.remote_updated_at = Time.current
        self.remote_last_checked_at = Time.current
        save
      end

      def new_remote_task_disposition
        case state.to_sym
        when :needs_consult
          :consult
        else
          :review
        end
      end

      def has_remote_task?
        remoteid.present?
      end
    end

  end
end
