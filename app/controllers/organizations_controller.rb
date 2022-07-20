class OrganizationsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_organization, only: [:edit, :show, :update, :destroy]
  after_action :verify_authorized

  def index
    authorize Organization
    @collection = record_scope.order(name: :asc)
  end

  def new
    @organization = Organization.new
    authorize @organization
  end

  def create
    @organization = Organization.new(organization_params)
    authorize @organization
    respond_to do |format|
      if @organization.save
        format.html { redirect_to organization_path(@organization), notice: 'Created new organization' }
      else
        format.html { render :new, status: :unprocessable_entity  }
      end
    end
  end

  def show
    authorize @organization
  end

  def edit
    authorize @organization
  end

  def update
    authorize @organization
    respond_to do |format|
      if @organization.update(organization_params)
        format.html { redirect_to edit_organization_path(@organization), notice: 'Organization updated'}
      else
        format.html { render :edit, status: :unprocessable_entity  }
      end
    end
  end

  def destroy
    authorize @organization
    @organization.destroy
    redirect_to organizations_path, notice: 'Organization was deleted'
  end

  private

  def record_scope
    policy_scope(Organization)
  end

  def set_organization
    @organization = record_scope.find(params[:id])
  end

  def organization_params
    allowed_params = policy(@organization||Organization).allowed_params
    params.require(:organization).permit(*allowed_params)
  end
end
