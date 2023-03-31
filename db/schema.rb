# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.0].define(version: 2023_03_31_163344) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "active_storage_attachments", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.uuid "record_id", null: false
    t.uuid "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "change_orders", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "project_cost_id", null: false
    t.uuid "draw_cost_id", null: false
    t.uuid "funding_source_id", null: false
    t.decimal "amount"
    t.text "description"
    t.string "external_task_id"
    t.datetime "integration_attempt_at"
    t.integer "integration_attempt_number"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "state", default: "pending"
    t.index ["draw_cost_id", "state"], name: "index_change_orders_on_draw_cost_id_and_state"
    t.index ["funding_source_id"], name: "index_change_orders_on_funding_source_id"
    t.index ["project_cost_id"], name: "index_change_orders_on_project_cost_id"
  end

  create_table "delayed_jobs", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.integer "priority", default: 0, null: false
    t.integer "attempts", default: 0, null: false
    t.text "handler", null: false
    t.text "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string "locked_by"
    t.string "queue"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["priority", "run_at"], name: "delayed_jobs_priority"
  end

  create_table "draw_costs", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "draw_id", null: false
    t.uuid "project_cost_id", null: false
    t.uuid "approver_id"
    t.decimal "total", default: "0.0", null: false
    t.string "state", default: "pending", null: false
    t.datetime "approved_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["draw_id", "project_cost_id", "approver_id"], name: "draw_costs_assoc_idx"
    t.index ["draw_id", "state"], name: "draw_costs_draw_state_idx"
    t.index ["draw_id"], name: "index_draw_costs_on_draw_id"
    t.index ["project_cost_id"], name: "index_draw_costs_on_project_cost_id"
  end

  create_table "draw_documents", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "user_id"
    t.uuid "draw_id", null: false
    t.uuid "approver_id"
    t.text "notes"
    t.integer "documenttype", default: 0, null: false
    t.datetime "approved_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "state", default: "pending"
    t.index ["approver_id"], name: "index_draw_documents_on_approver_id"
    t.index ["documenttype"], name: "index_draw_documents_on_documenttype"
    t.index ["draw_id", "user_id"], name: "draw_documents_assoc_idx"
    t.index ["draw_id"], name: "index_draw_documents_on_draw_id"
    t.index ["state"], name: "index_draw_documents_on_state"
    t.index ["user_id"], name: "index_draw_documents_on_user_id"
  end

  create_table "draws", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "project_id", null: false
    t.uuid "user_id", null: false
    t.uuid "organization_id", null: false
    t.uuid "approver_id"
    t.integer "index", default: 0, null: false
    t.decimal "amount", default: "0.0", null: false
    t.string "state", default: "pending", null: false
    t.string "reference"
    t.datetime "approved_at"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "invoice_auto_approvals_completed", default: false
    t.index ["approver_id"], name: "index_draws_on_approver_id"
    t.index ["organization_id"], name: "index_draws_on_organization_id"
    t.index ["project_id", "user_id", "organization_id", "approver_id", "state"], name: "draws_assoc_idx"
    t.index ["project_id"], name: "index_draws_on_project_id"
    t.index ["state", "invoice_auto_approvals_completed"], name: "draws_auto_approval_idx"
    t.index ["user_id"], name: "index_draws_on_user_id"
  end

  create_table "invoices", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "draw_cost_id"
    t.uuid "user_id"
    t.uuid "approver_id"
    t.string "state", default: "pending", null: false
    t.string "description"
    t.decimal "amount", default: "0.0", null: false
    t.boolean "manual_approval_required", default: true, null: false
    t.boolean "audit", default: false, null: false
    t.boolean "multi_invoice"
    t.datetime "approved_at"
    t.string "approved_by_desc"
    t.decimal "ocr_amount"
    t.datetime "ocr_processed"
    t.json "ocr_data"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "automatically_approved", default: false
    t.index ["approver_id"], name: "index_invoices_on_approver_id"
    t.index ["draw_cost_id", "user_id", "approver_id"], name: "invoices_assoc_idx"
    t.index ["draw_cost_id"], name: "index_invoices_on_draw_cost_id"
    t.index ["state", "audit", "manual_approval_required", "ocr_processed"], name: "invoices_state_idx"
    t.index ["user_id"], name: "index_invoices_on_user_id"
  end

  create_table "organizations", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "project_cost_samples", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name", null: false
    t.integer "cost_type", null: false
    t.integer "approval_lead_time"
    t.boolean "standard", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "drawable", default: true
    t.boolean "change_requestable", default: true
    t.boolean "change_request_allowed", default: true
    t.decimal "total", default: "0.0", null: false
    t.index ["standard", "name"], name: "project_cost_samples_idx"
  end

  create_table "project_costs", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "project_id", null: false
    t.integer "cost_type", null: false
    t.string "name", null: false
    t.string "state", default: "pending", null: false
    t.integer "approval_lead_time", default: 0, null: false
    t.decimal "total", default: "0.0", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "drawable", default: true
    t.boolean "change_requestable", default: true
    t.boolean "change_request_allowed", default: true
    t.index ["drawable", "change_requestable", "change_request_allowed"], name: "project_costs_drawable_idx"
    t.index ["project_id", "state"], name: "project_costs_project_idx"
    t.index ["project_id"], name: "index_project_costs_on_project_id"
  end

  create_table "project_roles", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name", null: false
    t.string "slug", null: false
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["slug"], name: "index_project_roles_on_slug"
  end

  create_table "project_tasks", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "project_id", null: false
    t.string "origin_type"
    t.uuid "origin_id"
    t.uuid "assignee_id"
    t.uuid "approver_id"
    t.string "state", default: "new", null: false
    t.string "remoteid"
    t.string "name", null: false
    t.string "assignee_name"
    t.string "approver_name"
    t.string "attachment_url"
    t.string "preview_url"
    t.datetime "reviewed_at"
    t.datetime "due_at"
    t.datetime "completed_at"
    t.text "description", null: false
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "remote_updated_at"
    t.datetime "remote_last_checked_at"
    t.index ["approver_id"], name: "index_project_tasks_on_approver_id"
    t.index ["assignee_id"], name: "index_project_tasks_on_assignee_id"
    t.index ["origin_type", "origin_id"], name: "idx_project_tasks_origin"
    t.index ["origin_type", "origin_id"], name: "index_project_tasks_on_origin"
    t.index ["project_id", "assignee_id", "approver_id", "state"], name: "idx_project_tasks_general"
    t.index ["project_id"], name: "index_project_tasks_on_project_id"
    t.index ["remoteid", "remote_updated_at", "remote_last_checked_at"], name: "idx_project_tasks_remote"
  end

  create_table "project_users", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "project_id", null: false
    t.uuid "user_id", null: false
    t.uuid "project_role_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["project_id", "user_id"], name: "project_users_idx", unique: true
    t.index ["project_id"], name: "index_project_users_on_project_id"
    t.index ["project_role_id"], name: "index_project_users_on_project_role_id"
    t.index ["user_id"], name: "index_project_users_on_user_id"
  end

  create_table "projects", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "roles", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name", null: false
    t.string "slug"
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["slug"], name: "index_roles_on_slug", unique: true
  end

  create_table "system_events", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "event_source_type", null: false
    t.uuid "event_source_id", null: false
    t.string "incidental_type"
    t.uuid "incidental_id"
    t.string "description"
    t.text "debug"
    t.integer "severity", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["event_source_type", "event_source_id", "incidental_type", "incidental_id", "severity"], name: "system_events_idx1"
  end

  create_table "user_profiles", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "user_id"
    t.string "name_prefix"
    t.string "first_name"
    t.string "last_name"
    t.string "name_suffix"
    t.string "title"
    t.string "phone"
    t.text "notes"
    t.jsonb "appsettings"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_user_profiles_on_user_id", unique: true
  end

  create_table "users", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string "unconfirmed_email"
    t.integer "failed_attempts", default: 0, null: false
    t.string "unlock_token"
    t.datetime "locked_at"
    t.string "timezone", default: "Pacific Time (US & Canada)", null: false
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "role_id", null: false
    t.uuid "organization_id"
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["organization_id"], name: "index_users_on_organization_id"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["role_id"], name: "index_users_on_role_id"
    t.index ["unlock_token"], name: "index_users_on_unlock_token", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "change_orders", "draw_costs"
  add_foreign_key "change_orders", "project_costs"
  add_foreign_key "change_orders", "project_costs", column: "funding_source_id"
  add_foreign_key "draw_costs", "draws"
  add_foreign_key "draw_costs", "project_costs"
  add_foreign_key "draw_costs", "users", column: "approver_id"
  add_foreign_key "draw_documents", "draws"
  add_foreign_key "draw_documents", "users"
  add_foreign_key "draw_documents", "users", column: "approver_id"
  add_foreign_key "draws", "organizations"
  add_foreign_key "draws", "projects"
  add_foreign_key "draws", "users"
  add_foreign_key "draws", "users", column: "approver_id"
  add_foreign_key "invoices", "draw_costs"
  add_foreign_key "invoices", "users"
  add_foreign_key "invoices", "users", column: "approver_id"
  add_foreign_key "project_costs", "projects"
  add_foreign_key "project_tasks", "projects"
  add_foreign_key "project_tasks", "users", column: "approver_id"
  add_foreign_key "project_tasks", "users", column: "assignee_id"
  add_foreign_key "project_users", "project_roles"
  add_foreign_key "project_users", "projects"
  add_foreign_key "project_users", "users"
  add_foreign_key "users", "organizations"
  add_foreign_key "users", "roles"
end
