class CreateProjects < ActiveRecord::Migration
  def change
    create_table :projects do |t|
      t.string :name
      t.string :customer
      t.text :description
      t.decimal :price, precision: 8, scale: 2
      t.belongs_to :employee, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
