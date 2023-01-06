module Draws
  module StateMachine
    extend ActiveSupport::Concern

    class_methods do
      def state_names
        Draw.aasm.states.map{|s| s.name.to_s}
      end
    end

    included do
      include AASM
      APPROVED_STATES = %i{ internally_approved externally_approved funded }.freeze
      VISIBLE_STATES = %i{ pending submitted internally_approved externally_approved funded rejected }.freeze
      ALLOW_DRAW_COST_CHANGE_STATES = %i{ pending rejected }.freeze
      ALLOW_DOCUMENT_CHANGE_STATES = %i{ pending rejected }.freeze
      ALLOW_DOCUMENT_APPROVALS_STATES = %i{ submitted }.freeze
      ALLOW_INVOICE_APPROVALS_STATES = %i{ submitted }.freeze

      scope :visible, -> { where(state: VISIBLE_STATES) }

      aasm column: :state do
        state :pending
        state :submitted
        state :internally_approved
        state :externally_approved
        state :funded
        state :rejected
        state :withdrawn

        event :submit do
          transitions from: %i{ pending rejected }, to: :submitted,
            guard: Proc.new{ allow_submit? },
            after: Proc.new {|*args| after_submit(*args) }
        end

        event :approve_internal do
          transitions from: %i{ submitted rejected }, to: :internally_approved,
            guard: Proc.new { allow_approval? },
            after: Proc.new {|*args| after_approval(*args) }
        end

        event :approve_external do
          transitions from: :internally_approved, to: :externally_approved,
            guard: Proc.new { allow_approval? },
            after: Proc.new {|*args| after_approval(*args) }
        end

        event :reject do
          transitions from: %i{ submitted internally_approved externally_approved }, to: :rejected
        end

        event :withdraw do
          transitions from: %i{ pending submitted rejected internally_approved }, to: :withdrawn,
            after: Proc.new {|*args| after_withdraw(*args) }
        end

        event :fund do
          transitions from: :externally_approved, to: :funded
        end
      end

      def trigger_event(event_name:, user: nil)
        event = event_name.to_sym
        if permitted_state_events.include?(event)
          self.aasm.fire(event, user)
          return self.save
        else
          return false
        end
      end

      def permitted_state_events
        aasm.events(permitted: true).map(&:name)
      end

      def permitted_states
        aasm.states(permitted: true).map(&:name)
      end

      def state_css_class
        {
          'pending' => 'info',
          'in_progress' => 'warning',
          'submitted' => 'warning',
          'internally_approved' => 'primary',
          'externally_approved' => 'primary',
          'funded' => 'success',
          'rejected' => 'danger'
        }.fetch(state, 'light')
      end

      def approved?
        APPROVED_STATES.include?(state.to_sym)
      end

      def allow_draw_cost_changes?
        ALLOW_DRAW_COST_CHANGE_STATES.include?(state.to_sym)
      end

      def allow_document_changes?
        ALLOW_DOCUMENT_CHANGE_STATES.include?(state.to_sym)
      end

      def allow_document_approvals?
        ALLOW_DOCUMENT_APPROVALS_STATES.include?(state.to_sym)
      end

      def allow_invoice_approvals?
        ALLOW_INVOICE_APPROVALS_STATES.include?(state.to_sym)
      end

      def submit_draw_costs(user)
        draw_costs.reload
        draw_costs.where(state: %i{pending rejected}).each do |draw_cost|
          draw_cost.trigger_event(event_name: :submit, user: user)
        end
      end

      def allow_submit?
        all_documents_submitted? &&
          draw_costs.visible.any? &&
          draw_costs.visible.all?(&:allow_submit?)
      end

      def create_document_verify_tasks
        draw_documents.visible.each do |doc|
          doc.create_task(assignee: nil, action: :verify) #rescue false
        end
      end

      def create_draw_approval_tasks
        create_task(action: :approve)
      end

      def after_submit(user)
        submit_draw_costs(user)
        create_document_verify_tasks
        create_draw_approval_tasks
      end

      def allow_approval?
        all_draw_costs_approved? && all_required_documents_approved?
      end

      def after_approval(user)
        approve(user)
      end

      def after_withdraw(user=nil)
        items = draw_documents.to_a + invoices.to_a
        ProjectTask.where(origin: items).pending.each{ |task| task.trigger_event(event_name: :archive, user: user) }
      end

    end
  end
end
