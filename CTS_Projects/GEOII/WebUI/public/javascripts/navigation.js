/****************************************************************************************************************************************
 Company: Siemens 
 Author: Kevin Ponce
 File: navigation.js
 Description: Create and controll all navigation
****************************************************************************************************************************************/
 var left_nav = {};
 var top_nav = [];
 var tabs = {};
 var current_url  = '';
 var v_config_menu_option = "";
 var vlp_io_log_menu_option = "";
 var field_adjustment_menu_option = "";
 var preload_page = '';
 var postload_page = '';
 var current_title = '';
 var load_content_flag = true; 
 var new_url = '';
 var ajax_check_session_flag = true;
 var new_title = '';
 var new_params = '';
 var keep_tabs_flag = '';
 var lost_connect_vlp = false; 
var signout_clicked = false;
 $(document).ready(function(){
    $('.logout').w_click(function(){
        signout_clicked = true;
    });

    //sets up ajax error checking
    $.ajaxSetup({
        error: function(jqXHR, exception) {
            if($('.ui-dialog').length == 0 && !signout_clicked){
				 if (jqXHR.status == 404) {
                    AlertDialog('Error','Page not found',function(){});
                    $('.ajax-loader').hide();
                } else if (jqXHR.status == 500) {
                    AlertDialog('Error','Internal Server Error.',function(){});
                    $('.ajax-loader').hide();
                } else if (exception === 'parsererror') {
                    AlertDialog('Error','Requested JSON parse failed.',function(){});
                    $('.ajax-loader').hide();
                } else if (exception === 'timeout') {
                    AlertDialog('Error','Time out error.',function(){});
                    $('.ajax-loader').hide();
                } 
            }    
        }
    });

    init_left_nav_tree();
    build_nav_object();
    build_top_nav();
    build_left_nav();

    if ($("#hd_product_type").val() == "0"){
        init_session_mouse();
        set_indicators();
    }
    
 }); 

 function build_nav_object(){
    var scope_index = 0;
    var current_top_nav = '';
    var url_val = '';
	if(product == 'VIU'){
		url_val = "../viu_menutree.ini";
	}else if (product == "CPU3" || product == "CPU2" || product == "CPU-III" || product == "CPU-II"){
		url_val = "../menutree.ini";
	}else if (product == 'GEO') {
		url_val = "../geo_menutree.ini";
	}else if (product == 'GCP') {
		url_val = "../gcp_menutree.ini";
	}else {    //product == 'iVIU' || product == 'iVIU PTC GEO'
		url_val = "../iviu_menutree.ini";
	}
	
	$.ajax({ 
        url: url_val,
        async: false, 
        success: function( menu_tree_resp){ 
            var menu_tree_array = menu_tree_resp.split('\n');
            var left_tree_tmp = [];

            for(var menu_i = 0; menu_i < menu_tree_array.length; menu_i++){
                var line = $.trim(menu_tree_array[menu_i]);

                var read_line = false;

                if(line == '{'){
                    scope_index++;
                }else if(line == '}'){
                    scope_index--;
                }else{
                    read_line = true; 
                }

                if(read_line){
                    if(scope_index == 0){
                        nav_info = line.split('|');
                        if(nav_info.length > 1){
                            if(left_tree_tmp.length > 0){
                                left_nav[current_top_nav] = left_tree_tmp;
                                left_tree_tmp = [];
                            }else{
                                left_tree_tmp = [];
                            }

                            current_top_nav = $.trim(nav_info[0]);
                            top_nav.push(nav_info);
                        }
                    }else{
                        left_tree_tmp.push((scope_index+'|'+line).split('|'));
                    }
                }
            }

            if(left_tree_tmp.length > 0){
                left_nav[current_top_nav] = left_tree_tmp;
            }
        }
    });
 }

