class DevelopmentSeeder
  include FactoryBot::Syntax::Methods

  def call
    puts " *** Seeding development data"
    create_organizations
    create_users
  end

  private

  def create_organizations
    puts "=== Creating Organizations"
    if Organization.any?
      puts " *** Skipping organization seed."
      return
    end

    puts " *** Creating Organization 1"
    @organization1 = create(:organization)
    puts " *** Creating Organization 2"
    @organization2 = create(:organization)
  end

  def create_users
    puts "=== Creating Users"
    if User.count > 2
      puts " *** Skipping user seed."
      return
    end

    puts " *** Creating User 1"
    @user1 = create(:user, role: Role.user) 
    puts " *** Creating User 2"
    @user2 = create(:user, role: Role.user, organization: @organization1) 
    puts " *** Creating User 1"
    @user3 = create(:user, role: Role.user) 
    puts " *** Creating Executive 1"
    @executive1 = create(:user, role: Role.executive) 
    puts " *** Creating Executive 2"
    @executive = create(:user, role: Role.executive) 
  end

  def create_projects
    puts "=== Creating Projects"
    if Project.count > 1
      puts " *** Skipping Project seeding."
      return
    end

    puts " *** Creating Project 1"
    @project1 = create(:project)
    create_draws(@project1)
  end

  def create_draws(project)
    puts " *** TODO: Draws seeder"
  end
end
