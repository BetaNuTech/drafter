class HealthCheck
  ### Check Job configuration
  CHECKS = [
    [HealthCheck::DelayedJob, true]
  ].freeze

  class << self
    def call
      errors = []

      enabled_checks.each do |check_config|
        next unless check_config[1]

        begin
          errors << check_config[0].call    
        rescue => e
          errors << [:err, "Error running HealthCheck::#{check_config[0].class.name}: #{e.backtrace}"]
        end
      end

      errors.reject!{ |e| e.blank? || e == :ok }
      err_string = errors.map{|e| e[1]}.join('; ')

      return err_string
    end
  end

  def enabled_checks
    CHECKS.select{|check| check[1] }
  end

end
