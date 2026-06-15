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

ActiveRecord::Schema[8.0].define(version: 2026_06_08_120000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "companies", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "description"
  end

  create_table "job_applications", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "job_post_id", null: false
    t.datetime "applied_at"
    t.string "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "contact_info"
    t.boolean "followed_up", default: false, null: false
    t.index ["job_post_id"], name: "index_job_applications_on_job_post_id"
    t.index ["user_id"], name: "index_job_applications_on_user_id"
  end

  create_table "job_posts", force: :cascade do |t|
    t.integer "company_id", null: false
    t.string "title"
    t.string "website"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "description"
    t.string "location"
    t.boolean "remote"
    t.datetime "posted_at", default: -> { "CURRENT_TIMESTAMP" }
    t.bigint "job_search_id", null: false
    t.integer "pay_range_min"
    t.integer "pay_range_max"
    t.integer "experience_years_min"
    t.integer "experience_years_max"
    t.index ["company_id"], name: "index_job_posts_on_company_id"
    t.index ["experience_years_max"], name: "index_job_posts_on_experience_years_max"
    t.index ["experience_years_min"], name: "index_job_posts_on_experience_years_min"
    t.index ["job_search_id", "website"], name: "index_job_posts_on_job_search_id_and_website"
    t.index ["job_search_id"], name: "index_job_posts_on_job_search_id"
    t.index ["pay_range_max"], name: "index_job_posts_on_pay_range_max"
    t.index ["pay_range_min"], name: "index_job_posts_on_pay_range_min"
  end

  create_table "job_searches", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "job_title", null: false
    t.string "location"
    t.boolean "remote"
    t.string "language_code"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "board_relevance", default: [], array: true
    t.datetime "runtime"
    t.string "timezone"
    t.integer "number_of_jobs", default: 0
    t.index ["user_id"], name: "index_job_searches_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "name"
    t.string "password_digest"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "email", null: false
    t.string "api_token"
    t.index ["api_token"], name: "index_users_on_api_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  add_foreign_key "job_applications", "job_posts"
  add_foreign_key "job_applications", "users"
  add_foreign_key "job_posts", "companies"
  add_foreign_key "job_posts", "job_searches"
  add_foreign_key "job_searches", "users"
end
