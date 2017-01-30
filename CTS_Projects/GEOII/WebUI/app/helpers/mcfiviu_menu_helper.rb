module McfiviuMenuHelper
  
   def display_mcfiviutree(tree, parent_id, controller, acton)
    session[:selectedmenu_name] = get_page_name()
    if session[:selectedmenu_name] =='MAIN PROGRAM menu'
              session[:selectedmenu_name] = nil
              session[:child_node] = nil
              session[:parent_node] = nil
              session[:menuenabled] = nil
    end
      ret = "<ul id='navigation'>"
      tree.each do |node|
        if node.parent_id == parent_id
              #ret += "<li id='#{node.menu_name}' class=''>"
              menu_pval = menu_val = Menu.find(:all,:select=>"show", :conditions=>["mcfcrc = ? and menu_name=? and layout_index = ?",session[:mcfcrc],node.name, session[:physical_layout_index]])
            @showpval = menu_pval.map(&:show)
            if @showpval[0].to_s == "true"
              if  session[:child_node] == node.name || session[:menuenabled] == node.name ||   session[:parent_node] == node.name
              #if  session[:parent_node] == node.name
                   ret += "<li id='#{node.name}' class='open'>"
              else
              ret += "<li id='#{node.name}' class='close'>"
              end
              @tempnoderoot = node.name
                   if node.name == 'Unique Check Number (UCN)' and @geo_val == 1
                      
                   ret += link_to node.name, '/ucn/index'
                   else
                   ret += link_to_remote node.name, :url=>{:controller=> controller, :action=> acton}, :condition => "values_changed_confirmation()", :html=>{:title=> populatevalue(node)},  :with=>"'id='+'#{node.name}'+'&node_value='+'#{node.name}'+'&menu_name='+'#{node.name}'+'&param_flag='+''" , :update=>"mcfcontent"
               
                   end
                   
              if node.layout_index == 0
              ret += display_mcfiviutree(tree, node.name,controller, acton)
              else
              ret += display_mcfiviusubtree(tree,node.name,node.layout_index, controller, acton)
              end
              ret += "</li>"
              @nod_val=node.layout_index
            else
             # e = Expression.find(:all,:select=>"expr",:conditions=>["expr_name=?",@showval])
              e = Expression.find(:all,:select=>"expr",:conditions=>["expr_name=? and mcfcrc = ? and layout_index = ?",@showval, session[:mcfcrc], session[:physical_layout_index] ])
                @exprval = e.map(&:expr)
