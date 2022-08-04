class HomeController < ApplicationController
  before_action :authenticate_user!
  after_action :verify_authorized

  def index
    authorize :home, :index? 
    @projects = policy_scope(Project).order(name: :asc)
    @notifications = []  # TODO
    @events = SystemEvent.where("1=0") # TODO
    #breadcrumbs.add(label: 'Home', url: '/', active: true)
  end
end
