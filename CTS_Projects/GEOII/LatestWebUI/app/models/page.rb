class Page < ActiveRecord::Base
  set_table_name "pages"
  set_primary_key "page_name"
  establish_connection :mcf_db
  
  has_many :tabs, :primary_key => 'tabsref', :foreign_key => 'tabs_name'
  
  if GCP_PRODUCT == 1
    has_many  :page_parameter,
            :class_name => "PageParameter",
            :finder_sql => 'select parameters.param_long_name,parameters.default_value,page_parameter.mcfcrc,page_parameter.page_name,page_parameter.parameter_name,page_parameter.card_index,page_parameter.parameter_type,page_parameter.enable,page_parameter.show,page_parameter.validate,page_parameter.mtf_index,page_parameter.menu_name,parameters.parameter_index,parameters.data_type,parameters.int_type_name,parameters.enum_type_name from parameters,page_parameter where page_parameter.page_name = \'#{page_name}\' and page_parameter.mcfcrc = #{mcfcrc} and parameters.mcfcrc= page_parameter.mcfcrc and parameters.name = page_parameter.parameter_name and parameters.parameter_type = page_parameter.parameter_type and parameters.cardindex = page_parameter.card_index and page_parameter.layout_index = parameters.layout_index and page_parameter.layout_type = parameters.layout_type and page_parameter.target not like \'LocalUI\' order by page_parameter.display_order '
    
    has_many  :menus,
            :class_name => "Menu",
            :finder_sql => 'select menus.* from menus where menus.page_name = \'#{page_name}\' and menus.mcfcrc = #{mcfcrc} order by menus.display_order ASC'
  else
    has_many  :page_parameter,
            :class_name => "PageParameter",
    #:finder_sql => 'select page_parameter.* from page_parameter where page_parameter.layout_index = #{layout_index} and page_parameter.layout_type = #{layout_type} and  page_parameter.page_name = \'#{page_name}\'  and page_parameter.mcfcrc = #{mcfcrc}'
            :finder_sql => 'select page_parameter.* from page_parameter where page_parameter.layout_index = #{layout_index} and  page_parameter.page_name = \'#{page_name}\'  and page_parameter.mcfcrc = #{mcfcrc} order by display_order'
    
    has_many  :menus,
            :class_name => "Menu",
            :finder_sql => 'select menus.* from menus where menus.layout_index = #{layout_index} and menus.page_name = \'#{page_name}\' and menus.mcfcrc = #{mcfcrc}'
    
  end
  
end