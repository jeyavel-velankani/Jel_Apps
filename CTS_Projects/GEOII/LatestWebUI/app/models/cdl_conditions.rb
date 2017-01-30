#********************************************************************************************************
# Siemens 
#
# @file      cdl_conditions.rb
#
# @author    Kevin Ponce
#
# @brief     This model is used to connect to the nvconfig database. This uses the CDL_Questions tables.
#
# Copyright 2012 Safetran Systems Corporation
#********************************************************************************************************/

class CdlConditions < ActiveRecord::Base
    
  set_table_name "CDL_Conditions"
  set_primary_key [:ID,:Question_ID,:Condition_Question_ID]
  establish_connection :development

  #was get_condition
  def self.get_condition(id)
      find(:all, :select => "Condition_Question_ID, Condition_Operator, Condition_Value", :conditions => ["Question_ID = ?", id])
  end


  # not me 
  def self.select_condition_query(id)
      #a = Cdlsitesetup.find_by_sql("select Condition_Question_ID, Condition_Operator, Condition_Value from CDL_Conditions where Question_ID=#{id}")
      find(:all, :select => "Condition_Question_ID, Condition_Operator, Condition_Value", :conditions => ["Question_ID = ?", id], :order => "ID desc")

  end

end