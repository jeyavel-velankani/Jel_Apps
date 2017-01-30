/************************************************************************
	Siemens
	Description: This is a custom iframe scroll bar.
	Note: Jquery draggable classes was a conflict so a custome drag class was written
	Author: Kevin Ponce

************************************************************************/

function custum_scroll(custum_height, object){
	setTimeout(function(){
		var view_obj = object.parent().parent();
		var object_margin_y = (isNaN(parseInt(object.css('margin-top')))? 0: parseInt(object.css('margin-top'))) + (isNaN(parseInt(object.css('margin-bottom'))) ? 0 : parseInt(object.css('margin-bottom'))); 
		var object_padding_y = (isNaN(parseInt(object.css('padding-top'))) ? 0 : parseInt(object.css('padding-top'))) + (isNaN(parseInt(object.css('padding-bottom'))) ? 0 : parseInt(object.css('padding-bottom')));
		var object_height = (isNaN(parseInt(object.height())) ? 0 : parseInt(object.height()))+object_margin_y+object_padding_y;
		var object_width  = parseInt(object.width());
		var container_height  = custum_height; 
		var container_width  = object.width(); 
		var scroll_bar_height = 0; 
		var scroll_container_width = 0; 
		var max_displacement = 0; 
		var handle_max_displacement = 0; 
		var handle_height = 0; 
		var scroll_increment = 10; 
		var handle_scroll_increment = 10; 
		var num_scrolls = 0; 
		var in_custum_fix = false; 

		var has_scrollbar = false; 
		var iframe_position = $('#iframe', window.parent.document).offset();
		var mouse_transition = false; 

		if(!in_custum_fix){
			in_custum_fix = true;

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
				}

				//css
				view_obj.css({'height':container_height+'px','overflow': 'hidden','position': 'relative'})
				view_obj.find('.custom_scroll_container').css({'height':container_height +'px','overflow':'hidden'});		
				view_obj.find('.custom_scroll_body').css({'position': 'absolute','width': object_width+'px','top':'0px'});
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
				
				var srcoll_displacement = 0; 
				var handle_displacement = 0; 

				$('.custom_scroll_container').unbind('mousewheel');
				$('.custom_scroll_container').bind('mousewheel', function(event, delta) {
			            var dir = delta > 0 ? -1 : 1;

			            if((srcoll_displacement < max_displacement && dir > 0 ) || (srcoll_displacement > 0   && dir < 0 ) ){
			           		srcoll_displacement+= (dir*scroll_increment);
			             	

			             	if(srcoll_displacement > max_displacement)
			             		srcoll_displacement = max_displacement;

			             	if(srcoll_displacement < 0)
			             		srcoll_displacement = 0;

			           		$(this).find('.custom_scroll_body').css({'top':-1*srcoll_displacement+'px'}); 

			           		handle_displacement+= dir*handle_scroll_increment;
			            		            	
			            	if(handle_displacement > handle_max_displacement)
			             		handle_displacement = handle_max_displacement;

			             	if(handle_displacement < 0 )
			             		handle_displacement = 0;

			            	$(this).find('.scrollbar_handle').css({'top':handle_displacement+'px'});
			            }
			            return false;
			    });

			    var draggable_increments = max_displacement / (handle_max_displacement); 
				var position = $('.scrollbar_handle').position();
				var mousedown_y = 0; 
				var mouseDown = false;
				var scroll_bar_top = 0;

				$('.scrollbar').live('click',function(event){
					var mouse_pos = parseInt(event.pageY);

					scroll_bar_top = mouse_pos - handle_height/2;

					if(scroll_bar_top > handle_max_displacement)
	             		scroll_bar_top = handle_max_displacement;

	             	if(scroll_bar_top < 0 )
	             		scroll_bar_top = 0;

	             	$(this).parent().find('.scrollbar_handle').css({'top':scroll_bar_top+'px'});

		 			//gets handles current location
					handle_displacement = scroll_bar_top;
					srcoll_displacement = scroll_bar_top*draggable_increments; 

					view_obj.find('.custom_scroll_body').css({'top':(-1*srcoll_displacement)+'px'});
				});
				
				$('.scrollbar_handle').mousedown(function(event) {

				 	mouseDown = true;
				 	mousedown_y = event.pageY;
				 	scroll_bar_top = parseInt($(this).css('top'));
				 	$('body').css({'cursor':'pointer !important','-moz-user-select': 'none','-khtml-user-select': 'none','-webkit-user-select': 'none','user-select': 'none'})

				});

				$('body').mouseup(function() {

				 	mouseDown = false;
				 	mousedown_y = 0;
				 	scroll_bar_top = 0;
				 	$('body').css({'cursor':'default','-moz-user-select': 'text','-khtml-user-select': 'text','-webkit-user-select': 'text','user-select': 'text'})
				});

				$('body').unbind('mousemove');
				$('body').bind('mousemove',function(event) {
				 	if(mouseDown){
				 		var e_y = event.pageY;
				 		var bar_move_to = (scroll_bar_top+((mousedown_y-e_y)*-1));

				 		if(bar_move_to >= 0 && (bar_move_to + handle_height) <= scroll_bar_height){
				 			view_obj.find('.scrollbar_handle').css({'top':bar_move_to+'px'});
				 			scroll_bar_top = bar_move_to;//parseInt($('.scrollbar_handle').css('top'));
				 			mousedown_y = e_y;

				 			//gets handles current location
							handle_displacement = scroll_bar_top;
							srcoll_displacement = scroll_bar_top*draggable_increments; 

							view_obj.find('.custom_scroll_body').css({'top':(-1*srcoll_displacement)+'px'});
				 		}
				 	}
				});

				$('body').unbind('mouseleave');
				$('body').bind('mouseleave',function(){
					if(mouseDown){
						$("body").mouseup();
					}
				});
			}else{
				var view_obj = object.parent().parent();
				if(view_obj.hasClass('custom_scroll_container')){
					view_obj.find('.scrollbar_area').remove();
					view_obj.find('.custom_scroll_body').unwrap();				//remove custom_scroll_container
					object.unwrap();	//remove .custom_scroll_body
				}
			}
			in_custum_fix = false;
		}

		return has_scrollbar;
	},10);
}


