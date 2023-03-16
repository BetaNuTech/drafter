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

      attr_reader :state_errors

      scope :visible, -> { where(state: VISIBLE_STATES) }

      include AASM

      aasm column: :state, whiny_transitions: false do
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
          transitions from: %i{ pending submitted rejected }, to: :approved,
            guard: :allow_approve?,
            after: Proc.new { |*args| after_approve(*args)}
        end

        event :reject do
          transitions from: %i{ pending submitted approved }, to: :rejected,
            after: Proc.new { |*args| after_reject(*args)}
        end

        event :withdraw do
          transitions from: %i{ pending submitted rejected }, to: :withdrawn,
            after: Proc.new { |*args| after_withdraw(*args)}
        end

        event :revert_to_pending do
          transitions from: %i{ submitted approved rejected }, to: :pending,
          after: Proc.new { |*args| after_revert_to_pending(*args)}
        end
      end

      def trigger_event(event_name:, user: nil)
        event = event_name.to_sym
        if permitted_state_events.include?(event)
          return ( self.aasm.fire!(event, user) && self.save )
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
          'pending' => 'secondary',
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
        change_orders.create_approval_tasks
      end

      def allow_submit?
        @state_errors = []
        @state_errors << 'There are rejected change orders' if change_orders.rejected.any?
        @state_errors << 'There are rejected invoices' if invoices.rejected.any?
        @state_errors << 'Over budget' if over_budget?
        if invoices.visible.any?
          @state_errors << 'Invoice total mismatch' if invoice_mismatch?
        else
          @state_errors << 'Invoices missing'
        end
        @state_errors << 'One or more invoice documents are missing' unless invoices.visible.all_documents_attached?
        @state_errors.empty?
      end

      def after_approve(user)
        bubble_event_to_project_tasks(:approve)
      end

      def allow_approve?
        @state_errors = []
        @state_errors << 'There are no submitted or approved Invoices' unless invoices.where(state: %i{submitted approved}).any?
        @state_errors << 'There are pending invoices' if invoices.pending.any?
        @state_errors << 'There are rejected invoices' if invoices.rejected.any?
        @state_errors << 'There are rejected change orders' if change_orders.rejected.any?
        @state_errors.empty?
      end

      def allow_auto_approve?
        allow_approve? &&
          all_invoices_approved? &&
          all_change_orders_approved?
      end

      def all_invoices_approved?
        invoices.reload
        invoices.submitted.none? &&
          invoices.approved.any? &&
          invoices.rejected.none?
      end

      def all_change_orders_approved?
        change_orders.reload
        change_orders.visible.none? ||
          (change_orders.pending.none? && change_orders.approved.any? && change_orders.rejected.none?)
      end

      def after_last_change_order_approval
        after_last_invoice_approval
      end

      def after_last_invoice_approval
        trigger_event(event_name: :approve) if allow_auto_approve?
      end

      def after_reject(user=nil)
        bubble_event_to_project_tasks(:reject)
      end

      def after_withdraw(user=nil)
        archive_project_tasks(recurse: true)
      end

      def after_revert_to_pending(user)
        invoices.reload
        invoices.approved.each do |invoice|
          invoice.trigger_event(event_name: :revert_to_pending)
        end
        change_orders.reload
        #change_orders.approved.each do |change_order|
          #change_order.trigger_event(event_name: :reset_approval)
        #end
      end

      def approval_lead_time
        APPROVAL_LEAD_TIME
      end

      def bubble_event_to_project_tasks(event_name)
        task_event = case event_name.to_sym
                     when :approve, :reject
                       event_name.to_sym
                     when :withdraw
                       :archive
                     end
        project_tasks.pending.each do |task|
          task.trigger_event(event_name: task_event) if task.permitted_state_events.include?(task_event)
        end
      end

    end
  end
end
