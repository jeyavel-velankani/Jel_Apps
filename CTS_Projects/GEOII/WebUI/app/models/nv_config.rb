class NvConfig < ActiveRecord::Base
  set_table_name "String_Parameters"
  set_primary_key 'ID'
  set_inheritance_column :atcs_string
  establish_connection :development
end