/**********************************************************************
 top nav
**********************************************************************/
    function build_top_nav(selected){
        if(typeof selected === "undefined"){
            //selected = 'System View';
            if ($("#hd_product_type").val() == 1){
        		selected = 'Configuration';
        	}
        	else{
                if(view_alarms){
                    selected = 'Diagnostics';
                }else{
            	   selected = 'System View';
                }
            }
        }

        var top_nav_string  = '<div id="tns" class="topnavsec"><img class="topnavbkgd" src="../images/NavigationBar.png" width="100%" height="90px">';
		var xctr = 40;
        for(var nav_i = 0; nav_i < top_nav.length; nav_i++){
        	if (show_top_nav_option($.trim(top_nav[nav_i][9]))){
	            var title = $.trim(top_nav[nav_i][0]);
	            var href = $.trim(top_nav[nav_i][1]);
	            //var xctr = parseInt($.trim(top_nav[nav_i][2]));
	          
	            var u_pos = $.trim(top_nav[nav_i][3]);
	            var u_pos_x = parseInt($.trim(u_pos.split(',')[0]));
	            var u_pos_y = parseInt($.trim(u_pos.split(',')[1]));
	
	            var h_pos = $.trim(top_nav[nav_i][4]);
	            var h_pos_x = parseInt($.trim(h_pos.split(',')[0]));
	            var h_pos_y = parseInt($.trim(h_pos.split(',')[1]));
	
	            var d_pos = $.trim(top_nav[nav_i][5]);
	            var d_pos_x = parseInt($.trim(d_pos.split(',')[0]));
	            var d_pos_y = parseInt($.trim(d_pos.split(',')[1]));
	
	            var icon = $.trim(top_nav[nav_i][6]);
	            var id = $.trim(top_nav[nav_i][7]);
	
	            top_nav_string += '<div class="topnavbtn" style="top:37px; left:'+(xctr+15)+'px;" page_href="'+href+'" id="'+id+'">'+
	                                    '<div class="topnavimg top_nav_reg" style="visibility:'+(selected == title ? 'hidden': 'visible')+'; top:'+u_pos_y+'px; left:'+u_pos_x+'px;">'+
	                                        '<img src="images/topnav/'+icon+'Icon.png">'+
	                                    '</div>'+
	                                    '<div class="topnavimg top_nav_highlight" style="visibility:hidden; top:'+h_pos_y+'px; left:'+h_pos_x+'px;">'+
	                                        '<img src="images/topnav/'+icon+'Icon_highlighted.png">'+
	                                    '</div>'+
	                                    '<div class="topnavimg top_nav_selected '+ (selected == title ? 'current_top_nav': '') +'" style="visibility:'+(selected == title ? 'visible': 'hidden')+'; top:'+d_pos_y+'px; left:'+d_pos_x+'px;">'+
	                                        '<img src="images/topnav/'+icon+'Icon_selected.png">'+
	                                    '</div>'+
	                                    '<div class="topnavtxt topnavtxt_u" style="top: 22px; left: -50px; width: 97px;">'+title+'</div>'+
	                                '</div>';
        		xctr = xctr + 110;
        	}
        }   
        top_nav_string += '</div>';

        $('#topnav').html(top_nav_string);
        top_nav_functions();
    }

    // top nav hoover
    function top_nav_functions(){
        $('#topnav .topnavbtn').w_hover(function(){
            if($(this).find('.top_nav_selected').css('visibility') == 'hidden'){
                $(this).find('.top_nav_highlight').css({'visibility':'visible'});
                $(this).find('.top_nav_reg').css({'visibility':'hidden'});
            }
        },function(){
            if($(this).find('.top_nav_selected').css('visibility') == 'hidden'){
                $(this).find('.top_nav_highlight').css({'visibility':'hidden'});
                $(this).find('.top_nav_reg').css({'visibility':'visible'});
            }
        });
    
        //clicked 
        $('#topnav .topnavbtn').w_click(function(){
            if(!$(this).hasClass('disable')){
                var current_object = $(this);
                var title = current_object.find('.topnavtxt').html();
                var href = current_object.attr('page_href');
                var id = current_object.attr('id');

                //unselecting the prev top nav item
                $('.current_top_nav').css({'visibility':'hidden'});
                $('.current_top_nav').closest('.topnavbtn').find('.top_nav_reg').css({'visibility':'visible'});
                $('.current_top_nav').removeClass('current_top_nav');

                //selecting the new top nav item
                current_object.find('.top_nav_highlight').css({'visibility':'hidden'});
                current_object.find('.top_nav_selected ').css({'visibility':'visible'});
                current_object.find('.top_nav_selected ').addClass('current_top_nav');
                
                top_nav_title_selected = title;
                top_nav_href_selected = href;
                item_clicked = $(this);
                if(typeof preload_page == 'function'){
                    preload_page(); 

                }else{
                    preload_page_finished(); 
                }
            }
        });
    }
