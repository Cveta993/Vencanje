class CreateInvitations < ActiveRecord::Migration[8.0]
  def change
    create_table :invitations do |t|
      t.string :first_name, null: false
      t.string :last_name, null: false
      t.string :access_token, null: false
      t.string :note

      t.timestamps
    end

    add_index :invitations, :access_token, unique: true
    add_index :invitations, %i[last_name first_name]
  end
end
