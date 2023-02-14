class ProjectsController < ApplicationController
  PROJECT_TASK_FILTERS = %i{all active approved rejected}
  PROJECT_TASK_FILTER_DEFAULT = :active
  PROJECT_TASK_COUNT_DEFAULT = 10
  PROJECT_TASK_COUNT_MAX = 99

  before_action :authenticate_user!
  before_action :set_project, only: [:edit, :update, :show, :destroy, :add_member, :project_tasks]
  after_action :verify_authorized
  rescue_from ActiveRecord::RecordNotFound, with: :redirect_to_home


  def index
    authorize Project
    @collection = record_scope.order(name: :asc)
    breadcrumbs.add(label: 'Home', url: '/')
    breadcrumbs.add(label: 'Projects', url: projects_path, active: true)
  end

  def new
    @project = Project.new
    authorize @project
    breadcrumbs.add(label: 'Home', url: '/')
    breadcrumbs.add(label: 'New Project', url: new_project_path, active: true)
  end

  def create
    @service = Projects::Updater.new(@current_user, Project.new)
    @project = @service.project
    authorize @project
    if @service.create(params)
      @project = @service.project
      redirect_to project_path(@project), notice: 'Created new project'
    else
      @project = @service.project
      render :new, status: :unprocessable_entity
    end
  end

  def show
    authorize @project
    @service = Projects::Updater.new(@current_user, @project)
    @project_tasks = filtered_project_tasks
    breadcrumbs.add(label: 'Home', url: '/')
    breadcrumbs.add(label: @project.name, url: project_path(@project), active: true)
  end

  def project_tasks
    authorize @project
    @project_tasks = filtered_project_tasks
    breadcrumbs.add(label: 'Home', url: '/')
    breadcrumbs.add(label: @project.name, url: project_path(@project))
    breadcrumbs.add(label: 'Tasks', url: project_path(@project), active: true)
  end

  def edit
    authorize @project
    breadcrumbs.add(label: 'Home', url: '/')
    breadcrumbs.add(label: 'Edit ' + @project.name, url: project_path(@project), active: true)
  end

  def update
    authorize @project
    @service = Projects::Updater.new(@current_user, @project)
    if @service.update(params)
      redirect_to project_path(@project), notice: 'Updated project'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @project
    @project.destroy
    redirect_to root_path, notice: 'Removed project'
  end

  def add_member
    authorize @project
    @service = Projects::Updater.new(@current_user, @project)
    @service.add_member(user: params[:user_id], role: params[:project_role_id])
    redirect_to project_path(@project), notice: 'A new member was added to the project'
  end

  def remove_member
    authorize @project
    @service = Projects::Updater.new(@current_user, @project)
    @service.remove_member(user: params[:user_id]) 
    redirect_to project_path(@project), notice: 'A member was removed from the project'
  end

  private

  def redirect_to_home
    redirect_to root_path
  end

  def record_scope
    policy_scope(Project)
  end

  def set_project
    @project = record_scope.find(params[:id] || params[:project_id])
  end

  def project_params
    allowed_params = policy(Project).allowed_params
    params.require(:project).permit(*allowed_params)
  end

  def filtered_project_tasks
    if params[:task_filter].present?
      @task_filter = params[:task_filter].to_sym
      task_count = PROJECT_TASK_COUNT_MAX
    else
      task_count = PROJECT_TASK_COUNT_DEFAULT
      @task_filter = PROJECT_TASK_FILTER_DEFAULT
    end

    skope = case @task_filter
            when :all
              @project.project_tasks
            when :active
              @project.project_tasks.active
            when :approved
              @project.project_tasks.approved
            when :rejected
              @project.project_tasks.rejected
            end

    skope.order(due_at: :asc).limit(task_count)
  end
end
