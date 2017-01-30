module SystemStateHelper
  def display_systemstatetree1(tree, mcfcrc)
    @mcfcrc = mcfcrc
    ret = "<ul id='navigation1'>"
    count = 1
    tree.each do |node|
      @counter = 1
      ret += "<li>"
      ret +=  node.sat_name
      ret += systemstatetree1(node.sat_index, node.sat_name)
      ret += "</li>"
      count += 1
    end
    ret += "</ul>"
  end
  
  def systemstatetree1(sat_index, parent_name)
    ls_categories = get_ls_categories(sat_index, "")
    ret = ""
    ls_categories.each do |category|
      ret += "<ul id='navigation1'>"
      ret += "<li>"
      ret += get_link(category, "#{parent_name} -> #{category.name}", parent_name)
      ret += build_second_state_view(category.name, category.sat_index, "#{parent_name} -> #{category.name}")      
      ret += "</li>"
      ret += "</ul>"
    end
    ret
  end
  
  def build_second_state_view(parent_name, sat_index, bread_crumb)
    ls_categories = get_ls_categories(sat_index, parent_name)
    ret = ""
    ls_categories.each do |category|
      ret += "<ul id='navigation1'>"
      ret += "<li>"
      ret += get_link(category, "#{bread_crumb} -> #{category.name}", parent_name)
      ret += build_third_state(category, "#{bread_crumb} -> #{category.name}", category.sat_index, category.name)
      ret += "</li>"
      ret += "</ul>"
    end
    ret
  end
  
  def build_third_state(categ, bread_crumb, sat_index, parent_name = "")
    ls_categories = get_ls_categories(sat_index, categ.name)
    ret = ""
    ls_categories.each do |category|
      ret += "<ul id='navigation1'>"
      ret += "<li>"
      ret += get_link(category, "#{bread_crumb} -> #{category.name}", parent_name)
      ret += "</li>"
      ret += "</ul>"  
    end
    ret
  end
  
  def get_ls_categories(sat_index, parent_name)
    LsCategories.all(:select => 'min, max, name, sat_index, parent', :conditions => ['sat_index = ? and mcfcrc = ? and parent = ? and layout_index = ?', sat_index, @mcfcrc, parent_name, @gwe.active_physical_layout], :order => "rowid")
  end

  def get_link(category, relation, parent_name = "")
    if LsCategories.count(:conditions => {:parent => category.name}) == 0
  		name = 'get'
  	else
  		parent_name = ''
  		name = 'set'
  	end
    disable_link = (!category.min.nil? && !category.max.nil? && category.min == 0 && category.max == 0)
    link_to(category.name, "javascript:void(0);", :id => category.sat_index, :name => name, :rel => relation, :class => "system_state_view #{disable_link ? 'disabled':''}", :title => parent_name)
  end
  
  # hex to decimal converting
  def cast_to_decimal(value)
    if value.size == 2
      return (value[0, 1] + ("0" + value[1, value.size])).hex
    elsif value.size > 2 && value.size <= 4
      return (value[0, 2] + ("0" + value[2, value.size])).hex
    else
      return value.hex
    end
  end
  
  def get_system_state_values(min, max, system_state_rq_id)
    collect_values = []
    no_and_is_value_hash = []
    if(session[:system_states_is_reply_values].nil?)
      system_state_replies = IsReply.find(:all, :select=>'is_value', 
        :conditions => ['request_id = ?', system_state_rq_id], :limit => (max.to_i - min.to_i+1))
      counter = min.to_i
      sys_values = []
      system_state_replies.each do |system_state_repy|
        no_and_is_value_hash[counter] = system_state_repy.is_value
        counter = counter + 1
        sys_values << system_state_repy.is_value
      end
      session[:system_states_is_reply_values] = sys_values.join(",")
    else
	  counter = min.to_i
	  session[:system_states_is_reply_values].split(",").each do |is_value|
        no_and_is_value_hash[counter] = is_value
      	counter = counter + 1
      end
    end
    ((min.to_i)..(max.to_i)).each do |no|
      if(no_and_is_value_hash[no].nil?)
        break
      end  
      is_value = no_and_is_value_hash[no]
      ls_logic_state_properties = LsLogicStates.find(:all, :select => 'no, prop_index', 
          :conditions => {:mcfcrc => @gwe.mcfcrc, :layout_index => @gwe.active_physical_layout, :no => no})
      if(ls_logic_state_properties.length > 0)
		found_ls_prop = false
        ls_logic_state_properties.each do |ls_logic|
           
          ls_prop = LsProperties.find(:first, :select => 'prop_name, enum_index, mask', 
                          :conditions => {:mcfcrc => @gwe.mcfcrc, :layout_index => @gwe.active_physical_layout, 
                          :prop_index => ls_logic.prop_index})
          if(ls_prop)
			  got_enum = false
              new_val = ls_prop.mask.to_i & is_value.to_i
              ls_enumumerator = LsEnumerators.find(:first , 
                            :conditions => {:mcfcrc => @gwe.mcfcrc, :layout_index => @gwe.active_physical_layout, 
                            :enum_index => ls_prop.enum_index, :value => new_val})
              if(!ls_enumumerator.nil?)
					collect_values << { :name => ls_prop.prop_name, :value => ls_enumumerator.name }
						found_ls_prop = true					
              else
                    
                    if(ls_prop.enum_index == 0)
                      collect_values << { :name => ls_prop.prop_name, :value => is_value }
                      found_ls_prop = true
                    end
              end              
          end
        end
		if(!found_ls_prop)
              collect_values << { :name => "LS" + ("%05d" % (no)), :value => is_value }        
		end
      else
		collect_values << { :name => "LS" + ("%05d" % (no)), :value => is_value }
      end
    end  
    return collect_values
  end
end