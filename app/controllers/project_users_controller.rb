class ProjectUsersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_project
  before_action :set_project_user, only: [:edit, :update, :show, :destroy]
  after_action :verify_authorized

  def index
    authorize ProjectUser
    @project_users = @project.project_users.includes(user: :profile).order("user_profiles.last_name ASC, user_profiles.first_name ASC")
  end

  def new
    @project_user = ProjectUser.new(project: @project)
    authorize @project_user
  end

  def create
    @project_user = ProjectUser.new(project: @project)
    authorize @project_user
  end

  def edit

  end

  def update

  end

  def destroy

  end

  private

  def record_scope
    @project.project_users
  end

  def project_record_scope
    ProjectPolicy::Scope.new(@current_user, Project).resolve
  end

  def set_project
    @project ||= project_record_scope.find(params[:project_id])
  end

  def set_project_user
    @project_user = record_scope.find(params[:id])
  end
end
