/****************************************************************************************************************************************
 Company: Siemens 
 Author: Ashwin
 File: programming.js
 Requirements: JQuery 1.9.1, jquery_wrapper.js
 Description: Generic vital config javascript file
****************************************************************************************************************************************/
var screen_verification_interval;
var save_interval;
var io_request_interval;

$(document).ready(function(){
	add_to_destroy(function(){
		$(document).bind("ready",function(){});
	
		//kills all wrapper events
		$('.v_save').w_die('click');
		$('input').w_die('change');
		$('select').w_die('change');
		$('input').w_die('keyup');
		$('input').w_die('keydown');
		$('.v_refresh').w_die('click');
		$('.reset_vlp').w_die('click');
		$('.v_force_update').w_die('click');
		$("#MTFIndex").w_die('change');

		//clear intervals
		clearInterval(screen_verification_interval);
		clearInterval(save_interval);
		clearInterval(io_request_interval);
		
		//clear functions 
		delete window.v_save;

		//clears global variables
		screen_verification_interval = null;
		save_interval = null;
		io_request_interval = null;
	});
});

/**********************************************************************
 saving
**********************************************************************/
$('.v_save').w_click(function(){
	if($(this).hasClass("disabled"))
		return;
	v_save($(this));
});

function v_save(t,callback){
	var has_error = false;	
	var errors = $('.v_error');
	if(errors.length > 1){
		errors.each(function(index, ele){			
			if ($(ele).html() != "") {
				has_error = true;
			}
		});
	}
	else if(errors.length == 1 && errors.html() != ""){
		has_error = true;
	}
	if(has_error == true)
		return;
	$('.v_error').html('');	//clears the errors
	var save_obj = {};	//creates json object
	var inputs = t.closest('#contentcontents').find('input,select');
	//indexs through all inputs
	inputs.each(function(){
		var key = $(this).attr('id');
		var val = $(this).val();
		//stores the key and val in the array
		save_obj[key] = val;
	});
	$('.message').html("");
	// ajax off to save vital config parameters
	$("#contentcontents").mask("Saving parameters, please wait...");
	$.post('/programming/save_page_parameters',save_obj,function(v_save_resp){
		if(typeof v_save_resp == 'string'){
			$('#contentcontents').html(v_save_resp);
			$("#contentcontents").unmask("Saving parameters, please wait...");
			remove_v_preload_page();
		}
		else{
			if(v_save_resp.error){
				$('.message_container span').html("").addClass("v_error_message").html(v_save_resp.message).show();
				if($('.hd_linker_message').length > 0){
                    $('.hd_linker_message').html("").addClass("v_error_message").html(v_save_resp.message).show();
                }
				$("#contentcontents").unmask("Saving parameters, please wait...");
			}else{
				var req_counter = 0;
				var request_in_process = false;
				var delete_request = false;
				var page_name = $("#page_name").val();
				var menu_link = $("#menu_link").val();
				var setup_wizard = $("#setup_wizard").val();
				if(save_interval != null)
					clearInterval(save_interval);
				save_interval = setInterval(function(){
					// ajax off to check save request state
					if (!request_in_process) {
						request_in_process = true;
						$.post('/programming/check_v_save_req', {
							request_id: v_save_resp.request_id,
							page_name: $("#page_name").val(), 
							menu_link: $("#menu_link").val(),
							parameters_values: v_save_resp.parameters_values,
							delete_request: delete_request,
							setup_wizard : setup_wizard,
						}, function(v_save_resp){
							if (typeof v_save_resp == 'string') {                               
                                if (page_name.indexOf("TEMPLATE") != -1|| menu_link.indexOf("TEMPLATE") != -1) {
                                	if($('.hd_linker_message').length == 0){
                                    	$(".programming_parameters_template").html(v_save_resp.html);
                                    }
                                    $("#contentcontents").unmask("Saving parameters, please wait...");
                                    remove_v_preload_page();

                                    if(typeof callback === 'function'){
                                    	callback(v_save_resp.message);
                                    }
                                }
                                else {
                                    $('#contentcontents').html(v_save_resp);
                                    $("#contentcontents").unmask("Saving parameters, please wait...");
                                    remove_v_preload_page();

                                    if(typeof callback === 'function'){
                                    	callback(v_save_resp.message);
                                    }
                                }
							}else {
								req_counter += 1;
								if (v_save_resp.error && (!v_save_resp.request_state || v_save_resp.request_state != "2")) {
									clearInterval(save_interval);
									$('.message_container span').html("").removeClass("success_message").removeClass("warning_message").addClass("error_message").html(v_save_resp.message).show();
									if($('.hd_linker_message').length > 0){
					                    $('.hd_linker_message').html("").removeClass("success_message").removeClass("warning_message").addClass("error_message").html(v_save_resp.message).show();
					                }
									$("#contentcontents").unmask("Saving parameters, please wait...");

									if(typeof callback === 'function'){
                                    	callback(v_save_resp.message);
                                    }
								}else {
									if (v_save_resp.request_state == "2") {
										if (v_save_resp.error) {
											$('.message_container span').html("").removeClass("success_message").removeClass("warning_message").addClass("error_message").html(v_save_resp.message).show();
											if($('.hd_linker_message').length > 0){
							                    $('.hd_linker_message').html("").removeClass("success_message").removeClass("warning_message").addClass("error_message").html(v_save_resp.message).show();
							                }
											if(typeof callback === 'function'){
		                                    	callback(v_save_resp.message);
		                                    }
										}else {
											if(typeof callback === 'function'){
		                                    	callback(v_save_resp.message);
		                                    }else{
		                                    	if($('.hd_linker_message').length == 0){
												 	if (page_name.indexOf("TEMPLATE") != -1 || menu_link.indexOf("TEMPLATE") != -1) {										 
														$('.programming_parameters_template').html(v_save_resp.html);
												    } else{
													    $('.content_wrapper').html(v_save_resp.html);
													}
												}
												if (v_save_resp.confirmed == "400") {
													$('.message_container span').html("").removeClass("success_message").removeClass("error_message").addClass("warning_message").html(v_save_resp.message).show();
													if($('.hd_linker_message').length > 0){
									                    $('.hd_linker_message').html("").removeClass("success_message").removeClass("error_message").addClass("warning_message").html(v_save_resp.message).show();
									                }
												}else{
													$('.message_container span').html("").removeClass("error_message").removeClass("warning_message").addClass("success_message").html(v_save_resp.message).show().fadeOut(6000);
													if($('.hd_linker_message').length > 0){
									                    $('.hd_linker_message').html("").removeClass("error_message").removeClass("warning_message").addClass("success_message").html(v_save_resp.message).show().fadeOut(6000);
									                }
												}
											}
											
											remove_v_preload_page();
											if (v_save_resp.reload_menu){ 
												build_vital_config_object("Configuration", $('.leftnavtext_D').last().closest('li').attr('page_href'));
											}
										}
										clearInterval(save_interval);
										if (page_name.toUpperCase() == "MODULE SELECTION" || page_name.toUpperCase() == "SET TEMPLATE" || page_name.toUpperCase()=="TEMPLATE:  SELECTION" || page_name.toUpperCase()=="SSCC CONFIGURATION" || page_name.toUpperCase().indexOf("DAX")!= -1 || page_name.toUpperCase().indexOf("PRIME")!= -1 || page_name.toUpperCase().indexOf("PREEMPTION")!= -1) {
												load_content_flag = true;
												$("#site_content").mask("Saving parameters, please wait...");
												if(page_name.indexOf('(') == -1){
													build_vital_config_object("Configuration",$('.leftnavtext_D').last().closest('li').attr('page_href'));
												}else{
													var partial_title = page_name.substr(0,page_name.indexOf('('));
													var partial_title_trace = [];

													//gets all of the trace to the partial_title
													var ul = $('.leftnavtext_D').last().closest('ul');

													while(ul.parent().is('li')){
														var text = ul.parent().find('span').first().text();
														ul = ul.parent().closest('ul');

														partial_title_trace.unshift(text);
													}

													var build_settings = {'partial_title':partial_title,'partial_title_trace':partial_title_trace};
													build_vital_config_object("Configuration",$('.leftnavtext_D').last().closest('li').attr('page_href'),build_settings);
												}
										}
										$("#contentcontents").unmask("Saving parameters, please wait...");
									}else {
										if (req_counter >= 15) {
											clearInterval(save_interval);
											$('.message_container span').html("").removeClass("success_message").removeClass("warning_message").addClass("error_message").html('Save request timeout').show();
											if($('.hd_linker_message').length > 0){
							                    $('.hd_linker_message').html("").removeClass("success_message").removeClass("warning_message").addClass("error_message").html('Save request timeout').show();
							                }
											$("#contentcontents").unmask("Saving parameters, please wait...");

											if(typeof callback === 'function'){
		                                    	callback('Save request timeout');
		                                    }
										}
									}
								}
								if (req_counter >= 14) {
									delete_request = true;
								}
								request_in_process = false;
							}
						});
					}
				}, 2000);	
			}
		}
	});
}

