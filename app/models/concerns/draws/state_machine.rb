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
      APPROVED_STATES = %i{ internally_approved externally_approved funded }.freeze
      VISIBLE_STATES = %i{ pending submitted internally_approved externally_approved funded rejected }.freeze
      ALLOW_DRAW_COST_CHANGE_STATES = %i{pending}

      scope :visible, -> { where(state: VISIBLE_STATES) }

      aasm column: :state do
        state :pending
        state :submitted
        state :internally_approved
        state :externally_approved
        state :funded
        state :rejected
        state :withdrawn

        event :submit do
          transitions from: :in_progress, to: :submitted,
            guard: Proc.new {|*args| draws.any? },
            after: Proc.new {|*args| submit_draw_costs(*args) }
        end

        event :approve_internal do
          transitions from: :submitted, to: :internally_approved
        end

        event :approve_external do
          transitions from: :internally_approved, to: :externally_approved
        end

        event :reject do
          transitions from: %i{ internally_approved externally_approved }, to: :rejected
        end

        event :withdraw do
          transitions from: %i{ pending submitted }, to: :withdrawn
        end

        event :fund do
          transitions from: :externally_approved, to: :funded
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
          'in_progress' => 'warning',
          'submitted' => 'danger',
          'internally_approved' => 'info',
          'externally_approved' => 'primary',
          'funded' => 'success'
        }.fetch(state, 'light')
      end

      def approved?
        APPROVED_STATES.include?(state)
      end

      def allow_draw_cost_changes?
        ALLOW_DRAW_COST_CHANGE_STATES.include?(state)
      end

      def submit_draw_costs(user)
        draw_costs.reload
        draw_costs.pending.each do |draw_cost|
          draw_cost.trigger_event(event_name: :submit, user: user)
        end
      end

    end
  end
end
