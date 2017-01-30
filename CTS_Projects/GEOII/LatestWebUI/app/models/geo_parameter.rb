class GeoParameter < ActiveRecord::Base
  set_table_name "geo_parameters"
  establish_connection :mcf_db
end
