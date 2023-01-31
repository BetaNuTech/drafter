module Clickup
  module Api
    class Tasks < Base

      ARCHIVED_STATUS = 'archived'
      APPROVED_STATUS = 'approved'
      REJECTED_STATUS = 'rejected'

      def getTasks(list_id:)
        request_options = {
          resource: "list/#{list_id}/task",
          parameters: ["archived=false"]
        }
        begin
          response = getData(request_options)
          tasks = Clickup::Data::Task.from_Tasks(response.parsed_response)
        rescue => e
          msg = "#{format_request_id} Clickup::Api::Tasks encountered an error fetching data. #{e}"
          Rails.logger.error msg
          return []
        end
        return tasks
      end

      def getTask(task_id:)
        request_options = {
          resource: "task/#{task_id}",
          parameters: []
        }
        begin
          response = getData(request_options)
          task = Clickup::Data::Task.from_Task(response.parsed_response)
        rescue => e
          msg = "#{format_request_id} Clickup::Api::Tasks encountered an error fetching data. #{e}"
          Rails.logger.error msg
          return nil
        end
        return task
      end

      def createTask(list_id:, name:, status:, description: nil, assignees: nil, tags: nil, priority: nil, 
        due_date: nil, due_date_time: false, time_estimate: nil, start_date: nil, start_date_time: false, 
        notify_all: false, parent: nil, links_to: nil, check_required_custom_fields: false, custom_fields: nil)
        data = {
          "name" => name,
          "status" => status,
          "markdown_description" => description,
          "assignees" => assignees,
          "tags" => tags,
          "priority" => priority,
          "due_date" => due_date,
          "due_date_time" => due_date_time,
          "time_estimate" => time_estimate,
          "start_date" => start_date,
          "start_date_time" => start_date_time,
          "notify_all" => notify_all,
          "parent" => parent,
          "links_to" => links_to,
          "check_required_custom_fields" => check_required_custom_fields,
          "custom_fields" => custom_fields
        }
        request_options = {
          resource: "list/#{list_id}/task",
          parameters: [],
          body: data
        }
        begin
          response = postData(request_options)
          task = Clickup::Data::Task.from_CreateTask(response.parsed_response)
        rescue => e
          msg = "#{format_request_id} Clickup::Api::Tasks encountered an error fetching data. #{e}"
          Rails.logger.error msg
          return nil
        end
        return task
      end

      def updateTask(task:, archived: false, start_date_time: false, due_date_time: false, status: nil)
        data = {
          "name" => task.name,
          "status" => ( status || task.status ),
          "markdown_description" => task.description,
          "tags" => task.tags,
          "assignees" => task.assignees,
          "priority" => task.priority,
          "due_date" => task.due_date,
          "due_date_time" => due_date_time,
          "time_estimate" => task.time_estimate,
          "start_date" => task.start_date,
          "start_date_time" => start_date_time,
          "parent" => task.parent,
        }
        request_options = {
          resource: "task/#{task.remoteid}",
          parameters: [],
          body: data
        }
        begin
          response = putData(request_options)
          task = Clickup::Data::Task.from_UpdateTask(response.parsed_response)
        rescue => e
          msg = "#{format_request_id} Clickup::Api::Tasks encountered an error fetching data. #{e}"
          Rails.logger.error msg
          return nil
        end
        return task
      end

      def updateTaskStatus(task:, status:)
        data = {
          "name" => task.name,
          # OMIT description so that it not overwritten
          "tags" => task.tags,
          "status" => ( status || task.status ),
          "assignees" => task.assignees,
          "priority" => task.priority,
          "due_date" => task.due_date,
          "time_estimate" => task.time_estimate,
          "start_date" => task.start_date,
          "parent" => task.parent
        }
        request_options = {
          resource: "task/#{task.remoteid}",
          parameters: [],
          body: data
        }
        begin
          response = putData(request_options)
          task = Clickup::Data::Task.from_UpdateTask(response.parsed_response)
        rescue => e
          msg = "#{format_request_id} Clickup::Api::Tasks encountered an error fetching data. #{e}"
          Rails.logger.error msg
          return nil
        end
        return task
      end

      def archiveTask(task_id:)
        task = getTask(task_id:)
        return true if ARCHIVED_STATUS == task.status

        updateTaskStatus(task:, status: ARCHIVED_STATUS)
      end

      def approveTask(task_id:)
        task = getTask(task_id:)
        return true if APPROVED_STATUS == task.status

        updateTaskStatus(task:, status: APPROVED_STATUS)
      end

      def rejectTask(task_id:)
        task = getTask(task_id:)
        return true if REJECTED_STATUS == task.status

        updateTaskStatus(task:, status: REJECTED_STATUS)
      end

      def deleteTask(task_id:)
        request_options = {
          resource: "task/#{task_id}",
          parameters: [],
        }
        begin
          response = deleteData(request_options)
          Clickup::Data::Task.from_DeleteTask(response.parsed_response)
        rescue => e
          msg = "#{format_request_id} Clickup::Api::Tasks encountered an error fetching data. #{e}"
          Rails.logger.error msg
          return nil
        end
        return nil
      end

    end
  end
end
