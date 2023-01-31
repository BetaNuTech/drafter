module ProjectTaskServices
  module SyncAdapters
    class Clickup
      class Error < StandardError; end

      attr_reader :workspace_id, :list_id

      REVIEW_TASK_STATUS = 'review'
      DEFAULT_TASK_STATUS = REVIEW_TASK_STATUS
      CONSULT_TAG = 'consult'
      TASK_STATUS_MAPPING = { approved: :approved,
                              rejected: :rejected,
                              archived: :archived,
                              needs_consult: :review,
                              needs_review: :review }.freeze # key = Local, value = Remote

      def initialize(workspace_id: nil, list_id: nil)
        @configuration = ::Clickup::Api::Configuration.new
        ( @workspace_id = workspace_id || get_workspace_id ) or raise Error.new('Invalid Workspace ID')
        ( @list_id = list_id || get_list_id ) or raise Error.new('Invalid List ID')
        @service = ::Clickup::Api::Tasks.new
      end

      def get_tasks
        @service.getTasks(list_id: @list_id)
      end

      def get_task(project_task_or_remote_id)
        task_id = project_task_or_remote_id.is_a?(ProjectTask) ?
          project_task_or_remote_id.remoteid : project_task_or_remote_id
        task_id.present? ? @service.getTask(task_id:) : nil
      end

      # options => { name: STRING, description: STRING, due_date: DateTime, status: OPTIONAL }
      def create_task(task_or_attributes, disposition: :default)
        project_task = nil

        if task_or_attributes.is_a?(ProjectTask)
          project_task = task_or_attributes
          attributes = {
            name: project_task.name,
            description: project_task.description,
            due_date: format_time(project_task.due_at)
          }
        else
          attributes = task_or_attributes
        end

        tags = case disposition.to_sym
                 when :default
                   nil
                 when :consult
                   [CONSULT_TAG]
                 else
                   nil
               end

        default_attributes = {
         list_id: @list_id,
         status: DEFAULT_TASK_STATUS,
         name: 'Unnamed Task',
         description: 'Unnamed Task Description',
         due_date: format_time(Time.current),
         start_date: format_time(Time.current),
         tags: tags
        }

        task_attributes = default_attributes.merge(attributes)

        clickup_task = ::Clickup::Api::Tasks.new.createTask(**task_attributes)

        if project_task.present? && clickup_task&.remoteid&.present?
          project_task.remoteid = clickup_task.remoteid 
          project_task.remote_updated_at = Time.current
          project_task.save
        end

        clickup_task
      end

      def approve_task(project_task_or_task_id)
        if project_task_or_task_id.is_a?(ProjectTask)
          task_id = project_task_or_task_id.remoteid
        else
          task_id = project_task_or_task_id
        end

        @service.approveTask(task_id:) if task_id.present?
      end

      def reject_task(project_task_or_task_id)
        if project_task_or_task_id.is_a?(ProjectTask)
          task_id = project_task_or_task_id.remoteid
        else
          task_id = project_task_or_task_id
        end

        @service.rejectTask(task_id:) if task_id.present?
      end

      def archive_task(project_task_or_task_id)
        if project_task_or_task_id.is_a?(ProjectTask)
          task_id = project_task_or_task_id.remoteid
        else
          task_id = project_task_or_task_id
        end

        @service.archiveTask(task_id:) if task_id.present?
      end

      def push_task_status(project_task_or_task_id)
        if project_task_or_task_id.is_a?(ProjectTask)
          project_task = project_task_or_task_id
          task_id = project_task.remoteid
          return false unless task_id.present?
        else
          task_id = project_task_or_task_id
          project_task = ProjectTask.where(remoteid: task_id).first
          return false unless project_task.present?
        end

        clickup_task = get_task(task_id)
        return false unless clickup_task.present?

        current_clickup_task_status = clickup_task.status
        new_clickup_task_status = TASK_STATUS_MAPPING.fetch(project_task.state.to_sym, DEFAULT_TASK_STATUS)
        return false if current_clickup_task_status == new_clickup_task_status

        clickup_task = @service.updateTaskStatus(task: clickup_task, status: new_clickup_task_status) 
        if clickup_task.status == new_clickup_task_status
          project_task.remote_updated_at = Time.current
          project_task.save
        else
          return false
        end

        clickup_task
      end

      private

      def get_workspace_id
        @configuration.workspace_id
      end

      def get_list_id
        @configuration.default_list_id
      end

      def format_time(time)
        ( time.to_f * 1000.0 ).to_i
      end

    end
  end
end
