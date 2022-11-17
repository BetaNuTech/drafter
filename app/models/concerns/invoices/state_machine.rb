module Invoices
  module StateMachine
    extend ActiveSupport::Concern

    class_methods do
      def state_names
        DrawCosts.aasm.states.map{|s| s.name.to_s}
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
          transitions from: %i{ submitted processed }, to: :approved,
            guard: Proc.new { allow_approve? },
            after: Proc.new{|*args| after_approve(*args)}
        end

        event :reject do
          transitions from: %i{ submitted processed }, to: :rejected,
            guard: Proc.new { allow_reject? },
            after: Proc.new{|*args| after_reject(*args)}
        end

        event :remove do
          transitions from: %i{pending submitted processed rejected}, to: :removed
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
        draw.allow_invoice_approvals?
      end

      def allow_approve?
        draw.allow_invoice_approvals?
      end

    end

  end
end
