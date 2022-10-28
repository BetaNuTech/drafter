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
      scope :totalable, -> { where.not(state: %i{removed rejected}) }

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
          transitions from: [:pending], to: :submitted
        end

        event :process do
          transitions from: [:submitted], to: :processing
        end

        event :complete_processing do
          transitions from: [:processing], to: :processed
        end

        event :approve do
          transitions from: [:submitted, :processed], to: :approved
        end

        event :reject do
          transitions from: [:submitted, :processed], to: :rejected
        end

        event :remove do
          transitions from: %i{pending submitted processed}, to: :removed
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

    end

  end
end
