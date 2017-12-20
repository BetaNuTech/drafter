# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20171220225135) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"
  enable_extension "pgcrypto"

  create_table "delayed_jobs", force: :cascade do |t|
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

  create_table "lead_preferences", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "lead_id"
    t.integer "min_area"
    t.integer "max_area"
    t.decimal "min_price"
    t.decimal "max_price"
    t.datetime "move_in"
    t.decimal "baths"
    t.boolean "pets"
    t.boolean "smoker"
    t.boolean "washerdryer"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "beds"
  end

  create_table "lead_sources", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name"
    t.boolean "incoming"
    t.string "slug"
    t.boolean "active"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "api_token"
    t.index ["active", "api_token"], name: "index_lead_sources_on_active_and_api_token"
  end

  create_table "leads", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "user_id"
    t.uuid "lead_source_id"
    t.string "title"
    t.string "first_name"
    t.string "last_name"
    t.string "referral"
    t.string "state"
    t.text "notes"
    t.datetime "first_comm"
    t.datetime "last_comm"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "property_id"
    t.string "phone1"
    t.string "phone2"
    t.string "fax"
    t.string "email"
  end

  create_table "properties", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name"
    t.string "address1"
    t.string "address2"
    t.string "address3"
    t.string "city"
    t.string "state"
    t.string "zip"
    t.string "country"
    t.string "organization"
    t.string "contact_name"
    t.string "phone"
    t.string "fax"
    t.string "email"
    t.integer "units"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "active", default: true
    t.index ["active"], name: "index_properties_on_active"
  end

  create_table "property_listings", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "code"
    t.string "description"
    t.uuid "property_id"
    t.uuid "source_id"
    t.boolean "active", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["active", "code"], name: "index_property_listings_on_active_and_code"
    t.index ["property_id", "source_id", "active"], name: "index_property_listings_on_property_id_and_source_id_and_active"
  end

end
