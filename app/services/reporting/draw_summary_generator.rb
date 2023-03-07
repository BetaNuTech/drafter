module Reporting
  class DrawSummaryGenerator
    class Error < StandardError; end

    COLUMNS = %i{
      project_cost
      contract_price
      change_order
      adjusted_contract
      total_draw_request
      balance
    }.freeze
    READY_STATES = %i{internally_approved externally_approved}

    attr_reader :draw, :errors, :project

    def initialize(draw:)
      reset_errors
      @draw = draw
      unless @draw.is_a?(Draw)
        msg = 'Invalid Draw argument'
        @errors << msg
        raise Error.new(msg) unless @draw.is_a?(Draw)
      end

      @project = @draw.project
    end

    def errors?
      errors.any?
    end

    def call
      return false unless check_state

      csv_data = generate_csv(report_data)
      filename = "#{@draw.name.parameterize.underscore}-#{Time.current.strftime("%Y%m%d%H%M")}.csv"
      @draw.draw_summary_sheet.attach(io: StringIO.new(csv_data), filename: )

      @draw.draw_summary_sheet
    end

    private

    def generate_csv(line_item_data)
      csv_data = CSV.generate do |csv|
        csv << COLUMNS
        line_item_data.each do |row|
          row_data = []
          COLUMNS.each do |col|
            row_data << row[col]
          end
          csv << row_data
        end
        csv
      end
    end

    def report_data
      totals = {
        project_cost: 'Total Uses',
        contract_price: 0.0,
        change_order: 0.0,
        adjusted_contract: 0.0,
        total_draw_request: 0.0,
        balance: 0.0
      }

      @project.project_costs.order(name: :asc).map do |project_cost|
        draw_cost = project_cost.draw_costs.visible.where(draw: @draw).first
        contract_price = project_cost.total
        change_order_total = project_cost.visible_change_orders.
          where(draws: {index: 1..@draw.index}).
          sum(:amount)
        change_order_funding_total = project_cost.visible_change_orders_funded.
          where(draws: {index: 1..@draw.index}).
          sum(:amount)
        overall_change_order_total = change_order_total - change_order_funding_total
        adjusted_contract =  project_cost.total + overall_change_order_total
        current_draw_costs = project_cost.draw_costs.includes(:draw).visible.
          where(draws: {index: 1..@draw.index})
        total_draw_request = current_draw_costs.sum(:total)
        balance = project_cost.total - current_draw_costs.sum(:total) + overall_change_order_total

        totals[:contract_price] += contract_price
        totals[:change_order] += change_order_total
        totals[:adjusted_contract] += adjusted_contract
        totals[:total_draw_request] += total_draw_request
        totals[:balance] += balance

        {
          project_cost: project_cost.name,
          contract_price:,
          change_order: overall_change_order_total,
          adjusted_contract:,
          total_draw_request:,
          balance: 
        }
      end << totals
    end

    def reset_errors
      @errors = []
    end

    def check_state
      return true if READY_STATES.include?(@draw.state.to_sym)

      @errors << 'Draw not in a ready state' 
      false
    end

  end
end
