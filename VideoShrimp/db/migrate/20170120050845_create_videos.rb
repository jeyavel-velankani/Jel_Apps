class CreateVideos < ActiveRecord::Migration[5.0]
  def change
    create_table :videos do |t|
      t.string :name
      t.attachment :video_file
      t.attachment :mp4_file
      t.attachment :webm_file
      t.attachment :ogg_file
      t.attachment :thumbnail
      t.boolean :published
      t.integer :likes
      t.references :user, foreign_key: true

      t.timestamps
    end
  end
end
