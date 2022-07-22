class ProjectUsersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_project
  before_action :set_project_user, only: [:edit, :update, :show, :destroy]
  after_action :verify_authorized

  def index
    authorize ProjectUser
    @project_users = @project.project_users.includes(user: :profile).order("user_profiles.last_name ASC, user_profiles.first_name ASC")
    @project_user = ProjectUser.new(project: @project)
  end

  def new
    @project_user = ProjectUser.new(project: @project)
    authorize @project_user
  end

  def create
    @project_user = ProjectUser.new(project_user_params.merge(project_id: @project.id))
    authorize @project_user
    if @project_user.save
        log_message = "Added %s as a member in the %s role" % [@project_user.name, @project_user.project_role.name]
        SystemEvent.log(description: log_message, event_source: @project, incidental: @project_user.user, severity: :warn)
      respond_to do |format|
        format.html { redirect_to project_project_users_path(project_id: @project.id), notice: 'Added project member'} 
        format.turbo_stream
      end
    else
      render :new, status: :unprocessable_entitity
    end
  end

  def edit
    authorize @project_user
  end

  def update
    authorize @project_user
    if (new_project_role_id = project_user_params[:project_role_id]).present?
      @project_user.project_role_id = new_project_role_id
    end
    if @project_user.save
        log_message = "Changed %s to the %s role" % [@project_user.name, @project_user.project_role.name]
        SystemEvent.log(description: log_message, event_source: @project, incidental: @project_user.user, severity: :warn)
      respond_to do |format|
        format.html { redirect_to project_project_user_path(project_id: @project.id, project_user_id: @project_user.id), notice: 'Updated project member' } 
        format.turbo_stream
      end
    else
      render :edit, status: :unprocessable_entitity
    end
  end

  def destroy
    authorize @project_user
    @project = @project_user.project
    @project_user.destroy
        log_message = "Removed %s as a member" % [@project_user.name]
        SystemEvent.log(description: log_message, event_source: @project, incidental: @project_user.user, severity: :warn)
    @project.reload
    respond_to do |format|
      format.html { redirect_to project_project_users_path(project_id: @project_user.project_id), notice: 'Project member removed' }
      format.turbo_stream
    end
  end

  private

  def project_user_params
    params.require(:project_user).permit([:user_id, :project_role_id ])
  end

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
