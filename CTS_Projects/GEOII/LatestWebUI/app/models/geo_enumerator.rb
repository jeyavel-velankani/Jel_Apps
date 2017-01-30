class GeoEnumerator < ActiveRecord::Base
  set_table_name "geo_enumerators"
  establish_connection :mcf_db
#    set_inheritance_column :enum_type
end
