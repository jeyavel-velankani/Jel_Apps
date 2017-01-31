class Product < ApplicationRecord
  include AASM

  ProductStatuses = {
    created: 0,
    activated: 1,
    deactivated: 2,
    suspended: 3,
    resumed: 4,
  }

  enum status: ProductStatuses

  aasm column: :status, enum: true, create_scopes: false, whiny_transitions: false, logger: Rails.logger do
    
    state :created, initial: true 
    state :activated, :deactivated, :suspended, :resumed
    
    after_all_transitions :log_status_change

    event :active do
      transitions :from => :created, :to => :activated
    end

    event :deactive do
      transitions :from => :activated, :to => :deactivated
    end

    event :suspend do
      transitions :from => [:created, :activated, :deactivated, :resumed], :to => :suspended
    end

    event :resume do
      transitions :from => :suspended, :to => :resumed
    end
  end

  def log_status_change
    puts "changing from #{aasm.from_state} to #{aasm.to_state} (event: #{aasm.current_event})"
  end

end
