module Api
  module V1
    class LeadsController < ApiController
      before_action :validate_lead_source_token

      # GET /api/v1/leads.json?token=XXX&limit=XXX
      def index
        unless access_policy.index?
          render json: {errors: {base: [ 'Access Denied' ]}}, status: :forbidden
          return
        end

        limit = (params[:limit] || 10).to_i
        @leads = @source.leads.order("created_at desc").limit(limit)

        render 'leads/index', format: :json
      end

      # POST /api/v1/leads
      def create
        unless access_policy.create?
          render json: {errors: {base: [ 'Access Denied' ]}}, status: :forbidden
          return
        end

        lead_data = params
        token = params[:token]
        lead_creator = Leads::Creator.new(data: lead_data, agent: nil, token: token)
        @lead = lead_creator.execute
        if @lead.valid?
          render :create, status: :created, format: :json
        else
          render json: {errors: lead_creator.errors}, status: :unprocessable_entity, format: :json
        end
      end

      # Return Prospect Stats
      #
      # URL Examples:
      # (all properties): GET /api/v1/prospect_stats.json?token=XXX
      # (specified properties): GET /api/v1/prospect_stats.json?token=XXX&stats=properties&ids[]=XXX&ids[]=YYY
      # (all teams): GET /api/v1/prospect_stats.json?token=XXX&stats=teams
      # (all agents): GET /api/v1/prospect_stats.json?token=XXX&stats=agents
      def prospect_stats
        @stats_for = ( params[:stats] || 'properties' )
        @ids = params[:ids]
        unless access_policy.prospect_stats?
          render json: {errors: {base: [ 'Access Denied' ]}}, status: :forbidden
          return
        end
        @stats = ProspectStats.new(ids: @ids, filters: {date: params[:date]})
      end

      private

      def validate_lead_source_token
        validate_source_token(source: LeadSource, token: api_token)
      end

      def access_policy
        LeadApiPolicy.new(nil, @source)
      end

    end
  end
end
