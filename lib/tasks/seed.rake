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

      team_count = 5
      puts "= Creating #{team_count} Teams"
      team_count.times do
        team = FactoryBot.create(:team)
        puts " - #{team.name}"
        Property.all.each do |property|
          property.team = Team.order("RANDOM()").first
          property.save
        end
      end

      agent_count = 10
      puts "= Creating #{agent_count} Agents"
      agent_count.times {
        role = Role.where("slug != 'administrator'").order("RANDOM()").first
        user = FactoryBot.create(:user, role: role)
        team = Team.order("RANDOM()").first
        teamrole = Teamrole.order("RANDOM()").first
        puts "  - #{user.name} is a member of #{team.name}"
        TeamUser.create(user: user, team: team, teamrole: teamrole)
      }

      lead_count = 200
      puts "= Creating #{lead_count } Leads"
      lead_count.times {
        agent = TeamUser.order("RANDOM()").first.user
        property = agent.team.properties.order("RANDOM()").first
        lead_source = LeadSource.order("RANDOM()").first
        lead = FactoryBot.create(:lead, property: property, source: lead_source)
        puts "  - #{lead.name}: interested in the property #{property.name}"
        if (Faker::Boolean.boolean(0.2))
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

    desc "Load Message Templates"
    task :message_templates => :environment do
      MessageTemplate.load_seed_data
    end

    desc "Load Message Delivery Adapters"
    task :message_delivery_adapters => :environment do
      MessageDeliveryAdapter.load_seed_data
    end

  end # namespace :seed

end # namespace :db
