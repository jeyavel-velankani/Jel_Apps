####################################################################
# Company: Siemens 
# Author: Jeyavel Natesan
# File: mcfextractor_helper.rb
# Description: MCF Extractor page helper
####################################################################
#History:
# Log: /wayside/GEOII/Trunk/Software/WebUI/app/controllers/mcfextractor_helper.rb
#
# Rev 4707   July 16 2013 18:00:00   Jeyavel Natesan
# Initial version
module McfextractorHelper
  ####################################################################
  # Function:      display_mcftree
  # Parameters:    tree
  # Retrun:        ret
  # Renders:       None
  # Description:   Construct the Installation menu tree for MCF Extractor page 
  ####################################################################
  def display_mcftree(tree)
    ret = "<ul id='navigation1'>"
    tree.each do |node|
      ret += "<li id=#{node.InstallationName} >"
      ret += link_to(node.InstallationName ,"javascript: void(0)")
      sub = Geoptcmenu.find(:all,:select=>'Distinct MCFName',:conditions=>['InstallationName=?', node.InstallationName] ,:order => 'MCFName  COLLATE NOCASE')
      ret += display_mcftree_child(sub, node.InstallationName)
      ret += "</li>"
    end
    ret += "</ul>"
  end
  
  ####################################################################
  # Function:      display_installationmenu
  # Parameters:    tree
  # Retrun:        reportmenu
  # Renders:       None
  # Description:   Get the installation name tree
  ####################################################################
  def display_installationmenu(tree)
    reportmenu = "<ul>"
    tree.each do |node|
      reportmenu += "<li>"
      reportmenu += "<a href='/reports/#{node.InstallationName}/generate_csv' id = '#{node.InstallationName}'>#{node.InstallationName}</a>"
      reportmenu += "</li>"
    end
    reportmenu += "</ul>"
  end
  
  ####################################################################
  # Function:      display_mcftree_child
  # Parameters:    tree1, installation_name
  # Retrun:        ret
  # Renders:       None
  # Description:   Display the Installation child mcf name
  ####################################################################
  def display_mcftree_child(tree1, installation_name)
    ret = "<ul>"
    tree1.each do |node|
      ret += "<li>"+node.MCFName+"</li>"
    end
    ret += "</ul>"
  end
  
  ####################################################################
  # Function:      masterdbpath
  # Parameters:    path
  # Retrun:        result
  # Renders:       None
  # Description:   Get the Master database path from system
  ####################################################################
  def masterdbpath(path)
    result=""
    unless path.blank?
      value = RAILS_ROOT+'/'+path
      arraysplitvalue = value.split('/')
      result = arraysplitvalue.join("\\")  
    end
    return result
  end
  
  ####################################################################
  # Function:      child_tree
  # Parameters:    directory
  # Retrun:        child_element
  # Renders:       None
  # Description:   Construct the child treeview
  ####################################################################
  def child_tree(directory)     
    child_dirs = Dir[directory+"/*"]
    child_element = ""
    unless child_dirs.blank?
      child_element +=  "<ul id='navigation'>"  
      child_dirs.each do |dir|
        if File.directory?(dir)         
          child_element += "<li class='folder dir_element' id='#{dir}'>"
          child_element += File.basename(dir)
          child_element +=  child_tree(dir)
          child_element += "</li>"
        else
          child_element += "<li>" 
          child_element += File.basename(dir)
          child_element += "</li>"
        end        
      end
      child_element += "</ul>"
    end
    return child_element
  end
  
  ####################################################################
  # Function:      child_tree_file
  # Parameters:    directory
  # Retrun:        child_element
  # Renders:       None
  # Description:   Get the list of file as a tree
  ####################################################################
  def child_tree_file(directory)     
    child_dirs = Dir[directory+"/*"]
    child_element = ""
    unless child_dirs.blank?
      child_element +=  "<ul id='navigation'>"  
      child_dirs.each do |dir|
        child_element += "<li class='file dir_element' id='#{dir}'>"
        child_element += File.basename(dir)
        child_element +=  child_tree_file(dir)
        child_element += "</li>"
      end
      child_element += "</ul>"
    end
    return child_element
  end
  
  ####################################################################
  # Function:      dbpathptc
  # Parameters:    mystringptc
  # Retrun:        receivedstr
  # Renders:       None
  # Description:   Get the exact db path and store in the session
  ####################################################################
  def dbpathptc(mystringptc)
    receivedstr = mystringptc
    substring = RAILS_ROOT+'/'
    start_ss = receivedstr.index(substring)
    receivedstr[start_ss.to_i, substring.length] = ""
    session[:mantmasterdblocation]=nil
    session[:mantmasterdblocation]=RAILS_ROOT+'/'+receivedstr
    return receivedstr.to_s
  end
end
