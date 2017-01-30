class Job < ApplicationRecord
	# include AASM
  
  has_attached_file :photo, styles: { thumb: "100x100>" }, default_url: 'spark'
  validates_attachment :photo, content_type: { content_type: ["image/jpeg", "image/png"], message: "is not a valid image type." }


	# JobStatus = {
 #    sleeping: 0,
 #    running: 1,
 #    cleaning: 2,
 #  }
  
 #  enum status: JobStatus

	# aasm column: :status, enum: true, create_scopes: false, whiny_transitions: false, logger: Rails.logger do
	# 	state :sleeping, :initial => true
 #    state :running
 #    state :cleaning

 #    after_all_transitions :log_status_change

 #    event :run do
 #    	transitions :from => :sleeping, :to => :running
 #    end

 #    event :clean do
 #      transitions :from => :running, :to => :cleaning
 #    end

 #    event :sleep do
 #      transitions :from => [:running, :cleaning], :to => :sleeping
 #    end

	# end

	# def log_status_change
	# 	puts "-------------------------------"
 #    Rails.logger.info { "Changed from #{aasm.from_state} to #{aasm.to_state} (event: #{aasm.current_event})" }
 #  end


end
