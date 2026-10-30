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

ActiveRecord::Schema[8.1].define(version: 2026_10_30_020000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pgcrypto"

  create_table "action_text_rich_texts", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name", null: false
    t.text "body"
    t.string "record_type", null: false
    t.uuid "record_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["record_type", "record_id", "name"], name: "index_action_text_rich_texts_uniqueness", unique: true
  end

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

  create_table "animal_categories", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "zone_id", null: false
    t.string "name", limit: 100, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "hidden", default: false, null: false
    t.index ["zone_id", "name"], name: "idx_animal_categories_zone_name", unique: true
    t.index ["zone_id"], name: "index_animal_categories_on_zone_id"
  end

  create_table "animals", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "zone_id", null: false
    t.string "name", limit: 100
    t.string "species", limit: 100, null: false
    t.integer "gender", limit: 2, default: 2, null: false
    t.date "birth_date"
    t.date "acquired_at"
    t.text "acquisition_note"
    t.integer "cites_grade", limit: 2, default: 0, null: false
    t.boolean "active", default: true, null: false
    t.text "note"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "animal_category_id"
    t.integer "individual_count", default: 1, null: false
    t.index ["animal_category_id"], name: "index_animals_on_animal_category_id"
    t.index ["zone_id"], name: "index_animals_on_zone_id"
    t.check_constraint "individual_count >= 1", name: "chk_animals_individual_count"
  end

  create_table "expense_records", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "created_by_id"
    t.date "spent_on", null: false
    t.integer "category", null: false
    t.integer "amount", null: false
    t.text "description", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["category"], name: "index_expense_records_on_category"
    t.index ["created_by_id"], name: "index_expense_records_on_created_by_id"
    t.index ["spent_on"], name: "index_expense_records_on_spent_on"
    t.check_constraint "amount >= 0", name: "chk_expense_amount"
  end

  create_table "feeding_records", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "animal_id", null: false
    t.uuid "created_by_id"
    t.datetime "fed_at", null: false
    t.string "food_type", limit: 100, null: false
    t.integer "amount_g"
    t.text "note"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["animal_id"], name: "index_feeding_records_on_animal_id"
    t.index ["created_by_id"], name: "index_feeding_records_on_created_by_id"
    t.index ["fed_at"], name: "index_feeding_records_on_fed_at"
  end

  create_table "health_records", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "animal_id", null: false
    t.uuid "created_by_id"
    t.date "recorded_on", null: false
    t.decimal "weight_kg", precision: 6, scale: 2
    t.integer "condition", default: 0, null: false
    t.text "note"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["animal_id", "recorded_on"], name: "idx_health_records_animal_date"
    t.index ["animal_id"], name: "index_health_records_on_animal_id"
    t.index ["created_by_id"], name: "index_health_records_on_created_by_id"
    t.check_constraint "condition = ANY (ARRAY[0, 1, 2])", name: "chk_health_condition"
  end

  create_table "notices", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "created_by_id"
    t.integer "category", default: 0, null: false
    t.text "body"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "title", limit: 100, null: false
    t.index ["category"], name: "index_notices_on_category"
    t.index ["created_by_id"], name: "index_notices_on_created_by_id"
  end

  create_table "sales_records", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "created_by_id"
    t.date "sold_on", null: false
    t.integer "source", null: false
    t.integer "amount", null: false
    t.text "note"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_by_id"], name: "index_sales_records_on_created_by_id"
    t.index ["sold_on", "source"], name: "index_sales_records_on_sold_on_and_source", unique: true
    t.check_constraint "amount >= 0", name: "chk_sales_amount"
  end

  create_table "solid_cache_entries", force: :cascade do |t|
    t.binary "key", null: false
    t.binary "value", null: false
    t.datetime "created_at", null: false
    t.bigint "key_hash", null: false
    t.integer "byte_size", null: false
    t.index ["byte_size"], name: "index_solid_cache_entries_on_byte_size"
    t.index ["key_hash", "byte_size"], name: "index_solid_cache_entries_on_key_hash_and_byte_size"
    t.index ["key_hash"], name: "index_solid_cache_entries_on_key_hash", unique: true
  end

  create_table "users", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "email", limit: 255, null: false
    t.string "password_digest", null: false
    t.string "name", limit: 100, null: false
    t.integer "role", limit: 2, default: 1, null: false
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "position", limit: 2
    t.boolean "is_team_leader", default: false, null: false
    t.date "hired_on"
    t.date "contract_ends_on"
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  create_table "zones", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name", limit: 100, null: false
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_zones_on_name", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "animal_categories", "zones"
  add_foreign_key "animals", "animal_categories", on_delete: :nullify
  add_foreign_key "animals", "zones"
  add_foreign_key "expense_records", "users", column: "created_by_id"
  add_foreign_key "feeding_records", "animals"
  add_foreign_key "feeding_records", "users", column: "created_by_id"
  add_foreign_key "health_records", "animals"
  add_foreign_key "health_records", "users", column: "created_by_id"
  add_foreign_key "notices", "users", column: "created_by_id"
  add_foreign_key "sales_records", "users", column: "created_by_id"
end