$.each(["input","select"], function(index, value) {
	$(value).w_change(function(){
		val_change = true;
		$('.v_save').removeClass("disabled");
		add_v_preload_page();	
	});
});

/**********************************************************************
 validation
**********************************************************************/
//allows number only
$('input').w_keydown(function(event){
	var object = $(this);
	if(object.hasClass('numeric_only')){
		validate_integer(event, false);
	}else if (object.hasClass('float_single_digit')){
		validate_integer(event, true);
	}
});

$('input').w_keyup(function(event){
	$('.v_save').removeClass("disabled");
	val_change = true;
	add_v_preload_page();
	var object = $(this);

	object.closest('.v_row').find('.v_error').html('');		//clear the error for this input

	var type = object.attr('param_type');
	var id = object.attr('id').split('_')[1];
	var val = object.val();
	var error = '';
	var min = 0;
	var max = 0; 
		
	if(type == 'string'){
		min = parseInt(object.attr('min'));
		max = parseInt(object.attr('max'));
		
		if(!(min <= val.length && val.length <= max)){
			error = 'Length should be in the range of ('+min+' to '+max+')';
		}
	}else if(type == 'int'){
		min = parseInt(object.attr('min'));
		max = parseInt(object.attr('max'));
		var base = 10; 

		if((val.toString().match(/^[-]?[0-9]+$/g) == null) || ((parseInt(min,base) > parseInt(val,base) ) || (parseInt(max,base) < parseInt(val,base))) ) {
			error = 'Should be in the numeric Range of ('+min +' to '+ max+' )';
		}
	}else if(type =='float_single_digit'){
		min = object.attr('min');
		max = object.attr('max');
		var res_1 = (/^(([0-9]*)|([0-9]*.))([0-9]{1})?$/i).test(val.toString());				//To check it as valid decimal number
		var res_2 = (/^(([0-9]*)|([0-9]*.))([0-9]{1})?$/i).test(parseFloat(val).toString());	//Perform check after removing trailing Zeros
		if(!res_1 || val.toString() == ''){
			if (res_2){
				if(val.indexOf(".") != val.lastIndexOf(".")){
					error = 'Should be in the numeric/decimal range of (' + min + ' to ' + max + ' ) with valid one decimal only.';	
				}				
			}
			else{
				error = 'Should be in the numeric/decimal range of (' + min + ' to ' + max + ' ) with valid one decimal only.';	
			}
		}
		if((parseFloat(min) > parseFloat(val)) || (parseFloat(max) < parseFloat(val))){
			error = 'Should be in the numeric/decimal range of ('+min+' to '+max+') with valid one decimal only.';
		}
	}else if(type == 'atcs_sin'){
		error = sin_validation(val);
		if (error.length == 0){			
			update_offset_values(val,$("#hd_actual_sin").val(), "",".numeric_only");
		}
	}
	object.closest('.v_row').find('.v_error').html(error);
});


