#*****************************************************************************************************//**
# @file      cdlsitesetup_Controller.rb
#
# @author    Kevin Ponce
#
# @brief     This module will display CDL Questions to the user and update CDL answers to nvconfig DB. 
#            It provides all the functionality required for CDL Compilation
#
# Copyright 2012 Safetran Systems Corporation
#********************************************************************************************************/

class CdlsitesetupController < ApplicationController
  layout  "general"
  if PRODUCT_TYPE == PRODUCT_TYPE_GEO_WEBUI
    require "socket"
  end
  include ReportsHelper
  include UdpCmdHelper
  before_filter :setup      #The setup action is executed before any other action in this controller

  $encoding_options = {
    :invalid => :replace,         # Replace invalid byte sequences
    :undef => :replace,           # Replace anything not defined in ASCII
    :replace => "?",               # Use a blank for the replacements
    :universal_newline => true    #Always break lines with \n
  }

#-------------------------------------------------------------------------------------------------------------------------
=begin
Function: Setup

Brief: If OCE_MODE is set to 1 and the database's path exists (aka office use) the database.yml is set with the location of nvconfig.sql3 file.
       Otherwise, you get an error and will be redirected to another page.       
=end
#-------------------------------------------------------------------------------------------------------------------------
  def setup
    if PRODUCT_TYPE == PRODUCT_TYPE_GEO_OCE
      if session[:cfgsitelocation] != nil
       (ActiveRecord::Base.configurations["development"])["database"] = session[:cfgsitelocation]+'/nvconfig.sql3'
      else
        session[:error] = "Please create/open the configuration from the configuration editor page and try again"
        redirect_to :controller=>"redirectpage" , :action=>"index"
      end
    end
  end
  
#-------------------------------------------------------------------------------------------------------------------------
=begin
Function: Index
Brief: Sets the nvconfig.sql3 path. Prints any previously answered questions and populates drop down menus for the
       _start partial to display. 
=end  
#-------------------------------------------------------------------------------------------------------------------------

def index
  if( session[:cdl_ques_done] == nil)
    session[:cdl_ques_done] = 0
  end
   #Used in the upload partial for flashing a cdl_remove_notice
  @nums = Array[4]        

  #creats and empty object so it can be access as var[0]=nil                                                                
  @current_question = nil
  @answered_question_answers = nil   

  #last question that was answered
  @ques_num = CdlQuestions.last_question_answered()

  if(@ques_num != nil)
    @ques_num += 1;
  end


  #gets the next question
  @ques_num = check_conditions(@ques_num)
                                                                        
  @file_name = ""
  if PRODUCT_TYPE == PRODUCT_TYPE_GEO_OCE
    @files = Dir.glob(session[:cfgsitelocation]+'/*.cdl')
  else
    @files = Dir.glob('/mnt/ecd/0/*.cdl')
  end
  
  unless @files.blank?
    for file in @files
      if file.split('.')[1].downcase  == 'cdl'
        @file_name = file.split('/').last
      end
    end
  end
  session[:cdl_file_name] = @file_name

  #If the user is on question 1 or greater
  if((@ques_num !=nil)&&(@ques_num >=1))                                        

    #gets the current and all the past question info
    @current_question = CdlQuestions.get_question(@ques_num.to_i)                               
    @answered_question_answers = CdlQuestions.get_all_answered_questions()       

    #checks if there was previous questions answered

    if @answered_question_answers!= nil 
      @answered_question_answers.each do |answered_question_answer|

         #If the question is a list of options
        if answered_question_answer[:Question_Type] == 1                                      
          answer = answered_question_answer[:Answer_Value]

          #updates the object with the answer the user selected
          answered_question_answer[:Question_Title] = CdlAnswerOptions.get_answered_option(answered_question_answer[:ID], answer)

        end
      end
    end
    
    #checks if the current question exists
    if @current_question!= nil   

      #If the question is a list of options                                                       
      if @current_question.Question_Type == 1  
        #Select possible options and sort by Answer_Value
        @answer_options = CdlAnswerOptions.get_answers_option(@ques_num)                               
      end
    else
      #Increment count of how many questions completed
      session[:cdl_ques_done] = session[:cdl_ques_done] + 1                            
    end
  end  

end 

