require 'clockwork'
require './config/boot'
require './config/environment'
require 'active_support/time' # Allow numeric durations (eg: 1.minutes)

module Clockwork
  handler do |job, time|
    puts "Running #{job}, at #{time}"
  end

  every(15.seconds, 'invoices.analyze') { Invoice.analyze_submitted }

  every(1.minute, 'invoices.process') { InvoiceProcessingService.new.process_completion_queue }
  every(1.minute, 'tasks.sync') { ProjectTaskServices::Sync.new.pull_project_task_states }
end
