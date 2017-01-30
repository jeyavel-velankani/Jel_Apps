# encoding: UTF-8
####################################################################
# Company: Siemens 
# Author: Jeyavel Natesan
# File: paccomparisontool_controller.rb
# Description: This module will compare the two PAC files and display/download comparison log  
####################################################################
class PaccomparisontoolController < ApplicationController
  layout "general"
  if OCE_MODE == 1
    require 'markaby'
    require 'pathname'
  end
  include GenericHelper
  include SelectsiteHelper
  include ProgrammingHelper
    
  ####################################################################
  # Function:      index
  # Parameters:    None
  # Retrun:        @pac_files
  # Renders:       None
  # Description:   Get all the pac files and display in dropdown
  ####################################################################
  def index
    @pac_files = nil
    root_directory = "#{RAILS_ROOT}/oce_configuration/#{session[:user_id].to_s}/pac"
    pac_root = "#{RAILS_ROOT}/oce_configuration/#{session[:user_id].to_s}"
    savefilepath = "#{RAILS_ROOT}/tmp/pac_files/Pac_Comparison-report.html"
    pacfile1path = "#{RAILS_ROOT}/tmp/pac_files/PAC1"
    pacfile2path= "#{RAILS_ROOT}/tmp/pac_files/PAC2"
    unless File.exists? pac_root
      Dir.mkdir(pac_root)
      Dir.mkdir(root_directory) unless File.exists? root_directory
    else
      Dir.mkdir(root_directory) unless File.exists? root_directory
    end
    @pac_files = Dir["#{root_directory}/*.*"].reject{|f| [".", ".."].include?f }
    if File.exists?(savefilepath)
      File.open(savefilepath) do |f| 
         @displayhtmlcontent = f.read
     end
   end
   session[:pac_comp_rep_path] = savefilepath
  end
  
  ####################################################################
  # Function:      get_pac
  # Parameters:    None
  # Retrun:        None
  # Renders:       filepaths
  # Description:   Get all the pac files from pac folder
  ####################################################################
  def get_pac
    root_directory = "#{RAILS_ROOT}/oce_configuration/#{session[:user_id].to_s}/pac"
    Dir.mkdir(root_directory) unless File.exists? root_directory
    file = Dir["#{root_directory}/*.*"].reject{|f| [".", ".."].include?f }
    filepaths = ""
    file.each do |f|
      filepaths = filepaths+ '|' + f
    end
    render :text =>  filepaths
  end
  
  ####################################################################
  # Function:      merge_data
  # Parameters:    params[:selected_pac1_path] , params[:selected_pac2_path] 
  # Retrun:        None
  # Renders:       None
  # Description:   Create PAC1 and PAC2 folders in tmp folder and place
  #                selected pac files in respective folder
  ####################################################################
  def merge_data
    begin
      session[:pac_comp_rep_path] = nil
      selected_pac1_file = params[:selected_pac1_path]
      selected_pac2_file = params[:selected_pac2_path]
      selected_pac1_filename = params[:selected_pac1_path].downcase
      selected_pac2_filename = params[:selected_pac2_path].downcase
      upload_pac1_file =""
      upload_pac2_file = ""
      unless params[:uploaded_pac1_path].blank?
        upload_pac1_file= params[:uploaded_pac1_path].downcase
      end
      unless params[:uploaded_pac2_path].blank?
        upload_pac2_file = params[:uploaded_pac2_path].downcase
      end
      pacfilespath = "#{RAILS_ROOT}/tmp/pac_files"
      pacfile1path = "#{RAILS_ROOT}/tmp/pac_files/PAC1"
      pacfile2path= "#{RAILS_ROOT}/tmp/pac_files/PAC2"      
      pac1_full_path = ""
      pac2_full_path = ""
      unless selected_pac1_file.blank? || selected_pac2_file.blank?
        Dir.mkdir(pacfilespath) unless File.exists? pacfilespath
      end
      Pathname.new(pacfilespath).children.each { |p| p.rmtree }
      unless selected_pac1_file.blank?       
        if (selected_pac1_filename == upload_pac1_file)
          unless params[:fileUploadPac1].blank?
            file_name = params[:fileUploadPac1].original_filename
            Dir.mkdir(pacfile1path) unless File.exists? pacfile1path
            content = params[:fileUploadPac1].read            
            path = File.join(pacfile1path, file_name)
            pac1_full_path = path
            File.open(path, "wb") { |f| f.write(content) }
          end
        else  
          Dir.mkdir(pacfile1path) unless File.exists? pacfile1path
          FileUtils.cp(selected_pac1_file , pacfile1path)
          pac1_full_path = "#{pacfile1path}/#{File.basename(selected_pac1_file)}"
        end
      end
      
      unless selected_pac2_file.blank?
        if (selected_pac2_filename == upload_pac2_file)
          unless params[:fileUploadPac2].blank?
            file_name=params[:fileUploadPac2].original_filename
            Dir.mkdir(pacfile2path) unless File.exists? pacfile2path
            content = params[:fileUploadPac2].read            
            path = File.join(pacfile2path, file_name)
            pac2_full_path = path
            File.open(path, "wb") { |f| f.write(content) }
          end
        else  
          Dir.mkdir(pacfile2path) unless File.exists? pacfile2path
          FileUtils.cp(selected_pac2_file , pacfile2path)
          pac2_full_path = "#{pacfile2path}/#{File.basename(selected_pac2_file)}"
        end
      end
      
      # Using GCP_OCE_Manager.exe create the rt , mcf , nvconfig database from the selected pac files
      begin
        template_files = "#{RAILS_ROOT}/oce_configuration/mcf/gcp/"
        fixfile_path = "#{RAILS_ROOT}/config/FIXPARAMS.XML"
        simulator = "\"#{session[:OCE_ROOT]}\\GCP_OCE_Manager.exe\", \"#{4}\" \"\" \"#{session[:OCE_ROOT]}\" \"#{pac1_full_path}\" \"#{pac2_full_path}\" \"#{template_files}\" \"#{fixfile_path}\""
        puts  simulator
        if system(simulator)
          gcp_errorfilepath = pacfile1path+'/oce_gcp_error.log'
          result,content= read_error_log_file(gcp_errorfilepath)
          gcp_errorfilepath1 = pacfile2path+'/oce_gcp_error.log'
          result1,content1= read_error_log_file(gcp_errorfilepath1)
          if result == true
            render :text=> "error"+"|"+content.to_s and return
          elsif result1 == true
            render :text => "error"+"|"+content1.to_s and return
          else
            puts "------------------------------------ Decompress Pass ----------------------------"
            if (!File.exists?("#{pacfile1path}/nvconfig.sql3")) || (File.exists?("#{pacfile1path}/nvconfig.sql3") && (File.size("#{pacfile1path}/nvconfig.sql3") == 0))
              initialdb_path = "#{RAILS_ROOT}/db/Initialdb/gcp"
              FileUtils.cp(initialdb_path + "/nvconfig.sql3", pacfile1path + "/nvconfig.sql3")
              xml1_file_name = pac1_full_path.gsub(".PAC", ".XML").gsub(".pac", ".XML")
              sin, dotnumber, milepost, site_name = read_pac_xml_file(xml1_file_name)
              puts sin, dotnumber, milepost, site_name
              db_nvconfig1 = SQLite3::Database.new("#{pacfile1path}/nvconfig.sql3")
              db_nvconfig1.execute("Update String_Parameters set String = '#{site_name.to_s}', DisplayOrder = 1 Where Group_ID = 1 and ID = 1")
              db_nvconfig1.execute("Update String_Parameters set String = '#{dotnumber.to_s}', DisplayOrder = 2 Where Group_ID = 1 and ID = 2")
              db_nvconfig1.execute("Update String_Parameters set String = '#{milepost.to_s}', DisplayOrder = 3 Where Group_ID = 1 and ID = 3")
              db_nvconfig1.execute("Update String_Parameters set String = '#{sin.to_s}', DisplayOrder = 4 Where Group_ID = 1 and ID = 4")
              db_nvconfig1.execute("Update Integer_Parameters set DisplayOrder = -1 where Group_ID = 1")
              db_nvconfig1.close()            
            end
            if (!File.exists?("#{pacfile2path}/nvconfig.sql3")) || (File.exists?("#{pacfile2path}/nvconfig.sql3") && (File.size("#{pacfile2path}/nvconfig.sql3") == 0))
              initialdb_path = "#{RAILS_ROOT}/db/Initialdb/gcp"
              FileUtils.cp(initialdb_path + "/nvconfig.sql3", pacfile2path + "/nvconfig.sql3")
              
              xml2_file_name = pac2_full_path.gsub(".PAC", ".XML").gsub(".pac", ".XML")
              sin, dotnumber, milepost, site_name = read_pac_xml_file(xml2_file_name)
              puts sin, dotnumber, milepost, site_name
              db_nvconfig2 = SQLite3::Database.new("#{pacfile2path}/nvconfig.sql3")
              db_nvconfig2.execute("Update String_Parameters set String = '#{site_name.to_s}', DisplayOrder = 1 Where Group_ID = 1 and ID = 1")
              db_nvconfig2.execute("Update String_Parameters set String = '#{dotnumber.to_s}', DisplayOrder = 2 Where Group_ID = 1 and ID = 2")
              db_nvconfig2.execute("Update String_Parameters set String = '#{milepost.to_s}', DisplayOrder = 3 Where Group_ID = 1 and ID = 3")
              db_nvconfig2.execute("Update String_Parameters set String = '#{sin.to_s}', DisplayOrder = 4 Where Group_ID = 1 and ID = 4")
              db_nvconfig2.execute("Update Integer_Parameters set DisplayOrder = -1 where Group_ID = 1")
              db_nvconfig2.close()
            end
          end        
        else
          puts "------------------------------------ Decompress Failed ----------------------------"
	        raise Exception, "Decompress Failed"
        end           
      rescue Exception => e
        puts e.inspect
        render :text => "error"+"|"+"#{e.message.to_s}" and return
      end

      # check the rt , mcf , nvconfig.sql3 db't available for PAC1 and PAC2 and allow user to compare databases      
      if File.exists?("#{pacfile1path}/mcf.db") && File.exists?("#{pacfile1path}/rt.db") && File.exists?("#{pacfile1path}/nvconfig.sql3")
        if File.exists?("#{pacfile2path}/mcf.db") && File.exists?("#{pacfile2path}/rt.db") && File.exists?("#{pacfile2path}/nvconfig.sql3")
            if ((File.size("#{pacfile1path}/mcf.db") > 0) && (File.size("#{pacfile1path}/rt.db") >0) && (File.size("#{pacfile1path}/nvconfig.sql3") >0) && (File.size("#{pacfile2path}/mcf.db") >0) && (File.size("#{pacfile2path}/rt.db") >0) && (File.size("#{pacfile2path}/nvconfig.sql3") >0))
                paccomparison(selected_pac1_file, selected_pac2_file)      
            else
              render :text=>"error|Vital and Non-Vital Configuration details was not created by #{File.basename(pac1_full_path)} and #{File.basename(pac2_full_path)}" and return 
            end
        else
          render :text => "error|Vital and Non-Vital Configuration details was not created by #{File.basename(pac2_full_path)}" and return
        end
      else
        render :text=>"error|Vital and Non-Vital Configuration details was not created by #{File.basename(pac1_full_path)}"  and return 
      end
    rescue Exception => e
        render :text => "error|#{e.message.to_s}" and return
    end
  end
  
  ####################################################################
  # Function:      paccomparison
  # Parameters:    pacfile1 , pacfile2
  # Retrun:        None
  # Renders:       paccomparison
  # Description:   Compare selected pac files and display result
  ####################################################################
  def paccomparison(pacfile1, pacfile2)
    error_flag = false
    begin
      pac1_split = pacfile1.split('/')
      pac2_split = pacfile2.split('/')
      pac1_length = pac1_split.length
      pac2_length = pac2_split.length
      pac1 = pac1_split[pac1_length-1]
      pac2 = pac2_split[pac2_length-1]
      mab = Markaby::Builder.new
      db1 = SQLite3::Database.new("#{RAILS_ROOT}/tmp/pac_files/PAC1/mcf.db") #pac1 file mcf.db connnection
      db2 = SQLite3::Database.new("#{RAILS_ROOT}/tmp/pac_files/PAC2/mcf.db") #pac2 file mcf.db connnection
      db1_rt = SQLite3::Database.new("#{RAILS_ROOT}/tmp/pac_files/PAC1/rt.db")#pac1 file rt.db connnection
      db2_rt = SQLite3::Database.new("#{RAILS_ROOT}/tmp/pac_files/PAC2/rt.db")#pac2 file rt.db connnection
      db1_nvconfig = SQLite3::Database.new("#{RAILS_ROOT}/tmp/pac_files/PAC1/nvconfig.sql3")#pac1 file nvconfig.sql3 connnection
      db2_nvconfig = SQLite3::Database.new("#{RAILS_ROOT}/tmp/pac_files/PAC2/nvconfig.sql3")#pac2 file nvconfig.sql3 connnection
      
      pac1_and_pac2_nv_config_version_info = []
      db1_and_db2_compare_results = []
      
      #------------------------------Validate PAC extracted MCF DB's and RT DB's ---------------------------------------
      db1_mcf_status = db1.execute('select mcf_status from mcfs').collect{|v|v[0]}
      db2_mcf_status = db2.execute('select mcf_status from mcfs').collect{|v|v[0]}
      db1_rt_ui_states_value = db1_rt.execute("Select value from rt_ui_states where name ='Database completed'").collect{|v|v[0]}
      db2_rt_ui_states_value = db2_rt.execute("Select value from rt_ui_states where name ='Database completed'").collect{|v|v[0]}
      strmsg = ""
      if !db1_mcf_status.blank? &&  db1_mcf_status[0].to_i == 1 && !db2_mcf_status.blank? &&  db2_mcf_status[0].to_i == 1
        if !db1_rt_ui_states_value.blank? && db1_rt_ui_states_value[0].to_i == 1 && !db2_rt_ui_states_value.blank? && db2_rt_ui_states_value[0].to_i == 1   
            strmsg = ""
        else
            strmsg = "#{pac2} is not extracted properly" if !db1_rt_ui_states_value.blank? && db1_rt_ui_states_value[0].to_i != 1
            strmsg = "#{pac1} is not extracted properly" if !db2_rt_ui_states_value.blank? && db2_rt_ui_states_value[0].to_i != 1
        end
      else
        strmsg = "#{pac2} is not extracted properly" if !db1_mcf_status.blank? &&  db1_mcf_status[0].to_i != 1
        strmsg = "#{pac1} is not extracted properly" if !db2_mcf_status.blank? &&  db2_mcf_status[0].to_i != 1 
      end
 
      if !strmsg.blank?
        raise Exception, strmsg
      end
       
      #------------------------------MCF Information comparison between pac1 and pac2 files---------------------------------------
      db1_mcf_info = db1_rt.execute("Select mcfcrc from rt_gwe").collect{|v|v[0]}
      db2_mcf_info = db2_rt.execute("Select mcfcrc  from rt_gwe").collect{|v|v[0]}
      
      res_of_pac1rtgwe_pac2rtgwe = db1_mcf_info - db2_mcf_info
      
      pac1_and_pac2_equal_mcf_info = []
      pac1_and_pac2_not_equal_mcf_info = []
      plus_mcf_info = []
      minus_mcf_info = []
      pac1_mcf_info = []
      pac2_mcf_info = []
            
      db1_mcf_info = db1_rt.execute("Select mcf_name , mcfcrc , mcf_revision  from rt_gwe")
      db2_mcf_info = db2_rt.execute("Select mcf_name , mcfcrc , mcf_revision  from rt_gwe")
      
      pac1_mcf_info << {:PacName => pac1 , :McfName => db1_mcf_info[0][0], :Mcfcrc => db1_mcf_info[0][1].to_s(16).upcase ,:Mcfrevision => db1_mcf_info[0][2]}
      pac2_mcf_info << {:PacName => pac2 , :McfName => db2_mcf_info[0][0], :Mcfcrc => db2_mcf_info[0][1].to_s(16).upcase ,:Mcfrevision => db2_mcf_info[0][2]}
      
      unless res_of_pac1rtgwe_pac2rtgwe.blank?
        if db1_mcf_info[0][1].to_i == db2_mcf_info[0][1].to_i
          pac1_and_pac2_not_equal_mcf_info << {:Pac1McfName => db1_mcf_info[0][0], :Pac1Mcfcrc => db1_mcf_info[0][1].to_s(16).upcase ,:Pac1Mcrevision => db1_mcf_info[0][2] , :Pac2McfName => db2_mcf_info[0][0] , :Pac2Mcfcrc => db2_mcf_info[0][1].to_s(16).upcase ,:Pac2Mcrevision => db2_mcf_info[0][2] }              
        else
          plus_mcf_info <<  {:Pac1McfName => db2_mcf_info[0][0], :Pac1Mcfcrc => db2_mcf_info[0][1].to_s(16).upcase ,:Pac1Mcrevision => db2_mcf_info[0][2] }
          minus_mcf_info << {:Pac1McfName => db1_mcf_info[0][0], :Pac1Mcfcrc => db1_mcf_info[0][1].to_s(16).upcase ,:Pac1Mcrevision => db1_mcf_info[0][2]}
        end
      else
        if ((db1_mcf_info[0][0].to_s == db2_mcf_info[0][0].to_s) && (db1_mcf_info[0][2].to_s == db2_mcf_info[0][2].to_s )) 
          pac1_and_pac2_equal_mcf_info << {:Pac1McfName => db1_mcf_info[0][0], :Pac1Mcfcrc => db1_mcf_info[0][1].to_s(16).upcase ,:Pac1Mcrevision => db1_mcf_info[0][2] , :Pac2McfName => db2_mcf_info[0][0] , :Pac2Mcfcrc => db2_mcf_info[0][1].to_s(16).upcase ,:Pac2Mcrevision => db2_mcf_info[0][2] }
        else
          pac1_and_pac2_not_equal_mcf_info << {:Pac1McfName => db1_mcf_info[0][0], :Pac1Mcfcrc => db1_mcf_info[0][1].to_s(16).upcase ,:Pac1Mcrevision => db1_mcf_info[0][2] , :Pac2McfName => db2_mcf_info[0][0] , :Pac2Mcfcrc => db2_mcf_info[0][1].to_s(16).upcase ,:Pac2Mcrevision => db2_mcf_info[0][2] }
        end
      end
      
      #------------------------------Vital Program Comparison between pac files - MCF---------------------------------------
      card_type_result_display = []
      db1_mcfcrc = db1_mcf_info[0][1]
      db2_mcfcrc = db2_mcf_info[0][1]
      
      parent_used = false
      check = db1.execute("select * from menus where parent != '(NULL)'")
      unless check.blank?
        parent_used = true
      end
      
      db2_parent_used = false
      check_db2 = db2.execute("select * from menus where parent != '(NULL)'")
      unless check_db2.blank?
        db2_parent_used = true
      end
      
      if !((parent_used && db2_parent_used) || (!parent_used && !db2_parent_used))
        raise Exception, "Both selected PAC files should be same type of system(Either GCP 4K OR 5K)"
      end
      
      db1_my_pages = get_menus_list(db1, db1_mcfcrc)
      db2_my_pages = get_menus_list(db2, db2_mcfcrc)
      
      db_2_plus_records = []  
      db2_my_pages.each do |db2_my_page|
        db1_value_available = db1_my_pages.select {|db1_page| (db1_page[:link] == db2_my_page[:link])}
        if db1_value_available.blank?
          db_2_plus_records << db2_my_page
        end
      end
      
      #############################################################
      db1_card_type_index = get_card_type_index(db1)      
      db2_card_type_index = get_card_type_index(db2)
      card_index_map = {}
      card_index_map_21 = {}
      min_len = 0
      db1_card_type_index.each do |crd|
        db1_card = crd[0]
        db1_index = crd[1]
        db2_index = db2_card_type_index[db1_card]
        db1_length = db1_index.length
        db2_length = (db2_index.blank? ? 0 : db2_index.length) 
        if (db1_length <= db2_length)
          min_len = db1_length
        else
          min_len = db2_length
        end
        for i in 0..(min_len-1)
          card_index_map[db1_index[i]] = db2_index[i]
        end
        for i in 0..(min_len-1)
          card_index_map_21[db2_index[i]] = db1_index[i]
        end
      end
      puts "*********************************"
      puts card_index_map.inspect
      puts card_index_map_21.inspect
      ###############################################################
      
      #--------------GCP 4K - Template display Start------------------------
      if !parent_used     # Display the Template name difference for 4K
        db1_template_rt_records = db1_rt.execute("Select current_value from rt_parameters where parameter_name like 'MTFIndex'").collect{|v|v[0]}
        db2_template_rt_records = db2_rt.execute("Select current_value from rt_parameters where parameter_name like 'MTFIndex'").collect{|v|v[0]}
        template_mismatch_values = []
        if (!db1_template_rt_records.blank? && !db2_template_rt_records.blank? && (db1_template_rt_records[0].to_i != db2_template_rt_records[0].to_i))
            db1_template_mcf_records = db1.execute("Select layout_index , cardindex , param_long_name ,context_string , name , enum_type_name , mcfcrc , data_type , int_type_name from parameters Where name like 'MTFIndex'")
            db2_template_mcf_records = db2.execute("Select layout_index , cardindex , param_long_name ,context_string , name , enum_type_name , mcfcrc , data_type , int_type_name from parameters Where name like 'MTFIndex'")
            
            rt1_enum_value = db1.execute("Select long_name  from enumerators Where value = #{db1_template_rt_records[0].to_i} and long_name not like '%ENUMTYPES.xml' and enum_type_name like 'MTFINDEXTYPE'").collect{|v|v[0]}
            if !rt1_enum_value.blank?
              rt1_enum_value = rt1_enum_value[0]
            else
              rt1_enum_value = db1_template_rt_records[0]  
            end
  
            rt2_enum_value = db2.execute("Select long_name  from enumerators Where value = #{db2_template_rt_records[0].to_i} and long_name not like '%ENUMTYPES.xml' and enum_type_name like 'MTFINDEXTYPE'").collect{|v|v[0]}
            if !rt2_enum_value.blank?
              rt2_enum_value = rt2_enum_value[0]
            else
              rt2_enum_value = db2_template_rt_records[0]  
            end
            
            if !db1_template_mcf_records.blank? && !db2_template_mcf_records.blank?
              template_mismatch_values << {:table1_rows =>{:layout_index => db1_template_mcf_records[0][0] , :cardindex => db1_template_mcf_records[0][1], :param_long_name => db1_template_mcf_records[0][2] ,:name =>db1_template_mcf_records[0][4] , :context_string => db1_template_mcf_records[0][3], :current_value =>rt1_enum_value} , 
                                           :table2_rows =>{:layout_index => db2_template_mcf_records[0][0] , :cardindex => db2_template_mcf_records[0][1], :param_long_name => db2_template_mcf_records[0][2] ,:name =>db2_template_mcf_records[0][4] , :context_string => db2_template_mcf_records[0][3], :current_value =>rt2_enum_value} 
                                          }
            end
        end
        
        if !template_mismatch_values.blank?
           card_type_result_display << {:page_name=> "TEMPLATE:  selection" ,:db1_db2_not_equal_rows => template_mismatch_values ,:db2_plus_rows => [] , :db2_minus_rows => []}
        end
      end
      #--------------4K - Template display END------------------------
      
      db1_my_pages.each do |menu_page|
        if !menu_page[:menu_name].blank?
          page_name = menu_page[:menu_name].strip
          db1_results = db1.execute("Select param.* from page_parameter page_param inner join parameters param " +
                          "on page_param.mcfcrc = param.mcfcrc And page_param.layout_index = param.layout_index " +
                          "And page_param.parameter_name = param.name And page_param.card_index = param.cardindex " +
                          "And page_param.parameter_type = 2 Where  (target Not Like 'LocalUI') and page_name Not Like 'template:%' and page_name Like '#{menu_page[:menu_name].strip}'")
        end
        if db1_results.blank?
          if !menu_page[:link].blank?
            page_name = menu_page[:link].strip
            db1_results = db1.execute("Select param.* from page_parameter page_param inner join parameters param " +
                          "on page_param.mcfcrc = param.mcfcrc And page_param.layout_index = param.layout_index " +
                          "And page_param.parameter_name = param.name And page_param.card_index = param.cardindex " +
                          "And page_param.parameter_type = 2 Where  (target Not Like 'LocalUI') and page_name Not Like 'template:%' and page_name Like '#{menu_page[:link].strip}'")
          end
        end
        
        if !menu_page[:menu_name].blank?
          db2_results = db2.execute("Select param.* from page_parameter page_param inner join parameters param " +
                          "on page_param.mcfcrc = param.mcfcrc And page_param.layout_index = param.layout_index " +
                          "And page_param.parameter_name = param.name And page_param.card_index = param.cardindex " +
                          "And page_param.parameter_type = 2 Where  (target Not Like 'LocalUI') and page_name Not Like 'template:%' and page_name Like '#{menu_page[:menu_name].strip}'")
        end
        if db2_results.blank?
          if !menu_page[:link].blank?
            db2_results = db2.execute("Select param.* from page_parameter page_param inner join parameters param " +
                          "on page_param.mcfcrc = param.mcfcrc And page_param.layout_index = param.layout_index " +
                          "And page_param.parameter_name = param.name And page_param.card_index = param.cardindex " +
                          "And page_param.parameter_type = 2 Where  (target Not Like 'LocalUI') and page_name Not Like 'template:%' and page_name Like '#{menu_page[:link].strip}'")
          end
        end
        
        db2_plus_rows = []
        db2_minus_rows = [] # databse 2 not available records and database 1 available records(MINUS)
        db1_db2_not_equal_rows = [] #database 1 and database 2 not equal records(NOT EQUAL)        
        db1_v_results_formated = []
        db2_v_results_formated = []
        
        db1_results.each do |db1_result|
          db1_v_results_formated << db1_result[0,10].join('_$$_')
        end
        
        db2_results.each do |db2_result|
          db2_v_results_formated << db2_result[0,10].join('_$$_')
        end
        
        plus_params_db2 = []
        db2_v_results_formated.each do |res_db2_value|
           db2_plus_available_flag = db1_v_results_formated.select {|db1_value| db1_value.split("_$$_")[6] == res_db2_value.split("_$$_")[6] }
           if db2_plus_available_flag.blank?
             plus_params_db2 << res_db2_value
           end
        end
        
        db1_v_results_formated.each do |res_db1_value|
          column_values = res_db1_value.split("_$$_")
          db2_card_index = card_index_map[column_values[3].to_i]
          where_conditions = "parameter_type =2 and layout_index = #{column_values[1].to_i} and layout_type = #{column_values[2].to_i} and cardindex= #{column_values[3].to_i} and name Like '#{column_values[6].strip}'"
          db1_records = db1.execute("Select layout_index , cardindex , param_long_name ,context_string , name , enum_type_name , mcfcrc , data_type , int_type_name from parameters Where #{where_conditions}")
          if !db2_card_index.blank?
            where_conditions2 = "parameter_type =2 and layout_index = #{column_values[1].to_i} and layout_type = #{column_values[2].to_i} and cardindex= #{db2_card_index} and name Like '#{column_values[6].strip}'"
            db2_records = db2.execute("Select layout_index , cardindex , param_long_name ,context_string , name , enum_type_name , mcfcrc , data_type , int_type_name from parameters Where #{where_conditions2}")
          else
            db2_records = nil
          end
          if db2_records.blank?
            rt_where_conditions = "parameter_type =2 and card_index= #{column_values[3].to_i} and parameter_name like '#{column_values[6].to_s}'"
            rt_current_value = db1_rt.execute("Select current_value from rt_parameters where #{rt_where_conditions}").collect{|v|v[0]}
            rt_value = ""
            if !rt_current_value.blank?
              param_enum_type_name = db1_records[0][5]
              if (!param_enum_type_name.blank? && (db1_records[0][7] == "Enumeration"))
                mcfcrc = db1_records[0][6]
                enumerators_condition = "mcfcrc = '#{mcfcrc}' and layout_index = #{column_values[1]} and enum_type_name like  '#{param_enum_type_name}' and value = #{rt_current_value[0]}"
                enum_long_name = db1.execute("Select long_name  from enumerators Where #{enumerators_condition}").collect{|v|v[0]}
                rt_value = enum_long_name[0]
                rt_value = "NO ENUM" if enum_long_name.blank?
              else
                rt_value = rt_current_value[0]
              end
            end
            db2_minus_rows << {:layout_index => column_values[1] ,:cardindex => column_values[3],:param_long_name =>column_values[7] ,:name =>column_values[6], :context_string =>column_values[9] , :current_value => rt_value }
          else
            unless db1_records.blank? && db2_records.blank?
                rt_where_conditions = "parameter_type =2 and card_index= #{column_values[3].to_i} and parameter_name like '#{column_values[6].to_s}'"
                rt1_current_value = db1_rt.execute("Select current_value from rt_parameters where #{rt_where_conditions}").collect{|v|v[0]}
                if !db2_card_index.blank?
                  rt_where_conditions2 = "parameter_type =2 and card_index= #{db2_card_index} and parameter_name like '#{column_values[6].to_s}'"
                  rt2_current_value = db2_rt.execute("Select current_value from rt_parameters where #{rt_where_conditions2}").collect{|v|v[0]}
                else
                  rt2_current_value = nil
                end
                if (!rt1_current_value.blank?)
                  db1_param_enum_type_name = db1_records[0][5]
                  if (!db1_param_enum_type_name.blank? && (db1_records[0][7] == "Enumeration"))
                    db1_enumerators_condition = "mcfcrc = '#{db1_mcfcrc}' and layout_index = #{column_values[1]} and enum_type_name like  '#{db1_param_enum_type_name}' and value = #{rt1_current_value[0]}"
                    db1_enum_long_name = db1.execute("Select long_name  from enumerators Where #{db1_enumerators_condition}").collect{|v|v[0]}
                    db1_rt_value = db1_enum_long_name[0]
                    db1_rt_value = "NO ENUM" if db1_enum_long_name.blank?
                  else
                    #---------------------------
                    int_type_name = db1_records[0][8]
                    integertypes_condition_val = db1.execute("select imperial_unit ,size , scale_factor , lower_bound , upper_bound , signed_number from integertypes where layout_index = #{column_values[1].to_i} and layout_type =#{column_values[2].to_i} and int_type_name like '#{int_type_name}'")
                    value_update = rt1_current_value[0]
                    factor = 1
                    check_for_signed = false
                    if !integertypes_condition_val.blank?
                      factor = (integertypes_condition_val[0][2].to_f / 1000).to_f
                      check_for_signed = true if integertypes_condition_val[0][5] == 'Yes'
                    end
                    value_display_name = value_update.to_f * factor
                    value_display_name = get_signed_value(value_display_name, integertypes_condition_val[0][1]) if check_for_signed == true
                    db1_rt_value = value_display_name.to_i
                    #----------------------------
                  end
                end
                if (!rt2_current_value.blank?)
                  db2_param_enum_type_name = db2_records[0][5]
                  if (!db2_param_enum_type_name.blank? && (db2_records[0][7] == "Enumeration"))
                    db2_enumerators_condition = "mcfcrc = '#{db2_mcfcrc}' and layout_index = #{column_values[1]} and enum_type_name like  '#{db2_param_enum_type_name}' and value = #{rt2_current_value[0]}"
                    db2_enum_long_name = db2.execute("Select long_name  from enumerators Where #{db2_enumerators_condition}").collect{|v|v[0]}
                    db2_rt_value = db2_enum_long_name[0]
                    db2_rt_value = "NO ENUM" if db2_enum_long_name.blank?
                  else
                    #---------------------------
                    int_type_name = db2_records[0][8]
                    integertypes_condition_val = db2.execute("select imperial_unit ,size , scale_factor , lower_bound , upper_bound , signed_number from integertypes where layout_index = #{column_values[1].to_i} and layout_type =#{column_values[2].to_i} and int_type_name like '#{int_type_name}'")
                    value_update = rt2_current_value[0]
                    factor = 1
                    check_for_signed = false
                    if !integertypes_condition_val.blank?
                      factor = (integertypes_condition_val[0][2].to_f / 1000).to_f
                      check_for_signed = true if integertypes_condition_val[0][5] == 'Yes'
                    end
                    value_display_name = value_update.to_f * factor
                    value_display_name = get_signed_value(value_display_name, integertypes_condition_val[0][1]) if check_for_signed == true
                    db2_rt_value = value_display_name.to_i
                    #----------------------------
                  end
                end
                if (!rt1_current_value.blank? && !rt2_current_value.blank? &&  ((db2_records[0][0] != db1_records[0][0]) || (db1_records[0][1] != db2_records[0][1]) || (db1_records[0][4] != db2_records[0][4]) || (db1_rt_value != db2_rt_value)))
                  db1_db2_not_equal_rows << {:table1_rows =>{:layout_index => db1_records[0][0] , :cardindex => db1_records[0][1], :param_long_name => db1_records[0][2] ,:name =>db1_records[0][4] , :context_string => db1_records[0][3], :current_value =>db1_rt_value} , 
                                             :table2_rows =>{:layout_index => db2_records[0][0] , :cardindex => db2_records[0][1], :param_long_name => db2_records[0][2] ,:name =>db2_records[0][4] , :context_string => db2_records[0][3], :current_value =>db2_rt_value} 
                   }
                end
            end # unless db1_records.blank? && db2_records.blank?
          end # if db2_records.blank?
        end # db1_v_results_formated.each
        
        
                
        plus_params_db2.each do |plus_param_db2|
          column_values = plus_param_db2.split("_$$_")
          db1_card_index = card_index_map_21[column_values[3].to_i]
          parameter_name = "name Like '#{column_values[6].strip}'"
          where_conditions = "parameter_type =2 and layout_index = #{column_values[1].to_i} and layout_type = #{column_values[2].to_i} and cardindex = #{column_values[3].to_i} and name Like '#{column_values[6].strip}'"
          db2_records = db2.execute("Select layout_index , cardindex , param_long_name ,context_string , name , enum_type_name , mcfcrc , data_type , int_type_name  from parameters Where #{where_conditions}")
          if !db2_records.blank?
            rt_where_conditions = "parameter_type =2 and card_index= #{column_values[3].to_i} and parameter_name like '#{column_values[6].to_s}'"
            rt_current_value = db2_rt.execute("Select current_value from rt_parameters where #{rt_where_conditions}").collect{|v|v[0]}
            rt_value = ""
            if !rt_current_value.blank?
              param_enum_type_name = db2_records[0][5]
              if (!param_enum_type_name.blank? && (db2_records[0][7] == "Enumeration"))
                mcfcrc = db2_records[0][6]
                enumerators_condition = "mcfcrc = '#{mcfcrc}' and layout_index = #{column_values[1]} and enum_type_name like  '#{param_enum_type_name}' and value = #{rt_current_value[0]}"
                enum_long_name = db2.execute("Select long_name  from enumerators Where #{enumerators_condition}").collect{|v|v[0]}
                rt_value = enum_long_name[0]
                rt_value = "NO ENUM" if enum_long_name.blank?
              else
                #---------------------------
                int_type_name = db2_records[0][8]
                integertypes_condition_val = db2.execute("select imperial_unit ,size , scale_factor , lower_bound , upper_bound , signed_number from integertypes where layout_index = #{column_values[1].to_i} and layout_type =#{column_values[2].to_i} and int_type_name like '#{int_type_name}'")
                value_update = rt_current_value[0]
                factor = 1
                check_for_signed = false
                if !integertypes_condition_val.blank?
                  factor = (integertypes_condition_val[0][2].to_f / 1000).to_f
                  check_for_signed = true if integertypes_condition_val[0][5] == 'Yes'
                end
                value_display_name = value_update.to_f * factor
                value_display_name = get_signed_value(value_display_name, integertypes_condition_val[0][1]) if check_for_signed == true
                rt_value = value_display_name.to_i
                #----------------------------
              end
            end
            db2_plus_rows << {:layout_index => column_values[1] , :cardindex => column_values[3], :param_long_name =>column_values[7] ,:name =>column_values[6], :context_string =>column_values[9] , :current_value => rt_value }
          end # if !db2_records.blank?
        end # plus_params_db2.each
        
        if !db1_db2_not_equal_rows.blank? || !db2_minus_rows.blank? || !db2_plus_rows.blank?
          card_type_result_display << {:page_name=> page_name ,:db1_db2_not_equal_rows => db1_db2_not_equal_rows ,:db2_plus_rows => db2_plus_rows , :db2_minus_rows => db2_minus_rows}
        end
      end #db1_my_pages.each
      
      db_2_plus_records.each do |db_2_plus_record|
        db2_plus_rows = [] # databse 1 not available records and database 2 available records(PLUS)
        page_name = (db_2_plus_record[:link].blank?) ? db_2_plus_record[:menu_name] : db_2_plus_record[:link]
        
        #---DB2
        db2_results_page_parameter_records = db2.execute("select parameter_name , card_index from page_parameter where parameter_type = 2 and page_name like '#{page_name.strip}' Order by display_order")          
        db2_results_page_parameter = db2_results_page_parameter_records.collect {|x| "'#{x[0]}'"  }
        db2_results_page_parameter.flatten!
        db2_page_parameter_names = db2_results_page_parameter.join(",")
        db2_cardindexs = db2_results_page_parameter_records.collect {|x| x[1].to_i } 
        db2_cardindexs.flatten!
        db2_card_indexs = db2_cardindexs.join(",")
        db2_cards_where_condtion = "and name in (#{db2_page_parameter_names}) and cardindex in (#{db2_card_indexs})"
        
        db2_v_results_formated = []
        db2_results = db2.execute('select * from parameters where parameter_type = 2 '+db2_cards_where_condtion)
        
        db2_results.each do |db2_result|
          db2_v_results_formated << db2_result[0,10].join('_$$_')
        end
        
        db2_v_results_formated.each do |res_db2_value|
          column_values = res_db2_value.split("_$$_")
          parameter_name = "name Like '#{column_values[6].strip}'"
          where_conditions = "parameter_type =2 and layout_index = #{column_values[1].to_i} and layout_type = #{column_values[2].to_i} and cardindex = #{column_values[3].to_i} and name Like '#{column_values[6].strip}'"
          db2_records = db2.execute("Select layout_index , cardindex , param_long_name ,context_string , name , enum_type_name , mcfcrc , data_type , int_type_name from parameters Where #{where_conditions}")
          if !db2_records.blank?
            rt_where_conditions = "parameter_type =2 and card_index= #{column_values[3].to_i} and parameter_name like '#{column_values[6].to_s}'"
            rt_current_value = db2_rt.execute("Select current_value from rt_parameters where #{rt_where_conditions}").collect{|v|v[0]}
            rt_value = ""
            if !rt_current_value.blank?
              param_enum_type_name = db2_records[0][5]
              if (!param_enum_type_name.blank? && (db2_records[0][7] == "Enumeration"))
                mcfcrc = db2_records[0][6]
                enumerators_condition = "mcfcrc = '#{mcfcrc}' and layout_index = #{column_values[1]} and enum_type_name like  '#{param_enum_type_name}' and value = #{rt_current_value[0]}"
                enum_long_name = db2.execute("Select long_name  from enumerators Where #{enumerators_condition}").collect{|v|v[0]}
                rt_value = enum_long_name[0]
                rt_value = "NO ENUM" if enum_long_name.blank?
              else
                #---------------------------
                int_type_name = db2_records[0][8]
                integertypes_condition_val = db2.execute("select imperial_unit ,size , scale_factor , lower_bound , upper_bound , signed_number from integertypes where layout_index = #{column_values[1].to_i} and layout_type =#{column_values[2].to_i} and int_type_name like '#{int_type_name}'")
                value_update = rt_current_value[0]
                factor = 1
                check_for_signed = false
                if !integertypes_condition_val.blank?
                  factor = (integertypes_condition_val[0][2].to_f / 1000).to_f
                  check_for_signed = true if integertypes_condition_val[0][5] == 'Yes'
                end
                value_display_name = value_update.to_f * factor
                value_display_name = get_signed_value(value_display_name, integertypes_condition_val[0][1]) if check_for_signed == true
                rt_value = value_display_name.to_i
                #----------------------------
              end
            end
            db2_plus_rows << {:layout_index => column_values[1] , :cardindex => column_values[3], :param_long_name =>column_values[7] ,:name =>column_values[6], :context_string =>column_values[9] , :current_value => rt_value }
          end
        end # db2_v_results_formated.each

        if !db2_plus_rows.blank? 
          card_type_result_display << {:page_name=> page_name ,:db2_plus_rows => db2_plus_rows}
        end
      end
      
      
      
      #------------------------------Non-Vital DB Information comparison between pac files---------------------------------------
      db1_nv_info = db1_nvconfig.execute("Select Product_Name, Platform_Name, Database_Name, Database_Version, Build_Number, Compatibility_Index  from Version_Information")
      db2_nv_info = db2_nvconfig.execute("Select Product_Name, Platform_Name, Database_Name, Database_Version, Build_Number, Compatibility_Index  from Version_Information")
      nv_compare_result = db1_nv_info - db2_nv_info
      nv_versions_columns = ["Product Name", "Platform Name", "Database Name", "Database Version", "Build Number", "Compatibility Index"] 
      if !nv_compare_result.blank?
         nv_versions_columns.each_with_index do |column_name , index |
           pac1_and_pac2_nv_config_version_info << {:db1_nv_information =>{:"#{column_name}"=>"#{db1_nv_info[0][index]}"} , :db2_nv_information =>{:"#{column_name}"=>"#{db2_nv_info[0][index]}"}}
           index +=1
         end
      end
      
      #------------------------------Non-Vital Program comparison between pac files---------------------------------------
      db1_nvconfig_records = []
      db2_nvconfig_records = []
      nv_db1_db2_not_equal_rows = []
      db2_minus_rows = []
      db2_plus_rows = []
       
      db1_nvconfig_group_ids =  db1_nvconfig.execute("Select distinct(ID) from Parameter_Groups where Parent_Group_ID is NULL order by ID").collect{|v|v[0]}
      db2_nvconfig_group_ids =  db2_nvconfig.execute("Select distinct(ID) from Parameter_Groups where Parent_Group_ID is NULL order by ID").collect{|v|v[0]}
      
      db1_nvconfig_group_ids.each do |group_id|
        group_channel_with_names = db1_nvconfig.execute("Select Group_Name ,Group_Channel from Parameter_Groups where ID =#{group_id.to_i}")
        group_channel_with_names.each do | group_channel_with_name |
          group_name = group_channel_with_name[0]
          group_channel = group_channel_with_name[1]
          db1_nvconfig_records << {:Group_ID => group_id , :Group_Name => group_name ,:Group_Channel => group_channel , :sub_group_params => get_subgroup_param_records(db1_nvconfig , group_id , group_channel) ,:enum_params => get_enum_params(db1_nvconfig, group_id, group_channel) , :int_params => get_int_params(db1_nvconfig, group_id, group_channel) ,:strings_params => get_string_params(db1_nvconfig, group_id, group_channel) , :bytearray_params => get_bytearray_params(db1_nvconfig, group_id, group_channel)}  
        end
      end
      
      db2_nvconfig_group_ids.each do |group_id|
        group_channel_with_names = db2_nvconfig.execute("Select Group_Name ,Group_Channel from Parameter_Groups where ID =#{group_id.to_i}")
        group_channel_with_names.each do | group_channel_with_name |
          group_name = group_channel_with_name[0]
          group_channel = group_channel_with_name[1]
          db2_nvconfig_records << {:Group_ID => group_id , :Group_Name => group_name ,:Group_Channel => group_channel , :sub_group_params => get_subgroup_param_records(db2_nvconfig, group_id, group_channel) ,:enum_params => get_enum_params(db2_nvconfig, group_id, group_channel) , :int_params => get_int_params(db2_nvconfig, group_id, group_channel) ,:strings_params => get_string_params(db2_nvconfig, group_id, group_channel) , :bytearray_params => get_bytearray_params(db2_nvconfig, group_id, group_channel)}  
        end
      end
      
      db1_nvconfig_records.each do |db1_nvconfig_record|
        db2_equal_group_params  = db2_nvconfig_records.select {|db2_nvconfig_record| (db2_nvconfig_record[:Group_ID].to_i == db1_nvconfig_record[:Group_ID].to_i)  && (db2_nvconfig_record[:Group_Channel].to_i == db1_nvconfig_record[:Group_Channel].to_i )  }
        if !db2_equal_group_params.blank?
          db2_equal_group_params.each do |db2_equal_group_param|
            if ((db2_equal_group_param[:Group_ID].to_i == db1_nvconfig_record[:Group_ID].to_i) && (db2_equal_group_param[:Group_Channel].to_i == db1_nvconfig_record[:Group_Channel].to_i))
              not_equal_rows = []
              if !db1_nvconfig_record[:enum_params].blank?
                db1_nvconfig_record[:enum_params].each do |enum_param|
                  not_equal = db2_equal_group_param[:enum_params].select {|db2_equal| ((db2_equal[0] == enum_param[0]) && ((db2_equal[3] != enum_param[3]) || (db2_equal[4] != enum_param[4]))) }
                  if !not_equal.blank?
                    tb1_enum_value = ""
                    tb2_enum_value = ""
                    if !enum_param[4].blank?
                      db1_enum_value = db1_nvconfig.execute("select Name from Enum_Values where ID=#{enum_param[4].to_i}").collect{|v|v[0]}
                      tb1_enum_value = db1_enum_value[0].to_s  
                    end
                    if !not_equal[0][4].blank?
                      db2_enum_value = db2_nvconfig.execute("select Name from Enum_Values where ID=#{not_equal[0][4].to_i}").collect{|v|v[0]}
                      tb2_enum_value = db2_enum_value[0].to_s  
                    end
                    not_equal_rows << {:ID => "enum_" + not_equal[0][0].to_s , :table1_rows =>{:ID => not_equal[0][0] ,:ParamsName => enum_param[3] , :CurrentValue =>tb1_enum_value} , :table2_rows =>{:ID => not_equal[0][0] ,:ParamsName => not_equal[0][3] , :CurrentValue =>tb2_enum_value}}
                  else
                    # Display the Enum name mismatch - START - value is same but the enum name different
                    not_equal = db2_equal_group_param[:enum_params].select {|db2_equal| ((db2_equal[0] == enum_param[0]) && ((db2_equal[3] != enum_param[3]) || (db2_equal[4] == enum_param[4]))) }
                    if !not_equal.blank?
                      tb1_enum_value = ""
                      tb2_enum_value = ""
                      if !enum_param[4].blank?
                        db1_enum_value = db1_nvconfig.execute("select Name from Enum_Values where ID=#{enum_param[4].to_i}").collect{|v|v[0]}
                        tb1_enum_value = db1_enum_value[0].to_s
                      end
                      if !not_equal[0][4].blank?
                        db2_enum_value = db2_nvconfig.execute("select Name from Enum_Values where ID=#{not_equal[0][4].to_i}").collect{|v|v[0]}
                        tb2_enum_value = db2_enum_value[0].to_s
                      end
                      if(tb1_enum_value != tb2_enum_value)
                          not_equal_rows << {:ID => "enum_" + not_equal[0][0].to_s , :table1_rows =>{:ID => not_equal[0][0] ,:ParamsName => enum_param[3] , :CurrentValue =>tb1_enum_value} , :table2_rows =>{:ID => not_equal[0][0] ,:ParamsName => not_equal[0][3] , :CurrentValue =>tb2_enum_value}}
                      end
                    end
                    # Display the Enum name mismatch - END
                  end
                end
              end
              if !db1_nvconfig_record[:int_params].blank?
                db1_nvconfig_record[:int_params].each do |int_param|
                  not_equal = db2_equal_group_param[:int_params].select {|db2_equal| ((db2_equal[0] == int_param[0]) && ((db2_equal[3] != int_param[3]) || (db2_equal[4] != int_param[4]))) }
                  if !not_equal.blank?
                    not_equal_rows << {:ID => "int_" + not_equal[0][0].to_s , :table1_rows =>{:ID => not_equal[0][0] ,:ParamsName => int_param[3] , :CurrentValue => int_param[4]} , :table2_rows =>{:ID => not_equal[0][0] ,:ParamsName => not_equal[0][3] , :CurrentValue => not_equal[0][4]}}
                  end
                end
              end

              if !db1_nvconfig_record[:strings_params].blank?
                db1_nvconfig_record[:strings_params].each do |strings_param|
                  not_equal = db2_equal_group_param[:strings_params].select {|db2_equal| ((db2_equal[0] == strings_param[0]) && ((db2_equal[3].strip.to_s != strings_param[3].strip.to_s) || (db2_equal[4].strip.to_s != strings_param[4].strip.to_s))) }
                  if !not_equal.blank?
                    not_equal_rows << {:ID => "str_" + not_equal[0][0].to_s ,:table1_rows =>{:ID => not_equal[0][0] ,:ParamsName => strings_param[3] , :CurrentValue => strings_param[4]} , :table2_rows =>{:ID => not_equal[0][0] ,:ParamsName => not_equal[0][3] , :CurrentValue => not_equal[0][4]}}
                  end
                end
              end

              if !db1_nvconfig_record[:bytearray_params].blank?
                db1_nvconfig_record[:bytearray_params].each do |bytearray_param|
                  not_equal = db2_equal_group_param[:bytearray_params].select {|db2_equal| ((db2_equal[0] == bytearray_param[0]) && ((db2_equal[3] != bytearray_param[3]) || (db2_equal[4] != bytearray_param[4]))) }
                  if !not_equal.blank?
                    not_equal_rows << {:ID => "byte_" + not_equal[0][0].to_s ,:table1_rows =>{:ID => not_equal[0][0] ,:ParamsName => bytearray_param[3] , :CurrentValue => bytearray_param[4]} , :table2_rows =>{:ID => not_equal[0][0] ,:ParamsName => not_equal[0][3] , :CurrentValue => not_equal[0][4]}}
                  end
                end
              end

              # Sub group Params
              
              if !db1_nvconfig_record[:sub_group_params].blank?
                if !db2_equal_group_param[:sub_group_params].blank?
                  
                  if !db1_nvconfig_record[:sub_group_params][0][:enum_params].blank?
                    db1_nvconfig_record[:sub_group_params][0][:enum_params].each do |enum_param|
                      not_equal = db2_equal_group_param[:sub_group_params][0][:enum_params].select {|db2_equal| ((db2_equal[0] == enum_param[0]) && ((db2_equal[3] != enum_param[3]) || (db2_equal[4] != enum_param[4]))) }
                      if !not_equal.blank?
                        db1_enum_value = db1_nvconfig.execute("select Name from Enum_Values where ID=#{enum_param[4].to_i}").collect{|v|v[0]}
                        tb1_enum_value = db1_enum_value[0].to_s
                        db2_enum_value = db2_nvconfig.execute("select Name from Enum_Values where ID=#{not_equal[0][4].to_i}").collect{|v|v[0]}
                        tb2_enum_value = db2_enum_value[0].to_s
                        not_equal_rows << {:ID => "enum_" + not_equal[0][0].to_s , :table1_rows =>{:ID => not_equal[0][0] ,:ParamsName => enum_param[3] , :CurrentValue => tb1_enum_value} , :table2_rows =>{:ID => not_equal[0][0] ,:ParamsName => not_equal[0][3] , :CurrentValue => tb2_enum_value}}
                      end
                    end
                  end
                  
                  if !db1_nvconfig_record[:sub_group_params][0][:int_params].blank?
                    db1_nvconfig_record[:sub_group_params][0][:int_params].each do |int_param|
                      not_equal = db2_equal_group_param[:sub_group_params][0][:int_params].select {|db2_equal| ((db2_equal[0] == int_param[0]) && ((db2_equal[3] != int_param[3]) || (db2_equal[4] != int_param[4]))) }
                      if !not_equal.blank?
                        not_equal_rows << {:ID => "int_" + not_equal[0][0].to_s , :table1_rows =>{:ID => not_equal[0][0] ,:ParamsName => int_param[3] , :CurrentValue => int_param[4]} , :table2_rows =>{:ID => not_equal[0][0] ,:ParamsName => not_equal[0][3] , :CurrentValue => not_equal[0][4]}}
                      end
                    end
                  end
                  if !db1_nvconfig_record[:sub_group_params][0][:strings_params].blank?
                    db1_nvconfig_record[:sub_group_params][0][:strings_params].each do |strings_param|
                      not_equal = db2_equal_group_param[:sub_group_params][0][:strings_params].select {|db2_equal| ((db2_equal[0] == strings_param[3]) && ((db2_equal[3] != strings_param[4]) || (db2_equal[4] != strings_param[4]))) }
                      if !not_equal.blank?
                        not_equal_rows << {:ID => "str_" + not_equal[0][0].to_s , :table1_rows =>{:ID => not_equal[0][0] ,:ParamsName => strings_param[3] , :CurrentValue => strings_param[4]} , :table2_rows =>{:ID => not_equal[0][0] ,:ParamsName => not_equal[0][3] , :CurrentValue => not_equal[0][4]}}
                      end
                    end
                  end
                  if !db1_nvconfig_record[:sub_group_params][0][:bytearray_params].blank?
                    db1_nvconfig_record[:sub_group_params][0][:bytearray_params].each do |bytearray_param|
                      not_equal = db2_equal_group_param[:sub_group_params][0][:bytearray_params].select {|db2_equal| ((db2_equal[0] == bytearray_param[0]) && ((db2_equal[3] != bytearray_param[3]) || (db2_equal[4] != bytearray_param[4]))) }
                      if !not_equal.blank?
                        not_equal_rows << {:ID => "byte_" + not_equal[0][0].to_s ,:table1_rows =>{:ID => not_equal[0][0] ,:ParamsName => bytearray_param[3] , :CurrentValue => bytearray_param[4]} , :table2_rows =>{:ID => not_equal[0][0] ,:ParamsName => not_equal[0][3] , :CurrentValue => not_equal[0][4]}}
                      end
                    end
                  end
                end
              end
              
              not_equal_rows.uniq! { |not_equal_row| not_equal_row[:ID]}
              not_equal_rows.sort_by! {|not_equal_row| not_equal_row[:ID]}
              if !not_equal_rows.blank?
                nv_db1_db2_not_equal_rows << {:Group_Name => db1_nvconfig_record[:Group_Name], :Group_ID => db1_nvconfig_record[:Group_ID] , :Group_Channel =>db1_nvconfig_record[:Group_Channel]  , :not_equal_rows=>not_equal_rows}
              end
            end
          end # nv_db1_db2_not_equal_rows end
        end
        
        #MINUS ROWS
        minus_rows = []
        if !db1_nvconfig_record[:enum_params].blank?
          compare_results = compare_hash_values(db1_nvconfig_record[:enum_params] , db2_equal_group_params[0][:enum_params])
          if !compare_results.blank?
            compare_results.each do |enum_param|
              db1_enum_value = db1_nvconfig.execute("select Name from Enum_Values where ID=#{enum_param[4].to_i}").collect{|v|v[0]}
              tb1_enum_value = db1_enum_value[0].to_s
              minus_rows << {:ID => enum_param[0] ,:ParamsName => enum_param[3] , :CurrentValue => tb1_enum_value}
            end
          end
        end
        if !db1_nvconfig_record[:int_params].blank?
          compare_results = compare_hash_values(db1_nvconfig_record[:int_params] , db2_equal_group_params[0][:int_params])
          if !compare_results.blank?
            compare_results.each do |int_param|
              minus_rows << {:ID => int_param[0] ,:ParamsName => int_param[3] , :CurrentValue => int_param[4]}
            end
          end
        end
        if !db1_nvconfig_record[:strings_params].blank?
          compare_results = compare_hash_values(db1_nvconfig_record[:strings_params] , db2_equal_group_params[0][:strings_params])
          if !compare_results.blank?
            compare_results.each do |strings_param|            
              minus_rows << {:ID => strings_param[0] ,:ParamsName => strings_param[3] , :CurrentValue => strings_param[4]}
            end
          end
        end
        if !db1_nvconfig_record[:bytearray_params].blank?
          compare_results = compare_hash_values(db1_nvconfig_record[:bytearray_params] , db2_equal_group_params[0][:bytearray_params])
          if !compare_results.blank?
            compare_results.each do |bytearray_param|  
              minus_rows << {:ID => bytearray_param[0] ,:ParamsName => bytearray_param[3] , :CurrentValue => bytearray_param[4]}
            end
          end
        end

        # Sub groups parms
        if !db1_nvconfig_record[:sub_group_params].blank?
          if !db2_equal_group_params[0][:sub_group_params].blank?
            if !db1_nvconfig_record[:sub_group_params][0][:enum_params].blank?
              compare_results = compare_hash_values(db1_nvconfig_record[:sub_group_params][0][:enum_params] , db2_equal_group_params[0][:sub_group_params][0][:enum_params])
              if !compare_results.blank?
                compare_results.each do |enum_param|
                  db1_enum_value = db1_nvconfig.execute("select Name from Enum_Values where ID=#{enum_param[4].to_i}").collect{|v|v[0]}
                  tb1_enum_value = db1_enum_value[0].to_s
                  minus_rows << {:ID => enum_param[0] ,:ParamsName => enum_param[3] , :CurrentValue => tb1_enum_value}
                end
              end
            end
            if !db1_nvconfig_record[:sub_group_params][0][:int_params].blank?
              compare_results = compare_hash_values(db1_nvconfig_record[:sub_group_params][0][:int_params] , db2_equal_group_params[0][:sub_group_params][0][:int_params])
              if !compare_results.blank?
                compare_results.each do |int_param|
                  minus_rows << {:ID => int_param[0] ,:ParamsName => int_param[3] , :CurrentValue => int_param[4]}
                end
              end
            end
            if !db1_nvconfig_record[:sub_group_params][0][:strings_params].blank?
              compare_results = compare_hash_values(db1_nvconfig_record[:sub_group_params][0][:strings_params] , db2_equal_group_params[0][:sub_group_params][0][:strings_params])
              if !compare_results.blank?
                compare_results.each do |strings_param|
                  minus_rows << {:ID => strings_param[0] ,:ParamsName => strings_param[3] , :CurrentValue => strings_param[4]}
                end
              end
            end
            if !db1_nvconfig_record[:sub_group_params][0][:bytearray_params].blank?
              compare_results = compare_hash_values(db1_nvconfig_record[:sub_group_params][0][:bytearray_params] , db2_equal_group_params[0][:sub_group_params][0][:bytearray_params])
              if !compare_results.blank?
                compare_results.each do |bytearray_param|
                  minus_rows << {:ID => bytearray_param[0] ,:ParamsName => bytearray_param[3] , :CurrentValue => bytearray_param[4]}
                end
              end
            end
          end
        end  # # Sub groups parms -end
        
        minus_rows.uniq! {|min_row| min_row[:ID] }
        minus_rows.sort_by! {|min_row| min_row[:ID]}
        if !minus_rows.blank?
          db2_minus_rows << {:Group_Name => db1_nvconfig_record[:Group_Name], :Group_ID => db1_nvconfig_record[:Group_ID] , :Group_Channel =>db1_nvconfig_record[:Group_Channel] ,:minus_rows => minus_rows}
        end
        #MINUS ROWS -END
      end # db1_minus_db2.each 

      db2_nvconfig_records.each do |db2_nvconfig_record|
        db1_equal_group_id_params  = db1_nvconfig_records.select {|db1_nvconfig_record| (db1_nvconfig_record[:Group_ID].to_i == db2_nvconfig_record[:Group_ID].to_i) && (db1_nvconfig_record[:Group_Channel].to_i == db2_nvconfig_record[:Group_Channel].to_i) }
          plus_rows = []
          if !db2_nvconfig_record[:enum_params].blank?
            compare_results = compare_hash_values(db2_nvconfig_record[:enum_params] , db1_equal_group_id_params[0][:enum_params])
            if !compare_results.blank?
              compare_results.each do |enum_param|
                db1_enum_value = db1_nvconfig.execute("select Name from Enum_Values where ID=#{enum_param[4].to_i}").collect{|v|v[0]}
                tb1_enum_value = db1_enum_value[0].to_s
                plus_rows << {:ID => enum_param[0] ,:ParamsName => enum_param[3] , :CurrentValue => tb1_enum_value}
              end
            end
          end
          
          if !db2_nvconfig_record[:int_params].blank?
            compare_results = compare_hash_values(db2_nvconfig_record[:int_params] , db1_equal_group_id_params[0][:int_params])
            if !compare_results.blank?
              compare_results.each do |int_param|
                plus_rows << {:ID => int_param[0] ,:ParamsName => int_param[3] , :CurrentValue => int_param[4]}
              end
            end
          end
          
          if !db2_nvconfig_record[:strings_params].blank?
            compare_results = compare_hash_values(db2_nvconfig_record[:strings_params] , db1_equal_group_id_params[0][:strings_params])
            if !compare_results.blank?
              compare_results.each do |strings_param|
                plus_rows << {:ID => strings_param[0] ,:ParamsName => strings_param[3] , :CurrentValue => strings_param[4]}
              end
            end
          end
          if !db2_nvconfig_record[:bytearray_params].blank?
            compare_results = compare_hash_values(db2_nvconfig_record[:bytearray_params] , db1_equal_group_id_params[0][:bytearray_params])
            if !compare_results.blank?
              compare_results.each do |bytearray_param|
                plus_rows << {:ID => bytearray_param[0] ,:ParamsName => bytearray_param[3] , :CurrentValue => bytearray_param[4]}
              end
            end
          end

          # Sub groups parms
          # if !db2_nvconfig_record[:sub_group_params].blank?
            # if !db2_nvconfig_record[:sub_group_params][0][:enum_params].blank?
              # compare_results = compare_hash_values(db2_nvconfig_record[:sub_group_params][0][:enum_params] , db1_equal_group_id_params[0][:sub_group_params][0][:enum_params])
              # if !compare_results.blank?
                # compare_results.each do |enum_param|
                  # db1_enum_value = db1_nvconfig.execute("select Name from Enum_Values where ID=#{enum_param[4].to_i}").collect{|v|v[0]}
                  # tb1_enum_value = db1_enum_value[0].to_s
                  # plus_rows << {:ID => enum_param[0] ,:ParamsName => enum_param[3] , :CurrentValue => tb1_enum_value}
                # end
              # end
            # end
