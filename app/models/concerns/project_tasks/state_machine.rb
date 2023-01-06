module ProjectTasks
  module StateMachine
    extend ActiveSupport::Concern

    PENDING_STATES = %w{new needs_review needs_consult rejected}

    class_methods do
      def state_names
        ProjectTask.aasm.states.map{|s| s.name.to_s}
      end
    end

    included do
      include AASM

      scope :pending, -> { where(state: ProjectTasks::StateMachine::PENDING_STATES) }

      aasm column: :state do
        state :new
        state :needs_review
        state :needs_consult
        state :rejected
        state :verified
        state :archived

        event :submit_for_review do
          transitions from: %i{new archived}, to: :needs_review
        end

        event :submit_for_consult do
          transitions from: %i{new needs_review archived}, to: :needs_consult
        end

        event :verify do
          transitions from: %i{new needs_review needs_consult rejected}, to: :verified
        end

        event :reject do
          transitions from: %i{new needs_review needs_consult verified archived}, to: :rejected
        end

        event :archive do
          transitions from: %i{new needs_review needs_consult verified rejected}, to: :archived
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

      def pending?
        PENDING_STATES.include?(state)
      end

      def due?
        pending? && Time.current >= due_at
      end

    end
  end
end