var top_nav_title_selected = '';
var top_nav_href_selected ='';
/**********************************************************************
 left nav
**********************************************************************/
var item_clicked;
    function build_left_nav(selected,left_nav_selected,left_v_nav_selected,build_settings){
        var first_page_load = false;
        if(typeof selected === "undefined"){
        	if ($("#hd_product_type").val() == 1){
        		selected = 'Configuration';
        	}
        	else{
                if(view_alarms){
                    selected = 'Diagnostics';
                }else{
            	   selected = 'System View';
                }
            first_page_load = true;
           }
        }else{
            selected = htmlDecode(selected);
        }

        $('#leftnavtitle').html(selected);

        set_current_url('');
        var current_title = '';
        var prev_scope_index = 1; 
        var scope_index = 1;
        var hide_scope = -1;
        var show_left_nav_scope = true;
        var left_nav_string = '<ul id="left_menu_selector">';
        var first_selected = false;
        var temp_left_nav_len = 1;
        var default_page_index = -1;

        var partial_title;
        var partial_title_trace;

        if(typeof build_settings !== 'undefined'){
            if(typeof build_settings['partial_title'] !== 'undefined'){
                partial_title = build_settings['partial_title'];
            }

            if(typeof build_settings['partial_title_trace'] !== 'undefined'){
                partial_title_trace = build_settings['partial_title_trace'];
            }
        }

        if(typeof left_nav[selected] !== 'undefined' && left_nav[selected].length > 0){  
 	      	if (($("#hd_product_type").val() == "1") && (selected == "Configuration") && (v_config_menu_option == "")){
 	      		temp_left_nav_len = 1;
 	      	}else{
				temp_left_nav_len = left_nav[selected].length;
			}   	
            for(var nav_i = 0; nav_i < temp_left_nav_len; nav_i++){
                scope_index = parseInt(left_nav[selected][nav_i][0]);
                var title = $.trim(left_nav[selected][nav_i][1]);
                var href = $.trim(left_nav[selected][nav_i][2]);
                var header_title;
                var item_system = $.trim(left_nav[selected][nav_i][3]);

                if(hide_scope == -1){
                    show_left_nav_scope = update_show_hide_nav_scope(item_system,-1,'show');

                    var hide_scope_temp = update_show_hide_nav_scope(item_system,scope_index,'hide');
                    if(typeof hide_scope_temp !== 'undefined'){
                        hide_scope = hide_scope_temp;
                    }

                }else if(hide_scope == scope_index || hide_scope > scope_index){
                    show_left_nav_scope = update_show_hide_nav_scope(item_system,-1,'show');

                    var hide_scope_temp = update_show_hide_nav_scope(item_system,scope_index,'hide');
                    if(typeof hide_scope_temp !== 'undefined'){
                        hide_scope = hide_scope_temp;
                    }else{
                        hide_scope = -1;
                    }
                }else{
                    show_left_nav_scope = false;
                }

                if(show_left_nav_scope){
                	if (default_page_index == -1){
                		default_page_index = nav_i;
                	}
                    if(scope_index < prev_scope_index){
                        for(var new_i = prev_scope_index; new_i > scope_index; new_i--){
                            left_nav_string += '</ul>';
                        }
                    }else if(scope_index > prev_scope_index){
                         for(var new_i = scope_index;  new_i > prev_scope_index; new_i--){
                            if(title == 'generating menu..')
								left_nav_string += '<ul class="vital_config_menu">' + v_config_menu_option;
							else if (title == 'vlp io log menu..') {
								left_nav_string += '<ul class="vlp_io_log_menu">' + vlp_io_log_menu_option;
							}else 
								left_nav_string += '<ul>';
						}
                    }else{
                        left_nav_string += '</li>';
                    }

                    var enable_left_item = true;
                    //checks if there is an enable 
                    if($.trim(left_nav[selected][nav_i][4]) != null && $.trim(left_nav[selected][nav_i][4]) == 'false'){
                        enable_left_item = false; 
                    }

                    if(enable_left_item && title != 'generating menu..' && title != 'vlp io log menu..' && title != 'Field Adjustment'){
                        var found = false;
                        if((left_nav_selected != null && left_nav_selected == href) || (typeof partial_title_trace === 'undefined' && typeof partial_title !== 'undefined' && title.indexOf(partial_title) != -1)){
                            found = true;
                        }
                        left_nav_string += '<li class="leftnavtext_U" page_href="'+href+'" '+(typeof left_nav_selected !== 'undefined' &&   found ? 'id="find_me"': '')+'><span>'+title+'</span>';
                    }else if (title == 'Field Adjustment'){
                        if(field_adjustment_menu_option.indexOf('...') == -1){
                            left_nav_string += '<ul class="field_adjustment_log_menu">' + field_adjustment_menu_option;
                        }
                    }  
                    prev_scope_index = scope_index;
                }
            }

            for(var i = prev_scope_index; i > 0; i--){
                left_nav_string += '</ul>';
            }

            clear_left_nav_functions();
            //adds the left nav into the html
            $('#leftnavtree').html(left_nav_string);
			$("#maskcontent").unmask("Processing request, please wait...");
            //$("#parent_window").unmask("Processing request, Please wait...");

            if ($.trim(current_title) == 'Field Adjustment' && current_url == ''){
                set_current_url('/setup/no_cards/');
            }

            $('#left_menu_selector li').each(function(){
                if(!first_selected && $(this).attr('page_href') != 'toggle'){
                    first_selected = true;

                    current_title = $(this).find('span').html();
                    set_current_url($(this).attr('page_href'));
                }
            });

			if(typeof left_v_nav_selected !== 'undefined'){
				$('li[page_href="' + left_v_nav_selected +'"]').attr("id", "find_me"); 
				init_left_nav_tree();
            	left_nav_functions();
			}else{
                init_left_nav_tree();
                left_nav_functions();
                if($("#hd_product_type").val() == "1"){
                	if (load_content_flag){
               		  loads_content(current_title,get_current_url());
                	}
                }else{
                	if (selected == 'Configuration'){
                		current_title = 'Configuration';
                		set_current_url('/construction/index');
                	}
                	loads_content(current_title,get_current_url());
                }
                load_content_flag = true;
			}

            setTimeout(function(){
                if(typeof partial_title_trace === "undefined" && typeof partial_title !== 'undefined'){
                    $('#left_menu_selector li').each(function(){
                        var title = $(this).html();

                        if(title.indexOf(partial_title) != -1 && title.indexOf('<li') == -1){
                            $(this).attr('id','find_me');
                            current_title = title;
                            $('#content_title').html('<p>'+title+'</p><img class="ajax-loader" src="/images/ajax-loader.gif"/>');
                            $('.ajax-loader').hide();
                        }
                    });
                }else if(typeof partial_title !== "undefined"){
                    //traces through array in partial_title_trace to get exact menu
                    var _this = $('.leftnav');
                    for(var i = 0; i < partial_title_trace.length; i++){
                        if(_this.find('span:contains("'+partial_title_trace[i]+'")').length > 0){
                            _this = _this.find('span:contains("'+partial_title_trace[i]+'")').first().parent();
                        }
                    }

                    var found_me = false;
                    _this.find('li').each(function(){
                        var title = $(this).find('span').text();
                        
                        if(!found_me && $(this).attr('page_href') != 'toggle' && title.indexOf(partial_title) != -1){
                            $(this).attr('id','find_me');
                            current_title = title;
                            $('#content_title').html('<p>'+title+'</p><img class="ajax-loader" src="/images/ajax-loader.gif"/>');
                            $('.ajax-loader').hide();
                            found_me = true;
                        }
                    });
                }

                //navigations upward so the select tag will appear selected
                var tag_trace_ul = $('#find_me').parent().closest('ul');
                var tag_trace_li = $('#find_me').parent().closest('li');
                var continue_trace = true;

                //adds style to the select link
                $('#find_me').find('span').addClass('leftnavtext_D');

                $('#find_me').click();
               
                var li_count = 0;
                if(tag_trace_ul.length > 0 ){
                    li_count++;
                    tag_trace_li.find('span').first().addClass('leftnavtext_D').removeClass('leftnavtext_U');
                    while(continue_trace){
                        tag_trace_ul.show();
                        tag_trace_li.removeClass('expandable-hitarea').addClass('collapsable-hitarea');
                        tag_trace_li.children().first().removeClass('expandable-hitarea').addClass('collapsable-hitarea');

                        if(tag_trace_ul.closest('ul').length > 0){
                            tag_trace_ul = tag_trace_ul.parent().closest('ul');
                            tag_trace_li = tag_trace_li.parent().closest('li');
                            tag_trace_li.find('span').first().addClass('leftnavtext_D').removeClass('leftnavtext_U');
                            li_count++;
                        }else{
                            continue_trace = false;
                        }
                    }
                }
            },2);
        }
    } 
    var CPU_3_titles = ['CPU3','CPU-III'];

    function update_show_hide_nav_scope(item_system,scope_index,type){
        var show_left_nav_scope; 
        var hide_scope;

        if(item_system != '*'){
            if(item_system == 'ptc_enable' && !ptc_enabled_flag){
                show_left_nav_scope = false;
                hide_scope = scope_index;
            }else if(item_system == '!ptc_enable' && ptc_enabled_flag){
                show_left_nav_scope = false;
                hide_scope = scope_index;
            }else if(item_system == 'usb_enable' && !usb_enabled_flag){
                show_left_nav_scope = false;
                hide_scope = scope_index;
            }else if(item_system == '!usb_enable' && usb_enabled_flag){
                show_left_nav_scope = false;
                hide_scope = scope_index;
            }else if(item_system == 'usb_enableAndNotOCE' && (PRODUCT_TYPE == PRODUCT_TYPE_GEO_OCE)){
                show_left_nav_scope = false;
                hide_scope = scope_index;
            }else if(item_system == 'usb_enableAndNotOCE' && (!usb_enabled_flag && PRODUCT_TYPE == PRODUCT_TYPE_GEO_WEBUI)){
                show_left_nav_scope = false;
                hide_scope = scope_index;
            }else if(item_system == 'GEO_OCE' && PRODUCT_TYPE != PRODUCT_TYPE_GEO_OCE){
                show_left_nav_scope = false;
                hide_scope = scope_index;
            }else if(item_system == '!GEO_OCE' && PRODUCT_TYPE == PRODUCT_TYPE_GEO_OCE){
                show_left_nav_scope = false;
                hide_scope = scope_index;
            }else if(item_system == 'GEO_OCE_ADMIN' && (OCE_ADMIN == 0)){ 
			    show_left_nav_scope = false;
                hide_scope = scope_index;
            }else if(item_system == 'GEO_OCE_ADMIN' && (OCE_ADMIN == 1) && ADMIN_FLAG && PRODUCT_TYPE == PRODUCT_TYPE_GEO_OCE ){
			    show_left_nav_scope = false;
                hide_scope = scope_index;
            }else if(item_system == 'cpu_3_menu_system' && !cpu_3_menu_system_flag){
                show_left_nav_scope = false;
                hide_scope = scope_index;
            }else if(item_system == '!cpu_3_menu_system' && cpu_3_menu_system_flag){
                show_left_nav_scope = false;
                hide_scope = scope_index;
            }else if(item_system == 'GCP5k' && !is_gcp_5k){
                show_left_nav_scope = false;
                hide_scope = scope_index;
            }else if(item_system == '!GCP5k' && is_gcp_5k){
                show_left_nav_scope = false;
                hide_scope = scope_index;
            }else{
                //no parameters so far are matching varible in menu tree
                show_left_nav_scope = true;
            }
        }else{
            show_left_nav_scope = true;
        }

        if(type == 'show'){
            return show_left_nav_scope;
        }else{
            return hide_scope;
        }
    }

    function clear_left_nav_functions(){

        $('#leftnavtree li span').w_die('hover');
    
        $('#leftnavtree span').w_die('click');
        
        $('#leftnavtree .hitarea').w_die('click');
    }

    //left nav hover
    function left_nav_functions(){
        $('#leftnavtree li span').w_hover(function(){
            if(!$(this).closest('li').hasClass('disable')){
                if(!$(this).hasClass('leftnavtext_D')){
                    $(this).removeClass('leftnavtext_U');
                    $(this).addClass('leftnavtext_H');
                }
            }
        },function(){
            if(!$(this).hasClass('disable')){
                if(!$(this).hasClass('leftnavtext_D')){
                    $(this).removeClass('leftnavtext_H');
                    $(this).addClass('leftnavtext_U');
                }
            }
        });
    
        //the left nav name is clicked 
        $('#leftnavtree span').w_click(function(){
            if(!$(this).closest('li').hasClass('disable')){
                var orginal_click = $(this);
                top_nav_title_selected = '';

                item_clicked = $(this);

                while(item_clicked.closest('li').attr('page_href') == "child_link"){
                    item_clicked = item_clicked.closest('li').find('ul li span').first();

                    if(item_clicked.closest('li').hasClass('disable')){
                        expand_left_navtree(orginal_click.closest('li').find('.hitarea').first());
                        return false;
                    }
                }

                if($.trim(item_clicked.closest('li').attr('page_href')) == "toggle"){
                    //when the user clicks on pages that has toogle as a url it will only toggle the menutree
                    expand_left_navtree($(this).closest('li').find('.hitarea').first());
                }else{
    				if ($(this).closest('li').attr("page_href")) {
    					if (typeof preload_page == 'function') {
    						preload_page();
    					}
    					else {
    						preload_page_finished();
    					}
    				}
                }
            }
        });

        //the arrow for the left nav is click
        $('#leftnavtree .hitarea').w_click(function(){
            expand_left_navtree(this);
        });

        function expand_left_navtree(t){
            top_nav_title_selected = '';

            //sets all of the color on the left nav to be not be selected or highlighted
            $('#leftnavtree li span').removeClass('leftnavtext_D');
            $('#leftnavtree li span').addClass('leftnavtext_U');
            
            //updates the color of the item selected
            if($(t).hasClass('collapsable-hitarea')){
                $(t).closest('li').find('span').first().removeClass('leftnavtext_U');
                $(t).closest('li').find('span').first().removeClass('leftnavtext_H');
                $(t).closest('li').find('span').first().addClass('leftnavtext_D');
            } 
        }
	}
    var destroy = '';

    var add_to_destroy = function(new_destroy){if(typeof destroy === 'function'){
            var temp_destroy = destroy;
            destroy = function(){
                temp_destroy();
                new_destroy();
            };
        }else{
            destroy = new_destroy; 
        }
    };

    var destroy_reset = function(){
        if(typeof destroy == 'function'){
            destroy();

            destroy = '';
        }

        preload_page = ''; 
    };
    
    preload_page_finished = function (){
        var params = (typeof new_params === "object" ? new_params : {});
        if(top_nav_title_selected != ''){
            if (typeof top_nav_title_selected === "undefined") {
                    build_left_nav(top_nav_title_selected,top_nav_href_selected);

                    destroy_reset();

            }else if(new_url != ''){

                destroy_reset();
                loads_content(new_title,new_url,params);

                new_url = '';
                new_title = '';
                new_params = '';
            }else {
                if (htmlDecode(top_nav_title_selected) == "Configuration") {
                	build_vital_config_object(top_nav_title_selected);
                    destroy_reset();
                }else if (htmlDecode(top_nav_title_selected) == "Reports & Logs") {
                	build_vlp_io_log_object(top_nav_title_selected);	
                	destroy_reset();
                }else if (htmlDecode(top_nav_title_selected) == "Field Adjustment") {
                    build_field_adjustment_object(top_nav_title_selected);    
                    destroy_reset();
                }else {

                    build_left_nav(top_nav_title_selected,top_nav_href_selected);

                    destroy_reset();
                }
            }
        }else{
            if(typeof item_clicked == 'object' && item_clicked != null){
                
                destroy_reset();

                $('li span').removeClass('leftnavtext_D');
                $('li span').removeClass('leftnavtext_H');
                $('li span').removeClass('leftnavtext_U');

                item_clicked.addClass('leftnavtext_D');

                var current_ul = item_clicked.closest('ul');

                while(current_ul.length > 0 && current_ul.closest('li').length > 0){
                    current_ul.closest('li').find('span').first().addClass('leftnavtext_D');
                    current_ul = current_ul.parent().closest('ul');
                }

                var page_title = item_clicked.closest('li').find('span').html(); 
                var content_href = item_clicked.closest('li').attr('page_href');
                if (page_title == 'Refresh' && content_href == '/io_status_view/module_refresh'){
                	module_refresh('io');
                }else{
                    loads_content(page_title,content_href,params);
                }
            }else if(new_url != ''){
                destroy_reset();
                loads_content(new_title,new_url,params);
                new_url = '';
                new_title = '';
                new_params = '';
            }
        }
    };
    
	function add_v_preload_page() {
		preload_page = function(){
			ConfirmDialog('Vital Config','You did not save all parameters.<br>Would you like to leave page?',function(){
				if(typeof item_clicked == 'object'){
					preload_page_finished();
				}
				preload_page = '';
			},function(){
				//don't load the next page
			});
		};
	}

    function add_nv_preload_page() {
        preload_page = function(){
            ConfirmDialog('NV Vital Config','You did not save all parameters.<br>Would you like to leave page?',function(){
                if(typeof item_clicked == 'object'){
                    preload_page_finished();
                }
                preload_page = '';
            },function(){
                //don't load the next page
            });
        };
    }

    function remove_preload_page(){
        preload_page = "";
    }
	
	function remove_v_preload_page(){
		preload_page = "";
	}
	
	//creates the tree view
    function init_left_nav_tree(){
    	$("#leftnavtree").treeview(
        { collapsed : true,     // Initial view is collapsed
          unique    : true,         // Accordion behavior (when one branch opens, its sibling closes)
          animated  : 100           // Speed of reveal (msec)
        });
    }

    function remove_left_nav_items(hidden_nav){

        if(typeof hidden_nav === 'string'){
            hidden_nav = [hidden_nav];
        }

        if(typeof hidden_nav === 'object'){
            $('#leftnavtree li').each(function(){
                var href = $(this).attr('page_href');

                if(hidden_nav.indexOf(href) >= 0){  //exact match
                    $(this).remove();
                }else if(hidden_nav.indexOf(href.split('?')[0]+'?*') >= 0){ //* after ?
                    $(this).remove();
                }else if(hidden_nav.indexOf('/'+href.split('/')[1]+'/*') >= 0){ //all from controller absolute path
                    $(this).remove();
                }
            });
        }
    }

    function disable_left_nav_items(hidden_nav){

        if(typeof hidden_nav === 'string'){
            hidden_nav = [hidden_nav];
        }

        if(typeof hidden_nav === 'object'){
            $('#leftnavtree li').each(function(){
                var href = $(this).attr('page_href');

                if(hidden_nav.indexOf(href) >= 0){  //exact match
                    $(this).addClass('disable');
                }else if(hidden_nav.indexOf(href.split('?')[0]+'?*') >= 0){ //* after ?
                    $(this).addClass('disable');
                }else if(hidden_nav.indexOf('/'+href.split('/')[1]+'/*') >= 0){ //all from controller absolute path
                    $(this).addClass('disable');
                }
            });
        }
    }

    function enable_left_nav_items(hidden_nav){

        if(typeof hidden_nav === 'string'){
            hidden_nav = [hidden_nav];
        }

        if(typeof hidden_nav === 'object'){
            $('#leftnavtree li').each(function(){
                var href = $(this).attr('page_href');

                if(hidden_nav.indexOf(href) >= 0){  //exact match
                    $(this).removeClass('disable');
                }else if(hidden_nav.indexOf(href.split('?')[0]+'?*') >= 0){ //* after ?
                    $(this).removeClass('disable');
                }else if(hidden_nav.indexOf('/'+href.split('/')[1]+'/*') >= 0){ //all from controller absolute path
                    $(this).removeClass('disable');
                }
            });
        }
    }

	function build_vital_config_object(title, v_selected_item,build_settings){
		var menu_url = '';
		 $("#maskcontent").mask("Loading contents, please wait...");
		if ((PRODUCT_TYPE == PRODUCT_TYPE_GEO_OCE) && ($(hd_current_site_type).val() == "GCP") && ((is_gcp_5k == false) || (is_gcp_5k == 'false'))){
			menu_url = "/gcp_programming/vital_config_menu";
		}
		else{
			menu_url = "/programming/vital_config_menu";
		}
	    $.post(menu_url,{
	        //no params
	    },function(config_resp){
	        v_config_menu_option = config_resp.html_content;	
			build_left_nav(title, null, v_selected_item,build_settings);
	    });
	 }
	 
	 function build_vlp_io_log_object(title, v_selected_item){
	    $.post('/geo_event_log/vlp_io_log_menu',{
	        //no params
	    },function(config_resp){
	        vlp_io_log_menu_option = config_resp.html_content;	
			build_left_nav(title, null, v_selected_item);
	    });
	 }

     function build_field_adjustment_object(title){
        $.post('/setup/get_cards',{
            //no params
        },function(setup_resp){
            field_adjustment_menu_option = setup_resp;
            build_left_nav(title);
        });
     }
