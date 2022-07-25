class ProjectUsersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_project
  before_action :set_project_user, only: [:edit, :update, :show, :destroy]
  after_action :verify_authorized

  def index
    @service = Projects::Membership.new(current_user: @current_user, project: @project)
    @project_user = @service.project_user
    @project_users = @service.memberships
    authorize @project_user
  end

  def new
    @service = Projects::Membership.new(current_user: @current_user, project: @project)
    @project_user = @service.project_user
    authorize @project_user
  end

  def create
    @service = Projects::Membership.new(current_user: @current_user, project: @project)
    @project_user = @service.project_user
    authorize @project_user
    if (@project_user = @service.add_member(user: project_user_params[:user_id], role: project_user_params[:project_role_id]))
      respond_to do |format|
        format.html { redirect_to project_project_users_path(project_id: @project.id), notice: 'Added project member'} 
        format.turbo_stream
      end
    else
      render :new, status: :unprocessable_entitity
    end
  end

  def edit
    @service = Projects::Membership.new(current_user: @current_user, project: @project)
    authorize @project_user
  end

  def update
    authorize @project_user
    @service = Projects::Membership.new(current_user: @current_user, project: @project)
    unless (new_project_role_id = project_user_params[:project_role_id]).present?
      raise 'foobar'
      render :edit, status: :unprocessable_entitity
      return
    end

    if (@project_user = @service.update_member_role(user: @project_user.user, role: new_project_role_id))
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
    @service = Projects::Membership.new(current_user: @current_user, project: @project)
    @service.remove_member(@project_user.user)
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