def check_conditions(id)
  #checks the conditions to see what is the next question
  @condition = CdlConditions.find(:first, :select => "Condition_Question_ID, Condition_Operator, Condition_Value", :conditions => ["Question_ID = ?", id])
  while @condition!=nil do    
    @asked_question = CdlQuestions.get_only_answer(@condition.Condition_Question_ID)
    #checks if there is a condition question 
    if @asked_question != -1
        con_operator_value = @condition.Condition_Operator
        asked_ques_no = @asked_question
        con_value = @condition.Condition_Value 

        if (session[:typeOfSystem].to_s == "GCP" && con_operator_value == CDL_GCP_EQUAL)||(session[:typeOfSystem].to_s != "GCP" && con_operator_value == CDL_GEO_EQUAL)
          if asked_ques_no == con_value
            break
          else
            id = id + 1
          end
        elsif (session[:typeOfSystem].to_s == "GCP" && con_operator_value == CDL_GCP_GREATER_THAN)||(session[:typeOfSystem].to_s != "GCP" && con_operator_value == CDL_GEO_GREATER_THAN)
          if asked_ques_no > con_value
            break
          else
            id = id + 1
          end
        elsif (session[:typeOfSystem].to_s == "GCP" && con_operator_value == CDL_GCP_LESS_THAN)||(session[:typeOfSystem].to_s != "GCP" && con_operator_value == CDL_GEO_LESS_THAN)
          if asked_ques_no < con_value
            break
          else
            id = id + 1
          end
        elsif (session[:typeOfSystem].to_s == "GCP" && con_operator_value == CDL_GCP_NOT_EQUAL)||(session[:typeOfSystem].to_s != "GCP" && con_operator_value == CDL_GEO_NOT_EQUAL)
          if asked_ques_no != con_value
            break
          else
            id = id + 1
          end
        elsif (session[:typeOfSystem].to_s == "GCP" && con_operator_value == CDL_GCP_GREATER_THAN_OR_EQUAL) #CDL_GEO_GREATER_THAN_OR_EQUAL value is now known ||(con_operator_value == CDL_GEO_GREATER_THAN_OR_EQUAL)
          if asked_ques_no >= con_value
            break
          else
            id = id + 1
          end
        elsif (session[:typeOfSystem].to_s == "GCP" && con_operator_value == CDL_GCP_LESS_THAN_OR_EQUAL) #CDL_GEO_LESS_THAN_OR_EQUAL value is now known ||(con_operator_value == CDL_GEO_LESS_THAN_OR_EQUAL)
          if asked_ques_no <= con_value
            break
          else
            id =id + 1
          end
        end

      else #if asked_question == nil
        id = id + 1
      end #end if asked_question != nil statement

      @condition = CdlConditions.find(:first, :select => "Condition_Question_ID, Condition_Operator, Condition_Value", :conditions => ["Question_ID = ?", id])

  end #end while loop
  return id
end

# Start the cdl compile
def start
  compile_success =""
  dbpath =""
  cdlfilepath = ""
  
  if PRODUCT_TYPE == PRODUCT_TYPE_GEO_OCE
    dbpath = session[:cfgsitelocation]+'/'
    cdlfilepath = session[:cfgsitelocation]+'/'
    @cdl_file = Dir[cdlfilepath+"/*.cdl"]
  else
    dbpath = '/mnt/ecd/0/'                                          #Default database path
    cdlfilepath = '/mnt/ecd/0/'                                     #Default database path
  end
  #Clear all answers and Is_Answered values
  CdlQuestions.delete_answers()  

  #Office use only
  if PRODUCT_TYPE == PRODUCT_TYPE_GEO_OCE        
    file_name = Dir.glob(RAILS_ROOT+"/cdl")
    if (session[:typeOfSystem].to_s == "iVIU" || session[:typeOfSystem].to_s == "iVIU PTC GEO")
      strpath = "\"#{session[:OCE_ROOT]}\\cdlc_ptcc.exe\", \"#{dbpath}\" \"#{cdlfilepath}\" -p M"
      compile_success = system(strpath)
    elsif (session[:typeOfSystem].to_s == "CPU-III")
      strpath = "\"#{session[:OCE_ROOT]}\\cdlc_geoii.exe\", \"#{dbpath}\" \"#{cdlfilepath}\" -p M"
      compile_success = system(strpath)
    elsif (session[:typeOfSystem].to_s == "GCP")
      nv_config_db = "#{session[:cfgsitelocation]}/nvconfig.sql3".gsub("/","\\")
      cdl_w_path = Dir[session[:cfgsitelocation]+"/*.cdl"][0].gsub("/","\\")
      sear_dll = "#{session[:OCE_ROOT]}".gsub("/","\\")

      gcpcdl = WIN32OLE.new('GCPCDLCompilerServer.GCPCDLCompiler.1')
      gcpcdl.Initialize(sear_dll,cdl_w_path,nv_config_db);
      gcpcdl.Compile(1);

      gcpcdl.ole_free
      gcpcdl = nil
      GC.start
    end
    
    render :text => 0
  else                   
    #Create request and save it
    @cdl_compile_request = CDLCompilerReq.new({:phase => 0, :request_state => 0})
    @cdl_compile_request.save

    udp_send_cmd(REQUEST_COMMAND_CDL_COMPILER, @cdl_compile_request.request_id)  #Send UDP command
    render :text => @cdl_compile_request.request_id
  end
