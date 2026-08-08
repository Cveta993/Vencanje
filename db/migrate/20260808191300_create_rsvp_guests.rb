class CreateRsvpGuests < ActiveRecord::Migration[8.0]
  def change
    create_table :rsvp_guests do |t|
      t.references :rsvp, null: false, foreign_key: true
      t.string :full_name, null: false
      t.string :guest_type, null: false
      t.integer :position, null: false, default: 0

      t.timestamps
    end

    add_index :rsvp_guests, %i[rsvp_id position]
    add_check_constraint :rsvp_guests,
      "guest_type IN ('adult', 'child_under_10')",
      name: "rsvp_guests_guest_type_check"
  end
end
