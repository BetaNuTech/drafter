module DrawCostSubmissions
  module StateMachine
    extend ActiveSupport::Concern

    class_methods do
      def state_names
        DrawCostSubmission.aasm.states.map{|s| s.name.to_s}
      end
    end

    included do
      class TransitionError < StandardError; end;

      ACTIVE_STATES = [:pending, :submitted, :approved]

      scope :active, -> { where(state: ACTIVE_STATES) }

      include AASM
      aasm column: :state do
        state :pending
        state :submitted
        state :approved
        state :rejected
        state :removed

        event :submit do
          transitions from: [:pending], to: :submitted,
            guard: Proc.new{ |*args| self.valid_pending_submission? }
        end

        event :approve do
          transitions from: [:submitted], to: :approved,
            after: Proc.new {|*args|
              if args.any?
                approve_submission(*args)
              else
                raise TransitionError.new('A Draw Cost Submission must be approved by a user')
              end
            }
        end

        event :reject do
          transitions from: [:submitted, :approved], to: :rejected,
            after: Proc.new {|*args| reject_submission }
        end

        event :remove do
          transitions from: [:pending, :submitted], to: :removed
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


    end

  end
end