end

#checks the state of cdl compile
def check_start
  if PRODUCT_TYPE == PRODUCT_TYPE_GEO_OCE  
    render :json => {:request_state => 2, :percentage_complete => 100}
  else
    @status =   CDLCompilerReq.find_by_request_id(params[:request_id])
    
    #deletes the row from the databasae whenthe state is finisheda
    if(@status.request_state.to_i == REQUEST_STATE_COMPLETED)
      CDLCompilerReq.delete_all "request_id =" + params[:request_id]
    end 
  
    if(@status.request_state == nil)
      # no cdl file exsist
      render :json => {:request_state => -1} 
    else
      render :json => {:request_state => @status.request_state, :percentage_complete => @status.percentage_complete}
    end
  end
end

#starts the questions
def start_questions
 
  session[:cdl_ques_done]=0
  @ques_num = 0
  
  #gets the current question and answered questions
  @current_question = CdlQuestions.get_question(@ques_num)  
  @answered_question_answers = CdlQuestions.get_answer(@ques_num)  
  
  #loops through each answered question
  @answered_question_answers.each do |answered_question_answer| 

    #checks if the aanswered question is a list of options
    if answered_question_answer.Question_Type == 1  

      #changes the answer to the text drop down the user selected
      answered_question_answer.Answer_Value = CdlAnswerOptions.get_answered_option(answered_question_answer.ID, answered_question_answer.Answer_Value) 
    end
  end unless @answered_question_answers.blank? #Run Do loop unless @answer_question_answers is empty
  
  #checks if current question exist
  if @current_question!= nil 
    #checks if the current question is a drop down
    if @current_question.Question_Type == 1

      #changes the answer to the text drop down the user selected
      @answer_options = CdlAnswerOptions.get_answers_option(@ques_num)
    end
    render :partial => "start", :layout => true
  else

    render :text => "No CDL Questions found"
  end
end

# Move to the next question
def next

  #gets the answer from post
  @answer = params[:answer_ID].to_i
  @ques_num = params[:ques_num].to_i

  #updates the answer in the database
  CdlQuestions.update_answer(@ques_num,@answer)

  #increments question number
  @ques_num += 1;

  @check_next_question = CdlQuestions.get_question(@ques_num)
  
  if((@ques_num==nil)||(@ques_num<=0))
    render :json => {:message => "no_next",:page_content=>"",:ques_num=>"-1"} and return
  else  
    @ques_num = check_conditions(@ques_num)
    #gets the current question and all previous questions
    @current_question = CdlQuestions.get_question(@ques_num)  
    @answered_question_answers = CdlQuestions.get_all_answered_questions() 
    #checks if @answered_question_answers is not empty
    if @answered_question_answers[0]!= nil          
      #Check each element if its question_type == 1
      @answered_question_answers.each do |answered_question_answer|   
        if answered_question_answer[:Question_Type] == 1
          #updates the object with the answer the user selected
          answered_question_answer[:Question_Title] = CdlAnswerOptions.get_answered_option(answered_question_answer[:ID] , answered_question_answer[:Answer_Value])
        end 
      end
    end 

    #If the question is a list of options 
    if @current_question!= nil
      if @current_question.Question_Type == 1
        @answer_options = CdlAnswerOptions.get_answers_option(@ques_num)
      end
    else 
      session[:cdl_ques_done]= session[:cdl_ques_done] + 1
    end
    if ((session[:cdl_ques_done] >= 1) && (@ques_num !=nil)&&(@ques_num >=1))
      session[:cdl_ques_done] = 0
      render :json => {:mesage => "",:page_content=>""} and return
    else
      page_content = render_to_string(:partial => "start")
      render :json => {:message => "get_data",:page_content => page_content, :ques_num => @ques_num}
    end
  end #end else for if(@ques_num==nil)||(@ques_num<=0)
