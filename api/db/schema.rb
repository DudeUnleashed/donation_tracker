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

ActiveRecord::Schema[7.1].define(version: 2025_05_26_101919) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "audit_logs", force: :cascade do |t|
    t.bigint "website_user_id"
    t.string "action"
    t.string "record_type"
    t.bigint "record_id"
    t.jsonb "changes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["record_type", "record_id"], name: "index_audit_logs_on_record_type_and_record_id"
    t.index ["website_user_id"], name: "index_audit_logs_on_website_user_id"
  end

  create_table "csv_imports", force: :cascade do |t|
    t.string "filename", null: false
    t.string "provider", default: "generic", null: false
    t.bigint "uploaded_by", null: false
    t.string "status", default: "pending", null: false
    t.integer "total_rows", default: 0
    t.integer "processed_rows", default: 0
    t.integer "failed_rows", default: 0
    t.text "error_details"
    t.text "processing_summary"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_csv_imports_on_created_at"
    t.index ["provider", "status"], name: "index_csv_imports_on_provider_and_status"
    t.index ["status"], name: "index_csv_imports_on_status"
    t.index ["uploaded_by"], name: "index_csv_imports_on_uploaded_by"
  end

  create_table "donations", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.decimal "amount", precision: 10, scale: 2, null: false
    t.string "platform"
    t.string "transaction_id"
    t.datetime "donation_date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "currency", default: "USD"
    t.index ["currency"], name: "index_donations_on_currency"
    t.index ["donation_date"], name: "index_donations_on_donation_date"
    t.index ["platform"], name: "index_donations_on_platform"
    t.index ["transaction_id"], name: "index_donations_on_transaction_id", unique: true, where: "(transaction_id IS NOT NULL)"
    t.index ["user_id", "amount", "donation_date"], name: "index_donations_on_user_amount_date"
    t.index ["user_id"], name: "index_donations_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "username"
    t.string "email"
    t.string "platform_id"
    t.decimal "lifetime_donations", precision: 10, scale: 2, default: "0.0"
    t.datetime "last_donation_date"
    t.string "current_status", default: "active"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email"
    t.index ["platform_id"], name: "index_users_on_platform_id"
  end

  create_table "website_users", force: :cascade do |t|
    t.string "username", null: false
    t.string "email", null: false
    t.string "password_digest", null: false
    t.string "role", default: "viewer"
    t.datetime "last_login_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_website_users_on_email", unique: true
    t.index ["username"], name: "index_website_users_on_username", unique: true
  end

  add_foreign_key "csv_imports", "website_users", column: "uploaded_by"
  add_foreign_key "donations", "users"
end
