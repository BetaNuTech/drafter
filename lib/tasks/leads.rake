namespace :leads do

  namespace :yardi do

    desc "Import GuestCards"
    task :import_guestcards => :environment do

      properties = [
        {name: 'Maplebrook', code: 'maplebr'},
        {name: 'Marble Alley', code: 'marble'},
      ]

      properties.each do |property|
        msg = " * Importing Yardi Voyager GuestCards for #{property[:name]} [YARDI ID: #{property[:code]}] as Leads"
        puts msg
        Rails.logger.warn msg
        adapter = Leads::Adapters::YardiVoyager.new({ property_code: property[:code] })
        leads = adapter.parse

        count = leads.size
        succeeded = leads.select{|l| l.id.present? }.size
        failures = leads.select{|l| !l.errors.empty?}.map do |record|
          "FAIL: #{record.name} [Yardi ID: #{record.remoteid}]: #{record.errors.to_a.join(', ')}"
        end

        msg=<<~EOS
          - Processed #{leads.size} Records
          - #{succeeded} Records saved
          - #{failures.size} Failed
        EOS
        msg += failures.join("\n")
        puts msg
        Rails.logger.warn msg
      end
    end
  end
end