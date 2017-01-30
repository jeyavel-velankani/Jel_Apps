/************************************************************************
	Siemens
	Description: This is a custom iframe scroll bar.
	Note: Jquery draggable classes was a conflict so a custome drag class was written
	Author: Kevin Ponce

************************************************************************/
(function($){
	/************************************************************************
		settings
			delimeter will allow the code to determine the height of each item. 
			off set will allow our code to skip false delimeter such as tr that are hidden.
			start_postion: top,bottom,auto
	/************************************************************************/

	$.fn.extend({
		custom_scroll_update_content: function(new_html,custom_height,settings){
			var object = $(this);

			var default_settings = {
				off_set: 0,
				delimeter:'',
				start_position:'top'
			}
			
			settings = $.extend(default_settings,settings);

			var visible_top_inner_html = '';
			if(object.has_custom_scroll() && settings.delimeter != ''){
				visible_top_inner_html = get_current_top_item_inner_html(object,settings.delimeter,settings.off_set);
			}

			object.closest('.custom_scroll_container').attr('current_top_item_inner_html',visible_top_inner_html);

			var scroll_to_type = 'else';
			if(check_bottom(object)){
				scroll_to_type = 'bottom';
			}else if(check_top(object)){
				scroll_to_type = 'top';
			}

			object.closest('.custom_scroll_container').attr('scroll_to_type',scroll_to_type);

			object.html(new_html);
			object.custom_scroll(custom_height,settings);
		}
	});

	$.fn.extend({
		has_custom_scroll:function(){
			if($(this).closest('.custom_scroll_container').length > 0){
				return true;
			}else{
				return false;
			}
		}
	})

	$.fn.extend({
		custom_scroll: function(custom_height,settings){
			var object = $(this);

			var default_settings = {
				off_set: 0,
				delimeter:'',
				start_position:'top'
			}

			settings = $.extend(default_settings,settings);

			setTimeout(function(){
				
				var view_obj = object.parent().parent();
				var object_margin_y = (isNaN(parseInt(object.css('margin-top')))? 0: parseInt(object.css('margin-top'))) + (isNaN(parseInt(object.css('margin-bottom'))) ? 0 : parseInt(object.css('margin-bottom'))); 
				var object_padding_y = (isNaN(parseInt(object.css('padding-top'))) ? 0 : parseInt(object.css('padding-top'))) + (isNaN(parseInt(object.css('padding-bottom'))) ? 0 : parseInt(object.css('padding-bottom')));
				var object_height = (isNaN(parseInt(object.height())) ? 0 : parseInt(object.height()))+object_margin_y+object_padding_y;
				var object_width  = (typeof object.attr('width') == 'undefined' || parseInt(object.attr('width')) == 0 ? parseInt(object.width()) : parseInt(object.attr('width')));
				var container_height  = parseInt(custom_height); 
				var container_width  = parseInt(object.width()); 
				var scroll_bar_height = 0; 
				var scroll_container_width = 0; 
				var max_displacement = 0; 
				var handle_max_displacement = 0; 
				var handle_height = 0; 
				var scroll_increment = 10; 
				var handle_scroll_increment = 10; 
				var num_scrolls = 0; 
				var in_custom_fix = false; 

				var has_scrollbar = false; 
				var mouse_transition = false; 

				if(!in_custom_fix){
					in_custom_fix = true;

					var scroll_environment_exsist = view_obj.hasClass('custom_scroll_container');

					if( object_height > container_height){
						has_scrollbar = true;

						scroll_bar_height = container_height;
						scroll_container_width = container_width - 25;	

						if(!scroll_environment_exsist){
							object.wrap('<div class="custom_scroll_container">');
							view_obj = object.parent();
							view_obj.wrapInner('<div class="custom_scroll_body">');
							view_obj.append('<div class="scrollbar_area"><div class="scrollbar"></div><div class="scrollbar_handle"></div></div>');
							object.attr('width',object_width);
						}

						//css
						view_obj.css({'height':container_height+'px','width':object_width+'px','overflow': 'hidden','position': 'relative','-o-user-select':'none','-khtml-user-select':'none','-webkit-user-select':'none','-webkit-touch-callout': 'none','-ms-user-select': 'none'})
						view_obj.find('.custom_scroll_container').css({'height':container_height +'px','overflow':'hidden'});		
						view_obj.find('.custom_scroll_body').css({'position': 'absolute','width': object_width+'px','top':'0px','-o-user-select':'none','-khtml-user-select':'none','-webkit-user-select':'none','-webkit-touch-callout': 'none','-ms-user-select': 'none'});
						view_obj.find('.scrollbar_area').css({'width': '17px','height': scroll_bar_height+'px','float': 'right','position': 'relative','margin': '0px auto'});

						max_displacement = object_height - container_height + 30; 

						scroll_increment = max_displacement / 10;
						//handle_scroll_increment = (scroll_increment)*scroll_bar_height/object_width;

						num_scrolls = max_displacement/scroll_increment; 
						//handle_scroll_increment = handle_scroll_increment*((num_scrolls-1)/num_scrolls);

						handle_height = scroll_bar_height - scroll_bar_height*max_displacement/object_height;

						handle_scroll_increment = (scroll_bar_height-handle_height)/num_scrolls;
						handle_max_displacement = scroll_bar_height - handle_height; 

						view_obj.find('.scrollbar').css({'border': '5px solid #515151','height': scroll_bar_height+'px','width': '0px','padding': '0px'});
						view_obj.find('.scrollbar_handle').css({'border': '5px solid #809818','height': handle_height+'px','width': '0px','position':'absolute','top':'0px','left':'0px','cursor':'pointer'})
						view_obj.find('.scrollbar_handle').attr('scroll_displacement',0);
						view_obj.find('.scrollbar_handle').attr('handle_displacement',0);

						$('.custom_scroll_container').off('wheel');
						$('.custom_scroll_container').on('wheel',function(event) {
								var scroll_displacement = parseInt(view_obj.find('.scrollbar_handle').attr('scroll_displacement'));
								var handle_displacement = parseInt(view_obj.find('.scrollbar_handle').attr('handle_displacement')); 

					            var dir = event.deltaY > 0 ? 1 : -1;
					            if((scroll_displacement < max_displacement && dir > 0 ) || (scroll_displacement > 0   && dir < 0 ) ){

					           		scroll_displacement+= (dir*scroll_increment);
					             	

					             	if(scroll_displacement > max_displacement)
					             		scroll_displacement = max_displacement;

					             	if(scroll_displacement < 0)
					             		scroll_displacement = 0;

					           		$('.custom_scroll_container').find('.custom_scroll_body').css({'top':-1*scroll_displacement+'px'}); 
					           		view_obj.find('.scrollbar_handle').attr('scroll_displacement',scroll_displacement);
					           		
					           		handle_displacement+= dir*handle_scroll_increment;
					            		            	
					            	if(handle_displacement > handle_max_displacement)
					             		handle_displacement = handle_max_displacement;

					             	if(handle_displacement < 0 )
					             		handle_displacement = 0;

					            	$('.custom_scroll_container').find('.scrollbar_handle').css({'top':handle_displacement+'px'});
					            	view_obj.find('.scrollbar_handle').attr('handle_displacement',handle_displacement);
					            }
					            return false;
					    });

					    var draggable_increments = max_displacement / (handle_max_displacement); 
						var position = $('.scrollbar_handle').position();
						var mousedown_y = 0; 
						var mouseDown = false;
						var scroll_bar_top = 0;

						$('.scrollbar').w_click(function(event){
							var scroll_displacement = parseInt(view_obj.find('.scrollbar_handle').attr('scroll_displacement'));
							var mouse_pos = parseInt(event.pageY);

							scroll_bar_top = mouse_pos - handle_height/2;

							if(scroll_bar_top > handle_max_displacement)
			             		scroll_bar_top = handle_max_displacement;

			             	if(scroll_bar_top < 0 )
			             		scroll_bar_top = 0;

			             	$(this).parent().find('.scrollbar_handle').css({'top':scroll_bar_top+'px'});

				 			//gets handles current location
							var handle_displacement = scroll_bar_top;
							scroll_displacement = scroll_bar_top*draggable_increments; 

							view_obj.find('.custom_scroll_body').css({'top':(-1*scroll_displacement)+'px'});
							view_obj.find('.scrollbar_handle').attr('scroll_displacement',scroll_displacement);
							view_obj.find('.scrollbar_handle').attr('handle_displacement',handle_displacement);
						});
						
						$('.scrollbar_handle').w_mousedown(function(event) {

						 	mouseDown = true;
						 	mousedown_y = event.pageY;
						 	scroll_bar_top = parseInt($(this).css('top'));
						 	$('body').css({'cursor':'pointer !important','-o-user-select':'none','-khtml-user-select':'none','-webkit-user-select':'none'});
						
						});

						$('body').w_mouseup(function() {

						 	mouseDown = false;
						 	mousedown_y = 0;
						 	scroll_bar_top = 0;
						 	$('body').css({'cursor':'default','-khtml-user-select': 'text','-webkit-user-select': 'text','user-select': 'text'})
						});

						$('body').w_die('mousemove');
						$('body').w_mousemove(function(event) {
						 	if(mouseDown){
						 		var e_y = event.pageY;
						 		var bar_move_to = (scroll_bar_top+((mousedown_y-e_y)*-1));
						 		var scroll_displacement = parseInt(view_obj.find('.scrollbar_handle').attr('scroll_displacement'));

						 		if(bar_move_to >= 0 && (bar_move_to + handle_height) <= scroll_bar_height){
						 			view_obj.find('.scrollbar_handle').css({'top':bar_move_to+'px'});
						 			scroll_bar_top = bar_move_to;//parseInt($('.scrollbar_handle').css('top'));
						 			mousedown_y = e_y;

						 			//gets handles current location
									var handle_displacement = scroll_bar_top;
									scroll_displacement = scroll_bar_top*draggable_increments; 

									view_obj.find('.custom_scroll_body').css({'top':(-1*scroll_displacement)+'px'});
									view_obj.find('.scrollbar_handle').attr('scroll_displacement',scroll_displacement);
									view_obj.find('.scrollbar_handle').attr('handle_displacement',handle_displacement);

									$('body').css({'cursor':'pointer !important','-o-user-select':'none','-khtml-user-select':'none','-webkit-user-select':'none'});
						
						 		}
						 	}
						});

					}else{
						if(!scroll_environment_exsist){
							object.wrap('<div class="custom_scroll_container">');
							view_obj = object.parent();
							view_obj.wrapInner('<div class="custom_scroll_body">');
							view_obj.append('<div class="scrollbar_area"><div class="scrollbar"></div><div class="scrollbar_handle"></div></div>');
							object.attr('width',object_width);
						}else{
							object.closest('.custom_scroll_container').attr('style','');
							object.closest('.custom_scroll_body').attr('style','')
							object.closest('.custom_scroll_container').find('.scrollbar_area').attr('style','');
							object.closest('.custom_scroll_container').find('.scrollbar').attr('style','')
							object.closest('.custom_scroll_container').find('.scrollbar_handle').attr('style','')
							
						}

					}
					in_custom_fix = false;

					if(settings.start_position == 'bottom'){
						object.scroll_to_bottom();
					}else if(settings.start_position == 'auto' && settings.delimeter != ''){
						var delimeter = settings.delimeter;
						//needs to use code to add html to custom scroll area

						var scroll_to_type = object.closest('.custom_scroll_container').attr('scroll_to_type');

						if(scroll_to_type == 'bottom'){
							object.scroll_to_bottom();

						}else if(scroll_to_type == 'top'){
							object.scroll_to_top();

						}else{
							var get_current_top_item_inner_html_string = object.closest('.custom_scroll_container').attr('current_top_item_inner_html');

							if(typeof get_current_top_item_inner_html_string !== 'undefined' && get_current_top_item_inner_html_string != ''){

								var go_to_line = get_item_index_from_inner_html(object,delimeter,settings.off_set,get_current_top_item_inner_html_string);

								if(go_to_line != -1){
									object.scroll_to(delimeter,go_to_line);
								}
							}
						}
					}
				}
				return has_scrollbar;
			},10);
		}
	});
	
	$.fn.extend({
		remove_custom_scroll:function(){
			$(this).closest('.custom_scroll_container').off('wheel');
			$(this).closest('.custom_scroll_container').find('.scrollbar').w_die('click');
			$(this).closest('.custom_scroll_container').find('.scrollbar_handle').w_die('mousedown');
			$('body').w_die('mouseup');
			$('body').w_die('mousemove');

			if($(this).closest('.custom_scroll_body').length > 0){
				$(this).closest('.custom_scroll_body').children().unwrap();
			}

			if($(this).closest('.custom_scroll_container').find('.scrollbar_area').length > 0){
				$(this).closest('.custom_scroll_container').find('.scrollbar_area').remove();
			}

			if($(this).closest('.custom_scroll_container').length > 0){
				$(this).closest('.custom_scroll_container').children().unwrap();
			}
		}
	});

	$.fn.extend({
		scroll_to:function(delimeter,line){
			var object = $(this);

			//sets scrol area to the correct line
			var height_line = get_scroll_object_item_height(object,delimeter); 
			
			object.closest('.custom_scroll_body').css('top',(-1*height_line*line)+'px')
			
			//sets scrolbar to the correct location
			var content_area_height = parseInt(object.height());
			var scrollbar_height = parseInt(object.closest('.custom_scroll_container').find('.scrollbar').height());
			var scrollbar_handle_height = parseInt(object.closest('.custom_scroll_container').find('.scrollbar_handle').height());
			var scrolbar_position_y = scrollbar_height * ((height_line*line)/content_area_height);
			
			object.closest('.custom_scroll_container').find('.scrollbar_handle').css('top',scrolbar_position_y+'px')
			
			object.closest('.custom_scroll_container').find('.scrollbar_handle').attr('scroll_displacement',height_line*line);
			object.closest('.custom_scroll_container').find('.scrollbar_handle').attr('handle_displacement',scrolbar_position_y);
		}
	});
	$.fn.extend({
		scroll_to_bottom:function(){
			var object = $(this);
			
			var content_area_height = parseInt(object.height())+parseInt(object.css('padding-top'))+parseInt(object.css('padding-bottom'));
			var content_visible_area_height = parseInt(object.closest('.custom_scroll_container').height());
			var content_position_y = (content_area_height-content_visible_area_height); 

			//sets scrol area to the bottom
			
			object.closest('.custom_scroll_body').css('top',(-1*content_position_y)+'px');
			object.closest('.custom_scroll_container').find('.scrollbar_handle').attr('scroll_displacement',content_position_y);
			
			//sets scrolbar to the correct location
			
			var scrollbar_height = parseInt(object.closest('.custom_scroll_container').find('.scrollbar').height());
			var scrollbar_handle_height = parseInt(object.closest('.custom_scroll_container').find('.scrollbar_handle').height());
			var scrolbar_position_y = scrollbar_height - scrollbar_handle_height ;
			
			object.closest('.custom_scroll_container').find('.scrollbar_handle').css('top',scrolbar_position_y+'px');	
			object.closest('.custom_scroll_container').find('.scrollbar_handle').attr('handle_displacement',scrolbar_position_y);
		}
	});

	$.fn.extend({
		scroll_to_top:function(){
			var object = $(this);

			//sets scrol area to the top
			object.closest('.custom_scroll_body').css('top','0px');
			object.closest('.custom_scroll_container').find('.scrollbar_handle').attr('scroll_displacement',0);
			
			//sets scrolbar to the correct location			
			object.closest('.custom_scroll_container').find('.scrollbar_handle').css('top','0px');	
			object.closest('.custom_scroll_container').find('.scrollbar_handle').attr('handle_displacement',0);
		}
	});
})(jQuery);



