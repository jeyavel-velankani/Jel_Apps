/*
####################################################################
# Company: Siemens 
# Author: Ashwin
# File: ucn.js
# Description: This js is used for UCN page
####################################################################
*/
var ucn_check_state_interval;
var reset_vlp_check_state_interval;
var ucn_check_state_xhr = null;
var ucn_reset_vlp_xhr = null;

$(document).ready(function(){
	add_to_destroy(function(){
		$(document).bind("ready",function(){});
		
		//kills all wrapper events
		$('.set_ucn').w_die('submit');
		$('.unlock').w_die('click');
		$('.v_save').w_die('click');
		$('.reset_vlp').w_die('click');
		$('#ucn_ucn').w_die('keyup');
		$('#ucn_ucn').w_die('change');
		
		//clear intervals
		clearInterval(ucn_check_state_interval);
		clearInterval(reset_vlp_check_state_interval);

		if(typeof ucn_check_state_xhr !== 'undefined' && ucn_check_state_xhr != null){
			ucn_check_state_xhr.abort();
		}
		if(typeof ucn_reset_vlp_xhr !== 'undefined' && ucn_reset_vlp_xhr != null){
			ucn_reset_vlp_xhr.abort();
		}		

		//clear functions 
		delete window.ucn_validation;		

		//clears global variables
		delete window.ucn_check_state_interval;
		delete window.reset_vlp_check_state_interval;
		delete window.ucn_check_state_xhr;
		delete window.ucn_reset_vlp_xhr;
	});
	
	var unlock_param = $('.user_presence').val();
	if(unlock_param == 'false'){
		$("#ucn_ucn").attr('disabled','disabled');
		$("#ptc_ucn_ptc_ucn").attr('disabled','disabled');
		$(".reset_vlp").addClass('disabled');
		$(".v_save").addClass('disabled');
	}
		
	$('.ajax-loader').hide();
	
	$('#ucn_ucn').w_change(function(){
		val_change = true;
		add_v_preload_page();
		$('.ajax-loader').hide();	
	});
	
	$('.v_save').w_click(function(){
		if (!($(this).hasClass('disabled'))) {
			$('.set_ucn').submit();
		}
	});
	
	$('.set_ucn').submit(function(){
	  	if ($('.v_error').html() == '') 
		{
			$("#contentcontents").mask("Saving UCN parameters., please wait..."); 	
			var form_url = $(this).attr('action');
			var atcs_addr = $('#atcs_addr').val();
			var ucn = $('#ucn_ucn').val();
			var ptc_ucn = $('#ptc_ucn_ptc_ucn').val();
			var ucn_req_check_process = false;
			var ucn_request_count = 0;
			if((8 - ucn.length) != 0)
			{
				var rem_len = 8 - ucn.length;
				for(var i = 0; i < rem_len; i++)
				{
					ucn = "0" + ucn;
				}
				$('#ucn_ucn').val(ucn);
			}

			if(typeof ptc_ucn !== 'undefined'){
				if((8 - ptc_ucn.length) != 0){
					var rem_len = 8 - ptc_ucn.length;
					for(var i = 0; i < rem_len; i++)
					{
						ptc_ucn = "0" + ptc_ucn;
					}
					$('#ptc_ucn_ptc_ucn').val(ptc_ucn);
				}
			}

			$.post(form_url,{
				atcs_addr: atcs_addr, 
				ucn: ucn
			},function(res){
				var delete_request = false;
				ucn_check_state_interval = setInterval(function(){
					if (!ucn_req_check_process) {
						ucn_req_check_process = true;
						if(usb_enabled_flag){
							var check_url = '/ucn/check_simple_request_state/';
						}else{
							var check_url = '/ucn/check_state/';
						}	

						ucn_check_state_xhr = $.post(check_url, {
							id: res.request_id, 
							delete_request: delete_request
						}, function(response){
						   	ucn_request_count += 1
							if (response.request_state == "2"){
								$("#contentcontents").unmask();
								clearTimeout(ucn_check_state_interval);
								if(response.saved){
									if(typeof ptc_ucn !== 'undefined'){
										$.post('/ucn/set_ptc_ucn/',{
											atcs_addr: atcs_addr, 
											ptc_ucn: ptc_ucn
										},function(res){
											ucn_check_state_interval = setInterval(function(){

												ucn_check_state_xhr = $.post('/ucn/check_simple_request_state', {
													id: res.request_id, 
													delete_request: delete_request
												}, function(response){
												   	ucn_request_count += 1
													if (response.request_state == "2"){
														$("#contentcontents").unmask();
														clearTimeout(ucn_check_state_interval);
														if(response.saved){
															$('.message_container span').html("").removeClass("warning_message").removeClass("error_message").addClass("success_message").html(response.message).show();
															remove_v_preload_page();
														}else{
															$('.message_container span').html("").removeClass("success_message").removeClass("warning_message").addClass("error_message").html(response.message).show();
														}
													}else {
														if (ucn_request_count >= 6) {
															clearInterval(ucn_check_state_interval);
															$('.message_container span').html("").removeClass("success_message").removeClass("warning_message").addClass("error_message").html('Request Timed Out').show();
															$("#contentcontents").unmask();
														}
													}
													if (ucn_request_count >= 5) {
														delete_request = true;
													}
													ucn_req_check_process = false;
												});
											},2000);
										});
									}else{
										$('.message_container span').html("").removeClass("warning_message").removeClass("error_message").addClass("success_message").html(response.message).show();
										remove_v_preload_page();
									}		
								}else{
									$('.message_container span').html("").removeClass("success_message").removeClass("warning_message").addClass("error_message").html(response.message).show();
								}
							}else {
								if (ucn_request_count >= 6) {
									clearInterval(ucn_check_state_interval);
									$('.message_container span').html("").removeClass("success_message").removeClass("warning_message").addClass("error_message").html('Request Timed Out').show();
									$("#contentcontents").unmask();
								}
							}
							if (ucn_request_count >= 5) {
								delete_request = true;
							}
							ucn_req_check_process = false;
						});
					}
				}, 2000);
			});
		}		
        return false;
    });	
  
	$('.reset_vlp').w_click(function(){
		if(!($(this).hasClass('disabled')))
		{
			var request_progress = false;
			var delete_request = false;
			var req_counter = 0;
			var msg = "Are you sure you want to Reset VLP ?";
			if(confirm(msg) == false) {
				return false;
			}else{
				$("#contentcontents").mask("Vital CPU Rebooting, Please wait");
				$.post("/ucn/reset_vlp", {}, function(data){
					reset_vlp_check_state_interval = setInterval(function(){
						if(!request_progress){
							request_progress = true;
							ucn_reset_vlp_xhr = $.post("/ucn/check_reset_vlp_state", {request_id: data.request_id, delete_request: delete_request}, function(data){
						        if (req_counter == 15) {
									clearInterval(reset_vlp_check_state_interval);
									$('.message_container span').html("").removeClass("success_message").removeClass("error_message").addClass("warning_message").html('Request Timed Out').show();
									$("#contentcontents").unmask();
								}
								else {
									req_counter += 1;
									if(data.request_state == 2){
										clearInterval(reset_vlp_check_state_interval);
										if (data.request_state == 2 && data.result == 0) {
											$("#contentcontents").unmask();
											$('.message_container span').html("").removeClass("error_message").removeClass("warning_message").addClass("success_message").html('Vital CPU Rebooted Successfully').show().fadeOut(6000);
										}
										else {
											$("#contentcontents").unmask();
											$('.message_container span').html("").removeClass("success_message").removeClass("warning_message").addClass("error_message").html('Error while rebooting Vital CPU').show();
										}
									}
								}
								if (req_counter == 14) {
									delete_request = true;
								}
								request_progress = false;					
							});
						}				
					}, 2000);
				});
			}
		}
	});
  
});

$('#ucn_ucn').w_keyup(function () {
    var strVal = $('#ucn_ucn').val().toUpperCase();
	$(this).val(strVal);
	ucn_validation();
});

function ucn_validation(){
	value = $('#ucn_ucn').val();
	if(value.toString().match(/^[0-9A-Fa-f]+$/g) == null)
	{
		$('.v_error').html("Enter Valid Hexadecimal Value");
		$('.v_save').addClass("disabled");
	}
	else{
		$('.v_error').html("");
		$('.v_save').removeClass("disabled");
	}
}

$('.unlock').unlock('.message_container span',function(unlock_resp){
	if(unlock_resp){
		var toolbar_items = $('.toolbar_button ')
		//updates the toolbar to not be locked anymore
		$(toolbar_items).removeClass('disabled');
		$(".unlock").addClass('disabled');
		$("#ucn_ucn").removeAttr('disabled');
		$("#ptc_ucn_ptc_ucn").removeAttr('disabled');
		$('.user_presence').val(true);
		$('.message_container span').html("").removeClass("error_message").removeClass("warning_message").addClass("success_message").html("Successfully unlocked parameters").show().fadeOut(6000);
	}else{
		//do nothing because still locked
	}
});

