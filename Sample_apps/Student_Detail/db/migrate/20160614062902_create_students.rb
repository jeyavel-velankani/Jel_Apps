class CreateStudents < ActiveRecord::Migration
  def change
    create_table :students do |t|
      t.integer :roll_no
      t.string :name
      t.string :blood_group
      t.string :department
      t.attachment :image

      t.timestamps null: false
    end
  end
end
