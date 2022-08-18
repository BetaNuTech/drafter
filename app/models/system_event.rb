# frozen_string_literal: true

# == Schema Information
#
# Table name: system_events
#
#  id                :uuid             not null, primary key
#  debug             :text
#  description       :string
#  event_source_type :string           not null
#  incidental_type   :string
#  severity          :integer          default("unknown")
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  event_source_id   :uuid             not null
#  incidental_id     :uuid
#
# Indexes
#
#  system_events_idx1  (event_source_type,event_source_id,incidental_type,incidental_id,severity)
#
class SystemEvent < ApplicationRecord
  ### Constants
  SEVERITIES = %i[unknown notification debug info warn error fatal].freeze

  enum severity: SEVERITIES, _default: :unknown

  ### Associations
  belongs_to :event_source, polymorphic: true
  belongs_to :incidental, polymorphic: true, required: false
  
  after_create_commit -> (system_event) {
    target =  "#{system_event.event_source_type}_#{system_event.event_source_id}_system_events"
    broadcast_prepend_to target,
                         partial: "system_events/system_event",
                         locals: {system_event: self},
                         target: target
  }

  def self.log(event_source:, description:, incidental: nil, debug: nil, severity: :info)
    system_event = create(
      event_source:,
      incidental:,
      description:,
      debug:,
      severity:
    )

    log_message = format('SystemEvent[%s] for %s[%s] -- %s', system_event.severity, system_event.event_source_type, system_event.event_source_id, system_event.description)

    case severity
    when :debug, 0
      Rails.logger.debug log_message
    when :info, 1
      Rails.logger.info log_message
    else
      Rails.logger.warn log_message
    end

    system_event
  end
end
