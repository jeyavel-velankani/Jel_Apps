class Mnemonic < ActiveRecord::Base
  establish_connection :mcf_db
  set_table_name "mnemonics"
end