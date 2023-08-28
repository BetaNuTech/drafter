class ProjectCostsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_project
  before_action :set_project_cost, only: %i[ show edit update destroy ]
  after_action :verify_authorized

  def index
    authorize new_project_cost
    @project_costs = record_scope.where(project: @project)
    @new_project_cost = @project.project_costs.new
    breadcrumbs.add(label: 'Home', url: '/')
    breadcrumbs.add(label: @project.name, url: project_path(@project))
    breadcrumbs.add(label: 'Project Costs', url: project_project_costs_path(project_id: @project.id), active: true)
  end

  def new
    @project_cost = new_project_cost
    authorize @project_cost
  end

  def create
    @project_cost = @project.project_costs.new(project_cost_params)
    authorize @project_cost
    @new_project_cost = @project.project_costs.new
    if @project_cost.save
        SystemEvent.log(description: "Added Project Cost '#{@project_cost.name}' for Project '#{@project.name}'", event_source: @project_cost, incidental: @project, severity: :warn)
      respond_to do |format|
        format.html { redirect_to project_project_cost_path(project_id: @project_cost.project_id, id: @project_cost.id), notice: 'Added a new Project Cost' }
        format.turbo_stream
      end
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
    authorize @project_cost
  end

  def edit
    authorize @project_cost
  end

  def edit_multiple
    @new_project_cost = @project.project_costs.new
    authorize @new_project_cost
    @project_costs = record_scope.where(project: @project).order(name: :asc)
    breadcrumbs.add(label: 'Home', url: '/')
    breadcrumbs.add(label: @project.name, url: project_path(@project))
    breadcrumbs.add(label: 'Project Costs', url: project_project_costs_path(project_id: @project.id))
    breadcrumbs.add(label: 'Bulk Edit', url: update_multiple_project_project_costs_path(project_id: @project.id), active: true)
  end

  def update
    authorize @project_cost
    if @project_cost.update(project_cost_params)
      respond_to do |format|
        SystemEvent.log(description: "Updated Project Cost '#{@project_cost.name}' for Project '#{@project.name}'", event_source: @project_cost, incidental: @project, severity: :warn)
        format.html { redirect_to project_project_cost_path(project_id: @project_cost.project_id, id: @project_cost.id), notice: 'Updated Project Cost' }
        format.turbo_stream
      end
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def update_multiple
    @new_project_cost = @project.project_costs.new
    authorize @new_project_cost

    project_costs_params = params.require(:project_costs).permit!

    permitted_params = policy(@new_project_cost).allowed_params
    project_costs_params.each do |id, values|
      record_scope.find(id).update(values.slice(*permitted_params))
    end

    redirect_to edit_multiple_project_project_costs_path(project_id: @project.id), notice: 'Project Costs updated'
  end

  def destroy
    authorize @project_cost
    if @project_cost.destroy
      respond_to do |format|
        SystemEvent.log(description: "Deleted Project Cost '#{@project_cost.name}' for Project '#{@project.name}'", event_source: @project_cost, incidental: @project, severity: :warn)
        format.html { redirect_to project_path(@project), notice: 'Project Cost deleted'}
        format.turbo_stream
      end
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def new_project_cost
    ProjectCost.new(project: @project)
  end

  def record_scope
    @project.project_costs
  end

  def set_project_cost
    @project_cost = record_scope.find(params[:id])
  end

  # Only allow a list of trusted parameters through.
  def project_cost_params
    new_project_cost = @project.project_costs.new
    allowed_params = policy(new_project_cost).allowed_params
    params.require(:project_cost).permit(*allowed_params)
  end
  
  def project_record_scope
    ProjectPolicy::Scope.new(@current_user, Project).resolve
  end

  def set_project
    @project ||= project_record_scope.find(params[:project_id]) if params[:project_id].present?
  end


end
