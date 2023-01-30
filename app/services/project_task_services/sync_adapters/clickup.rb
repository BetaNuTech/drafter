module ProjectTaskServices
  module SyncAdapters
    class Clickup

      def initialize
      end

      def list_tasks
      end

      def list_workspaces
        service = Clickup::Api::Workspaces.new
        service.getWorkspaces
      end

      def get_task(id)
      end

      def create_task(options)
      end

      def archive_task(id)
      end
    end
  end
end
