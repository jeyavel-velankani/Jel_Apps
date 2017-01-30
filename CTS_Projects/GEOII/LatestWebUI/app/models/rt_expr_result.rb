class RtExprResult < ActiveRecord::Base
  set_table_name "rt_expr_results"
  establish_connection :real_time_db
  
  def self.expr_result(expr_name)
    find(:first, :conditions => {:expr_name => expr_name})
  end
end
