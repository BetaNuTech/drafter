module ProjectTaskServices
  class Sync
    class Error < StandardError; end

    ADAPTER_INTERFACE_METHODS = %i{get_task create_task approve_task reject_task archive_task push_task_status}.freeze
    DEFAULT_ADAPTER = ProjectTaskServices::SyncAdapters::Clickup
    PROJECT_TASK_STATES_FOR_REFRESH = %i{new needs_review needs_consult}.freeze
    REFRESH_WINDOW = 30 # seconds

    delegate *ADAPTER_INTERFACE_METHODS, to: :@adapter

    def initialize(adapter: DEFAULT_ADAPTER)
      @adapter = adapter.new
      validate_adapter_interface
    end

    # Create remote tasks for unsynced Drafter ProjectTasks
    def push_project_tasks
      remote_tasks = []
      pending_project_tasks.where(remoteid: nil).each do |project_task|
        remote_tasks << create_task(project_task, project_task.new_remote_task_disposition)
      end

      remote_tasks
    end

    def push_project_task_state(project_task)
      return false unless project_task.has_remote_task?

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
                        project_tasks_for_refresh
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
        pull_project_task_state(task)
      end

      project_tasks.compact
    end

    def pull_project_task_state(project_task, remote_task: nil, remote_task_status: nil)
      return nil unless project_task.has_remote_task?

      unless remote_task_status.present?
        remote_task ||= get_task(project_task) 

        unless remote_task.present?
          description = "ProjectTaskServices::Sync could not fetch ClickUp Task[#{project_task.remoteid}] for status update"
          SystemEvent.log(event_source: project_task, description: , severity: :error)
          return nil
        end

        remote_task_status = remote_task.status
        project_task.remote_last_checked_at = Time.current
      end

      project_task.remote_updated_at = remote_task.date_updated.present? ? remote_task.date_updated : Time.current
      project_task.save

      ProjectTaskService.new(project_task).update_status(remote_task_status)

      project_task
    rescue => e
      description = 'Error in ProjectTaskServices::Sync processing remote task status'
      SystemEvent.log(event_source: project_task, description:, debug: e.to_s, severity: :fatal)
      return nil
    end

    private

    def project_tasks_for_refresh
      ProjectTask.where(state: PROJECT_TASK_STATES_FOR_REFRESH).
        or(ProjectTask.where(remote_last_checked_at: nil))
    end

    def validate_adapter_interface
      ADAPTER_INTERFACE_METHODS.each{|method|
        raise Error.new("ProjectTaskService service adapter #{@adapter.class} missing '#{method}' method") unless @adapter.respond_to?(method)
      }
    end

  end
end
