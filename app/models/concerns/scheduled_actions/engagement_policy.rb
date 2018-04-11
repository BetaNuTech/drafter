module ScheduledActions
  module EngagementPolicy
    extend ActiveSupport::Concern

    included do

      attr_accessor :completion_message, :completion_action

      def update_compliance_record
        EngagementPolicyScheduler.new.handle_scheduled_action_completion(self)
      end

    end
  end
end
