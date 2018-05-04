namespace :db do

  namespace :seed do

    desc "Seed Property Data"
    task :properties => :environment do
      require_relative Rails.root + "db/seeds/seed_properties"

      SeedProperties.new.call
    end

    desc "Seed LeadActions"
    task :lead_actions => :environment do
      LeadAction.load_seed_data
    end

    desc "Seed Reasons"
    task :reasons => :environment do
      Reason.load_seed_data
    end

    desc "Seed Development Environment with random data"
    task :development => :environment do
      require 'factory_bot_rails'

      puts "=== Seeding Development Environment"

      puts "(press ENTER to continue or CTRL-C to quit)"
      _c = STDIN.gets

      #lead_source_count = 5
      #puts "= Creating #{lead_source_count} Lead Sources"
      #lead_source_count.times {
      #source = FactoryBot.create(:lead_source)
      #puts "  - #{source.name}"
      #}

      #property_count = 10
      #puts "= Creating #{property_count} Properties"
      #property_count.times {
      #property = FactoryBot.create(:property)
      #puts "  - #{property.name}"
      #}

      agent_count = 10
      puts "= Creating #{agent_count} Agents"
      agent_count.times {
        user = FactoryBot.create(:user, role: Role.agent)
        puts "  - #{user.name}"
        rand(4).times {
          property = Property.order("RANDOM()").first
          PropertyAgent.create(user: user, property: property)
          puts "    * Agent for #{property.name}"
        }
      }

      lead_count = 200
      puts "= Creating #{lead_count } Leads"
      lead_count.times {
        property = Property.order("RANDOM()").first
        lead_source = LeadSource.order("RANDOM()").first
        lead = FactoryBot.create(:lead, property: Property.order("RANDOM()").first, source: lead_source)
        puts "  - #{lead.name}: interested in the property #{property.name}"
        if (Faker::Boolean.boolean(0.2))
          agent = PropertyAgent.order("RANDOM()").first.user
          lead.user = agent
          lead.claim if lead.open?
          puts "    + Claimed by #{agent.name}"
        end
      }

    end

    desc "Load EngagementPolicy"
    task :engagement_policy => :environment do
      filename = File.join(Rails.root,"db","seeds", "engagement_policy.yml")

      puts "*** Loading EngagementPolicy from #{filename}"
      loader = EngagementPolicyLoader.new(filename)
      loader.call
    end

    desc "Load Message Types"
    task :message_types => :environment do
      MessageType.load_seed_data
    end

  end # namespace :seed

end # namespace :db
