class AddPhotoToJobs < ActiveRecord::Migration[5.0]
  def change
  	change_table :jobs do |t|
      t.attachment :photo
    end
  end
end