/**********************************************************************
 refresh
**********************************************************************/
$('.v_refresh').w_click(function(){
	if($(this).hasClass("disabled"))
		return;
	var page_name = $("#page_name").val();
	var menu_link = $("#menu_link").val();
	var setup_wizard = $("#setup_wizard").val();
	$("#contentcontents").mask("Loading parameters, please wait...");
	$.post("/programming/page_parameters",{
        page_name: $("#page_name").val(), 
		menu_link: $("#menu_link").val(),
		setup_wizard :setup_wizard
    },function(response){
		if (typeof response == 'string') {
			$('#contentcontents').html(response);
			$("#contentcontents").unmask("Saving parameters, please wait...");
			remove_v_preload_page();
		}
		else {
			if (page_name.indexOf("TEMPLATE")!= -1 || menu_link.indexOf("TEMPLATE") != -1) {
				$('.programming_parameters_template').html('<div class="site_content">' + response.html_content + '</div>');
				$('.v_config_wrapper').custom_scroll(450);
			}else {
				$('#contentcontents').html('<div class="content_wrapper">' + response.html_content + '</div>');
			}
			if (response.screen_verification == true) {
				if (response.screen_verification != undefined && (($('#parameter_count').length <= 0 || $('#parameter_count').val() == "0") || ($('#parameters_missing').length > 0 && $('#parameters_missing').val() != "0"))) 
					$("#contentcontents").unmask("Loading contents, please wait...");
				else 
					$("#contentcontents").mask("Processing screen verification, please wait...");
			}else {
				$("#contentcontents").unmask("Loading contents, please wait...");
			}
			remove_v_preload_page();
		}
    });
});

