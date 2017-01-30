class Employee < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable
  belongs_to :role
  has_many :projects

  def admin?
  	self.role.name == "Admin"
  end

  def manager?
  	self.role.name == "Manager"
  end

  def staff?
  	self.role.name == "Staff"
  end 
end
