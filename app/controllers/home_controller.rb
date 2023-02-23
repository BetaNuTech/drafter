class HomeController < ApplicationController
  before_action :authenticate_user!
  after_action :verify_authorized

  def index
    authorize :home, :index? 
    @projects = policy_scope(Project).order(name: :asc)
    @notifications = []  # TODO
    @events = SystemEvent.none # TODO
    #breadcrumbs.add(label: 'Home', url: '/', active: true)
  end

  def about
    authorize :home, :about?
  end
end
