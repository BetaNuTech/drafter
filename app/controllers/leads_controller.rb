class LeadsController < ApplicationController
  http_basic_authenticate_with **http_auth_credentials unless Rails.env.test?

  before_action :set_lead, only: [:show, :edit, :update, :destroy]

  # GET /leads
  # GET /leads.json
  def index
    @leads = Lead.all
  end

  # GET /leads/1
  # GET /leads/1.json
  def show
  end

  # GET /leads/new
  def new
    @lead = Lead.new
    @lead.build_preference
  end

  # GET /leads/1/edit
  def edit
    @lead.build_preference unless @lead.preference.present?
  end

  # POST /leads
  # POST /leads.json
  def create
    set_lead_source
    #TODO assign current_user to agent
    lead_creator = Leads::Creator.new(data: lead_params, agent: nil, source: @lead_source.slug, validate_token: @lead_source.api_token)
    @lead = lead_creator.execute

    respond_to do |format|
      if !@lead.errors.any?
        format.html { redirect_to @lead, notice: 'Lead was successfully created.' }
        format.json { render :show, status: :created, location: @lead }
      else
        @lead.build_preference unless @lead.preference.present?
        format.html { render :new }
        format.json { render json: @lead.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /leads/1
  # PATCH/PUT /leads/1.json
  def update
    respond_to do |format|
      if @lead.update(lead_params)
        format.html { redirect_to @lead, notice: 'Lead was successfully updated.' }
        format.json { render :show, status: :ok, location: @lead }
      else
        format.html { render :edit }
        format.json { render json: @lead.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /leads/1
  # DELETE /leads/1.json
  def destroy
    @lead.destroy
    respond_to do |format|
      format.html { redirect_to leads_url, notice: 'Lead was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_lead
      @lead = Lead.find(params[:id])
    end

    def set_lead_source
      lead_source_id = lead_params[:lead_source_id]
      if lead_source_id.present?
        @lead_source = LeadSource.active.find(lead_source_id)
      else
        @lead_source = LeadSource.default
      end
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def lead_params
      valid_lead_params = Lead::ALLOWED_PARAMS
      valid_preference_params = [{preference_attributes: LeadPreference::ALLOWED_PARAMS }]
      params.require(:lead).permit(*(valid_lead_params + valid_preference_params))
    end

end
