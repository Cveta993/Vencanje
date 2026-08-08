class CreateRsvps < ActiveRecord::Migration[8.0]
  def change
    create_table :rsvps do |t|
      t.references :invitation, null: false, foreign_key: true, index: { unique: true }
      t.string :attendance, null: false
      t.text :message
      t.datetime :submitted_at, null: false

      t.timestamps
    end

    add_check_constraint :rsvps,
      "attendance IN ('attending', 'declined')",
      name: "rsvps_attendance_check"
  end
end