end

def check_question
  @check_next_question = CdlQuestions.find(:first, :conditions=>["ID = ?",params[:ques_num]])
  if(@check_next_question == nil)
    render :text => "false" and return 
  else
    render :text => "true" and return 
  end
end

 # Move to the Previous question
def prev
  @ques_num = params[:ques_num].to_i
  #checks if it is the first question
  if ((@ques_num != nil)&&(@ques_num >0))    
    @prev_question = CdlQuestions.get_prev_question_id()  
    CdlQuestions.delete_answer(@prev_question.ID)  
    #updates question number to the previous question
    @ques_num = @prev_question.ID                          
    session[:cdl_ques_done]= 0      
    if @ques_num != 0
      @current_question = CdlQuestions.get_question(@ques_num)  
      @answered_question_answers = CdlQuestions.get_all_answered_questions() 
      if @answered_question_answers != nil
        @answered_question_answers.each do |answered_question_answer|
          if answered_question_answer.Question_Type == 1
            answer = answered_question_answer.Answer_Value
            answered_question_answer.Question_Title = CdlAnswerOptions.get_answered_option(answered_question_answer.ID,answer)
          end
        end
      end
      if @current_question != nil
        if @current_question.Question_Type == 1
          @answer_options = CdlAnswerOptions.get_answers_option(@ques_num)  
        end
      end
      page_content = render_to_string(:partial => "start", :layout => true)
      render :json => {:message => "", :page_content =>page_content, :ques_num => @ques_num}
    elsif @ques_num == 0
      @current_question = CdlQuestions.get_question(0)
      @answered_question_answers = nil
      if @current_question != nil
        if @current_question.Question_Type == 1
          @answer_options = CdlAnswerOptions.get_answers_option(@ques_num)  
        end
      end
      page_content = render_to_string(:partial => "start", :layout => true)
      render :json => {:message => "", :page_content =>page_content, :ques_num => @ques_num}
    end
  else
    render :json => {:message => "start", :page_content =>page_content, :ques_num => @ques_num}
  end #if
end

def finish
  dbpath =""
  cdlfilepath = ""

  req_id = -1

  if PRODUCT_TYPE == PRODUCT_TYPE_GEO_OCE
    dbpath = session[:cfgsitelocation]+'/'
    cdlfilepath = session[:cfgsitelocation]+'/'
    
    if (session[:typeOfSystem].to_s == "iVIU" || session[:typeOfSystem].to_s == "iVIU PTC GEO")
      strpath = "\"#{session[:OCE_ROOT]}\\cdlc_ptcc.exe\", \"#{dbpath}\" \"#{cdlfilepath}\""
      compile_success = system(strpath)
    elsif (session[:typeOfSystem].to_s == "CPU-III")
      strpath = "\"#{session[:OCE_ROOT]}\\cdlc_geoii.exe\", \"#{dbpath}\" \"#{cdlfilepath}\""
      compile_success = system(strpath)
    elsif (session[:typeOfSystem].to_s == "GCP")
      CdlQuestions.update_all("Answer_Default = Answer_Value")
    end

    render :text => 0
  else
    compile_success = false
    @cdl_compile_request =  CDLCompilerReq.new({:phase => 1, :request_state => 0})                       #Create a CDL compiler request for phase 2 after questions have been answered
    @cdl_compile_request.save
                                             
    udp_send_cmd(REQUEST_COMMAND_CDL_COMPILER, @cdl_compile_request.request_id) 
    req_id = @cdl_compile_request.request_id 
    render :text => req_id
  end
end
    
def check_finish
  if PRODUCT_TYPE == PRODUCT_TYPE_GEO_OCE
    render :json => {:request_state => 2, :percentage_complete => 100, :result => 0}
  else
    @status =  CDLCompilerReq.find(:first, :select => "request_state, percentage_complete,result,error_message", :conditions => {:request_id => params[:request_id]})
    if @status.request_state == 2
      CDLCompilerReq.delete_all "request_id = "+params[:request_id].to_s
    end
    render :json => {:request_state => @status.request_state, :percentage_complete => @status.percentage_complete,:error_message=>@status.error_message,:result=>@status.result}
  end
