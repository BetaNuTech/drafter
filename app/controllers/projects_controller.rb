class ProjectsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_project, only: [:edit, :update, :show, :destroy, :add_member]
  after_action :verify_authorized

  def index
    authorize Project
    @collection = record_scope.order(name: :asc)
  end

  def new
    @project = Project.new
    authorize @project
  end

  def create
    @service = Projects::Updater.new(Project.new, @current_user)
    @project = @service.project
    authorize @project
    respond_to do |format|
      if @service.create(params)
        @project = @service.project
        SystemEvent.log(description: 'Created new project',event_source: @project, incidental: @current_user, severity: :warn)
        format.html { redirect_to project_path(@project), notice: 'Created new project'}
      else
        format.html { render :new, status: :unprocessable_entity }
      end
    end
  end

  def show
    authorize @project
    @service = Projects::Updater.new(@project, @current_user)
  end

  def edit
    authorize @project
  end

  def update
    authorize @project
    @service = Projects::Updater.new(@project, current_user)
    respond_to do |format|
      if @project.update(params)
        SystemEvent.log(description: "Updated Project",event_source: @project, incidental: @current_user, severity: :info)
        format.html { redirect_to project_path(@project), notice: 'Updated project' }
      else
        format.html { render :edit, status: :unprocessable_entity  }
      end
    end
  end

  def destroy
    authorize @project
    @project.destroy
    SystemEvent.log(description: "Removed Project", event_source: @project, incidental: @current_user, severity: :warn)
    respond_to do |format|
      format.html { redirect_to projects_path, notice: 'Removed project' }
    end
  end

  def add_member
    authorize @project
    @service = Projects::Updater.new(@project, current_user)
    
    @service.add_member(user: params[:user_id], role: params[:role_id])
  end

  private

  def record_scope
    policy_scope(Project)
  end

  def set_project
    @project = record_scope.find(params[:id])
  end

  def project_params
    allowed_params = policy(Project).allowed_params
    params.require(:project).permit(*allowed_params)
  end
end
