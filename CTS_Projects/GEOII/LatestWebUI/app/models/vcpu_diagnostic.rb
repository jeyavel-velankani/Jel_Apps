class VcpuDiagnostic < ActiveRecord::Base
  establish_connection :real_time_status_db
  set_table_name "VCPU_Diagnostics"
end
