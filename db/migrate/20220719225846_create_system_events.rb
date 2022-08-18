class CreateSystemEvents < ActiveRecord::Migration[7.0]
  def change
    create_table :system_events, id: :uuid do |t|
      t.string :event_source_type, null: false
      t.uuid :event_source_id, null: false
      t.string :incidental_type
      t.uuid :incidental_id
      t.string :description
      t.text :debug
      t.integer :severity, default: 0

      t.timestamps
    end
    add_index :system_events, [:event_source_type, :event_source_id, :incidental_type, :incidental_id, :severity], name: 'system_events_idx1'
  end
end
