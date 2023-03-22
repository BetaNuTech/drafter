module HealthCheck
  class CheckJob
    class << self
      def call
        errors = []
        const_get('SUBTASKS').each do |task_function|
          errors << public_send(task_function)
        end

        errors.reject!{ |e| e.blank? || e == :ok }
        err_string = errors.map{|e| e[1]}.join('; ')

        return err_string
      end
    end
  end
end