end

#-------------------------------------------------------------------------------------------------------------------------
=begin
Function: display_q_n_s
Brief:  If there have been previously answered questions, display them. 
=end  
#-------------------------------------------------------------------------------------------------------------------------
  def display_q_n_s

  @current_question = nil
  @answered_question_answers = nil   

  #last question that was answered
  @ques_num = CdlQuestions.last_question_answered()

  if(@ques_num != nil)
    @ques_num += 1;
  end

  #gets the next question
  @ques_num = check_conditions(@ques_num)

    #If the user is on question 1 or greater
    if((@ques_num !=nil)&&(@ques_num >=1))                                        

      #gets the current and all the past question info
      @current_question = CdlQuestions.get_question(@ques_num.to_i)                               
      @answered_question_answers = CdlQuestions.get_all_answered_questions()       

      #checks if there was previous questions answered

      if @answered_question_answers!= nil 
        @answered_question_answers.each do |answered_question_answer|

           #If the question is a list of options
          if answered_question_answer[:Question_Type] == 1                                      
            answer = answered_question_answer[:Answer_Value]

            #updates the object with the answer the user selected
            answered_question_answer[:Question_Title] = CdlAnswerOptions.get_answered_option(answered_question_answer[:ID], answer)

          end
        end
      end
      
      #checks if the current question exists
      if @current_question!= nil   

        #If the question is a list of options                                                       
        if @current_question.Question_Type == 1  
          #Select possible options and sort by Answer_Value
          @answer_options = CdlAnswerOptions.get_answers_option(@ques_num)                               
        end
      else
        #Increment count of how many questions completed
        session[:cdl_ques_done] = session[:cdl_ques_done] + 1                            
      end
    end   
    page_content = render_to_string(:partial => "start", :layout => true)
    render :json => {:page_content => page_content, :ques_num => @ques_num}                                               #Render the _start partial and stay with the current layout       
  end

#-------------------------------------------------------------------------------------------------------------------------
=begin
Function: Index
Brief: Finish compiling the CDL. Sends UDP command for phase 2 compilation. Sets compile_success flag and flash success
       or fail notice
