var check_state_interval;
var object_name_xhr = null;
var auto_default_enable = null;	
var form_default_enable;

$(document).ready(function(){
	add_to_destroy(function(){
		$(document).bind("ready",function(){});
		//kills all events
		$(".default_object").w_die("click");
		$("#obj_name").w_die("keyup");
		$('.obj_name_img').w_die("click");
		$(".object_name_update").w_die("submit");
		$(".v_save").w_die("click");
		$('.v_refresh').w_die('click');
		
		//clear intervals
		if(typeof check_state_interval !== 'undefined' && check_state_interval != null){			
			clearInterval(check_state_interval);
		}
		
		if(typeof object_name_xhr !== 'undefined' && object_name_xhr != null){
		        object_name_xhr.abort();  //cancels previous request if it is still going
		}
		
		//clear functions 
		delete window.check_object_req_state;
		delete window.refresh_page;

		//clears global variables
		delete window.check_state_interval;
		delete window.object_name_xhr;
		delete window.auto_default_enable;
		delete window.form_default_enable;
	});

	$('.v_save').addClass("disabled");
	$('.default_object').addClass("disabled");	

	$('.v_refresh').w_click(function(){
		refresh_page();
	});	
	
	$(".default_object").w_click(function(event){
		event.preventDefault();
		if($(".default_object").hasClass("disabled")){
			return false;
		}
		var current_ele_img = $('#' +auto_default_enable).attr('id')+'_image';
		$('#' + current_ele_img).show();
		if (auto_default_enable) {
			form_default_enable = true;
			$('.obj_name').attr('disabled', 'disabled').addClass('disabled');
			$('#' +auto_default_enable).removeAttr('disabled').removeClass('disabled').addClass('selected');			
			$('#' +auto_default_enable).val($('#' +auto_default_enable).attr('def_obj_name'));
			$('#' +auto_default_enable).addClass('selected');
			$('#' +auto_default_enable).focus();
			$('.v_save').removeClass('disabled');
		}
		else {
			$('.selected').val($('.selected').attr('def_obj_name'));
			$('.selected').focus();
		}
		$('.default_object').addClass("disabled");
	});		
	
	$('.obj_name_img').w_click(function(){
		if(!$(this).hasClass('disabled'))
		{
			var current_ele = $(this).attr('id').slice(0,10);
			$('.obj_name').removeAttr('disabled').removeClass('disabled selected');
			$(this).hide();	
			$('#'+current_ele).val($('#'+current_ele).attr('current_obj_name'));
			$('.v_save').addClass('disabled');
			$('.default_object').addClass("disabled");
			$(this).removeClass("edit_enable");
			remove_v_preload_page();
		}
	});

	$('.obj_name').w_click(function(){
		if($(this).attr('current_obj_name') != $(this).attr('def_obj_name')){
			auto_default_enable = $(this).attr('id');
			form_default_enable = true;
			$('.default_object').removeClass("edit_enable");
			$('.default_object').removeClass("disabled");			
		}
		if ($(this).attr('current_obj_name') == $(this).attr('def_obj_name')) {
			auto_default_enable = null;
			$('.default_object').addClass("disabled");
		}	
	});
	
	$('#object_container').w_click(function(){
		if (!$('.default_object').hasClass("edit_enable")) {
			if ((form_default_enable != true)) {
				$('.default_object').addClass("disabled");
			}
			form_default_enable = false;
		}
	});
	
	$('.obj_name').w_keydown(function(event) {
		if((event.keyCode == 222) || (event.keyCode == 107)){
			event.preventDefault();
		}  
		if(event.keyCode == 188 || event.keyCode == 53 || event.keyCode == 55 || (event.keyCode == 187 || event.keyCode == 61) || event.keyCode == 188 || event.keyCode == 190 || event.keyCode == 191){
			if(event.shiftKey){
				event.preventDefault();		
			}
		}
	});
	
    $('.obj_name').w_keyup(function(event) {
		var current_ele_img = $(this).attr('id') + '_image';
		if ($(this).attr('value') != $(this).attr('current_obj_name')) {
			val_change = true;
			add_v_preload_page();
			$('.obj_name').attr('disabled', 'disabled').addClass('disabled');
			if($('#' + current_ele_img).is(":visible") == false)
				$('#' + current_ele_img).show();
			$(this).removeAttr('disabled').removeClass('disabled').addClass('selected');
			$('.v_save').removeClass('disabled');
			$('.default_object').removeClass("disabled");
			$('.default_object').addClass("edit_enable");
		}
		else {
			remove_v_preload_page();
			$('#' + current_ele_img).hide();
			$('.obj_name').removeAttr('disabled').removeClass('disabled selected');
			$('.default_object').removeClass("edit_enable");
			$('.v_save').addClass('disabled');
			if (auto_default_enable == null) {
				$('.default_object').addClass("disabled");
			}
		}
		$(this).focus();
		if (event.keyCode == 27){
			$('.obj_name_img').trigger('click');
		}		
    });
	
	$('.v_save').w_click(function(){
		$('.message_container span').html("");
		$(".object_name_update").submit();
	});
	
	$(".object_name_update").submit(function(event){
		event.preventDefault();
		if($(".v_save").hasClass("disabled")){
			return false;
		}
        var page_url = $(this).attr('action');
		var object_type_name = $("#object_type_name").val();
		var name_type = $("#name_type").val();
		var obj_index = $('.selected').attr('obj_index');
		var def_obj_name = $('.selected').attr('def_obj_name');
		var new_obj_name = $('.selected').attr('value');
		$("#contentcontents").mask("Updating " + object_type_name + " Name, please wait...");
		$.post(page_url, {name_type: name_type, obj_index: obj_index, def_obj_name: def_obj_name, new_obj_name: new_obj_name, object_type_name: object_type_name}, function(response){
			if (response.error) {
				$('.message_container span').html("").removeClass("success_message").removeClass("warning_message").addClass("error_message").html(response.message).show();					
				$("#contentcontents").unmask("Updating " + object_type_name + " Name, please wait...");
			}
			else {
				check_object_req_state(response.request_id, "Updating " + $("#object_type_name").val() + " Name, please wait...");
			}	
        });
        return false;
    });

});

