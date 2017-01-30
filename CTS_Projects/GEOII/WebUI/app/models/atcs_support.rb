class AtcsSupport < ActiveRecord::Base
  set_table_name "atcs_support"
  establish_connection :real_time_db

  #set_primary_key [:mefcrc,:label]

end
