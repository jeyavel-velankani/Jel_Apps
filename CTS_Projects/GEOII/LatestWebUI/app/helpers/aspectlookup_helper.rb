####################################################################
# Company: Siemens 
# Author: Jeyavel Natesan
# File: aspectlookup_helper.rb
# Description: This module is the support file for the aspect lookup page  
####################################################################
module AspectlookupHelper
  require 'fileutils'
  require 'find'
  
  ####################################################################
  # Function:      aspect_data_style
  # Parameters:    signal_id, current_aspect
  # Retrun:        style
  # Renders:       None
  # Description:   Return the style vale
  #################################################################### 
  def aspect_data_style(signal_id, current_aspect)
    signal_id == current_aspect ? "style='background-color:#CFD638;color:#000;'" : ""
  end
  
  ####################################################################
  # Function:      delete_lines_from_file
  # Parameters:    filename, linesno_to_delete
  # Retrun:        None
  # Renders:       None
  # Description:   Delete the corresponding line from the specified Aspectlookuptable.txt 
  ####################################################################
  def delete_lines_from_file(filename, linesno_to_delete)
    @filename=filename
    line_arr = IO::readlines(@filename) 
    line_arr.delete_at(linesno_to_delete)
    File.open(@filename, "w") do |f| 
      line_arr.each{|line| f.puts(line)}
    end
  end
  
  ####################################################################
  # Function:      swap_line_with_above_from_file
  # Parameters:    filename, line_no_to_swap
  # Retrun:        None
  # Renders:       None
  # Description:   Swap the selected aspect values line up/down
  ####################################################################
  def swap_line_with_above_from_file(filename, line_no_to_swap)
    @filename=filename
    line_arr = IO::readlines(@filename) 
    str_tmp = line_arr[line_no_to_swap]
    line_arr.delete_at(line_no_to_swap)
    line_arr.insert(line_no_to_swap - 1,str_tmp.to_s)
    File.open(@filename, "w") do |f| 
      line_arr.each{|line| f.puts(line)}
    end
  end
  
  ####################################################################
  # Function:      validate_aspect_textfile
  # Parameters:    session[:aspectfilepath]
  # Retrun:        None
  # Renders:       None
  # Description:   Validate the aspect text files and return error if exception occur
  ####################################################################
  def validate_aspect_textfile
    @txtfilepath = session[:aspectfilepath]
    unless @txtfilepath.blank?
      if File.exists?(@txtfilepath)
        file = File.new(@txtfilepath, "r")
      else
        return ""
      end
      begin
        while (line = file.gets)
          result=[]
          @data = "#{line}"
          result = @data.split(", \"")
          if (result.length == 1)
            result = @data.split(",\"")
          end
          restrim = []
          restrim = result[1].split("\"")
        end
        file.close
        return true
      rescue => err
        file.close
        #just transfer file accessing - nothing
        path = RAILS_ROOT+'/config/database.yml'
        puts "Exception: #{err}"
        file1 = File.new(path, "r")
        file1.close
        File.delete(@txtfilepath)
        return false
      end
      file.close
    else
      return ""
    end
  end
end
