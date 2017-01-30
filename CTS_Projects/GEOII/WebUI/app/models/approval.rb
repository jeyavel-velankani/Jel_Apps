class Approval < ActiveRecord::Base
  set_table_name "Approval"
  set_primary_key 'InstallationName'
  establish_connection :site_ptc_db if OCE_MODE == 1

  def insert_installation_approval_details(ptcdbpath , installationname , approver , date , time , approvalcrc, approvalstatus)
      db = SQLite3::Database.new(ptcdbpath)
      db.execute( "Insert into Approval values('#{installationname}','#{approver}','#{date}','#{time}','#{approvalcrc}','#{approvalstatus}')" )
      db.close
  end
end