/**********************************************************************
 tabs
**********************************************************************/
    function build_tabs(){
        if(typeof tabs !== 'undefined' && !$.isEmptyObject(tabs)) {

            $('.contenttabs').html('');
            
            var table = '<table clas="tabs"><tr>'
            for (var tab in tabs) {
               table += '<td page_href="'+tab+'" class="'+(get_current_url() == tab ? 'tab_s' : 'tab_u')+' contenttab"><span>'+tabs[tab]+'</span></td>';
            }
            table += '</tr></table>'
            $('.contenttabs').html(table);

            tabs = {};
            tabs_functions();
        }
    }

    function keep_tabs(){
        keep_tabs_flag = 'true';
    }

    function destroy_tabs(){
        if(keep_tabs_flag != ''){
            keep_tabs_flag = '';
        }else{
            $('.contenttabs').html('');
        }
    }

    function tabs_functions(){
        $('.contenttabs td').w_hover(function(){
            if(!$(this).hasClass('tab_s')){
                $(this).removeClass('tab_u').addClass('tab_h');
            }
        },function(){
            if(!$(this).hasClass('tab_s')){
                $(this).removeClass('tab_h').addClass('tab_u');
            }
        });

        $('.contenttabs td').w_click(function(){
            if(!$(this).hasClass('disable')){
                $('.contenttabs td').removeClass('tab_s').addClass('tab_u');
                $(this).removeClass('tab_h').removeClass('tab_u').addClass('tab_s');

                var href = $(this).attr('page_href');
                var title = $(this).find('span').html();
                keep_tabs_flag = 'true';

                render_content(title,href);
            }
        });
    }