=end  
#-------------------------------------------------------------------------------------------------------------------------
  def cdl_upload
    @nums = Array[0]
    cdl_file_directory =""                                                                        #Initialize cdl_file_directory and path
    path =""
    if PRODUCT_TYPE == PRODUCT_TYPE_GEO_OCE
      path = session[:cfgsitelocation]+'/'
      cdl_file_directory = session[:cfgsitelocation]
    else
      config = open_ui_configuration                                                              #Load ui_configuration.yml
      @nv_app_cdl =  config["upload_directory"]["iviu_nv_app"]                                    #Reads from ui_configuration.yml and sets nv_app_cdl to /tmp/upload 
      path = @nv_app_cdl +'/'                                                                     #Path = '/tmp/upload/'
      cdl_file_directory = @nv_app_cdl                                                            #Cdl_file_directory = '/tmp/upload'
    end
    Dir.foreach(path) {|x|                                                                        #For each file in /tmp/upload/ run this code block where x is the filename
      if File.extname(x).upcase =='.CDL'                                                          
        File.delete(path+x)                                                                       #Delete any CDL files in the /tmp/upload folder
      end
    }

    cdl_file_name = params[:fileToUpload].original_filename                                       #cdl_file_name = file name of the cdl we are uploading
    session[:cdl_file_name] = cdl_file_name
    Dir.mkdir(cdl_file_directory) unless File.exists? cdl_file_directory                          #Create the /tmp/upload directory unless it already exists
    path = File.join(cdl_file_directory, cdl_file_name)                                         #Path = /tmp/upload/"insert cdl_file_name here"
    File.open(path, "w+") do |f|                                                                #Create an empty file for both reading and writing
      f.write(params[:fileToUpload].read)                                                       #Write to the file
      f.close                                                                                  #Close the file and flushes any pending writes to the OS.
    end
    cdl_upload_request
    render :text => 'upload'
  end

  def cdl_upload_request
    if PRODUCT_TYPE == PRODUCT_TYPE_GEO_OCE
      CdlQuestions.delete_answers()
    else
      config = open_ui_configuration                                                              #Load ui_configuration.yml
      @nv_app_cdl =  config["upload_directory"]["iviu_nv_app"]                                    #Reads from ui_configuration.yml and sets nv_app_cdl to /tmp/upload 
      path = @nv_app_cdl +'/'     
      cdl_file_upload_request = SoftwareUpload.new({:request_state => 0, :target => TARGET_NV_APP, :file_name => session[:cdl_file_name].to_s, :file_type => FILE_TYPE_CDL, :path => path})  #Upload the cdl file    
      cdl_file_upload_request.save
      udp_send_cmd(REQUEST_COMMAND_UPLOAD_FILE, cdl_file_upload_request.request_id)                  #Send UDP command
      session[:cdl_upload_request_id] = cdl_file_upload_request.request_id
    end
  end
      
  def check_cdl_upload
    @nums = Array[0]
    if PRODUCT_TYPE == PRODUCT_TYPE_GEO_OCE
      render :json => {:request_state =>2, :result => 200, :percentage_complete => 100, :file_name => session[:cdl_file_name].to_s}
    else
      @status = SoftwareUpload.find(:last, :select => "request_state, result, file_name, percentage_complete", :conditions => {:request_id => session[:cdl_upload_request_id]})
      
      if(@status != nil && @status.request_state != nil && @status.request_state == 2)
        SoftwareUpload.delete_all "request_id = " + session[:cdl_upload_request_id].to_s
      end 
      
      if @status != nil
       render :json => {:request_state => @status.request_state, :result => @status.result, :percentage_complete => @status.percentage_complete, :file_name => @status.file_name}
      else
        render :json => {:request_state =>1, :result => 0, :percentage_complete => 0, :file_name => ''}
      end
    end
  end

  def check_cdl_log  
    if PRODUCT_TYPE == PRODUCT_TYPE_GEO_OCE
      log_file_path = session[:cfgsitelocation]+'/cdl_log.txt'
    else
      log_file_path= '/mnt/ecd/0/cdl_log.txt'
    end
    
    @down_log_fil = Dir.glob(log_file_path)
    if @down_log_fil.first != nil
      @msg = 'file'
    else
      @msg = 'no file'
    end
    render :text => @msg 
  end
  
  def download_cdl_log  
    if PRODUCT_TYPE == PRODUCT_TYPE_GEO_OCE
      log_file_path = session[:cfgsitelocation]+'/cdl_log.txt'
    else
      log_file_path= '/mnt/ecd/0/cdl_log.txt'
    end
    
    @down_log_fil = Dir.glob(log_file_path)
    if @down_log_fil.first != nil
      if PRODUCT_TYPE == PRODUCT_TYPE_GEO_OCE
        send_file(log_file_path, :filename => "cdl_log.txt",:dispostion=>'attachment',:status=>'200 OK',:stream=>'true')
      else
        send_file(log_file_path, :filename => "cdl_log.txt",:dispostion=>'attachment',:status=>'200 OK',:stream=>'true',:x_sendfile => true )
      end
    end
  end

  def view_cdl_log  
    @resp = "";

    if PRODUCT_TYPE == PRODUCT_TYPE_GEO_OCE
      log_file_path = session[:cfgsitelocation]+'/cdl_log.txt'
    else
      log_file_path= '/mnt/ecd/0/cdl_log.txt'
    end
    
    @view_log_fil = Dir.glob(log_file_path)
    if @view_log_fil.first != nil
        @log_file = Dir.glob(@view_log_fil)

        File.readlines(@log_file.first).each do |file_line|
          @resp +=file_line.strip.size > 1 ? file_line + "<br />" : "<br /><br />"
        end
    end

    render :text => @resp
  end

  def check_cdl_file 
    if PRODUCT_TYPE == PRODUCT_TYPE_GEO_OCE
      log_file_path = session[:cfgsitelocation]+'/'+session[:cdl_file_name]
    else
      log_file_path= '/mnt/ecd/0/'+session[:cdl_file_name]
    end
    
    @down_log_fil = Dir.glob(log_file_path)
    if @down_log_fil.first != nil
      @msg = 'file'
    else
      @msg = 'no file'
    end
    render :text => @msg 
  end

  def download_cdl_file 
    if PRODUCT_TYPE == PRODUCT_TYPE_GEO_OCE
      log_file_path = session[:cfgsitelocation]+'/'+session[:cdl_file_name]
    else
      log_file_path= '/mnt/ecd/0/'+session[:cdl_file_name]
    end
    
    @down_log_fil = Dir.glob(log_file_path)
    if @down_log_fil.first != nil
      if PRODUCT_TYPE == PRODUCT_TYPE_GEO_OCE
       send_file(log_file_path, :filename => session[:cdl_file_name],:dispostion=>'attachment',:status=>'200 OK',:stream=>'true')
      else
        send_file(log_file_path, :filename => session[:cdl_file_name],:dispostion=>'attachment',:status=>'200 OK',:stream=>'true',:x_sendfile => true )
      end
    end
  end
  
  # Upload cdl file to cdl folder location
  def upload
    @nums = Array[1]
    render :partial => "upload", :layout => false
  end
  
  # Remove the cdl file from cdl folder  
  def remove_cdl_request
    if PRODUCT_TYPE == PRODUCT_TYPE_GEO_OCE
      filepath= session[:cfgsitelocation] + '/'
      strpath= session[:cfgsitelocation]
      Dir.chdir(strpath)
      file_name = Dir.glob("*.{C,c}{D,d}{L,l}")
      remove_files(filepath, file_name)
      
      render :json => {:message => "CDL file removed successfully.", :oce_mode => true}
    else
      remove_cdl_request = RrSimpleRequest.new(:command => 14, :subcommand => 0, :request_state => 0)
      remove_cdl_request.save

      udp_send_cmd(REQUEST_COMMAND_SIMPLE_REQUEST, remove_cdl_request.request_id)  #Send UDP command
      render :json => {:text => "check_remove_cdl",:request_id => remove_cdl_request.request_id}
    end
  end
  
  def check_remove_cdl
    remove_cdl_request_state = RrSimpleRequest.find(:last, :select => "request_state,result", :conditions => {:request_id => params[:request_id].to_i})

    if(remove_cdl_request_state.request_state.to_i == 2)
      RrSimpleRequest.delete_all "request_id = " + params[:request_id].to_s

      message = remove_cdl_request_state.result == 1 ? "<span style='color:green'>CDL file removed successfully!!</span>" : "<span style='color:red'>CDL file removing failed!!</span>"
      partial = render_to_string(:partial => "upload")
      render :json => {:partial => partial, :request_state => 2, :message => message, :file_removal => remove_cdl_request_state.result}
    
    else
      render :json => {:request_state => remove_cdl_request_state.request_state}
    end

  end
  
  
  def operational_parameters
    @values = Cdlopparam.get_value
  end
  
  def update_operational_parameter
    error = ''
    cdlopparam_values = Cdlopparam.get_value
    cdlopparam_values.each do |cdlopparam_value|
      id = cdlopparam_value.ID
      updatecontorlvalue = params["ctrl_id_#{id}"]
      if cdlopparam_value.Param_Type != 1
        minandmax = Cdlopparam.get_min_and_max(id)

        min = minandmax.map{|y| y.Min_Value}
        max = minandmax.map{|z| z.Max_Value}

        min = min[0].to_s
        max = max[0].to_s

        if min.to_i <= updatecontorlvalue.to_i && updatecontorlvalue.to_i <= max.to_i
          Cdlopparam.update_all("Current_Value = '#{updatecontorlvalue}'" , "ID = #{id}")
        else
          error += 'ctrl_id_'+id.to_s+'=>Parameter should be of '+min+' to '+max+','
        end
      else
         Cdlopparam.update_all("Current_Value = '#{updatecontorlvalue}'" , "ID = #{id}")
      end
    end
    
    if error != ''
      error = error[0..error.length-2] #removes the last comma
    end

    render :text => error
  end
  
  private
  
  # Removing CDL files - For OCE mode only
  def remove_files(filepath, file_name)
    begin
      y = filepath.to_s + file_name.first
      File.delete y 
      CdlQuestions.delete_answers
      CdlQuestions.delete_all
      CdlAnswerOptions.delete_all
      CdlConditions.delete_all
      Cdlopparam.delete_all
      Cdlopparamoption.delete_all
      rescue Exception => e
      puts e
      end
    begin
      y = filepath.to_s + "cdl_log.txt"
      if File.exist?(y)
        File.delete y
      end
    rescue Exception => e
      puts e
    end
  end
  
end
