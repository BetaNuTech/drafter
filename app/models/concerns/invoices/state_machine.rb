module Invoices
  module StateMachine
    extend ActiveSupport::Concern

    class_methods do
      def state_names
        Invoice.aasm.states.map{|s| s.name.to_s}
      end
    end

    included do

      scope :visible, -> { where.not(state: :removed) }
      scope :totalable, -> { where.not(state: %i{removed}) }

      include AASM

      aasm column: :state do
        state :pending
        state :submitted
        state :processing
        state :processed
        state :processing_failed
        state :approved
        state :rejected
        state :removed

        event :submit do
          transitions from: %i{ pending rejected }, to: :submitted,
            after: Proc.new{|*args| after_submit(*args)}
        end

        event :process do
          transitions from: %i{ submitted }, to: :processing
        end

        event :complete_processing do
          transitions from: %i{ processing }, to: :processed,
            after: Proc.new {|*args| after_processing(*args)}
        end

        event :approve do
          transitions from: %i{ submitted processing processed processing_failed rejected }, to: :approved,
            guard: Proc.new { allow_approve? },
            after: Proc.new{|*args| after_approve(*args)}
        end

        event :reject do
          transitions from: %i{ submitted processed processing_failed approved }, to: :rejected,
            guard: Proc.new { allow_reject? },
            after: Proc.new{|*args| after_reject(*args)}
        end

        event :reset_approval do
          transitions from: %i{approved rejected processing_failed}, to: :submitted,
            after: Proc.new{|*args| after_reset_approval(*args)}
        end

        event :remove do
          transitions from: %i{pending submitted processed processing_failed rejected approved}, to: :removed,
            guard: Proc.new { allow_remove? },
            after: Proc.new {|*args| after_remove(*args)}
        end

        event :fail_processing do
          transitions from: %i{ processing }, to: :processing_failed,
            after: Proc.new {|*args| after_processing(*args)}
        end

        event :fail_processing_attempt do
          transitions from: %i{ processing }, to: :submitted
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
          'pending' => 'secondary',
          'submitted' => 'warning',
          'processing' => 'warning',
          'processed' => 'warning',
          'approved' => 'success',
          'rejected' => 'danger',
          'removed' => 'danger'
        }.fetch(state, 'primary')
      end

      def after_approve(user)
        draw_cost.invoices.reload
        draw_cost.after_last_invoice_approval
      end

      def after_reject(user)
        draw_cost.trigger_event(event_name: :reject, user: user)
      end

      def allow_reject?
        draw_cost.draw.allow_invoice_approvals?
      end

      def allow_approve?
        draw_cost.draw.allow_invoice_approvals?
      end

      def after_remove(user)
        draw_cost.trigger_event(event_name: :revert_to_pending, user: user) if
          draw_cost.permitted_state_events.include?(:revert_to_pending)
        archive_project_tasks
      end

      def allow_remove?
        draw_cost.allow_invoice_changes?
      end

      def after_reset_approval(user)
        # Reset Draw Cost to pending state
        draw_cost.trigger_event(event_name: :revert_to_pending, user: user) if
          draw_cost.permitted_state_events.include?(:revert_to_pending)

        # Clear pending tasks and create a new approve task
        project_tasks.pending.each{|task| task.trigger_event(event_name: :archive, user: user)}
        create_task(assignee: nil, action: :approve)
      end

      def after_submit(user)
        delay(queue: Invoice::PROCESSING_QUEUE).start_analysis
      end

      def after_processing(user)
        # Create invoice review task
        create_task(assignee: nil, action: :approve)
      end

      def displayed_invoice_state_name
        case state
        when 'processing', 'processed', 'processing_failed'
          'submitted'.titleize
        else
          state.titleize
        end
      end

      def document_processing_display_state
        return nil unless document.attached?

        case state
        when 'processing', 'processed', 'failed_processing'
          state.titleize
        else
          nil
        end
      end
    end

  end
end