/**********************************************************************
 content
**********************************************************************/
function render_content(page_title,content_href,params){
    new_title = (page_title == '' ? current_title : page_title);
    new_params = (params == '' || params == null ? {} : params);
    new_url = content_href;
    item_clicked = null;

    if (typeof preload_page == 'function') {
        preload_page(params);
    }
    else {
        preload_page_finished(params);
    }
}
var xhr; 
var request_canceled = false; 

//loads the new page the user selected 
function loads_content(page_title,content_href,params){

    if(typeof params === 'undefined'){
        params = {};
    }

	$('.context-menu').each(function(){
		$(this).remove();
	});
	
	if ($("#hd_product_type").val() == "0"){
		$("#colorbox").remove();
		$("#cboxOverlay").remove();
	}
    destroy_tabs();
    current_title = page_title;
    current_url = content_href;
    set_current_url(content_href);

    if(page_title.length != 0 && page_title.indexOf(':') != -1){
        $('#content_title').html('<p>'+page_title.split(':')[1]+'</p><img class="ajax-loader" src="/images/ajax-loader.gif"/>');
    }else{
        if(page_title.length > 0 ){
            $('#content_title').html('<p>'+page_title+'</p><img class="ajax-loader" src="/images/ajax-loader.gif"/>');
        }
    }
	 $("#contentcontents").html("");
	 //$("#contentcontents").html("").mask("Loading contents, please wait...");
	 $("#maincontent").mask("Loading contents, please wait...");

    if(typeof xhr !== 'undefined' && xhr != null){
        xhr.abort();  //cancels previous request if it is still going
        request_canceled = true;
    }else{
        request_canceled = false;
    }


    xhr = $.post(content_href,params,function(content_resp){
        if(typeof content_resp == "object"){
            if (content_resp.error) {
                $('#contentcontents').html('<div class="error_message">' + content_resp.message + '</div>');
            }
            else {
                $('#contentcontents').html('<div class="content_wrapper">' + content_resp.html_content + '</div>');
                if (($("#hd_product_type").val() == "0") && (content_resp.screen_verification != undefined || content_resp.location_request != undefined)) {
                    if (content_resp.screen_verification != undefined && (($('#parameter_count').length <= 0 || $('#parameter_count').val() == "0")) || ($('#parameters_missing').length > 0 && $('#parameters_missing').val() != "0"))
                        $("#contentcontents").unmask("Loading contents, please wait...");
                    else if (content_resp.screen_verification != undefined)
                        $("#contentcontents").mask("Processing screen verification, please wait...");
                    else
                        $("#contentcontents").mask("Loading contents, please wait...");
                }
            }
        }else{
            $('#contentcontents').html('<div class="content_wrapper">'+content_resp+'</div>');
        }
        $('.ajax-loader').hide();
        if(typeof postload_page == 'function'){
             postload_page();    
             postload_page = function(){};   
        }
            
            $(document).trigger("ready");
            $(document).unbind('ready');
            $('#contentcontents').css({'overflow':'hidden'})
        xhr = null;
		$("#maincontent").unmask("Loading contents, please wait..."); 		
    });
    
    $("#contentcontents").css({'height': 'auto', 'min-height':'400px', 'width': '930px', 'min-width': '800px'});   
}
function load_page(new_title,new_url,params){
    render_content(new_title,new_url,params);
}
function reload_page(params){
    render_content(current_title,current_url,params);
}

