module HealthCheck
  class DelayedJob < HealthCheck::CheckJob
    SUBTASKS = %i{check_queue_size}
    CANDENCE = 3600 # seconds
    QUEUE_SIZE_THRESHOLD = 1000

    class << self
      def check_queue_size
        if ( ( count = ::Delayed::Job.count ) > QUEUE_SIZE_THRESHOLD )
          [:err, "DelayedJob queue is large (#{count} > #{QUEUE_SIZE_THRESHOLD})"]
        else
          [:ok, '']
        end
      end
    end
  end
end
