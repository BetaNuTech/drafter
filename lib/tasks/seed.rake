namespace :db do
  namespace :seed do

    desc "Seed Roles"
    task :roles => :environment do
      Role.load_seed_data
    end
    
    desc "Seed Users"
    task :users => [:roles] do
      if User.count > 0
        puts " - Skipped user seeding. Accounts exist!"
        next
      end

        #### Admin Account
        email =  'admin@example.com'
        password = 'Password1.'
        print " - Create Admin account..."
        user = User.new(
          active: true,
          email: 'admin@example.com',
          role: Role.admin,
          password: password,
          password_confirmation: password,
          profile_attributes: {
            first_name: 'Admin',
            last_name: 'Admin'
          }
        )

        if user.save
          user.confirmed_at = Time.now
          user.save
          puts "OK (#{email} / #{password})"
        else
          puts 'FAILED'
          puts user.errors.full_messages.join('; ')
        end
        #### Admin Account

    rescue
      puts "\n!!! There were errors creating seed users"
      next
    end # task :users

    desc "Seed ProjectRoles"
    task :project_roles => :environment do
      ProjectRole.load_seed_data
    end

    desc "Seed Draw Cost Samples"
    task :draw_cost_samples => :environment do
      DrawCostSample.load_seed_data
    end

    desc "Development"
    task :development => :environment do
      DevelopmentSeeder.new.call
    end

  end # namespace seed
end # namespace db
