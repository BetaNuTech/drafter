module Clickup
  module Data
    class Task
      require 'nokogiri'

      attr_accessor :remoteid, :name, :description, :status, :date_created, :date_updated, 
        :date_closed, :due_date, :assignees, :priority, :parent, :start_date, :time_estimate, :url


      def self.from_Tasks(data)
        self.from_api_response(response: data, method: 'Tasks')
      end

      def self.from_Task(data)
        self.from_api_response(response: data, method: 'Task')
      end

      def self.from_CreateTask(data)
        self.from_api_response(response: data, method: 'CreateTask')
      end

      def self.from_UpdateTask(data)
        self.from_api_response(response: data, method: 'UpdateTask')
      end

      def self.from_DeleteTask(data)
        self.from_api_response(response: data, method: 'DeleteTask')
      end

      def self.from_api_response(response:, method:)
        root_node = nil

        case response
        when String
          begin
            data = JSON(response)
          rescue => e
            raise Clickup::Data::Error.new("Invalid Task JSON: #{e}")
          end
        when Hash
          data = response
        else
          case method
          when 'DeleteTask'
            data = '{}'
          else 
            raise Clickup::Data::Error.new("Invalid Task data. Should be JSON string or Hash")
          end
        end

        begin
          # Handle Error
          if data["err"].present?
            err_msg = data["err"].to_s
            raise Clickup::Data::Error.new(err_msg)
          end

          case method
          when 'Tasks'
            root_node = data["tasks"]
          when 'Task'
            root_node = data
          when 'CreateTask'
            root_node = data
          when 'UpdateTask'
            root_node = data
          when 'DeleteTask'
            root_node = data
          else 
            root_node = data
          end
  
        rescue => e
          raise Clickup::Data::Error.new("Invalid Tasks data schema: #{e}")
        end

        case method
        when 'Tasks'
          raw_tasks = root_node.map{|record| Task.from_task_node(record)}.flatten
          return raw_tasks
        when 'Task'
          raw_task = Task.from_task_node(root_node)
          return raw_task
        when 'CreateTask'
          raw_task = Task.from_task_node(root_node)
          return raw_task
        when 'UpdateTask'
          raw_task = Task.from_task_node(root_node)
          return raw_task
        when 'DeleteTask'
          return root_node
        else 
          raw_task = Task.from_task_node(root_node)
          return raw_task
        end

      end

      def self.from_task_node(data)
        task = Task.new
        task.remoteid = data["id"]
        task.name = data["name"]
        task.description = data["description"]
        task.status = data["status"]["status"]
        task.date_created = data["date_created"]
        task.date_updated = data["date_updated"]
        task.date_closed = data["date_closed"]
        task.due_date = data["due_date"]
        task.assignees = data["assignees"]
        task.priority = data["priority"]
        task.parent = data["parent"]
        task.start_date = data["start_date"]
        task.time_estimate = data["time_estimate"]
        task.url = data["url"]
        return task
      end
    end
  end
end
