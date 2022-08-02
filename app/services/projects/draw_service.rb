module Projects
  class DrawService
    attr_reader :project, :current_user, :draw, :errors

    def initialize(current_user: nil, project:, draw: nil)
      @current_user = current_user
      @project = project
      @draw = case draw
              when Draw
                draw
              when String
                @project.draws.find(draw)
              when nil
                draw = @project.draws.new
                draw.project = @project
                draw.index = draw.next_index
                draw.name = "Draw #{draw.index}"
                draw
              end
      @policy = DrawPolicy.new(current_user, @draw)
    end

    def draws
      @project.draws.order(index: :asc)
    end

    def create(params)
      @draw = Draw.new(sanitize_params(params))
      @draw.project = @project
      if @draw.save
        SystemEvent.log(description: "Created new Draw '#{@draw.name}'", event_source: @project, incidental: @current_user, severity: :warn)
        add_draw_costs(@draw)
        return @draw
      else
        record_errors
        return false
      end
    end

    def update(params)
      if @draw.update(sanitize_params(params))
        SystemEvent.log(description: "Updated information for Draw '#{@draw.name}'", event_source: @project, incidental: @current_user, severity: :info)
        return @draw
      else
        record_errors
        return false
      end
    end

    def destroy
      @draw.destroy
      SystemEvent.log(description: "Deleted Draw '#{@draw.name}'", event_source: @project, incidental: @current_user, severity: :danger)
      return true
    end

    def approve
      # TODO
    end

    def errors?
      @errors.present?
    end

    def load_sample_costs
      return false unless ( @draw.present? && !@draw.new_record? )

      DrawCostSample.standard.each do |dcs|
        DrawCost.create(
          draw: @draw,
          name: dcs.name,
          state: :pending,
          cost_type: dcs.cost_type
        )
      end

      SystemEvent.log(description: "Added initial costs for '#{draw.name}'", event_source: @project, incidental: draw, severity: :info)

      @draw.reload
      @draw.draw_costs
    end

    private

    def add_draw_costs(draw)
      DrawCostSample.standard.order(cost_type: :asc, name: :asc).each do |sample|
        draw.draw_costs.create(
          cost_type: sample.cost_type,
          name: sample.name,
          approval_lead_time: sample.approval_lead_time,
          total: 0.0,
          state: 'pending'
        )
      end
      @project.draw_costs.reload
    end

    def record_errors
      @errors = []
      @draw.errors.full_messages.each do |error|
        @errors << error
      end
      @errors
    end

    def sanitize_params(params)
      allowed_params = @policy.allowed_params
      if params.is_a?(ActionController::Parameters)
        params.require(:draw).permit(*allowed_params)
      else
        params.select{|k,v| allowed_params.include?(k.to_s) }
      end
    end

  end
end