class Cdlsitesetup < ActiveRecord::Base
  
  #*****************************************************************************************************//**
  # @file      cdlsitesetup.rb
  #
  # @author    Vijaya
  #
  # @brief     This model is used to connect to the nvconfig database. This uses the CDL_Questions,
  #            CDL_Conditions and CDL_Answer_Options tables.
  #
  # Copyright 2011 Safetran Systems Corporation
  #********************************************************************************************************/
  
  set_table_name "CDL_Questions"
  establish_connection :development
  
  def self.select_question_query1(id)
      find_by_sql("select Question_Type, Question_Text, Answer_Min, Answer_Max, Answer_Default from CDL_Questions where ID=#{id}")
  end
  
  def self.select_condition_query(id)
      Cdlsitesetup.find_by_sql("select Condition_Question_ID, Condition_Operator, Condition_Value from CDL_Conditions where Question_ID=#{id}")
  end
  
  def self.update_answer(id, answer)
      update_all("Is_Answered = " + CDL_IS_ANSWERED_TRUE + " , Answer_Value=#{answer}", "ID = #{id}")
  end
  
  def self.delete_all
    Cdlsitesetup.find_by_sql("delete from CDL_Questions")
    Cdlsitesetup.find_by_sql("delete from CDL_Conditions")
    Cdlsitesetup.find_by_sql("delete from CDL_Answer_Options")
  end
  
  def self.clear_all_is_answered_and_answer()
      update_all("Is_Answered = " + CDL_IS_ANSWERED_FALSE + ", Answer_Value = null")
  end
  def self.clear_is_answered_and_answer(id)
      update_all("Is_Answered = " + CDL_IS_ANSWERED_FALSE + " , Answer_Value = null", {:ID => id})
  end
  
  def self.select_answered_questions(id)
    #find_by_sql("select ID, Question_Type, Question_Title, Question_Text, Answer_Value from CDL_Questions where Is_Answered = " + CDL_IS_ANSWERED_TRUE + " and ID < #{id} Order by ID" )
    find(:select => "ID, Question_Type, Question_Title, Question_Text, Answer_Value", :conditions => ["Is_Answered = ? AND ID = ?", CDL_IS_ANSWERED_TRUE, ID], :order => "ID desc")
  end
  
  def self.select_all_answered_questions()
    #find_by_sql("select ID, Question_Type, Question_Title, Question_Text, Answer_Value from CDL_Questions where Is_Answered = " + CDL_IS_ANSWERED_TRUE + " Order by ID" )
    find(:select => "ID, Question_Type, Question_Title, Question_Text, Answer_Value", :conditions => ["Is_Answered = ?", CDL_IS_ANSWERED_TRUE], :order => "ID desc")
  end
  
  def self.select_prev_ans_question_query()
    #find_by_sql("select ID from CDL_Questions where Is_Answered = " + CDL_IS_ANSWERED_TRUE + " Order by ID DESC" )
    find(:select => "ID", :conditions => ["Is_Answered = ?", CDL_IS_ANSWERED_TRUE], :order => "ID desc")
  end
  
  def self.select_answer_options(id)
      find_by_sql("select Answer_Value, Option_Text from CDL_Answer_Options where Question_ID=#{id} Order by Answer_Value" )
  end
  
   def self.select_answer_query(id)
      queryvaluet = Cdlsitesetup.find_by_sql("select Answer_Value from CDL_Questions where ID=#{id} and Is_Answered = " + CDL_IS_ANSWERED_TRUE )
      t1 = queryvaluet[0]
      t1['Option_Text']
  end
  
  def self.select_count()
      queryvaluet = Cdlsitesetup.find_by_sql("select COUNT(*) FROM CDL_Questions")
  end
  
  def self.select_answer_query(id,answer)
      queryvaluet = Cdlsitesetup.find_by_sql("select Option_Text from CDL_Answer_Options where Question_ID=#{id} and Answer_Value=#{answer}")
      t1 = queryvaluet[0]
      t1.Option_Text
  end
    
  def self.select_answer_query1(id) 
    queryvaluet = Cdlsitesetup.find_by_sql("select Answer_Value from CDL_Questions where ID=#{id} and Is_Answered ="  + CDL_IS_ANSWERED_TRUE) 
    t1 = queryvaluet[0]
    
    if (t1 == nil)
      return -1
    else
    return t1.Answer_Value
    end
    
  end
  
  def self.check_first_answer_query()
    queryvaluet = Cdlsitesetup.find_by_sql("select Is_Answered from CDL_Questions where ID=0") 
    t1 = queryvaluet[0]
    t1.Is_Answered
  end
    
end