function check_object_req_state(request_id, unmask_msg){
	var req_counter = 0;
	var request_in_process = false;
	var delete_request = false;
	var object_type_name = $("#object_type_name").val();
	var name_type = $("#name_type").val();
	check_state_interval = setInterval(function(){
		if (!request_in_process) {
			request_in_process = true;
	    	object_name_xhr = $.post('/object_name/check_state', {id: request_id, object_type_name: object_type_name, name_type: name_type, delete_request: delete_request}, function(response){
		        req_counter += 1;
				if (response.error) {
					clearInterval(check_state_interval);
					$('.message_container span').html("").addClass("error_message").html(response.message).show();
					$("#contentcontents").unmask(unmask_msg);
				} else {
					if (response.request_state == "2") {
						clearInterval(check_state_interval);
						$('.message_container span').html("").removeClass("error_message").removeClass("warning_message").addClass("success_message").html(response.message).show().fadeOut(6000);					
						$("#contentcontents").unmask(unmask_msg);
						$('.obj_name_img').hide();
						$('.selected').attr("current_obj_name", $('.selected').attr('value'));
						$('.obj_name').removeAttr('disabled').removeClass('disabled selected');
						$('.v_save').addClass("disabled");
						$('.default_object').addClass("disabled");	
						refresh_page();
					}else {
						if (req_counter >= 15) {
							clearInterval(check_state_interval);
							$('.message_container span').html("").addClass("error_message").html($("#object_type_name").val() + ' Name request timeout').show();
							$("#contentcontents").unmask(unmask_msg);
						}
					}
				}
				if (req_counter >= 14) {
					delete_request = true;
				}
				request_in_process = false;
		     });
		} 
	}, 3000);
}

function refresh_page(){
	var object_type_name = $("#object_type_name").val();
	var name_type = $("#name_type").val();
	var page_name = object_type_name+' '+'Names'
	url = '/object_name/get_object_name?object_type_name=' + object_type_name + '&name_type=' + name_type;
	remove_v_preload_page();
	load_page(page_name, url);
}