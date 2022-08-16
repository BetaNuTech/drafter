module DrawCostRequests
  module StateMachine
    extend ActiveSupport::Concern

    EXISTING_STATES = ['pending', 'submitted', 'approved']

    class_methods do
      def state_names
        DrawCostRequests.aasm.states.map{|s| s.name.to_s}
      end
    end

    included do
      include AASM

      aasm column: :state do
        state :pending
        state :submitted
        state :approved
        state :rejected

        event :submit do
          transitions from: [:pending], to: :submitted
        end

        event :approve do
          transitions from: [:submitted], to: :approved
        end

        event :reject do
          transitions from: [:submitted, :approved], to: :rejected
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
          'approved' => 'success',
          'rejected' => 'danger'
        }.fetch(state, 'primary')
      end
      
    end
  end
end