function get_scroll_object_item_height(object,delimeter){
	var object_item_height = parseInt(object.find(delimeter).last().height());

	if(isNaN(object_item_height)){
		return 0;
	}else{
		return object_item_height;
	}
}

function get_scroll_object_item_index(object,delimeter){
	var height_line = get_scroll_object_item_height(object,delimeter); 
	
	var content_height = -1*get_scroll_current_posttion_y(object);
	
	return (content_height/height_line);
}

function get_scroll_current_posttion_y(object){
	var current_scrol_y = parseInt(object.closest('.custom_scroll_body').css('top'));

	if(isNaN(current_scrol_y)){
		current_scrol_y = 0; 
	}
	
	return current_scrol_y; 
}



function get_current_top_item_inner_html(object,delimeter,off_set){
	if(typeof off_set === 'undefined'){
		var off_set = 0; 
	}

	var current_item_index = Math.round(get_scroll_object_item_index(object,delimeter));
		
	if(typeof object.find(delimeter).eq(current_item_index+off_set) !== 'undefined'){
		return $.trim(object.find(delimeter).eq(current_item_index+off_set).html());
	}else{
		return '';
	}
}

function get_item_index_from_inner_html(object,delimeter,off_set,delimeter_inner_html){
	var delimeter_select_count = 0; 
	var delimeter_select_index; 
	var found = false;

	object.find(delimeter).each(function(){
		var current_eter_inner_html  = $.trim($(this).html());
			
		if(current_eter_inner_html == delimeter_inner_html){
			found = true;
			delimeter_select_index = delimeter_select_count;
		}else{
			delimeter_select_count++;
		}
	});

	if(found){
		return delimeter_select_index - off_set; 
	}else{
		return -1;
	}
}

function check_bottom(object){
	var scrollbar_height = parseInt(object.closest('.custom_scroll_container').find('.scrollbar').height());
	var scrollbar_handle_height = parseInt(object.closest('.custom_scroll_container').find('.scrollbar_handle').height());
	var scrolbar_bottom = scrollbar_height - scrollbar_handle_height;
	var scrolbar_position_y = parseInt(object.closest('.custom_scroll_container').find('.scrollbar_handle').css('top'));
		
	if(scrolbar_position_y  >= scrolbar_bottom - 15){
		return true;
	}else{
		return false;
	}
}

function check_top(object){
	var scrolbar_position_y = parseInt(object.closest('.custom_scroll_container').find('.scrollbar_handle').css('top'));
	
	if(scrolbar_position_y  <= 15){
		return true;
	}else{
		return false;
	}
}
