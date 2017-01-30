/*
####################################################################
# Company: Siemens 
# Author: Gopu
# File: location.js
# Description: This js is used for location settings page
####################################################################
*/
var location_check_state_interval;
var location_xhr = null;

$(document).ready(function(){
	add_to_destroy(function(){
		$(document).bind("ready",function(){});
	
		//kills all wrapper events
		$('.location_update').w_die('submit');
		$('.v_save').w_die('click');
		$('.v_refresh').w_die('click');
		$('.location_update input').w_die('change');
		
		//clear intervals
		if(typeof location_check_state_interval !== 'undefined' && location_check_state_interval != null){
		        clearInterval(location_check_state_interval);
		}		

		if(typeof location_xhr !== 'undefined' && location_xhr != null){
		        location_xhr.abort();  //cancels previous request if it is still going
		}
		
		//clear functions 
		delete window.submit_form;
		delete window.siteconfig_validation;
		delete window.checkerror;
		delete window.check_location_req;
		
		//clears global variables
		delete window.location_check_state_interval;
		delete window.location_xhr;
	});
	
	check_location_req("/location/check_state", $(".req_id").val(), false);
		
	$('.v_refresh').w_click(function(){
		load_page('Location','/location/get_location');
	});

	
});

function submit_form(req_id){
		check_location_req("/location/check_state", req_id, true);
}


function siteconfig_validation(elem_name){
    var res = false;
    var msg = "";
    var patt1=new RegExp("e");
    var elem = $("#"+elem_name);
    switch(elem_name){
        case 'site_name':
            res = (/^[0-9A-Za-z\_\-]*$/i).test(elem.val());
            msg = "Must contain only letters, numbers and special chars(- and _)"
            break;
        case 'dot_number':
            res = (/^[0-9A-Za-z\_\-]*$/i).test(elem.val());
			msg = "Must contain only letters, numbers and special chars(- and _)"
            break;
        case 'mile_post':
            res = (/^[0-9A-Za-z\.\-\_\@\ ]*$/i).test(elem.val());
            msg = "Must contain only letters, numbers, dot, space and special chars(-, _ and @)"
            break;
    }
    if(!res){
        $("#"+elem_name+"_error_msg").html(msg);
    }else {
        $("#"+elem_name+"_error_msg").html("");
    }
}

function checkerror(){
    if ($("#site_name_error_msg").html() != "" || $("#dot_number_error_msg").html() != "" || $("#mile_post_error_msg").html() != "") {
        return false;
    }
    else{       
        return true;
    }
}

function check_location_req(page_url, req_id, save_request){
	$("#contentcontents").mask("Getting location info from the system, please wait...");
	var req_counter = 0;
	var request_in_process = false;
	var delete_request = false;
		location_check_state_interval = setInterval(function(){
			if(!request_in_process){
				request_in_process = true;
			    location_xhr = $.post(page_url, {id: req_id, delete_request: delete_request}, function(data){
					req_counter += 1;
					if (data.error) {
						$("#contentcontents").unmask("Getting location info from the system, please wait...");
						clearInterval(location_check_state_interval);
						$('.message').html("").addClass("v_error_message").html(data.message).show();
						
					} 
					else {
						if (data.request_state == '2'){
							$("#contentcontents").unmask("Getting location info from the system, please wait...");
							$('#location_name_container').html(data.html_content);
							if (save_request == true) {
								$('.message').html("").removeClass("v_error_message").html("Successfully saved Location parameters...").show().fadeOut(10000);
								remove_v_preload_page();
								if ($('#site_name_hdr').length > 0) {
									$('#site_name_hdr').html($("#site_name").val());
									$('#mile_post_hdr').html($("#mile_post").val());
									$('#dot_number_hdr').html($("#dot_number").val());
								}
							}
							else {
								$('.message').html("").removeClass("v_error_message").html("");
							}
							clearInterval(location_check_state_interval);
							$(document).trigger("ready");

							$('.location_update input').w_change(function(){
								add_v_preload_page();
							});
						}else {
							if (req_counter >= 15) {
								$("#contentcontents").unmask("Getting location info from the system, please wait...");
								clearInterval(location_check_state_interval);
								$('.message').html("").addClass("v_error_message").html('Location request timeout').show();
								if (save_request != true) {
									$('.v_save').addClass('disabled');
									$('.v_refresh').addClass('disabled');
								}
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
