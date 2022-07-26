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

      aasm column: :state do
        state :pending
        state :in_progress
        state :submitted
        state :internally_approved
        state :externally_approved
        state :funded
      end

      event :start do
        transitions from: [:pending], to: :in_progress
      end

      event :submit do
        transitions from: [:in_progress], to: :submitted
      end

      event :approve_internal do
        transitions from: [:submitted], to: :internally_approved
      end

      event :approve_external do
        transitions from: [:submitted], to: :externally_approved
      end

      event :reject do
        transitions from: [:internally_approved, :externally_approved], to: :submitted
      end

      event :fund do
        transitions from: [:externally_approved], to: :funded
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
      
    end
  end
end
