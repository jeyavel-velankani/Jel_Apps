class LsCategories < ActiveRecord::Base
  set_table_name "ls_categories"
  establish_connection :mcf_db
end