/**********************************************************************
 Force Update
**********************************************************************/
$('.v_force_update').w_click(function(){
	if($(this).hasClass("disabled"))
		return;
	var mask_message = "Updating parameters, please wait...";
	var atcs_address = $("#atcs_address").val();
	var card_index = $("#card_index").val();
	$("#contentcontents").mask(mask_message);
	$.post("/io_status_view/initiate_io_card_req", {
		view_type: "io",
		atcs_address: atcs_address,
		card_ind: card_index,
		information_type: 2,
		force_update_request: true
	}, function(resp){
			if (resp.error) {
				$('.message_container span').html("").removeClass("success_message").removeClass("warning_message").addClass("error_message").html("Update request failed").show();
				$("#contentcontents").unmask(mask_message);
			}
			else{
				check_io_status(resp.request_id,atcs_address, "io", false, mask_message);
			}			
	});
});

function check_io_status(request_id, atcs_address, view_type, render_io, mask_message){		
	var req_counter = 0;
	var request_in_process = false;
	if (io_request_interval != null) {
		clearInterval(io_request_interval);
	}
	io_request_interval = setInterval(function(){
		// ajax off to check io request state
		if (!request_in_process) {
			request_in_process = true;
			$.post("/io_status_view/check_state", {
				id: request_id,
				force_update_request: true
			}, function(resp){
				req_counter += 1;
				if (resp.error) {
					clearInterval(io_request_interval);
					$('.message_container span').html("").removeClass("success_message").removeClass("warning_message").addClass("error_message").html("Update request failed").show();
					$("#contentcontents").unmask(mask_message);
				}
				else {
					if (resp.request_state == 2) {
						clearInterval(io_request_interval);
						$.post("/programming/page_parameters", {
							page_name: $("#page_name").val(),
							menu_link: $("#menu_link").val()
						}, function(response){
							$('#contentcontents').html('<div class="content_wrapper">' + response.html_content + '</div>');
							if (response.screen_verification == true) {
								if (response.screen_verification != undefined && (($('#parameter_count').length <= 0 || $('#parameter_count').val() == "0") || ($('#parameters_missing').length > 0 && $('#parameters_missing').val() != "0"))) 
									$("#contentcontents").unmask("Loading contents, please wait...");
								else 
									$("#contentcontents").mask("Processing screen verification, please wait...");
							}
							else {
								$("#contentcontents").unmask("Loading contents, please wait...");
							}
							remove_v_preload_page();
						});
					}
					else {
						if (req_counter >= 15) {
							clearInterval(io_request_interval);
							$('.message_container span').html("").removeClass("success_message").removeClass("warning_message").addClass("error_message").html("Update request timeout").show();
							$("#contentcontents").unmask(mask_message);
						}
					}
				}
				request_in_process = false;
			});
		}
	}, 3000);
}

$('.unlock').unlock('.message_container',function(unlock_resp){
	if(unlock_resp){
		reload_page({"unlock":"true"});
	}else{
		//do nothing because still locked
	}
});
/**********************************************************************
 screen verification request
**********************************************************************/