// ajax calls will have to be async:"false"
//these functions are called before and after the content is loaded
preload_page = '';
postload_page = '';

//changes content demesions

function set_content_height(new_height){
    $('#contentcontents').css({'height':parseInt(new_height)+'px'});
}

function set_content_width(new_width){
    $('#contentcontents').css({'width':parseInt(new_width)+'px'});
}
function set_content_deminsions(new_width,new_height){
    set_content_height(new_height);
    set_content_width(new_width);
}

function get_current_url(){
    return current_url;
}

function set_current_url(new_url){
    current_url =  new_url;
}

function ptc_enable(){
    return $.post('/application/ptc_enable_check',{
        //params
    },function(ptc_enable_resp){
        if(ptc_enable_resp == "true"){
            ptc_enabled_flag = true; 
        }else{
            ptc_enabled_flag = false;
        }
    });
}

function usb_enable(){
   return $.post('/application/usb_enable_check',{
        //params
    },function(ptc_enable_resp){
        if(ptc_enable_resp == "true"){
            usb_enabled_flag = true; 
        }else{
            usb_enabled_flag = false;
        }
    });
}

function cpu_3_menu_system(){
   return $.post('/application/cpu_3_menu_system',{
        //params
    },function(ptc_enable_resp){
        if(ptc_enable_resp == "true"){
            cpu_3_menu_system_flag = true; 
        }else{
            cpu_3_menu_system_flag = false;
        }
    });
}

