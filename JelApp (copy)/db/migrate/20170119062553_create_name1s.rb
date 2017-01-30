class CreateName1s < ActiveRecord::Migration[5.0]
  def change
    create_table :name1s do |t|

      t.timestamps
    end
  end
end