#               
            # if !db2_nvconfig_record[:sub_group_params][0][:int_params].blank?
              # compare_results = compare_hash_values(db2_nvconfig_record[:sub_group_params][0][:int_params] , db1_equal_group_id_params[0][:sub_group_params][0][:int_params])
              # if !compare_results.blank?
                # compare_results.each do |int_param|
                  # plus_rows << {:ID => int_param[0] ,:ParamsName => int_param[3] , :CurrentValue => int_param[4]}
                # end
              # end
            # end
            # if !db2_nvconfig_record[:sub_group_params][0][:strings_params].blank?
              # compare_results = compare_hash_values(db2_nvconfig_record[:sub_group_params][0][:strings_params] , db1_equal_group_id_params[0][:sub_group_params][0][:strings_params])
              # if !compare_results.blank?
                # compare_results.each do |strings_param|
                  # plus_rows << {:ID => strings_param[0] ,:ParamsName => strings_param[3] , :CurrentValue => strings_param[4]}
                # end
              # end
            # end
            # if !db2_nvconfig_record[:sub_group_params][0][:bytearray_params].blank?
              # compare_results = compare_hash_values(db2_nvconfig_record[:sub_group_params][0][:bytearray_params] , db1_equal_group_id_params[0][:sub_group_params][0][:bytearray_params])
              # if !compare_results.blank?
                # compare_results.each do |bytearray_param|
                  # plus_rows << {:ID => bytearray_param[0] ,:ParamsName => bytearray_param[3] , :CurrentValue => bytearray_param[4]}
                # end
              # end
            # end
          # end # Sub groups parms end
          plus_rows.uniq! {|plus_row| plus_row[:ID]}
          plus_rows.sort_by! {|plus_row| plus_row[:ID]}
          if !plus_rows.blank?
            db2_plus_rows << {:Group_Name => db2_nvconfig_record[:Group_Name], :Group_ID => db2_nvconfig_record[:Group_ID] , :Group_Channel =>db2_nvconfig_record[:Group_Channel] ,:plus_rows => plus_rows}
          end
      end # db2_minus_db1.each
      
      if !nv_db1_db2_not_equal_rows.blank? || !db2_minus_rows.blank? || !db2_plus_rows.blank?
          db1_and_db2_compare_results << {:TableName => "Group_Name", :db1_db2_not_equal_rows => nv_db1_db2_not_equal_rows ,:db2_plus_rows => db2_plus_rows , :db2_minus_rows => db2_minus_rows }
      end
      
      # Compare the :CDL_OpParams , :CDL_Questions , :Wizard_Questions tables
      lst_tables = {:CDL_OpParams => ["ID" , "Param_Type" , "Param_Name" , "Param_Comment" , "Min_Value" , "Max_Value" , "Current_Value"],
                  :CDL_Questions => ["ID","Question_Type","Question_Title","Question_Text", "Is_Answered","Answer_Min","Answer_Max","Answer_Default", "Answer_Value"],
                  :Wizard_Questions => ["ID", "Question_Type","Question_Title", "Question_Text","Is_Answered","Answer_Min","Answer_Max","Answer_Default","Answer_Value"]
      }
       
      lst_tables.each do |table_name, columns|
        db2_plus_rows = [] # databse 1 not available records and database 2 available records(PLUS)
        db2_minus_rows = [] # databse 2 not available records and database 1 available records(MINUS)
        db1_db2_not_equal_rows = [] #database 1 and database 2 not equal records(NOT EQUAL)
        
        db1_nv_results = db1_nvconfig.execute('select * from ' + table_name.to_s)
        db2_nv_results = db2_nvconfig.execute('select * from ' + table_name.to_s)
        
        db1_nv_results_formated = []
        db2_nv_results_formated = []
        
        #Non-Vital comparison for CDL and Wizard tables
        if (table_name.to_s.start_with?("CDL", "Wizard"))
          db1_nv_results.each do |db1_nv_result|
            db1_nv_results_formated << db1_nv_result[0,9].join('_$$_')
          end
        
          db2_nv_results.each do |db2_nv_result|
            db2_nv_results_formated << db2_nv_result[0,9].join('_$$_')
          end
          
          res_nv_db1 = db1_nv_results_formated - db2_nv_results_formated
          res_nv_db2 = db2_nv_results_formated - db1_nv_results_formated
          
          res_nv_db1.each do |res_nv_db1_value|
            column_values = res_nv_db1_value.split("_$$_")
            where_conditions = "#{columns[0]} = #{column_values[0]}" # ID
            if (table_name.downcase.to_s == "cdl_opparams")
              select_value = "#{columns[0]} , #{columns[2]} , #{columns[6]}"  #ID , Param_Name , Answer_value
            else
              select_value = "#{columns[0]} , #{columns[3]} , #{columns[8]}"  #ID , Question_Text , Answer_value                
            end
                
            db1_records = db1_nvconfig.execute("Select #{select_value} from #{table_name.to_s} Where #{where_conditions}")
            db2_records = db2_nvconfig.execute("Select #{select_value} from #{table_name.to_s} Where #{where_conditions}")
            
            if db2_records.blank?
              if(table_name.downcase.to_s == "cdl_questions")
                select_option_query = "select Option_text from CDL_Answer_Options where Question_ID=#{db1_records[0][0]} and Answer_Value ='#{db1_records[0][2]}'"
              elsif (table_name.downcase.to_s == "cdl_opparams")
                select_option_query = "select Option_Text from CDL_OpParam_Options where OpParam_ID=#{db1_records[0][0]} and Option_Value ='#{db1_records[0][2]}'"
              else
                 select_option_query = "select Option_text from Wizard_Answer_Options where Question_ID=#{db1_records[0][0]} and Answer_Value ='#{db1_records[0][2]}'"
              end 
              
              values_ct = db1_nvconfig.execute(select_option_query).collect{|v|v[0]}
              if !values_ct.blank?
                ct_record_value = values_ct[0].to_s  
              else
                ct_record_value = db1_records[0][2]
              end
              db2_minus_rows << {:ID => db1_records[0][0], :ParamsName => db1_records[0][1] , :CurrentValue => ct_record_value}
            else              
              unless db1_records.blank? && db2_records.blank?
                if((db2_records[0][1] != db1_records[0][1]) || (db2_records[0][2] != db1_records[0][2])) # Not Equal db2 current(2) , default(3) 
                  if(table_name.downcase.to_s == "cdl_questions")
                    db1_select_option_query = "select Option_text from CDL_Answer_Options where Question_ID=#{db1_records[0][0]} and Answer_Value ='#{db1_records[0][2]}'"
                    db2_select_option_query = "select Option_text from CDL_Answer_Options where Question_ID=#{db2_records[0][0]} and Answer_Value ='#{db2_records[0][2]}'"
                  elsif (table_name.downcase.to_s == "cdl_opparams")
                    db1_select_option_query = "select Option_Text from CDL_OpParam_Options where OpParam_ID=#{db1_records[0][0]} and Option_Value ='#{db1_records[0][2]}'"
                    db2_select_option_query = "select Option_Text from CDL_OpParam_Options where OpParam_ID=#{db2_records[0][0]} and Option_Value ='#{db2_records[0][2]}'"
                  else
                     db1_select_option_query = "select Option_text from Wizard_Answer_Options where Question_ID=#{db1_records[0][0]} and Answer_Value ='#{db1_records[0][2]}'"
                     db2_select_option_query = "select Option_text from Wizard_Answer_Options where Question_ID=#{db2_records[0][0]} and Answer_Value ='#{db2_records[0][2]}'"
                  end 
                  
                  db1_values_ct = db1_nvconfig.execute(db1_select_option_query).collect{|v|v[0]}
                  if !db1_values_ct.blank?
                    db1_ct_record_value = db1_values_ct[0].to_s  
                  else
                    db1_ct_record_value = db1_records[0][2]
                  end

                  db2_values_ct = db2_nvconfig.execute(db2_select_option_query).collect{|v|v[0]}
                  if !db2_values_ct.blank?
                    db2_ct_record_value = db2_values_ct[0].to_s    
                  else
                    db2_ct_record_value = db2_records[0][2]
                  end
                  db1_db2_not_equal_rows << {:table1_rows =>{:ID => db1_records[0][0], :ParamsName => db1_records[0][1] , :CurrentValue => db1_ct_record_value} , :table2_rows =>{:ID => db2_records[0][0], :ParamsName => db2_records[0][1] , :CurrentValue => db2_ct_record_value}}
                end   # !=
              end # unless
            end # else
          end # res_nv_db1
                   
          res_nv_db2.each do |res_nv_db2_value|
            column_values = res_nv_db2_value.split("_$$_")
            where_conditions = "#{columns[0]}= #{column_values[0]}"
            if (table_name.downcase.to_s == "cdl_opparams")
              select_value = "#{columns[0]} , #{columns[2]} , #{columns[6]}"
            else
              select_value = "#{columns[0]} , #{columns[3]} , #{columns[8]}"
            end
            
            db2_records = db2_nvconfig.execute("Select #{select_value} from #{table_name.to_s} Where #{where_conditions}")
            db1_records = db1_nvconfig.execute("Select #{select_value} from #{table_name.to_s} Where #{where_conditions}")
            if db1_records.blank?
              if(table_name.downcase.to_s == "cdl_questions")
                select_option_query = "select Option_text from CDL_Answer_Options where Question_ID=#{db2_records[0][0]} and Answer_Value ='#{db2_records[0][2]}'"
              elsif (table_name.downcase.to_s == "cdl_opparams")
                select_option_query = "select Option_Text from CDL_OpParam_Options where OpParam_ID=#{db2_records[0][0]} and Option_Value ='#{db2_records[0][2]}'"
              else
                 select_option_query = "select Option_text from Wizard_Answer_Options where Question_ID=#{db2_records[0][0]} and Answer_Value ='#{db2_records[0][2]}'"
              end 
              
              db2_values_ct = db2_nvconfig.execute(select_option_query).collect{|v|v[0]}
              if !db2_values_ct.blank?
                db2_ct_record_value = db2_values_ct[0].to_s
              else
                db2_ct_record_value = db2_records[0][2]
              end
              db2_plus_rows << {:ID => db2_records[0][0], :ParamsName => db2_records[0][1] , :CurrentValue => db2_ct_record_value }
            end
          end # res_nv_db2
        end #CDL & Wizrad Code END
        
        if(!res_nv_db1.blank? || !res_nv_db2.blank?)
          if !db2_plus_rows.blank? || !db2_minus_rows.blank? || !db1_db2_not_equal_rows.blank? 
            db1_and_db2_compare_results << {:TableName => table_name.to_s ,:db2_plus_rows => db2_plus_rows , :db2_minus_rows => db2_minus_rows , :db1_db2_not_equal_rows => db1_db2_not_equal_rows }  
          end
        end
      end  # lst_tables END
      #----------------Non-Vital Program comparison between pac files-END-----------------  
      
      #Display PAC Files Comaprison Table
      mab.html do
        head do 
          title "PAC file comparison report"
          style :type => "text/css" do
           %[body,#mycontent { font-family: Arial;font-size: 13px; background-color:#282828 ;color:#F2F2F2; }
             .comparisoncontent table th{font-family: Arial;background-color: #424242;text-align: center ;color: #CFD638; width: 8%;font-size:13px;font-weight:bold; }
             .comparisoncontent table{font-family: Arial;background-color: #787878; border:1px solid #4E4E4E; color: #E4E4E4; width: 100%; text-align: left ;}
             .comparisoncontent table tr td {font-family: Arial;font-size:13px;word-wrap: break-word;}
             ]
          end
        end
        
        dark_bg = "background: #424242;"
        light_bg = "background: #515151;"
        body do 
          div.comparisoncontent  :style =>"border-top: 0;" do
            div "", :style => "clear:both; padding-top:10px;width:auto;"
            a "Goto Non-Vital Report", :href => "#nonvital" , :style =>"display:none;color:#CFD638;font-weight: bold;"
            div "PAC file comparison report" , :style => "color: #CFD638;font-family: Arial; font-size:15px;font-weight:bold;text-align: center;"
            div "", :style => "clear:both; padding-top:20px;width:auto;"
            icon_style = "font-size:18px;font-weight:bold;text-align:center;color:#A7C942"
            
            #---------------------------------Display PAC Information ----------------------------
            if !pac1_mcf_info.blank? && !pac2_mcf_info.blank? 
              #PAC Information 
              table :style =>"width:97%;" do
                tr do
                  th "PAC File Information",:colspan=>4
                end
                tr do
                  th "",:style =>"width:50%;"
                  th "MCF Name",:style =>"width:20%;"
                  th "MCFCRC",:style =>"width:20%;"
                  th "Revision",:style =>"width:10%;"
                end
                
                tr_count = 0
                pac1_mcf_info.each do |pac1_mcf_inf |
                  bg = (tr_count%2 == 0) ?  light_bg : dark_bg 
                  tr :style =>bg  do
                     td pac1_mcf_inf[:PacName] , :style =>"width:50%;font-family: Arial;color: #CFD638;font-size:13px;font-weight:bold;"
                     td pac1_mcf_inf[:McfName] , :style =>"width:20%;"
                     td pac1_mcf_inf[:Mcfcrc] , :style =>"width:20%;"
                     td pac1_mcf_inf[:Mcfrevision] , :style =>"width:10%;"                                             
                  end
                  tr_count+=1
                end
                
                pac2_mcf_info.each do |pac2_mcf_inf |
                  bg = (tr_count%2 == 0) ?  light_bg : dark_bg 
                  tr :style =>bg  do
                     td pac2_mcf_inf[:PacName] , :style =>"width:50%;font-family: Arial;color: #CFD638;font-size:13px;font-weight:bold;"
                     td pac2_mcf_inf[:McfName] , :style =>"width:20%;"
                     td pac2_mcf_inf[:Mcfcrc] , :style =>"width:20%;"
                     td pac2_mcf_inf[:Mcfrevision] , :style =>"width:10%;"                                             
                  end
                end
                
                if card_type_result_display.blank? && pac1_and_pac2_not_equal_mcf_info.blank? && plus_mcf_info.blank? && minus_mcf_info.blank? && pac1_and_pac2_nv_config_version_info.blank? && db1_and_db2_compare_results.blank?
                  tr :style =>light_bg do
                    th "PAC files are identical" ,:style =>"width:30%;color:#F2F2F2",:colspan=>4
                  end 
                end
                
              end
            end
            
            if !card_type_result_display.blank? || !pac1_and_pac2_not_equal_mcf_info.blank? || !plus_mcf_info.blank? || !minus_mcf_info.blank? || !pac1_and_pac2_nv_config_version_info.blank? || !db1_and_db2_compare_results.blank?
              div "", :style => "clear:both; padding-top:20px;width:auto;"
              #---------------------------------Display MCF Information----------------------------
              if !pac1_and_pac2_not_equal_mcf_info.blank? || !plus_mcf_info.blank? || !minus_mcf_info.blank?
                table :style =>"width:97%;" do
                  tr do
                    th "MCF Information",:colspan=>7
                  end
                  tr do
                    th  "" , :rowspan =>2,:style=>"width:3%;"
                    th "#{pac1}", :colspan=>3,:style =>"width:50%;"
                    th "#{pac2}", :colspan=>3,:style =>"width:50%;"
                  end
                  tr do
                    th "MCF Name",:style =>"width:20%;"
                    th "MCFCRC",:style =>"width:20%;"
                    th "Revision",:style =>"width:10%;"
                    th "MCF Name",:style =>"width:20%;"
                    th "MCFCRC",:style =>"width:20%;"
                    th "Revision",:style =>"width:10%;"
                  end
                  
                  tr_count = 0           
                  #MCF Information Not Equal records results
                  pac1_and_pac2_not_equal_mcf_info.each do |pac1_and_pac2_not_equal_mcf_info|
                    bg = (tr_count%2 == 0) ?  light_bg : dark_bg 
                    tr :style =>bg  do
                      td "≠" , :style =>icon_style
                      if(pac1_and_pac2_not_equal_mcf_info[:Pac1McfName] == pac1_and_pac2_not_equal_mcf_info[:Pac2McfName])
                        td pac1_and_pac2_not_equal_mcf_info[:Pac1McfName] , :style =>"width:20%;"
                      else
                        td pac1_and_pac2_not_equal_mcf_info[:Pac1McfName] , :style =>"width:20%;background-color:#8B0000;color:#FFF;"
                      end
                      
                      if(pac1_and_pac2_not_equal_mcf_info[:Pac1Mcfcrc] == pac1_and_pac2_not_equal_mcf_info [:Pac2Mcfcrc])
                        td pac1_and_pac2_not_equal_mcf_info[:Pac1Mcfcrc] , :style =>"width:20%;"
                      else
                        td pac1_and_pac2_not_equal_mcf_info[:Pac1Mcfcrc] , :style =>"width:20%;background-color:#8B0000;color:#FFF;"
                      end
                      
                      if(pac1_and_pac2_not_equal_mcf_info[:Pac1Mcrevision] == pac1_and_pac2_not_equal_mcf_info [:Pac2Mcrevision])
                        td pac1_and_pac2_not_equal_mcf_info[:Pac1Mcrevision] , :style =>"width:5%;"
                      else
                        td pac1_and_pac2_not_equal_mcf_info[:Pac1Mcrevision] , :style =>"width:5%;background-color:#8B0000;color:#FFF;"
                      end
                      
                      if(pac1_and_pac2_not_equal_mcf_info[:Pac1McfName] == pac1_and_pac2_not_equal_mcf_info[:Pac2McfName])
                        td pac1_and_pac2_not_equal_mcf_info[:Pac2McfName] , :style =>"width:20%;"
                      else
                        td pac1_and_pac2_not_equal_mcf_info[:Pac2McfName] , :style =>"width:20%;background-color:#8B0000;color:#FFF;"
                      end
                      
                      if(pac1_and_pac2_not_equal_mcf_info[:Pac1Mcfcrc] == pac1_and_pac2_not_equal_mcf_info [:Pac2Mcfcrc])         
                        td pac1_and_pac2_not_equal_mcf_info[:Pac2Mcfcrc] , :style =>"width:20%;"
                      else
                        td pac1_and_pac2_not_equal_mcf_info[:Pac2Mcfcrc] , :style =>"width:20%;background-color:#8B0000;color:#FFF;" 
                      end
                      
                      if(pac1_and_pac2_not_equal_mcf_info[:Pac1Mcrevision] == pac1_and_pac2_not_equal_mcf_info [:Pac2Mcrevision])
                        td pac1_and_pac2_not_equal_mcf_info[:Pac2Mcrevision] , :style =>"width:5%;"
                      else
                        td pac1_and_pac2_not_equal_mcf_info[:Pac2Mcrevision] , :style =>"width:5%;background-color:#8B0000;color:#FFF;"
                      end
                    end
                    tr_count+=1
                  end
                  
                  tr_count = 0
                  #MCF Information PAC1 Plus records results
                  plus_mcf_info.each do |plus_mcf_info|
                    bg = (tr_count%2 == 0) ?  light_bg : dark_bg 
                    tr :style =>bg  do
                      td "+" , :style =>icon_style
                      td "" ,:style =>"width:20%;"
                      td "" ,:style =>"width:20%;"
                      td "" ,:style =>"width:5%;"
                      
                      td plus_mcf_info[:Pac1McfName] , :style =>"width:20%;"
                      td plus_mcf_info[:Pac1Mcfcrc] , :style =>"width:20%;"
                      td plus_mcf_info[:Pac1Mcrevision] , :style =>"width:5%;"
                    end
                    tr_count+=1
                  end
                  
                  tr_count = 0
                  #MCF Information PAC1 Minus records results
                  minus_mcf_info.each do |minus_mcf_info|
                    bg = (tr_count%2 == 0) ?  light_bg : dark_bg 
                    tr :style =>bg  do
                      td "-" , :style =>icon_style
                      td minus_mcf_info[:Pac1McfName],:style =>"width:20%;"                 
                      td minus_mcf_info [:Pac1Mcfcrc],:style =>"width:20%;"                 
                      td minus_mcf_info [:Pac1Mcrevision],:style =>"width:5%;"
                      td "" ,:style =>"width:20%;"
                      td "" ,:style =>"width:20%;"
                      td "" ,:style =>"width:5%;"               
                    end
                    tr_count+=1
                  end
                end
              end
              
              #---------------------------------Display Vital Program Comparison----------------------------
              div "", :style => "clear:both; padding-top:20px;width:auto;"
              
              if !card_type_result_display.blank?  
                table :style =>"width:97%;" do
                  tr do
                    th "Program Comparison",:colspan=>7,:style=>"width:30%;"
                  end
                  tr do
                    th  "" , :rowspan =>2,:style =>"width:1%;"
                    # th "Card Type" , :rowspan => 2 ,:style =>"width:5%;"
                    # th "Card Number" , :rowspan => 2 ,:style =>"width:5%;"
                    th "#{pac1}" , :colspan => 2 , :style =>"width:40%;"
                    th "#{pac2}" , :colspan => 2 , :style =>"width:40%;"
                  end
                  tr do              
                    th "Parameter",:style =>"width:20%;"
                    th "Value",:style =>"width:5%;"
                    th "Parameter",:style =>"width:20%;"
                    th "Value",:style =>"width:5%;"
                  end
                  
                  card_type_result_display.each do |card_type_result_display_row |
                    tr :style =>dark_bg  do
                      td card_type_result_display_row[:page_name],:colspan => 6,:style=>"font-weight:bold;color: #CFD638;"
                    end
                    tr_count = 0  
                    # Display PAC1 and PAC2 - Vital Program not equal records 
                    not_equal_rows = card_type_result_display_row[:db1_db2_not_equal_rows]
                    plus_rows = card_type_result_display_row[:db2_plus_rows]
                    minus_rows = card_type_result_display_row[:db2_minus_rows]
                    
                    if !not_equal_rows.blank?
                      not_equal_rows.each do |db1_db2_not_equal_row |
                        table1_row = db1_db2_not_equal_row[:table1_rows]
                        table2_row = db1_db2_not_equal_row[:table2_rows]
      
                        bg = (tr_count%2 == 0) ?  light_bg : dark_bg 
                        tr :style =>bg  do
                          td "≠" , :style =>icon_style
                          # td table1_row[:card_type]
                          # td table1_row[:cardindex]
                            tbl_empty_context_flag = false
                            tb2_empty_context_flag = false
                            tbl_empty_context_flag = true if table1_row[:context_string].blank?
                            tb2_empty_context_flag = true if table2_row[:context_string].blank?
                            table1_parameter_display = (table1_row[:context_string].blank?)? "   : #{(table1_row[:param_long_name].blank?)? table1_row[:name] : table1_row[:param_long_name]}" :  ((table1_row[:param_long_name].blank?)? "#{table1_row[:context_string]} #{table1_row[:name]}" : "#{table1_row[:context_string]} #{table1_row[:param_long_name]}")
                            table2_parameter_display = (table2_row[:context_string].blank?)? "   : #{(table2_row[:param_long_name].blank?)? table2_row[:name] : table2_row[:param_long_name]}" :  ((table2_row[:param_long_name].blank?)? "#{table2_row[:context_string]} #{table2_row[:name]}" : "#{table2_row[:context_string]} #{table2_row[:param_long_name]}")
                            style1_val = (tbl_empty_context_flag == true)? "width:20%;background-color:#8B0000;color:#FFF;padding-left:4em;" : "width:20%;background-color:#8B0000;color:#FFF;"
                            style2_val = (tb2_empty_context_flag == true)? "width:20%;background-color:#8B0000;color:#FFF;padding-left:4em;" : "width:20%;background-color:#8B0000;color:#FFF;"
                            if((table1_row[:param_long_name].to_s != table2_row[:param_long_name].to_s || table1_row[:context_string].to_s != table2_row[:context_string].to_s) && table1_row[:current_value].to_s == table2_row[:current_value].to_s )
                              td table1_parameter_display ,:style => style1_val
                              td table1_row[:current_value] ,:style =>"width:5%;"
                              td table2_parameter_display ,:style =>style2_val
                              td table2_row[:current_value] ,:style =>"width:5%;"
                            elsif(table1_row[:param_long_name].to_s == table2_row[:param_long_name].to_s && table1_row[:context_string].to_s == table2_row[:context_string].to_s && table1_row[:current_value].to_s != table2_row[:current_value].to_s )
                              style1_val = (tbl_empty_context_flag == true) ? "width:20%;padding-left:4em;" :  "width:20%;"
                              style2_val = (tb2_empty_context_flag == true) ? "width:20%;padding-left:4em;" :  "width:20%;"
                              td table1_parameter_display ,:style =>style1_val
                              td table1_row[:current_value] ,:style =>"width:5%;background-color:#8B0000;color:#FFF;"
                              td table2_parameter_display ,:style =>style2_val
                              td table2_row[:current_value] ,:style =>"width:5%;background-color:#8B0000;color:#FFF;"
                            elsif((table1_row[:param_long_name].to_s != table2_row[:param_long_name].to_s || table1_row[:context_string].to_s != table2_row[:context_string].to_s) && table1_row[:current_value].to_s != table2_row[:current_value].to_s )
                              td table1_parameter_display ,:style =>style1_val
                              td table1_row[:current_value] ,:style =>"width:5%;background-color:#8B0000;color:#FFF;"
                              td table2_parameter_display ,:style =>style2_val
                              td table2_row[:current_value] ,:style =>"width:5%;background-color:#8B0000;color:#FFF;"
                            else
                              style1_val = (tbl_empty_context_flag == true) ? "width:20%;padding-left:4em;" :  "width:20%;"
                              style2_val = (tb2_empty_context_flag == true) ? "width:20%;padding-left:4em;" :  "width:20%;"
                              td table1_parameter_display ,:style =>style1_val
                              td table1_row[:current_value] ,:style =>"width:5%;"
                              td table2_parameter_display ,:style =>style2_val
                              td table2_row[:current_value] ,:style =>"width:5%;"
                            end
                        end # tr
                        tr_count+=1   
                      end # each not_equal_rows
                    end # if !not_equal_rows.blank?
                    
                    # Display PAC2 - Vital Program Plus records
                    if !plus_rows.blank?
                      plus_rows.each do |db2_plus_row |
                        bg = (tr_count%2 == 0) ?  light_bg : dark_bg 
                        tr :style =>bg  do
                          td "+" , :style =>icon_style
                          # td db2_plus_row[:card_type]
                          # td db2_plus_row[:cardindex]
                          if (db2_plus_row[:context_string]==nil && db2_plus_row[:param_long_name] != nil)
                           td "" ,:style =>"width:20%;"
                           td "" ,:style =>"width:5%;"
                           td ""+":"+db2_plus_row[:param_long_name] ,:style =>"width:20%;padding-left:4em;"                
                           td db2_plus_row[:current_value] ,:style =>"width:5%;"
                         elsif (db2_plus_row[:context_string] == nil)&& (db2_plus_row[:param_long_name] == nil)
                           td "" ,:style =>"width:20%;"
                           td "" ,:style =>"width:5%;"
                           td ""+":"+db2_plus_row[:name] ,:style =>"width:20%;padding-left:4em;"                
                           td db2_plus_row[:current_value] ,:style =>"width:5%;"
                         else
                           td "" ,:style =>"width:20%;"
                           td "" ,:style =>"width:5%;"
                           td db2_plus_row[:context_string], db2_plus_row[:param_long_name] ,:style =>"width:20%;"                
                           td db2_plus_row[:current_value] ,:style =>"width:5%;"
                          end
                        end # tr
                        tr_count+=1   
                      end # each db2_plus_rows
                    end # if !plus_rows.blank?
                  
                    # Display PAC2 - Vital Program MINUS records
                    if !minus_rows.blank?
                      minus_rows.each do |db2_minus_row |
                        bg = (tr_count%2 == 0) ?  light_bg : dark_bg 
                        tr :style =>bg  do
                          td "-" , :style =>icon_style
                          # td db2_minus_row[:card_type]
                          # td db2_minus_row[:cardindex]
                          if(db2_minus_row[:context_string]==nil && db2_minus_row[:param_long_name] != nil)
                            td ""+":",db2_minus_row[:param_long_name] ,:style =>"width:20%;padding-left:4em;"
                            td db2_minus_row[:current_value] ,:style =>"width:5%;"
                         elsif(db2_minus_row[:context_string] == nil)&& (db2_minus_row[:param_long_name] == nil)                      
                            td ""+":"+db2_minus_row[:name] ,:style =>"width:20%;padding-left:4em;"
                            td db2_minus_row[:current_value] ,:style =>"width:5%;"
                          else
                            td db2_minus_row[:context_string]+db2_minus_row[:param_long_name] ,:style =>"width:20%;"
                            td db2_minus_row[:current_value] ,:style =>"width:5%;"
                          end
                          td "" ,:style =>"width:20%;"                                             
                          td "" ,:style =>"width:5%;"
                        end # tr
                        tr_count+=1   
                      end # each  minus_rows
                    end # if !minus_rows.blank?
                  end #card_type_result_display   each 
                end
              else
                table :style =>"width:97%;" do
                  tr do
                    th "Program Comparison",:colspan=>7,:style=>"width:30%;"
                  end
                  tr :style =>light_bg do
                    th "No Mismatches found" ,:style =>"width:30%;color:#F2F2F2",:colspan=>6
                  end 
                end
              end
              
              
              #---------------------------------Display Non-Vital Parameters comparison----------------------------
              div "", :style => "clear:both; padding-top:25px;width:auto;"
              a :id => 'nonvital' ,:style => "display:none;"
              a "Top", :href => "#top", :style => "display:none;color:#CFD638;font-weight: bold;"
              div "", :style => "clear:both; padding-top:10px;width:auto;"
              #---------------------------------Display Non-Vital DB Information----------------------------
              table :style =>"width:97%;" do
                  tr do
                    th "Non Vital DB Version Comparison",:colspan=>7
                  end
                  if !pac1_and_pac2_nv_config_version_info.blank?
                    # Not eqaul records
                    tr do
                      th  "" , :rowspan =>2,:style=>"width:3%;"
                      th "#{pac1}", :colspan=>2,:style =>"width:40%;"
                      th "#{pac2}", :colspan=>2,:style =>"width:40%;"
                    end
                    tr do
                      th "Information",:style =>"width:20%;"
                      th "Value",:style =>"width:20%;"
                      th "Information",:style =>"width:20%;"
                      th "Value",:style =>"width:20%;"
                    end
                    tr_count = 0
                    pac1_and_pac2_nv_config_version_info.each do |nv_config_version_info |
                      bg = (tr_count%2 == 0) ?  light_bg : dark_bg 
                       db1_val = []
                       db2_val = []
                       nv_config_version_info[:db1_nv_information].each do |key , value| 
                        db1_val = [ key.to_s, value]
                       end
                       nv_config_version_info[:db2_nv_information].each do |key , value| 
                        db2_val = [key.to_s , value]
                       end
                       equal = db1_val - db2_val
                       tr :style =>bg  do
                         if !equal.blank?
                           td "≠" , :style =>icon_style
                           td db1_val[0],:style =>"width:20%;"
                           td db1_val[1],:style =>"width:20%;background-color:#8B0000;color:#FFF;"
                           td db2_val[0],:style =>"width:20%;"
                           td db2_val[1],:style =>"width:20%;background-color:#8B0000;color:#FFF;" 
                         else
                           td "=" , :style =>icon_style
                           td db1_val[0],:style =>"width:20%;"
                           td db1_val[1],:style =>"width:20%;"
                           td db2_val[0],:style =>"width:20%;"
                           td db2_val[1],:style =>"width:20%;" 
                         end
                       end
                       tr_count +=1
                    end # pac1_and_pac2_nv_config_version_info.each
                  else
                    #equal records
                    tr :style =>light_bg do
                      th "No Mismatches found" ,:style =>"width:30%;color:#F2F2F2",:colspan=>5
                    end 
                  end
              end
              
              #---------------------------------Display Non-Vital Program Comparison----------------------------
              div "", :style => "clear:both; padding-top:20px;width:auto;"
              if !db1_and_db2_compare_results.blank? 
                table :style =>"width:97%;" do
                  tr do
                    th "Non-Vital Program Comparision",:style =>"width:30%;",:colspan=>6
                  end
                  tr do
                    th  "" , :rowspan =>2,:style=>"width:1%;"
                    th "ID", :rowspan => 2,:style=>"width:3%;"
                    th "#{pac1}", :colspan => 2, :style =>"width:40%;"
                    th "#{pac2}", :colspan => 2, :style =>"width:40%;"
                  end
                  tr do
                    th "Parameter",:style =>"width:20%;"
                    th "Value",:style =>"width:10%;"
                    th "Parameter",:style =>"width:20%;"
                    th "Value",:style =>"width:10%;"
                  end
                  
                  db1_and_db2_compare_results.each do |db1_and_db2_compare_result|
                    if (db1_and_db2_compare_result[:TableName] != "Group_Name") # CDL , Wizard
                      tr :style =>dark_bg  do
                        td db1_and_db2_compare_result[:TableName],:colspan => 6,:style=>"font-weight:bold;"
                      end
                      tr_count = 0
                      # PAC1 and PAC2 Non-vital records mismatch value display
                      db1_db2_not_equal_rows_info = db1_and_db2_compare_result[:db1_db2_not_equal_rows] 
                      db1_db2_not_equal_rows_info.each do |db1_db2_not_equal_row_info|
                        table1_row = db1_db2_not_equal_row_info[:table1_rows]
                        table2_row = db1_db2_not_equal_row_info[:table2_rows]
                        bg = (tr_count%2 == 0) ?  light_bg : dark_bg 
                        tr :style =>bg  do
                          td "≠" , :style => icon_style
                          td table1_row[:ID],:style=>"width:3%;"
                          
                          if (table1_row[:ParamsName].to_s != table2_row[:ParamsName].to_s && table1_row[:CurrentValue].to_s == table2_row[:CurrentValue].to_s)
                            td table1_row[:ParamsName].to_s ,:style =>"width:20%;background-color:#8B0000;color:#FFF;"
                            td table1_row[:CurrentValue] ,:style =>"width:10%;"
                            td table2_row[:ParamsName].to_s ,:style =>"width:20%;background-color:#8B0000;color:#FFF;"
                            td table2_row[:CurrentValue] ,:style =>"width:10%;"
                          elsif (table1_row[:ParamsName].to_s == table2_row[:ParamsName].to_s && table1_row[:CurrentValue].to_s != table2_row[:CurrentValue].to_s)
                            td table1_row[:ParamsName].to_s ,:style =>"width:20%;"
                            td table1_row[:CurrentValue] ,:style =>"width:10%;background-color:#8B0000;color:#FFF;"    
                            td table2_row[:ParamsName].to_s ,:style =>"width:20%;"
                            td table2_row[:CurrentValue] ,:style =>"width:10%;background-color:#8B0000;color:#FFF;"                       
                          elsif (table1_row[:ParamsName].to_s != table2_row[:ParamsName].to_s && table1_row[:CurrentValue].to_s != table2_row[:CurrentValue].to_s)
                            td table1_row[:ParamsName].to_s ,:style =>"width:20%;background-color:#8B0000;color:#FFF;"
                            td table1_row[:CurrentValue] ,:style =>"width:10%;background-color:#8B0000;color:#FFF;"
                            td table2_row[:ParamsName].to_s ,:style =>"width:20%;background-color:#8B0000;color:#FFF;"
                            td table2_row[:CurrentValue] ,:style =>"width:10%;background-color:#8B0000;color:#FFF;"
                          else 
                            td table1_row[:ParamsName].to_s ,:style =>"width:20%;"
                            td table1_row[:CurrentValue] ,:style =>"width:10%;"
                            td table2_row[:ParamsName].to_s ,:style =>"width:20%;"
                            td table2_row[:CurrentValue] ,:style =>"width:10%;"
                          end
                        end # tr
                        tr_count+=1
                      end # each db1_db2_not_equal_rows_info
                      
                      tr_count = 0
                      # PAC1 and PAC2 Non-vital PLUS records value display
                      db2_plus_rows_info = db1_and_db2_compare_result[:db2_plus_rows]                   
                      db2_plus_rows_info.each do |db2_plus_row_info|
                        bg = (tr_count%2 == 0) ?  light_bg : dark_bg 
                        tr :style =>bg  do
                          td "+" , :style =>icon_style
                          td db2_plus_row_info[:ID]
                          td "" ,:style =>"width:20%;"
                          td "" ,:style =>"width:10%;"
                          td db2_plus_row_info[:ParamsName] ,:style =>"width:20%;"
                          td db2_plus_row_info[:CurrentValue] ,:style =>"width:10%;"
                        end # tr
                        tr_count+=1
                      end # each
                      
                      tr_count = 0
                      # PAC1 and PAC2 Non-vital MINUS records value display
                      db2_minus_rows_info = db1_and_db2_compare_result [:db2_minus_rows]
                      db2_minus_rows_info.each do |db2_minus_row_info|
                        bg = (tr_count%2 == 0) ?  light_bg : dark_bg 
                        tr :style =>bg  do
                          td "-" , :style =>icon_style
                          td db2_minus_row_info[:ID]
                          td db2_minus_row_info[:ParamsName] ,:style =>"width:20%;"
                          td db2_minus_row_info[:CurrentValue] ,:style =>"width:10%;"
                          td "" ,:style =>"width:20%;"
                          td "" ,:style =>"width:10%;"                  
                        end # tr
                        tr_count+=1
                      end # each  db2_minus_rows_info
                    else    # other than CDL , Wizard 
                      tr_count = 0
                      db1_db2_not_equal_rows_info = db1_and_db2_compare_result[:db1_db2_not_equal_rows]
                      db2_plus_rows_info = db1_and_db2_compare_result[:db2_plus_rows]
                      db2_minus_rows_info = db1_and_db2_compare_result[:db2_minus_rows]
                      if !db1_db2_not_equal_rows_info.blank?
                        db1_db2_not_equal_rows_info.each do |db1_db2_not_equal|
                          tr :style =>dark_bg  do
                            td db1_db2_not_equal[:Group_Name],:colspan => 6,:style=>"font-weight:bold;"
                          end
                          
                          plus_rows = db2_plus_rows_info.select {|plus_rows| plus_rows[:Group_ID] == db1_db2_not_equal[:Group_ID]}
                          minus_rows = db2_minus_rows_info.select {|minus_rows| minus_rows[:Group_ID] == db1_db2_not_equal[:Group_ID]}
                          
                          tr_count = 0
                          # PAC1 and PAC2 Non-vital records mismatch value display
                          not_equal_rows = db1_db2_not_equal[:not_equal_rows] 
                          not_equal_rows.each do |not_equal_row|
                            table1_row = not_equal_row[:table1_rows]
                            table2_row = not_equal_row[:table2_rows]
                            bg = (tr_count%2 == 0) ?  light_bg : dark_bg 
                            tr :style =>bg  do
                              td "≠" , :style => icon_style
                              td table1_row[:ID],:style=>"width:3%;"
                              
                              if (table1_row[:ParamsName].to_s != table2_row[:ParamsName].to_s && table1_row[:CurrentValue].to_s == table2_row[:CurrentValue].to_s)
                                td table1_row[:ParamsName].to_s ,:style =>"width:20%;background-color:#8B0000;color:#FFF;"
                                td table1_row[:CurrentValue] ,:style =>"width:10%;"
                                td table2_row[:ParamsName].to_s ,:style =>"width:20%;background-color:#8B0000;color:#FFF;"
                                td table2_row[:CurrentValue] ,:style =>"width:10%;"
                              elsif (table1_row[:ParamsName].to_s == table2_row[:ParamsName].to_s && table1_row[:CurrentValue].to_s != table2_row[:CurrentValue].to_s)
                                td table1_row[:ParamsName].to_s ,:style =>"width:20%;"
                                td table1_row[:CurrentValue] ,:style =>"width:10%;background-color:#8B0000;color:#FFF;"    
                                td table2_row[:ParamsName].to_s ,:style =>"width:20%;"
                                td table2_row[:CurrentValue] ,:style =>"width:10%;background-color:#8B0000;color:#FFF;"                       
                              elsif (table1_row[:ParamsName].to_s != table2_row[:ParamsName].to_s && table1_row[:CurrentValue].to_s != table2_row[:CurrentValue].to_s)
                                td table1_row[:ParamsName].to_s ,:style =>"width:20%;background-color:#8B0000;color:#FFF;"
                                td table1_row[:CurrentValue] ,:style =>"width:10%;background-color:#8B0000;color:#FFF;"
                                td table2_row[:ParamsName].to_s ,:style =>"width:20%;background-color:#8B0000;color:#FFF;"
                                td table2_row[:CurrentValue] ,:style =>"width:10%;background-color:#8B0000;color:#FFF;"
                              else 
                                td table1_row[:ParamsName].to_s ,:style =>"width:20%;"
                                td table1_row[:CurrentValue] ,:style =>"width:10%;"
                                td table2_row[:ParamsName].to_s ,:style =>"width:20%;"
                                td table2_row[:CurrentValue] ,:style =>"width:10%;"
                              end
                              
                            end # tr
                            tr_count+=1
                          end # not_equal_rows END
                          
                          
                          # PAC1 and PAC2 Non-vital PLUS records value display
                          if !plus_rows.blank?                   
                            plus_rows[0][:plus_rows].each do |plus_row|
                              bg = (tr_count%2 == 0) ?  light_bg : dark_bg 
                              tr :style =>bg  do
                                td "+" , :style =>icon_style
                                td plus_row[:ID]
                                td "" ,:style =>"width:20%;"
                                td "" ,:style =>"width:10%;"
                                td plus_row[:ParamsName] ,:style =>"width:20%;"
                                td plus_row[:CurrentValue] ,:style =>"width:10%;"
                              end # tr
                              tr_count+=1
                            end # each
                          end #if !plus_rows.blank?   
                          
                          
                          # PAC1 and PAC2 Non-vital MINUS records value display
                          if !minus_rows.blank?       
                            minus_rows[0][:minus_rows].each do |minus_row|
                              bg = (tr_count%2 == 0) ?  light_bg : dark_bg 
                              tr :style =>bg  do
                                td "-" , :style =>icon_style
                                td minus_row[:ID]
                                td minus_row[:ParamsName] ,:style =>"width:20%;"
                                td minus_row[:CurrentValue] ,:style =>"width:10%;"
                                td "" ,:style =>"width:20%;"
                                td "" ,:style =>"width:10%;"                  
                              end # tr
                              tr_count+=1
                            end # each  db2_minus_rows_info
                          end #!minus_rows.blank?    
                          
                        end # db1_db2_not_equal_rows_info.each
                      end # if !db1_db2_not_equal_rows_info.blank?
                      
                      #---------------------------
                      if !db2_minus_rows_info.blank?
                        db2_minus_rows_info.each do |db2_minus_row|
                            tr_count = 0
                            minus_rows_available_not_equal_rows = db1_db2_not_equal_rows_info.select {|min_rows| min_rows[:Group_ID] == db2_minus_row[:Group_ID]}
                            plus_rows = db2_plus_rows_info.select {|plus_rows| ((plus_rows[:Group_ID] == db2_minus_row[:Group_ID]) &&(plus_rows[:Group_Channel] == db2_minus_row[:Group_Channel]))}
                            if !minus_rows_available_not_equal_rows.blank?
                              next  # skip the iteration if alreday displayed in the not_equal_rows
                            else
                              
                              if !plus_rows.blank? || !db2_minus_row.blank?
                                tr :style =>dark_bg  do
                                  td db2_minus_row[:Group_Name],:colspan => 6,:style=>"font-weight:bold;"
                                end
                                if !db2_minus_row.blank?   
                                  db2_minus_row[:minus_rows].each do |minus_row|
                                    bg = (tr_count%2 == 0) ?  light_bg : dark_bg 
                                    tr :style =>bg  do
                                      td "-" , :style =>icon_style
                                      td minus_row[:ID]
                                      td minus_row[:ParamsName] ,:style =>"width:20%;"
                                      td minus_row[:CurrentValue] ,:style =>"width:10%;"
                                      td "" ,:style =>"width:20%;"
                                      td "" ,:style =>"width:10%;"                  
                                    end # tr
                                    tr_count+=1
                                  end # db2_minus_row[:minus_rows].each
                                end #if !db2_minus_row.blank?   
                                
                                if !plus_rows.blank?
                                    plus_rows.each do |plus_row|
                                        if !plus_row[:plus_rows].blank?
                                          bg = (tr_count%2 == 0) ?  light_bg : dark_bg 
                                          tr :style =>bg  do
                                            td "+" , :style =>icon_style
                                            td plus_row[:plus_rows][0][:ID]
                                            td "" ,:style =>"width:20%;"
                                            td "" ,:style =>"width:10%;"
                                            td plus_row[:plus_rows][0][:ParamsName] ,:style =>"width:20%;"
                                            td plus_row[:plus_rows][0][:CurrentValue] ,:style =>"width:10%;"
                                          end # tr
                                          tr_count+=1
                                        end
                                    end # each
                                end #if !plus_rows.blank?  
                              end  #if !plus_rows.blank? || !db2_minus_row.blank?
                           end     
                        end
                      end # if !db2_minus_rows_info.blank?
                      #------------END---------------
                      
                      #+++++++++++++++++++++
                      if !db2_plus_rows_info.blank?
                        db2_plus_rows_info.each do |db2_plus_row|
                            tr_count = 0
                            plus_rows_available_not_equal_rows = db1_db2_not_equal_rows_info.select {|plus_row| plus_row[:Group_ID] == db2_plus_row[:Group_ID]}
                            minus_rows = db2_minus_rows_info.select {|minus_row| minus_row[:Group_ID] == db2_plus_row[:Group_ID]}
                            if (!plus_rows_available_not_equal_rows.blank? || !minus_rows.blank?)
                              next  # skip the iteration if alreday displayed in the not_equal_rows
                            else
                                if !db2_plus_row.blank?
                                  tr :style =>dark_bg  do
                                    td db2_plus_row[:Group_Name],:colspan => 6,:style=>"font-weight:bold;"
                                  end   
                                    db2_plus_row[:plus_rows].each do |plus_row|
                                        bg = (tr_count%2 == 0) ?  light_bg : dark_bg 
                                        tr :style =>bg  do
                                          td "+" , :style =>icon_style
                                          td plus_row[:ID]
                                          td "" ,:style =>"width:20%;"
                                          td "" ,:style =>"width:10%;"
                                          td plus_row[:ParamsName] ,:style =>"width:20%;"
                                          td plus_row[:CurrentValue] ,:style =>"width:10%;"
                                        end # tr
                                        tr_count+=1
                                    end # db2_plus_row[:plus_rows].each
                                end #if !db2_plus_row.blank? 
                           end  #if !plus_rows_available_not_equal_rows.blank? && !minus_rows.blank?  
                        end #db2_plus_rows_info.each do
                      end # if !db2_plus_rows_info.blank?
                      #++++++++END+++++++++++++
                    end
                  end #each   db1_and_db2_compare_results     
                end # table
              else
                table :style =>"width:97%;" do
                  tr do
                    th "Non-Vital Program Comparision",:style =>"width:30%;",:colspan=>6
                  end
                  tr :style =>light_bg do
                    th "No Mismatches found" ,:style =>"width:30%;color:#F2F2F2",:colspan=>6
                  end 
                end
              end # if !db1_and_db2_compare_results.blank? 
            end # if !card_type_result_display.blank? || !pac1_and_pac2_not_equal_mcf_info.blank? || !plus_mcf_info.blank? - No Mismatch all info equal
          end
        end
      end
      
      # Copy the all framed html values to display variable
      @displayhtmlcontent = mab.to_s
    rescue Exception => e
        # Display Error message if you got any exception
        error_flag = true
        raise Exception, e.message
        @displayhtmlcontent = "<div style='padding-left:10px;color:#FF0000;font-family: Arial; font-size:13px;'>Error :#{e.message}</div>" 
    end
    
    # Save the formated html reports to download 
    savefilepath = "#{RAILS_ROOT}/tmp/pac_files/Pac_Comparison-report.html"
   
    File.open(savefilepath,'w') do |f| 
      if error_flag == true
        f.write("<div style='padding-left:10px;color:#FF0000;font-family: Arial; font-size:13px;'>#{@displayhtmlcontent}</div>")
      else
        f.write("<div style='clear:both; padding-top:20px;width:auto;'></div>")
        f.write(@displayhtmlcontent)
      end
    end
    
    if error_flag != true
      File.open(savefilepath) do |f| 
          contents = f.read
          contents.gsub!(/display:none;/, '')
          File.open(savefilepath, "w+") { |f1| f1.write(contents) }
      end
    end
    session[:pac_comp_rep_path] = savefilepath
    render :partial=>'paccomparison'
  end

  ####################################################################
  # Function:      downloadcomparison_report
  # Parameters:    session[:pac_comp_rep_path]
  # Retrun:        None
  # Renders:       send_file
  # Description:   Download the pacfiles comparison log
  ####################################################################
  def downloadcomparison_report
    path =""
    unless session[:pac_comp_rep_path].blank?
      if File.exist?(session[:pac_comp_rep_path])
        path = session[:pac_comp_rep_path]
        send_file(path, :filename => "Pac_comparison_Report.html",:dispostion=>'inline',:status=>'200 OK',:stream=>'true' )
      else
        render :text=>""
      end     
    else
      render :text => ""
    end
  end
  
end