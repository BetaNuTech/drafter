module ProjectTaskServices
  class ChangeOrderTaskGenerator
    include Routing

    class Error < StandardError; end

    class << self
      def call(origin:, assignee: nil, action:)
        self.new(change_order: origin, assignee:, action:).generate
      end
    end # Class methods

    ACTIONS = %i{approve}

    attr_reader :change_order, :assignee, :action

    def initialize(change_order:, assignee: nil, action:)
      @change_order = change_order
      @assignee = assignee
      @action = action.to_sym
      raise Error.new('Invalid Task Action') unless ACTIONS.include?(@action)
    end

    def generate
      name = 'Change Order Task'
      description = 'undefined'

      case action
      when :approve
        name = task_name('Approve')
        description = base_task_description
      else
        name = task_name('Review')
        description = base_task_description
      end

      if existing_task = ProjectTask.pending.where(origin: change_order, name: name).first
        return existing_task
      end

      task = ProjectTask.create(
        project: change_order.project,
        assignee: assignee,
        assignee_name: ( assignee&.name || '' ),
        origin: change_order,
        attachment_url: attachment_url,
        due_at: due_at,
        name: name,
        description: description
      )

      task
    end

    private

    def task_name(verb)
      data = { origin_state: change_order.displayed_state_name.upcase, verb:, base_task_name:}
      "%{verb} %{base_task_name}" % data
    end

    def base_task_name
      data = { amount: ( "$%0.2f" % change_order.amount ), project_name: change_order.project.name, draw_name: change_order.draw_cost.draw.name, draw_cost_name: change_order.draw_cost.name }
      "this %{amount} Change Order [%{project_name}, %{draw_name}, %{draw_cost_name}]" % data
    end

    def base_task_description
      description = "%{amount} from '%{funding_source}' funding '%{draw_cost}'" % {
        amount: "$%0.2f" % change_order.amount,
        funding_source: change_order.funding_source.name,
        draw_cost: change_order.draw_cost.name
      }
      [attachment_markup, description, origin_link_markup].compact.join(" -- ")
    end

    def due_at
      Time.current + (change_order.draw_cost&.project_cost&.approval_lead_time || 1).days
    end

    def attachment_url
      change_order.document.attached? ? url_prefix + rails_blob_path(change_order.document) : nil
    end

    def attachment_markup
      url = attachment_url
      url.present? ? "[%{description}](%{url})" % {description: 'Document', url: url} : nil
    end

    def origin_link_markup
      "[View in Drafter](#{origin_url})"
    end

    def origin_url
      url_prefix + project_draw_path(project_id: change_order.draw_cost.draw.project_id, id: change_order.draw_cost.draw_id)
    end
    
  end
end
