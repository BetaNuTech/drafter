class HomeController < ApplicationController
  before_action :authenticate_user!
  after_action :verify_authorized

  def index
    authorize :home, :index? 
    @projects = policy_scope(Project).order(name: :asc)
    @notifications = []  # TODO
    @events = [] # TODO
  end
end
