module ProjectTaskServices
  class InvoiceTaskGenerator
    include Routing

    class Error < StandardError; end

    class << self
      def call(origin:, assignee: nil, action:)
        self.new(invoice: origin, assignee:, action:).generate
      end
    end # Class methods

    ACTIONS = %i{approve}

    attr_reader :invoice, :assignee, :action

    def initialize(invoice:, assignee: nil, action:)
      @invoice = invoice
      @assignee = assignee
      @action = action.to_sym
      raise Error.new('Invalid Task Action') unless ACTIONS.include?(@action)
    end

    def generate
      name = 'Invoice Task'
      description = 'undefined'

      case @action
      when :approve
        name = task_name('Approve')
        description = base_task_description
      else
        name = task_name('Review')
        description = base_task_description
      end

      if existing_task = ProjectTask.pending.where(origin: invoice, name: name).first
        return existing_task
      end

      task = ProjectTask.create(
        project: invoice.project,
        assignee: @assignee,
        assignee_name: ( @assignee&.name || '' ),
        origin: @invoice,
        attachment_url: attachment_url,
        preview_url: preview_url,
        due_at: due_at,
        name: name,
        description: description
      )

      task
    end

    private

    def task_name(verb)
      data = { origin_state: @invoice.displayed_invoice_state_name.upcase, verb:, base_task_name:}
      "%{verb} %{base_task_name}" % data
    end

    def base_task_name
      data = { amount: ( "$%0.2f" % @invoice.amount ), project_name: @invoice.project.name, draw_name: @invoice.draw_cost.draw.name, draw_cost_name: @invoice.draw_cost.name }
      "this %{amount} Invoice [%{project_name}, %{draw_name}, %{draw_cost_name}]" % data
    end

    def base_task_description
      [attachment_markup, preview_markup, origin_link_markup].compact.join(" -- ")
    end

    def due_at
      Time.current + (@invoice.draw_cost&.project_cost&.approval_lead_time || 1).days
    end

    def attachment_url
      @invoice.document.attached? ? url_prefix + rails_blob_path(@invoice.document) : nil
    end

    def preview_url
      @invoice.annotated_preview.attached? ? url_prefix + rails_blob_path(@invoice.annotated_preview) : nil
    end

    def attachment_markup
      url = attachment_url
      url.present? ? "[%{description}](%{url})" % {description: 'Document', url: url } : nil
    end

    def preview_markup
      url = preview_url
      url.present? ? "[%{description}](%{url})" % {description: 'Preview', url: url } : nil
    end

    def origin_link_markup
      "[View in Drafter](#{origin_url})"
    end

    def origin_url
      url_prefix + project_draw_path(project_id: @invoice.draw_cost.draw.project_id, id: @invoice.draw_cost.draw_id)
    end
  end
end
