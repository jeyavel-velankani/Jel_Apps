class CreateContacts < ActiveRecord::Migration[5.0]
  def change
    create_table :contacts do |t|
      t.string :full_name
      t.string :email
      t.integer :phone_number
      t.text :address

      t.timestamps
    end
  end
end
