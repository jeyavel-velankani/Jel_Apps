####################################################################
# Company: Siemens 
# Author: Jeyavel Natesan 
# File: viunonvital_configuration_controller.rb
# Description: This module going to generate OCE-VIU Pages controls at Runtime , reading the corresponding 
#              page parameters from the nvconfig.bin file  through cfgmgr.exe & cfg2xml.exe , updating the 
#              VIU page parameter values to nvconfig.bin through cfgmgr.exe & cfg2xml.exe  
####################################################################
#History:
# Log: /wayside/GEOII/Trunk/Software/WebUI/app/controllers/viunonvital_configuration_controller.rb
#
# Rev 5670   Oct 10 2013 20:30:00   Jeyavel
# Initial Version
class ViunonvitalConfigurationController < ApplicationController
  layout 'general'
  include ReportsHelper
  include SelectsiteHelper
  if OCE_MODE == 1
    require 'win32ole'
    require 'builder'
    require 'rexml/document'
    include REXML
  end

  def serial_lap_top
    reload = 1
    default = (params[:default] ? params[:default] : nil)

    enumerator_expression(6,['SER_PORT_1_PROTO'],default)
    viunonvitalpage_func(7,reload, default)
  end

  def serial_port_1
    reload = 1
    default = (params[:default] ? params[:default] : nil)

    enumerator_expression(7,['SER_PORT_LAP_PROTO'],default)
    viunonvitalpage_func(6,reload, default)
  end
  
  ####################################################################
  # Function:      enumerator_expression
  # Parameters:    tagname,get_by_names
  # Retrun:        @enumerator_expressions
  # Renders:       None
  # Description:   Display VIU Non vital configuration page
  ####################################################################  
  def enumerator_expression(tagname,get_by_names,default=nil)
    if get_by_names.length != 0
      session[:cfgmgr_state] = false
      strmsg = ""

      xmlfilpath = RAILS_ROOT+'/oce_configuration/'+session[:user_id]+'/xmltemplate/'
      if default==nil
        if File.directory?(xmlfilpath)
          @files_delete = true
          fileslist = Dir[xmlfilpath+"/*.*"]
          fileslist.each do |file_delete|
            begin
              File.delete file_delete
            rescue Exception => e
              puts e.inspect
            end
          end
        else
          Dir.mkdir("#{RAILS_ROOT}/oce_configuration/#{session[:user_id]}/xmltemplate")
        end
      end
            
      strmsg = viu_generate_xml(tagname)

      @enumerator_expressions = Hash.new
      (0..get_by_names.length-1).each do |i|
        @enumerator_expressions[get_by_names[i]] = ''
      end

      params_look_up = read_page_parameter_from_xml(tagname , nil) 

      name_lookup = Hash[get_by_names.map.with_index.to_a]

      params_look_up.each do |p|
        if name_lookup[p[0]]!=nil
          param_name = p[0]
          datatype = p[3]


          if (datatype == "string" || datatype == "integer" || datatype == "bytearray" || datatype == "hex" || datatype == "sin" || datatype == "ip")
            param_value = p[2]

            @enumerator_expressions[param_name] = param_value
          elsif(datatype == "boolean")
            param_value = p[2]

            if param_value == 0
              @enumerator_expressions[param_name] = "No"
            else
              @enumerator_expressions[param_name] = "Yes"
            end
          else
            serial_values = get_collection_of_constant(datatype)

            serial_values.each do |sv|
              # p[2] is value of SER_PORT_1_PROTO

              #gets the string value for selected value
              if sv[1] == p[2] 
                
                param_value = sv[0]

                @enumerator_expressions[param_name] = param_value
              end
            end
          end
        end
      end
    end
  end

  ####################################################################
  # Function:      viunonvitalpage
  # Parameters:    tagname,reload,default
  # Retrun:        @nonvital_parameters
  # Renders:       None
  # Description:   Display VIU Non vital configuration page
  ####################################################################  
  def viunonvitalpage_func(tagname,reload=1,default=nil)
    @tagname = tagname

    session[:cfgmgr_state] = false
    strmsg = ""
    if (default.blank? && (reload == 1))
      xmlfilpath = RAILS_ROOT+'/oce_configuration/'+session[:user_id]+'/xmltemplate'
      if File.directory?(xmlfilpath)
        fileslist = Dir[xmlfilpath+"/*.*"]
        if fileslist
          fileslist.each do |file_delete|
            begin
              if @files_delete == nil
                File.delete file_delete
              end
            rescue Exception => e
              puts e.inspect
            end
          end
        end
      else
        Dir.mkdir("#{RAILS_ROOT}/oce_configuration/#{session[:user_id]}/xmltemplate")
      end
            
      strmsg = viu_generate_xml(@tagname)
      unless strmsg.blank?      
        flash[:errormessage] = strmsg
      else
        flash[:errormessage] = nil
      end
    end
    @emp = get_rc2keybin_crc_values()
    @nonvital_parameters = read_page_parameter_from_xml(@tagname , default) 

    render :template => '/viunonvital_configuration/viunonvitalpage'   
  end

  ####################################################################
  # Function:      viunonvitalpage
  # Parameters:    params
  # Retrun:        @nonvital_parameters
  # Renders:       None
  # Description:   Display VIU Non vital configuration page
  ####################################################################  
  def viunonvitalpage
    @tagname = params[:tagname]
    defaultflag = nil
    unless params[:default].blank?
      defaultflag = params[:default]
    end
    reload = 1
    unless params[:reload].blank?
      reload = params[:reload]
    end
    session[:cfgmgr_state] = false
    strmsg = ""
    if (defaultflag.blank? && (reload == 1))
      xmlfilpath = RAILS_ROOT+'/oce_configuration/'+session[:user_id]+'/xmltemplate/'
      if File.directory?(xmlfilpath)
      fileslist = Dir[xmlfilpath+"/*.*"]
      fileslist.each do |file_delete|
          begin
            File.delete file_delete
          rescue Exception => e
            puts e.inspect
          end
        end
      else
        Dir.mkdir("#{RAILS_ROOT}/oce_configuration/#{session[:user_id]}/xmltemplate")
      end
            
      strmsg = viu_generate_xml(@tagname)
      unless strmsg.blank?      
        flash[:errormessage] = strmsg
      else
        flash[:errormessage] = nil
      end
    end
    @emp = get_rc2keybin_crc_values()
    @nonvital_parameters = read_page_parameter_from_xml(@tagname , defaultflag)    
  end
  
  ####################################################################
  # Function:      update_viunonvitalpage
  # Parameters:    params
  # Retrun:        tagname
  # Renders:       render :text => tagname
  # Description:   Update VIU Non vital configuration page parameters
  ####################################################################  
  def update_viunonvitalpage
    [:controller, :action, :authenticity_token, :page, :'submit.x', :'submit.y', :submit].each { |k| params.delete(k) }
    tagname = params[:tagname]

    begin
      params3 = Array.new

      if params[:reorder_params] != nil
        params3_temp = Array.new
        params.delete :reorder_params
        params.delete :tagname

        params.each do |key,param|
          temp=key 
          new_name = ''
          num = key.split('_')
          under_score_count = 0
          num.each do |param1|
            if num.length-1 > under_score_count
              new_name = new_name+param1+'_'
            end
            under_score_count= under_score_count+1
          end

          #remove last _
          new_name = new_name[0..-2]

          num = num[num.length-1].to_i

          params3_temp_val = Array.new
          params3_temp_val[0] = new_name
          params3_temp_val[1] = param
           
          params3_temp[num] = params3_temp_val

          if tagname == "4" && new_name == "EMP_RC2_KEY" && !param.blank?
            @rc2_val = param
          end

          if tagname == "1"
            if new_name == "SITE_NAME"
              @site_name = param
            end

            if new_name == "DOT_NUM"
              @dot_num = param
            end

            if new_name == "MILEPOST"
              @mile_post = param
            end 
          end
        end

        if @rc2_val.blank?
            @rc2_val = ""
          end
        
        params3_temp.each do |param|

          params3 << param
        end

      else
        startingpos = 1 
        endpos = params.length-1
        params.each_with_index{ |y ,i|
          if (i >= startingpos && i <= endpos)
            params3 << y
          end
        }

        if tagname == "4" && !params[:EMP_RC2_KEY].blank?
          @rc2_val = params[:EMP_RC2_KEY].to_s 
        else
          @rc2_val = ""
        end

        if tagname == "1"
          @site_name = params[:SITE_NAME]    
          @dot_num = params[:DOT_NUM]    
          @mile_post = params[:MILEPOST]    
        end
      end
      xmlfilpath = createxml_and_updatevalues(params3 , tagname)
      session[:cfgmgr_state] = false
      strmsg = viu_update_xml(tagname, xmlfilpath)
      if (strmsg.downcase == "successfully updated...")
        strmsg = get_flash_message(tagname)
        flash[:message] = strmsg
        flash[:errormessage] = nil
        if (tagname == "4")
          rc2bin_path = "#{session[:cfgsitelocation]}/rc2key.bin"
          libcic = WIN32OLE.new('CIC_BIN.CICBIN')
          strmsg = libcic.GenerateRc2KeyFile(rc2bin_path , @rc2_val)
        elsif (tagname == "1")
          StringParameter.update_value_by_name("Site Name" ,  @site_name)
          StringParameter.update_value_by_name("DOT Number" , @dot_num)
          StringParameter.update_value_by_name("Mile Post" , @mile_post)
          header_function
        end
      else
        flash[:errormessage] = strmsg 
      end
    rescue Exception => e
      puts e.inspect
    end
    render :text => tagname
  end
  
  ####################################################################
  # Function:      read_page_parameter_from_xml
  # Parameters:    tagname , default
  # Retrun:        params1
  # Renders:       None
  # Description:   Read VIU Page parameters from the generated xml file
  ####################################################################  
  def read_page_parameter_from_xml(tagname , default)
    resultfilepath = RAILS_ROOT+'/oce_configuration/'+session[:user_id]+'/xmltemplate/'
    path = RAILS_ROOT+'/doc/cfgdef.viu.xml'
    xmlfile = File.new(path)
    xmldoc = Document.new(xmlfile)
    params1 = Array.new
    filename = getfilename_for_tagname( path , tagname) 
    unless default.blank?
      filename = filename+'.defaults.xml'
    else
      filename = filename+'.xml'
    end
    resultfilepath = resultfilepath +"#{filename}"
    xmldoc.elements.each("*/record[@tag=#{tagname}]/item") { |element| 

      if element.attributes["show"] == nil ||  element.attributes["show"] != 'false'
        params = []
        j = 0
        params[j] = element.attributes["name"]
        params[j+1] = element.attributes["title"]
        params[j+2] = readvalue_from_xml(resultfilepath ,"#{tagname}",params[j])
        params[j+3] = element.attributes["datatype"]
        params[j+4] = element.attributes["enable"]
        params[j+5] = element.attributes["show"] == 'true' ? nil : element.attributes["show"]
        params[j+6] = element.attributes["display_order"]

        # conditional_params = []
        # if(tagname.to_i == 6 || tagname.to_i == 7)
          # conditional_params = ["PROTO_PORT_LAP_BCP_NUMBER", "PROTO_PORT_LAP_NMEA_RECV_TIMEOUT", "PROTO_PORT_LAP_NMEA_TIME_DIFF", "PROTO_PORT_1_NMEA_RECV_TIMEOUT", "PROTO_PORT_1_NMEA_TIME_DIFF", "PROTO_PORT_1_BCP_NUMBER"]
        # end
        # if((tagname.to_i == 6 || tagname.to_i == 7)  && !conditional_params.index(params[j]).nil?)
          # default_resultfilpath = resultfilepath.split(".xml")[0] + ".defaults.xml"
          # params[j+7] = readvalue_from_xml(default_resultfilpath ,"#{tagname}",params[j])
        # end
        params1 << params
      end
    }
    return params1
  end
  
  ####################################################################
  # Function:      readvalue_from_xml
  # Parameters:    filename, tagname , fieldname
  # Retrun:        value
  # Renders:       None
  # Description:   Read the value from the specified xml file
  ####################################################################    
  def readvalue_from_xml(filename, tagname , fieldname)
    xmlfile = File.new(filename)
    xmldoc = Document.new(xmlfile)
    root = xmldoc.root
    value = nil
    if(root.attributes["tag"].to_i == tagname.to_i)
      root.each_element_with_attribute('name') do |e| 
        if (e.attributes["name"] == fieldname)
          if(e.get_text)
            if (tagname.to_i == 6 || tagname.to_i == 7)
              if ((fieldname == "PROTO_PORT_LAP_BCP_NUMBER") || (fieldname == "PROTO_PORT_1_BCP_NUMBER"))
                value = e.get_text.value.to_i
              else
                value = e.get_text.value
              end
            else
              value = e.get_text.value
            end            
          end
        end
      end
    end
    unless value.blank?
      return value
    else
      return ""
    end
  end
  
  ####################################################################
  # Function:      get_flash_message
  # Parameters:    tagname
  # Retrun:        returnflashmessage
  # Renders:       None
  # Description:   Get the flash message according to the tag name 
  ####################################################################    
  def get_flash_message(tagname)
    mainxmlfilepath = RAILS_ROOT+'/doc/cfgdef.viu.xml'
    xmlfile = File.new(mainxmlfilepath)
    xmldoc = Document.new(xmlfile)
    titlename = xmldoc.elements().to_a("*/record[@tag=#{tagname}]").first.attributes["title"]
    returnflashmessage = "Successfully updated #{titlename} parameters."
    return returnflashmessage
  end
  
  ####################################################################
  # Function:      createxml_and_updatevalues
  # Parameters:    params3,tagno
  # Retrun:        resultfilepath
  # Renders:       None
  # Description:   Create the result xml file and update the values 
  ####################################################################    
  def createxml_and_updatevalues(params3, tagno)
    path = RAILS_ROOT+'/doc/cfgdef.viu.xml'
    filename = getfilename_for_tagname(path, tagno)
    resultfilepath = "#{RAILS_ROOT}/oce_configuration/#{session[:user_id]}/xmltemplate/#{filename}.xml"
    if File.exists?(resultfilepath)
      # XML FILE Updation START
      xmlfile = File.new(resultfilepath)
      xmldoc = Document.new(xmlfile)
      root = xmldoc.root
      if(root.attributes["tag"].to_i == tagno.to_i)
        root.each_element_with_attribute('name') do |e| 
          name = e.attributes["name"]
          params3.each do |value|
            if(name == value[0].to_s)
              e.text = value[1].to_s
              if (tagno.to_i == 1) && (name == "SITE_ATCS_ADDR") 
                update_rt_sin_values(4, value[1].to_s)
              end
            end
          end
        end
      end
      File.open(resultfilepath, 'w') do |result|
        xmldoc.write(result)
      end
      #XML FILE Updation END
    else
      
      #XML FILE GENERATION START
      params2 = Array.new
      xmlfile = File.new(path)
      xmldoc = Document.new(xmlfile)
      xmldoc.elements.each("*/record[@tag=#{tagno}]/item") { |element| 
        temp = element.attributes["name"]
        params2 << temp.to_s
      }
      if File.exists?(resultfilepath)
        begin
          File.delete(resultfilepath)
        rescue Exception => e
          puts e.inspect
        end
      end
      root = xmldoc.root
      createfilename = root.attributes["name"]
      createfilename = createfilename.titleize.downcase
      xml = Builder::XmlMarkup.new(:target=> output_string = "" ,:indent => 2 )
      xml.instruct! :xml
      xml.config(:tag => tagno , :name =>createfilename , :offset=>"0" ) do |p|
        params2.each do |name |
          params3.each do |value|
            if (name == value[0].to_s)
              p.item(value[1].to_s , :name => name.to_s )
              if (tagno.to_i == 1) && (name == "SITE_ATCS_ADDR") 
                update_rt_sin_values(4, value[1].to_s)
              end
            end
          end
          
        end
      end
      f = File.new(resultfilepath, "w")
      f.write(output_string)
      f.close
      #XML FILE GENERATION END
    end
    return resultfilepath
  end
  
end