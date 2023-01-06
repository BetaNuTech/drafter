module ProjectTaskServices
  class DrawTaskGenerator
    class Error < StandardError; end

    class << self
      def call(origin:, assignee: nil, action:)
        self.new(draw: origin, assignee:, action:).generate
      end
    end

    ACTIONS = %i{approve}

    attr_reader :draw, :assignee, :action

    def initialize(draw:, assignee: nil, action:)
      @draw = draw
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

      ProjectTask.create(
        project: @draw.project,
        assignee: @assignee,
        assignee_name: ( @assignee&.name || '' ),
        origin: @draw,
        due_at: due_at,
        name: name,
        description: description
      )
    end

    private

    def base_task_name
      data = {draw_name: @draw.name, project_name: @draw.project.name}
      "%{draw_name} [%{project_name}]" % data
    end

    def base_task_description
      base_task_name
    end

    def due_at
      Time.current
    end

  end
end
