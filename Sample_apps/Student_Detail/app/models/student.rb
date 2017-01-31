class Student < ActiveRecord::Base
	has_attached_file :image, styles: { small: "64x64", med: "100x100", large: "200x200" }
	validates_attachment :image, :presence => true,
  :content_type => { content_type: ["image/jpeg", "image/gif", "image/png"] }
  before_create :randomize_id


private

def randomize_id
  begin
    self.roll_no = SecureRandom.random_number(1_00)
  end #while Student.exist?(roll_no: self.roll_no)
end
  
end
