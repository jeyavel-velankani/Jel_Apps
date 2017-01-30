class MaintenanceLog < ActiveRecord::Base
  has_and_belongs_to_many :enum_parameter
  establish_connection :log_db
  set_table_name "log_maintenance"

end
