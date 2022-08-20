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

ActiveRecord::Schema[7.0].define(version: 2022_08_23_234025) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pgcrypto"
  enable_extension "plpgsql"

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

  create_table "draw_cost_requests", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "draw_id", null: false
    t.uuid "draw_cost_id", null: false
    t.uuid "user_id", null: false
    t.uuid "organization_id", null: false
    t.string "state", default: "pending", null: false
    t.decimal "amount", default: "0.0", null: false
    t.decimal "total", default: "0.0", null: false
    t.text "description"
    t.boolean "plan_change", default: false, null: false
    t.text "plan_change_reason"
    t.integer "alert", default: 0, null: false
    t.boolean "audit", default: false, null: false
    t.date "approval_due_date"
    t.uuid "approver_id"
    t.datetime "approved_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["draw_cost_id"], name: "index_draw_cost_requests_on_draw_cost_id"
    t.index ["draw_id"], name: "index_draw_cost_requests_on_draw_id"
    t.index ["organization_id"], name: "index_draw_cost_requests_on_organization_id"
    t.index ["user_id"], name: "index_draw_cost_requests_on_user_id"
  end

  create_table "draw_cost_samples", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name", null: false
    t.integer "cost_type", null: false
    t.integer "approval_lead_time"
    t.boolean "standard", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name", "standard"], name: "draw_cost_samples_idx"
  end

  create_table "draw_cost_submissions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "draw_cost_request_id"
    t.uuid "approver_id"
    t.boolean "audit", default: false, null: false
    t.boolean "manual_approval_required", default: false, null: false
    t.boolean "multi_invoice", default: false, null: false
    t.boolean "ocr_approval"
    t.date "approval_due_date"
    t.date "approved_at"
    t.decimal "amount", default: "0.0", null: false
    t.string "state", default: "pending", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["approver_id"], name: "index_draw_cost_submissions_on_approver_id"
    t.index ["draw_cost_request_id"], name: "index_draw_cost_submissions_on_draw_cost_request_id"
  end

  create_table "draw_costs", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "draw_id", null: false
    t.integer "cost_type", null: false
    t.string "name", null: false
    t.string "state", default: "pending", null: false
    t.integer "approval_lead_time", default: 0, null: false
    t.decimal "total", default: "0.0", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["draw_id", "state"], name: "draw_costs_idx"
    t.index ["draw_id"], name: "index_draw_costs_on_draw_id"
  end

  create_table "draws", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "project_id", null: false
    t.integer "index", default: 1, null: false
    t.string "name", null: false
    t.string "state", default: "pending", null: false
    t.string "reference"
    t.decimal "total"
    t.uuid "approver"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["project_id", "index"], name: "index_draws_on_project_id_and_index", unique: true
    t.index ["project_id"], name: "index_draws_on_project_id"
  end

  create_table "organizations", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "project_roles", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name", null: false
    t.string "slug", null: false
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["slug"], name: "index_project_roles_on_slug"
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
    t.decimal "budget", default: "0.0", null: false
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
    t.string "company"
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

  add_foreign_key "draw_cost_requests", "draw_costs"
  add_foreign_key "draw_cost_requests", "draws"
  add_foreign_key "draw_cost_requests", "organizations"
  add_foreign_key "draw_cost_requests", "users"
  add_foreign_key "draw_cost_submissions", "draw_cost_requests"
  add_foreign_key "draw_cost_submissions", "users", column: "approver_id"
  add_foreign_key "draw_costs", "draws"
  add_foreign_key "draws", "projects"
  add_foreign_key "project_users", "project_roles"
  add_foreign_key "project_users", "projects"
  add_foreign_key "project_users", "users"
  add_foreign_key "users", "organizations"
  add_foreign_key "users", "roles"
end
