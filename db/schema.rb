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

ActiveRecord::Schema[8.0].define(version: 2026_08_08_191300) do
  create_table "invitations", force: :cascade do |t|
    t.string "first_name", null: false
    t.string "last_name", null: false
    t.string "access_token", null: false
    t.string "note"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["access_token"], name: "index_invitations_on_access_token", unique: true
    t.index ["last_name", "first_name"], name: "index_invitations_on_last_name_and_first_name"
  end

  create_table "rsvp_guests", force: :cascade do |t|
    t.integer "rsvp_id", null: false
    t.string "full_name", null: false
    t.string "guest_type", null: false
    t.integer "position", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["rsvp_id", "position"], name: "index_rsvp_guests_on_rsvp_id_and_position"
    t.index ["rsvp_id"], name: "index_rsvp_guests_on_rsvp_id"
    t.check_constraint "guest_type IN ('adult', 'child_under_10')", name: "rsvp_guests_guest_type_check"
  end

  create_table "rsvps", force: :cascade do |t|
    t.integer "invitation_id", null: false
    t.string "attendance", null: false
    t.text "message"
    t.datetime "submitted_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["invitation_id"], name: "index_rsvps_on_invitation_id", unique: true
    t.check_constraint "attendance IN ('attending', 'declined')", name: "rsvps_attendance_check"
  end

  create_table "users", force: :cascade do |t|
    t.string "email_address", null: false
    t.string "password_digest", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
  end

  add_foreign_key "rsvp_guests", "rsvps"
  add_foreign_key "rsvps", "invitations"
end
