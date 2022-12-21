namespace :invoices do

  desc "Analyze Documents"
  task :analyze_documents => :environment do
    service = InvoiceProcessingService.new

    submitted_invoices = Invoice.submitted.count
    unless submitted_invoices.zero?
      puts "*** Starting Analysis of Submitted Invoice Documents (#{submitted_invoices} found)..."
      Invoice.analyze_submitted
    else
      puts "*** No submitted Invoices found for analysis."
    end

    puts "*** Processing Completion Queue"
    service.process_completion_queue
  end
end
