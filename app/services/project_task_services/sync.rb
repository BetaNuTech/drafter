module ProjectTaskServices
  class Sync
    class Error < StandardError; end

    ADAPTER_INTERFACE_METHODS = %i{get_task create_task approve_task reject_task archive_task push_task_status}.freeze
    DEFAULT_ADAPTER = ProjectTaskServices::SyncAdapters::Clickup
    PENDING_PROJECT_TASK_STATES = %i{new needs_review needs_consult}.freeze
    REFRESH_WINDOW = 30 # seconds

    delegate *ADAPTER_INTERFACE_METHODS, to: :@adapter

    def initialize(adapter: DEFAULT_ADAPTER)
      @adapter = adapter.new
      validate_adapter_interface
    end

    # Create remote tasks for unsynced Drafter ProjectTasks
    def push_project_tasks
      remote_tasks = []
      pending_project_tasks.where(remoteid: nil).each do |task|
        remote_tasks << create_task(task, task.new_remote_task_disposition)
      end

      remote_tasks
    end

    def push_project_task_state(project_task)
      return false unless project_task.remoteid.present?

      push_task_status(project_task)
      project_task
    end

    # Get and apply ClickUp task state to the provided collection of ProjectTasks (if stale)
    #  use 'force' to ignore remote_updated_at
    def pull_project_task_states(provided_project_tasks=nil, force: false)
      # Normalize the project_tasks into an ActiveRecord collection
      project_tasks = case provided_project_tasks
                      when ActiveRecord::Relation
                        provided_project_tasks
                      when Array
                        tasks = provided_project_tasks.compact
                        case tasks.first
                          when String
                            ProjectTask.where(id: tasks)
                          when ProjectTask
                            ProjectTask.where(id: tasks.map(&:id))
                          else
                            raise Error.new('Invalid project_tasks colleciton')
                        end
                      when nil
                        pending_project_tasks
                      else
                        raise Error.new('Invalid project_tasks collection')
                      end

      project_tasks = project_tasks.where.not(remoteid: nil)

      unless force
        # Default behavior is to select only ProjectTasks that have not been
        #  synced in the last REFRESH_WINDOW seconds
        project_tasks = project_tasks.where(remote_updated_at: nil).
          or(ProjectTask.where(ProjectTask.arel_table[:remote_updated_at].lt(REFRESH_WINDOW.seconds.ago)))
      end

      project_tasks = project_tasks.map do |task|
        pull_project_task_state(task) rescue nil
      end

      project_tasks.compact
    end

    def pull_project_task_state(project_task, remote_task: nil, remote_task_status: nil)
      remote_task = nil
      if project_task.remoteid.present?
        unless remote_task_status.present?
          remote_task ||= get_task(project_task) 
          remote_task_status = remote_task.status
        end
        service = ProjectTaskService.new(project_task) 
        service.update_status(remote_task_status)
      else
        remote_task = create_task(project_task, project_task.new_remote_task_disposition)
      end

      project_task.reload
      project_task.remote_updated_at = Time.current
      project_task.save

      project_task
    end

    private

    def pending_project_tasks
      ProjectTask.where(state: PENDING_PROJECT_TASK_STATES)
    end

    def validate_adapter_interface
      ADAPTER_INTERFACE_METHODS.each{|method|
        raise Error.new("ProjectTaskService service adapter #{@adapter.class} missing '#{method}' method") unless @adapter.respond_to?(method)
      }
    end

  end
end
