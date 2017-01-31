class Article < ActiveRecord::Base
	mount_uploader :image, ImageUploader
	validates_processing_of :image
	validate :image_size_validation
	validates :text, presence: true
	validates :title, presence: true,
                    length: { minimum: 5 }
    has_many :comments,  dependent: :destroy
    private
    	def image_size_validation
    		errors[:image] <<"Size should be less than 500KB" if image.size > 0.5
    	end

end
