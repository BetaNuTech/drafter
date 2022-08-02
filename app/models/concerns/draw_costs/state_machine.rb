module DrawCosts
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
         state :submitted
         state :deleted

         event :submit do
           transitions from: [:pending], to: :submitted
         end

         event :cancel do
           transitions from: [:pending, :submitted], to: :deleted
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
          'submitted' => 'success',
          'deleted' => 'light'
        }.fetch(state, 'primary')
      end
    end
  end
end
