class DevelopmentSeeder
  include FactoryBot::Syntax::Methods

  def call
    puts " *** Seeding development data"
    return unless Rails.env.development?

    create_organizations
    create_users
    create_draws
    create_requests
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

  def create_draws(project=nil)
    project ||= Project.first
    puts "=== Creating Draws"
    Draw.create(
      project: project,
      name: 'Test Draw 1',
      total: 1234567
    )
  end

  def create_requests(project=nil)

    project ||= Project.first
    create_draws(project) if project.draws.empty?

    unless  (user = project.developers.first).present?
      user = create(:user, role: Role.user )
      project.add_user(user: , role: ProjectRole.developer)
      user.reload
    end

    draw = project.draws.first
    draw_cost = draw.draw_costs.first
    create(:draw_cost_request, draw_cost:, draw:, organization: user.organization, user:)
  end
end
