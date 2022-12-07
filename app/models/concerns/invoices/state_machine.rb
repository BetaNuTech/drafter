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
          transitions from: %i{ pending rejected }, to: :submitted
        end

        event :process do
          transitions from: %i{ submitted }, to: :processing
        end

        event :complete_processing do
          transitions from: %i{ processing }, to: :processed
        end

        event :approve do
          transitions from: %i{ submitted processed rejected }, to: :approved,
            guard: Proc.new { allow_approve? },
            after: Proc.new{|*args| after_approve(*args)}
        end

        event :reject do
          transitions from: %i{ submitted processed approved }, to: :rejected,
            guard: Proc.new { allow_reject? },
            after: Proc.new{|*args| after_reject(*args)}
        end

        event :reset_approval do
          transitions from: %i{approved rejected}, to: :submitted,
            after: Proc.new{|*args| after_reset_approval(*args)}
        end

        event :remove do
          transitions from: %i{pending submitted processed rejected approved}, to: :removed,
            guard: Proc.new { allow_remove? },
            after: Proc.new {|*args| after_remove(*args)}
        end

        event :fail_processing do
          transitions from: [:processing], to: :processing_failed
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
        if draw_cost.invoices.submitted.none? && draw_cost.invoices.approved.any?
          draw_cost.trigger_event(event_name: :approve, user: user)
        end
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
      end

      def allow_remove?
        draw_cost.allow_invoice_changes?
      end

      def after_reset_approval(user)
        draw_cost.trigger_event(event_name: :revert_to_pending, user: user) if
          draw_cost.permitted_state_events.include?(:revert_to_pending)
      end

    end

  end
end