#                @exprval = e.map{|u|[u.expr]}.to_s
                 if e
                  r = evaluatePostfixExpr(@exprval[0].to_s, method(:getOperandValue))
                  if r.to_i == 0
                     
                       if node.name != 'Unique Check Number (UCN)'
                          if  session[:child_node] == node.name || session[:menuenabled] == node.name ||   session[:parent_node] == node.name
                           ret += "<li id='#{node.name}' class='open'>"
                      else
                      ret += "<li id='#{node.name}' class='close'>"
                      end
                        @tempnoderoot = node.name
                        ret += link_to_remote node.name, :url=>{:controller=> controller, :action=>acton}, :condition => "values_changed_confirmation()", :html=>{:title=> populatevalue(node)}, :with=>"'id='+'#{node.name}'+'&node_value='+'#{populatevalue(node)}'+'&menu_name='+'#{node.name}'+'&param_flag='+''" , :update=>"mcfcontent"
                        if node.layout_index == 0
                        ret += display_mcfiviutree(tree, node.name, controller, acton)
                        else
                        ret += display_mcfiviusubtree(tree,node.name,node.layout_index, controller, acton)
                      end
                      
                        ret += "</li>"
                        else
                        if @geo_val == 1
                      if  session[:child_node] == node.name || session[:menuenabled] == node.name ||   session[:parent_node] == node.name
                      
                           ret += "<li id='#{node.name}' class='open'>"
                      else
                      ret += "<li id='#{node.name}' class='close'>"
                      end
                          ret += link_to node.name, '/ucn/index'
                ret += "</li>"
                end
                       end
                        
                        @nod_val=node.layout_index
                  else
                    
                end
              end
              
            end
        end
      end
       ret += "</ul>"
  end
  
  def display_mcfiviusubtree(tree, parent_id, l_index, controller, acton)
     menu_val= Hash.new
     expr = Hash.new
      ret = "<ul id='navigation'>"
      tree.each do |node|
        if node.parent_id == parent_id and node.layout_index == l_index
           menu_val = menu_val = Menu.find(:all,:select=>"distinct show", :conditions=>["mcfcrc = ? and menu_name=? and layout_index = ?",session[:mcfcrc],node.name, session[:physical_layout_index]])
            @showval = menu_val.map(&:show)
            if @showval[0].to_s == "true" || @showval[0].to_s == ''
                  #link_to 'UCN', '/ucn/get_pending' %>
                    if session[:child_node] == node.name || session[:menuenabled] == node.name ||   session[:parent_node] == node.name
                      ret += "<li id='#{node.name}' class='open'>"
                    else
                      ret += "<li id='#{node.name}' class='close'>"
                    end
                    if node.name =='ATCS SIN' and @geo_val == 1
                       
                       # ret += "<li>"
                         ret += link_to 'ATCS SIN', { :controller => "atcs_sin", :action => "get_sin" }, { :id => "atcs_sin_sub_tree"}
                        #  ret += "</li>"
                      
                    elsif node.name == 'Object Names'  and @geo_val == 1
                         #ret += "<li>"
                         ret += link_to('Object Names', { :controller => "object_name", :action => "get_object_name"}, { :id => "object_name_id"})
                         # ret += "</li>"
                    
                    elsif node.name == 'Location' and @geo_val == 1
                        #  ret += "<li>"
                         ret += link_to 'Location', :controller => "location", :action => "get_location"
                         # ret += "</li>"
                    elsif node.name == 'Time' and @geo_val == 1
                         ret += "<li>"
                         ret += link_to 'Time', '/geo_time/get_geo_time'
                        # ret += "</li>"
                    elsif node.name == 'Card Names' and @geo_val == 1
                        #ret += "<li>"
                        ret += link_to('Card Names', { :controller => "card_name", :action => "get_object_name" }, { :id => "card_name_id"})
                        #ret += "</li>"
                    elsif(node.name == "Set to Defaults")
                        ret += "<a onclick='if(values_changed_confirmation()){set_to_default();}' href='#'>" + node.name + "</a>"
                    else
                        ret += link_to_remote node.name, :url=>{:controller=>controller, :action=>acton}, :condition => "values_changed_confirmation()",  :html=>{:title=> populatevalue(node)}, :with=>"'node_value='+'#{populatevalue(node)}'+'&menu_name='+'#{node.name}'" , :update=>"mcfcontent"
                    end
                  
                  ret += display_mcfiviusubtree(tree, node.name, node.layout_index, controller, acton)
                  ret += "</li>"
                  
             else
                e = Expression.find(:all,:select=>"distinct expr",:conditions=>["expr_name=? and mcfcrc = ? and layout_index = ?",@showval, session[:mcfcrc], session[:physical_layout_index] ])
                @exprval = e.map(&:expr)
                 if e
                  r = evaluatePostfixExpr(@exprval[0].to_s, method(:getOperandValue))
                  if r.to_i != 0 and @geo_val == 0
                    @disabled = false
                     if  session[:child_node] == node.name || session[:menuenabled] == node.name ||   session[:parent_node] == node.name
                      ret += "<li id='#{node.name}' class='open'>"
                    else
                      ret += "<li id='#{node.name}' class='close'>"
                    end
                  #   if node.name !='ATCS SIN' and node.name !='Location' and node.name !='Time'
                  
                  ret += link_to_remote node.name, :url=>{:controller=> controller, :action=>acton}, :condition => "values_changed_confirmation()", :html=>{:title=> populatevalue(node)}, :with=>"'node_value='+'#{populatevalue(node)}'+'&menu_name='+'#{node.name}'" , :update=>"mcfcontent"
                  
                  ret += display_mcfiviusubtree(tree, node.name, node.layout_index, controller, acton)
                  #end
                  ret += "</li>"
                elsif @geo_val == 1
                      if  session[:child_node] == node.name || session[:menuenabled] == node.name ||   session[:parent_node] == node.name
                          ret += "<li>"
                      else
                          ret += "<li>"
                      end
                     if node.name =='ATCS SIN' and @geo_val == 1
                       
                       # ret += "<li>"
                         ret += link_to 'ATCS SIN', { :controller => "atcs_sin", :action => "get_sin" }, { :id => "atcs_sin_sub_tree"}
                        #  ret += "</li>"
                      elsif node.name == 'Location' and @geo_val == 1
                        #  ret += "<li>"
                         ret += link_to 'Location', :controller => "location", :action => "get_location"
                         # ret += "</li>"
                     elsif node.name == 'Object Names'  and @geo_val == 1
                        # ret += "<li>"
                         ret += link_to('Object Names', {:controller => "object_name", :action => "get_object_name"}, { :id => "object_name_id"})
                         # ret += "</li>"
                      elsif node.name == 'Card Names' and @geo_val == 1
                        # ret += "<li>"
                         ret += link_to('Card Names', {:controller => "card_name", :action => "get_object_name"}, {:id => "card_name_id"})
                         # ret += "</li>"
                      elsif node.name == 'Time' and @geo_val == 1
                         ret += "<li>"
                         ret += link_to 'Time', '/geo_time/get_geo_time'
                        # ret += "</li>"
                     else
                       if node.name != 'Object Names'
                         ret += link_to_remote node.name, :url=>{:controller=> controller, :action=>acton}, :condition => "values_changed_confirmation()", :html=>{:title=> populatevalue(node)}, :with=>"'node_value='+'#{populatevalue(node)}'+'&menu_name='+'#{node.name}'" , :update=>"mcfcontent"
                        end
                        
                      end
                      #ret += "</li>"
                         ret += display_mcfiviusubtree(tree, node.name, node.layout_index, controller, acton)
                      
                     # ret += "</li>"
                      
                  end
                end
             end
             
        end
      end
       ret += "</ul>"
  end
  
  def populatevalue(node)
   if !node.link.blank?
     return node.link
   else
     return node.name
   end
 end
 
end