function screen_verification_request(){
    var save_obj = {};	//creates json object
	var inputs = $(this).closest('#contentcontents').find('input,select');
	//indexes through all inputs
	inputs.each(function(){
		var key = $(this).attr('id');
		var val = $(this).val();
		//stores the key and val in the array
		save_obj[key] = val;
	});
	save_obj["page_name"] = $("#page_name").val();
	save_obj["menu_link"] = $("#menu_link").val();
    $.post('/programming/verify_screen', save_obj, function(resp){
        if(resp.error){
			$('.message_container span').html("").removeClass("success_message").removeClass("warning_message").addClass("error_message").html(resp.message).show();
			$("#contentcontents").unmask("Processing screen verification, please wait...");
		}else{
			check_screen_verification_state(resp.request_id,"");
		}
	});
}

/**********************************************************************
 checking screen verification request state
**********************************************************************/
function check_screen_verification_state(request_id, msg){
	var req_counter = 0;
	var request_in_process = false;
	var delete_request = false;
	if(screen_verification_interval != null)
		clearInterval(screen_verification_interval);
	screen_verification_interval = setInterval(function(){
		if (!request_in_process) {
			request_in_process = true;
			$.post('/programming/screen_verification_req_state', {
				request_id: request_id,
				delete_request: delete_request
			}, function(screen_verify_resp){
				req_counter += 1;
				if (screen_verify_resp.error && (!screen_verify_resp.request_state || screen_verify_resp.request_state != "2")) {
					clearInterval(screen_verification_interval);
					$('.message_container span').html("").removeClass("success_message").removeClass("warning_message").addClass("error_message").html(msg + screen_verify_resp.message + "To resolve this issue click on fix button.").show();
					$('.message_container div').html("<img src='/images/fix.png' alt='Update parameters'>").show();
					$('.v_force_update').show();
					$("#contentcontents").unmask("Processing screen verification request, please wait...");
				} else {
					if (screen_verify_resp.request_state == "2") {
						if (screen_verify_resp.error) {
							$('.message_container span').html("").removeClass("success_message").removeClass("warning_message").addClass("error_message");
							$('.message_container span').html(msg + 'Screen Verification Failed. To resolve this issue click on fix button.').show();
							$('.message_container div').html("<img src='/images/fix.png' alt='Update parameters'>").show();
							$('.v_force_update').show();
						}
						else {
							$('.message_container span').html("").removeClass("success_message").removeClass("error_message").removeClass("warning_message").html("").show();
						}
						clearInterval(screen_verification_interval);
						$("#contentcontents").unmask("Processing screen verification request, please wait...");
					}else {
						if (req_counter >= 15) {
							clearInterval(screen_verification_interval);
							$('.message_container span').html("").removeClass("success_message").removeClass("warning_message").addClass("error_message").html(msg + 'Screen verification request timeout').show();
							//$('.v_force_update').show();  //removeClass("disabled");
							$("#contentcontents").unmask("Processing screen verification request, please wait...");
						}
					}
				}
				if (req_counter >= 14) {
					delete_request = true;
				}
				request_in_process = false;
			});
		}
	}, 2000);	
}
$('.reset_vlp').w_click(function(){
	ConfirmDialog('Vital Config','Are you sure you want to reset the vlp?',function(){
		$(".message").html('<div class="">Getting acts address..</div>');
		$.post("/application/get_atcs_address", {
			//no params
		},function(atcs_resp){
			if(atcs_resp != ''){
				$('.ajax-loader').show();
			    $(".message").html('<div class="">Module is resetting, please wait...</div>');
			    $.post("/io_status_view/module_reset", {
			        slot_number: 1,
			        atcs_addr: atcs_resp
			    }, function(data){
			        $('.ajax-loader').hide();
			        $(".message").html("");
			    });
			}
		});
	},function(){
		//do nothing
	});
});


$("#MTFIndex").w_change(function(){
    var mtf_index = $(this).val();
    request_template_details(mtf_index);
});

function request_template_details(mtf_index){
    $.ajax({
        url: '/programming/load_template_details',
        type: 'POST',
        data: {mtf_index: mtf_index},
        success: function(response){
            $("#template_details").html(response)
        }
    });
}
