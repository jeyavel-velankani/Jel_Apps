class CreateJobs < ActiveRecord::Migration[5.0]
  def change
    create_table :jobs do |t|
      t.string :name
      t.integer :age
      t.integer :status

      t.timestamps
    end
  end
end
