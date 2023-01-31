module ProjectTaskServices
  class DrawCostTaskGenerator
    include Routing

    class Error < StandardError; end

    class << self
      def call(origin:, assignee: nil, action:)
        self.new(draw_cost: origin, assignee:, action:).generate
      end
    end

    ACTIONS = %i{approve}
    SUBMISSION_DELAY = 30 # seconds

    attr_reader :draw_cost, :assignee, :action

    def initialize(draw_cost:, assignee: nil, action:)
      @draw_cost = draw_cost
      @assignee = assignee
      @action = action.to_sym
      raise Error.new('Invalid Task Action') unless ACTIONS.include?(@action)
    end

    def generate
      name = 'Draw Task'
      description = 'undefined'

      case @action
      when :approve
        name = 'Approve ' + base_task_name
        description = base_task_description
      else
        name = 'Review ' + base_task_name
        description = base_task_description
      end

      task = ProjectTask.create(
        project: @draw_cost.project,
        assignee: @assignee,
        assignee_name: ( @assignee&.name || '' ),
        origin: @draw_cost,
        due_at: due_at,
        name: name,
        description: description
      )

      @draw_cost.reload
      @draw_cost.delay(run_at: SUBMISSION_DELAY.seconds.from_now).submit_new_tasks

      task
    end

    private

    def due_at
      Time.current + (@draw_cost.draw.approval_lead_time || 1).days
    end

    def base_task_name
      data = {draw_cost_name: @draw_cost.name, project_name: @draw_cost.project.name, draw_name: @draw_cost.draw.name}
      "%{draw_cost_name} [%{project_name}, %{draw_name}]" % data
    end

    def base_task_description
      [base_task_name, origin_link_markup, funding_summary].join(' ')
    end

    def origin_link_markup
      "([View in Drafter](#{origin_url}))"
    end

    def origin_url
      url_prefix + project_draw_path(project_id: @draw_cost.draw.project_id, id: @draw_cost.id)
    end

    def funding_summary
      change_order_line = -> (change_order) {
        " - *%{name}:* $%{subtotal}" % {
          name: change_order.funding_source.name,
          subtotal: "%0.2f" % change_order.amount 
         }
      }
      <<~EOF

      ```
      **TOTAL COST:**  #{"$%0.2f" % @draw_cost.invoice_total}
       - *#{@draw_cost.project_cost.name}:* $#{@draw_cost.project_cost_subtotal}
      #{@draw_cost.change_orders.map{|co| change_order_line.call(co)}.join('\n')}
      ```
      EOF
    end

  end
end
