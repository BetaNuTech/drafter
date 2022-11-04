module DrawCosts
  module StateMachine
    extend ActiveSupport::Concern

    class_methods do
      def state_names
        DrawCost.aasm.states.map{|s| s.name.to_s}
      end
    end

    included do
      class TransitionError < StandardError; end;

      ALLOW_INVOICE_CHANGE_STATES = %i{pending rejected}
      VISIBLE_STATES = %i{pending submitted approved rejected}

      scope :visible, -> { where(state: VISIBLE_STATES) }

      include AASM

      aasm column: :state do
        state :pending
        state :submitted
        state :approved
        state :rejected
        state :withdrawn

        event :submit do
          transitions from: %i{ pending rejected }, to: :submitted, 
            guard: :allow_submit?,
            after: Proc.new { |*args| after_submit(*args)}
        end

        event :approve do
          transitions from: %i{ submitted rejected }, to: :approved,
            guard: :allow_approve?
        end

        event :reject do
          transitions from: %i{ submitted approved }, to: :rejected,
            after: Proc.new {|*args| reject_request }
        end

        event :withdraw do
          transitions from: %i{ pending submitted rejected }, to: :withdrawn
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
          'submitted' => 'warning',
          'approved' => 'success',
          'rejected' => 'danger'
        }.fetch(state, 'primary')
      end

      def allow_invoice_changes?
        draw.allow_draw_cost_changes? &&
          ALLOW_INVOICE_CHANGE_STATES.include?(state.to_sym)
      end

      def submit_invoices(user)
        invoices.reload
        invoices.pending.each do |invoice|
          invoice.trigger_event(event_name: :submit, user: user)
        end
      end

      def after_submit(user)
        submit_invoices(user)
      end

      def allow_submit?
        invoices.visible.any? && !over_budget?
      end

      def allow_approve?
        invoices.where(state: %i{submitted approved}).any? && invoices.pending.none?
      end
    end
  end
end
