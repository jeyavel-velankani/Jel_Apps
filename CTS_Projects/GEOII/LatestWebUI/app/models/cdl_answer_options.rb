#********************************************************************************************************
# Siemens 
#
# @file      cdl_answer_options.rb
#
# @author    Kevin Ponce
#
# @brief     This model is used to connect to the nvconfig database. This uses the CDL_Questions tables.
#
# Copyright 2012 Safetran Systems Corporation
#********************************************************************************************************/
class CdlAnswerOptions < ActiveRecord::Base
  
  set_table_name "CDL_Answer_Options"
  set_primary_key [:ID,:Question_ID,:Option_Text]
  establish_connection :development

  #gets the answer that the user selected
  #was select_answer_query
  def self.get_answered_option(id,answer)
    option_Text = nil

    ans = find(:first, :select => "Option_Text", :conditions => ["Question_ID = ? and Answer_Value = ?", id, answer])

    if(ans == nil)
      option_Text = nil
    else
      option_Text = ans.Option_Text
    end 
    option_Text 
  end

  #was select_answer_options
  def self.get_answers_option(id)
    #find_by_sql("select Answer_Value, Option_Text from CDL_Answer_Options where Question_ID=#{id} Order by Answer_Value" )
    find(:all, :select => "Answer_Value, Option_Text", :conditions => ["Question_ID = ?", id], :order => "Answer_Value")
  end


end