function update_gcp5k_flag(){
    return $.post('/application/gcp5k',{
        //params
    },function(gcp5k_resp){
        if(gcp5k_resp == "true"){
            is_gcp_5k  = true; 
        }else{
            is_gcp_5k  = false;
        }
    });
}

function oce_enable(){
   return is_oce_flag;
}

/**********************************************************************
 log out session
**********************************************************************/
var session_mouse_last_x;
var session_mouse_last_y;
var session_mouse_timer;
var session_mouse_reset_flag = "false";

function update_session_mouse(session_mouse_new_x,session_mouse_new_y){
    if(typeof session_mouse_last_x != 'undefined' && typeof session_mouse_last_x != 'undefined'){
        if(session_mouse_last_x != session_mouse_new_x && session_mouse_last_x != session_mouse_new_y){
            session_mouse_reset_flag = "true";
            reset_logout_session_flag = true; 
            
            clearInterval(session_mouse_timer);
            session_mouse_timer = setInterval(function(){
                ajax_check_login_session();
            },10000);
        }

    }

    session_mouse_last_x = session_mouse_new_x;
    session_mouse_last_y = session_mouse_new_y;

}
var setInterval_check_mousemove_bound;
function init_session_mouse(){
    $('body').mousemove(function(event){
        update_session_mouse(event.pageX ,event.pageY)
    });


    //when user leaves or comes back to the page it checks status again
    $([window, document]).focusin(function(){
        ajax_check_login_session();
    }).focusout(function(){
        ajax_check_login_session();
    });
}

var reset_logout_session_flag = true; 

