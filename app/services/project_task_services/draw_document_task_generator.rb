module ProjectTaskServices
  class DrawDocumentTaskGenerator
    include Routing

    class Error < StandardError; end

    class << self
      def call(origin:, assignee: nil, action:)
        self.new(draw_document: origin, assignee:, action:).generate
      end
    end # Class methods

    ACTIONS = %i{approve}

    attr_reader :draw_document, :assignee, :action

    def initialize(draw_document:, assignee: nil, action:)
      @draw_document = draw_document
      @assignee = assignee
      @action = action.to_sym
      raise Error.new('Invalid Task Action') unless ACTIONS.include?(@action)
    end

    def generate
      name = 'Document Task'
      description = 'undefined'

      case @action
      when :approve
        name = task_name('Approve')
        description = base_task_description
      else
        name = task_name('Review')
        description = base_task_description
      end

      ProjectTask.create(
        project: @draw_document.project,
        assignee: @assignee,
        assignee_name: ( @assignee&.name || '' ),
        origin: @draw_document,
        attachment_url: attachment_url,
        due_at: due_at,
        name: name,
        description: description
      )
    end

    private

    def task_name(verb)
      data = { origin_state: @draw_document.state.upcase, verb:, base_task_name:}
      "[%{origin_state}] %{verb} %{base_task_name}" % data
    end

    def base_task_name
      data = { type: @draw_document.documenttype.capitalize, project_name: @draw_document.project.name, draw_name: @draw_document.draw.name }
      "this %{type} Document [%{project_name}, %{draw_name}]" % data
    end

    def base_task_description
      [attachment_markup, origin_link_markup].compact.join(' ')
    end

    def due_at
      Time.current + (@draw_document.approval_lead_time || 1).days
    end

    def attachment_url
      @draw_document.document&.url
    end

    def attachment_markup
      "[%{description}](%{url})" % {description: 'Document', url: attachment_url}
    end

    def preview_markup
      "[%{description}](%{url})" % {description: 'Preview', url: preview_url}
    end

    def origin_link_markup
      "[View in Drafter](#{origin_url})"
    end

    def origin_url
      project_draw_path(project_id: @draw_document.draw.project_id, id: @draw_document.draw_id)
    end
  end
end
