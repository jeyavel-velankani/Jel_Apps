#********************************************************************************************************
#  Siemens
#
# @file      cdl_questions.rb
#
# @author    Kevin Ponce
#
# @brief     This model is used to connect to the nvconfig database. This uses the CDL_Questions tables.
#
# Copyright 2012 Safetran Systems Corporation
#********************************************************************************************************/
class CdlQuestions < ActiveRecord::Base
  
  set_table_name "CDL_Questions"
  set_primary_key [:ID]
  establish_connection :development
  
  #was self.select_question_query1(
  def self.get_question(id)
    find(:first, :select => "Question_Type, Question_Text, Answer_Min, Answer_Max, Answer_Default", :conditions => ["ID = ?", id.to_i])
  end

  #was self.select_answered_questions
  def self.get_answer(id)
    find(:first, :select => "ID, Question_Type, Question_Title, Question_Text, Answer_Value", :conditions => ["Is_Answered = ? AND ID = ?", CDL_IS_ANSWERED_TRUE, id])
  end

  #was self.select_all_answered_questions
  def self.get_all_answered_questions()
    find(:all, :select => "ID, Question_Type, Question_Title, Question_Text, Answer_Value", :conditions => ["Is_Answered = ?", CDL_IS_ANSWERED_TRUE], :order => "ID")
  end

  #was clear_all_is_answered_and_answer
  def self.delete_answers()
    update_all("Is_Answered = " + CDL_IS_ANSWERED_FALSE + ", Answer_Value = null")
  end

  #did not change
  def self.update_answer(id, answer)
    update_all("Is_Answered = " + CDL_IS_ANSWERED_TRUE + " , Answer_Value=#{answer}", "ID = #{id}")
  end

  #was select_answer_query1
  def self.get_only_answer(id) 
    queryvaluet = find(:first, :select => "Answer_Value", :conditions => ["ID = ? and Is_Answered = ?", id, CDL_IS_ANSWERED_TRUE])
    
    if (queryvaluet == nil)
      return -1
    else
      return queryvaluet.Answer_Value
    end 
  end

  #new
  def self.last_question_answered()
    last_question = find(:first, :select => "ID", :conditions => ["Is_Answered = ?", CDL_IS_ANSWERED_TRUE], :order => "ID desc")
      
    if(last_question == nil)
      return nil
    else
      return last_question.ID
    end
  end

  #was select_prev_ans_question_query
  def self.get_prev_question_id()
    find(:first, :select => "ID", :conditions => ["Is_Answered = ?", CDL_IS_ANSWERED_TRUE], :order => "ID desc")
  end

  #was clear_is_answered_and_answer
  def self.delete_answer(id)
    update_all("Is_Answered = " + CDL_IS_ANSWERED_FALSE + " , Answer_Value = null", {:ID => id})
  end

  
    
end