function ajax_check_login_session(){
    if(reset_logout_session_flag){
    	if(ajax_check_session_flag){
	    	ajax_check_session_flag = false;
	        $.ajax({
	          type: "POST",
	          url: '/application/ajax_check_session/',
	          data:{ reset:session_mouse_reset_flag},
	          success: function(sessoin_rep){
	          	ajax_check_session_flag = true;
	            session_mouse_reset_flag = "false";
	            if(sessoin_rep!=""){
	                clearInterval(session_mouse_timer);
	                window.location = "/access/logout"
	            }
	          }
	        });
        }
    }else{
        $.post('/application/reset_timeout_session/',{
            //no params
        },function(){
            session_mouse_reset_flag = "false";
            reset_logout_session_flag = true; 
        })
    }
}
function reset_logout_session(){
    session_mouse_reset_flag = "true";
    reset_logout_session_flag = false; 
}

/**********************************************************************
 sessions indicators
**********************************************************************/
function set_indicators(){
    get_sessions_indicators();
    setInterval(function(){
        get_sessions_indicators();
    },5000);
}
function get_sessions_indicators(){
    $.post('/sessions/get_sessions/',{
        //no params
    },function(sessions_resp){
        if(sessions_resp.cpu == 'ready'){
            $('#cpu_status_indicator').hide();

            if(lost_connect_vlp){
                lost_connect_vlp = false; 
                //checks if it is ptc enabled
                 ptc_enable();
                 usb_enable();
                 cpu_3_menu_system();

                if(!ptc_enabled_flag){
                     make_header_request();
                }

                if($('.current_top_nav').parent().find('.topnavtxt').html() == "Configuration"){
                    build_vital_config_object("Configuration", $('.leftnavtext_D').last().closest('li').attr('page_href'));                    
                }
            }
        }else{
            $('#cpu_status_indicator').show();
            $('#cpu_status_indicator img').attr('src','images/indicator/'+sessions_resp.cpu+'_icon.png');
            lost_connect_vlp = true;
        }

        if(sessions_resp.alrams == 'alarms'){
            $('#diag_msg_indicator').show();
        }else{
            $('#diag_msg_indicator').hide();
        }
        
        if (sessions_resp.cdl == '0') {
            $('#cdl_status_indicator').hide();
        }
        else {
            $('#cdl_status_indicator').show();
        }

    },'json');
}
/**********************************************************************
 rebuild site info
**********************************************************************/
function rebuild_site_info(){
    if(ptc_enabled_flag){
        $.post('/nv_config/build_site_info/',{
            //no params
        },function(site_info_resp){
            $('#mainheader').html(site_info_resp);
        });
    }else{
        make_header_request();
    }
}

/**********************************************************************
 generic
**********************************************************************/
var exit_reload_warning_msg = '';

$(window).bind('beforeunload', function(){
    if(exit_reload_warning_msg.length > 0)
        return exit_reload_warning_msg;
});

function set_exit_reload_warning_msg(msg){
    exit_reload_warning_msg = msg;
}


/**********************************************************************
 generic
**********************************************************************/

function htmlEncode(value){
  //create a in-memory div, set it's inner text(which jQuery automatically encodes)
  //then grab the encoded contents back out.  The div never exists on the page.
  return $('<div/>').text(value).html();
}

function htmlDecode(value){
  return $('<div/>').html(value).text();
}

//makes all links use this method but still loads the page
$('.leftnav a').w_click(function(event){
    if(!$(this).hasClass('disable')){
        $('.ajax-loader').show();
        event.preventDefault()
        var url = $(this).attr('href');
        var title = $(this).attr('title');

        if(title == null){
            title = '';
        }

        if(url != null){
            loads_content(title,url);
        }
    }
});


$('.submenu_click').w_click(function(event){
	$('.ajax-loader').show();
        event.preventDefault();
        var url = $(this).attr('page_href');
        var title = $(this).attr('title');
        if(title == null){
            title = '';
        }

        if(url != null){
            loads_content(title,url);
        }
});

function ConfirmDialog(title,message,callback_yes,callback_no){
$('<div></div>').appendTo('body').html('<div><h6>'+message+'</h6></div>').dialog({
        modal: true, title: title, zIndex: 10000, autoOpen: true,
        width: 'auto', resizable: false,
        buttons: {
            Yes: function () {
                $(this).dialog("close");

                if(typeof callback_yes === 'function'){
                    callback_yes();
                }
            },
            No: function () {
                $(this).dialog("close");

                if(typeof callback_no === 'function'){
                    callback_no();
                }
            }
        },
        close: function (event, ui) {
            $(this).remove();
        }
    });
};

function AlertDialog(title,message,callback){
$('<div></div>').appendTo('body').html('<div><h6>'+message+'</h6></div>').dialog({
        modal: true, title: title, zIndex: 10000, autoOpen: true,
        width: 'auto', resizable: false,
        buttons: {
            Ok: function () {
                $(this).dialog("close");

                if(typeof callback === 'function'){
                    callback();
                }
            }
        },
        close: function (event, ui) {
            $(this).remove();
        }
    });
};

function show_top_nav_option(item_system){
	if(item_system != '*'){
		if(item_system == 'ptc_enable' && !ptc_enabled_flag){
	        return false;
	    }else if(item_system == '!ptc_enable' && ptc_enabled_flag){
	        return false;
	    }else if(item_system == 'GEO_OCE' && PRODUCT_TYPE != PRODUCT_TYPE_GEO_OCE){
	        return false;
	    }else if(item_system == '!GEO_OCE' && PRODUCT_TYPE == PRODUCT_TYPE_GEO_OCE){
	       	return false;
	    }else{
	        return true;
	    }
	}else{
	        return true;
	}
}
