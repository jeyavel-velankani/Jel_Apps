module SystemstateViewHelper
  
   def display_systemstatetree(tree)
    
      ret = "<ul id='navigation'>"
      tree.each do |node|
          ret += "<li>"
          ret += link_to_remote node.sat_name, :url=>{:controller=>"systemstate_view", :action=>"page_node"}, :with=>"'node_value='+'#{node.sat_name}'" , :update=>"systemstateviewparams"
          ret += systemstatetree(node.id)
          ret += "</li>"
      end
       ret += "</ul>"
  end
  
  def systemstatetree(satname)
      @sat  = satname
      tree2 = LsCategories.find(:all,:select=>'name,parent',:conditions=>['sat_index= ?',@sat])
      ret = "<ul id='navigation'>"
      tree2.each do |node|
                  ret += "<li>"
                  ret += link_to_remote node.name, :url=>{:controller=>"systemstate_view", :action=>"UDP_call",:id=>node.parent, :name => node.name}, :with=>"'node_value='+'#{node.name}'" , :update=>"systemstateviewparams"
                  ret += "</li>"
      end
       ret += "</ul>"
  end
  
 
end
