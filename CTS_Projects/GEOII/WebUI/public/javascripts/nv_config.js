/****************************************************************************************************************************************
 Company: Siemens 
 Author: Kevin Ponce
 File: nv_config.js
 Requirements: JQuery 1.9.1, jquery_wrapper.js
 Description: Generic nv config javascript file
****************************************************************************************************************************************/
var date_id = 'date';
var hour_id = 'start_time_begin_hour';
var min_id = 'start_time_begin_minute';
var sec_id = 'start_time_begin_second';
var timezone_id = '';
var atcs_id = '';
var date_timezone_changed = false; 
var atcs_changed = false;
var val_change = false;
var save_sin_interval;
var check_rc2_interval; 
var check_rc2_default_interval; 
var check_webserver_interval;
var check_rc2; 
var rc2_key_orginal;
var datetime_changed = false;
var save_flag = false;
var sscc_save_ar = Array();

add_to_destroy(function(){
	$(document).unbind("ready");
	
	//kills all wrapper events
	$('.unlock').w_die('click');
	$('.nv_save').w_die('click');
	$('input').w_die('change');
	$('select').w_die('change');
	$('input').w_die('keyup');
	$('.nv_refresh').w_die('click');	
	$('.nv_default').w_die('click');
	$('.subgroup_anchor').w_die('change');
	$('.nv_arrow').w_die('click');
	$('.nv_io_assignment_arrow').w_die('click');
	$('.nv_set_all_default').w_die('click');
	$('.nv_set_all_sear_default').w_die('click');
	$('.rc2_key').w_die('change');
	$('.site_info_time ').w_die('change');
	$('#date').w_die('change');
	$('.page_anchor ').w_die('click');
	$('.template_select').w_die('change');

	
	//clear intervals
	if(typeof save_sin_interval !== 'undefined' && save_sin_interval != null){
	       clearInterval(save_sin_interval);
	}	
	if(typeof check_rc2_interval !== 'undefined' && check_rc2_interval != null){
	       clearInterval(check_rc2_interval);
	}
	if(typeof check_rc2_default_interval !== 'undefined' && check_rc2_default_interval != null){
	       clearInterval(check_rc2_default_interval);
	}
	if(typeof check_webserver_interval !== 'undefined' && check_webserver_interval != null){
	       clearInterval(check_webserver_interval);
	}		

	//clear functions 
	delete window.m_n_validate;
	delete window.ip_validate;
	delete window.set_to_default;
	delete window.nv_save_object;
	delete window.add_cal_event;
	delete window.get_id_from_nv_title;
	delete window.not_key;
	delete window.nv_save;
	delete window.finish_save;
	delete window.load_subgroup;
	delete window.sscc_document_ready;
	delete window.get_sscc;
	delete window.update_sscc_height;
	delete window.inArray;
	delete window.build_sscc_save_obj;

	//clears global variables
	delete window.date_id;
	delete window.hour_id;
	delete window.min_id;
	delete window.sec_id;
	delete window.timezone_id;
	delete window.atcs_id;
	delete window.date_timezone_changed;
	delete window.atcs_changed;
	delete window.val_change;
	delete window.save_sin_interval;
	delete window.check_rc2_interval;
	delete window.check_rc2_default_interval;
	delete window.check_webserver_interval;
	delete window.check_rc2;
	delete window.rc2_key_orginal;
	delete window.datetime_changed;
	delete window.sscc_save_ar;

	//removes and kills the functionality of the scroll bar
	$('.nv_config_wrapper').remove_custom_scroll();
});

$(document).bind("ready",function(){
		add_cal_event();


	timezone_id = get_id_from_nv_title('Time Zone');	//for site config

	if(timezone_id != ''){
		$('#'+timezone_id).w_change(function(){
			date_timezone_changed = true;
		});
	}

	if(typeof nv_page_type === 'undefined' || (typeof nv_page_type !== 'undefined' && nv_page_type != 'table')){
		atcs_id = get_id_from_nv_title('ATCS Address');
		if(atcs_id != ''){
			$('#'+atcs_id).w_change(function(){
				atcs_changed = true;
			});
		}
		else{
			atcs_id = get_id_from_nv_title('ATCS - Railroad');
		}
	}

	if(typeof action_name != 'undefined' && action_name == 'digital_inputs'){
		set_content_deminsions(960,500);
	}else{
		set_content_deminsions(914,500);	
	}
	
	if($('.subgroup_anchor').closest('.nv_config_channels_right_wrapper').length != 0){
		$('.nv_config_channels_content_wrapper').custom_scroll(435);
	}else{
		$('.nv_config_wrapper').custom_scroll(435);
	}

	$('#'+get_id_from_nv_title('Site Name')).addClass('site_config');

	if(typeof $('.rc2_key').eq(0).val() !== 'undefined'){
		rc2_key_orginal = $('.rc2_key').eq(0).val();
	}

	var ucn_protected = false;
	var inputs = $('#contentcontents').find('input,select');
		
	//indexs through all inputs
	inputs.each(function(){
		
		if(typeof $(this).attr('ucn_protected') !== 'undefined' && parseInt($(this).attr('ucn_protected')) != 0){
			ucn_protected = true;
		}
	});

	if(!ucn_protected){
		$('.unlock ').remove();
	}
	sscc_document_ready();
});

$('.unlock').unlock('.nv_config_message',function(unlock_resp){
	if(unlock_resp){
		var toolbar_items = $('.toolbar_button ');
		
		//updates the toolbar to not be locked anymore
		$(toolbar_items).removeClass('disabled');
		$(toolbar_items[0]).addClass('disabled');

		//only remove disable and readonly if it is not locked
		$('.contentcontents').find('select, input').each(function(){
			if(!$(this).hasClass('locked')){
				$(this).removeClass('disable').removeClass('readonly').removeAttr('disabled');
			}
		});
	}else{
		//do nothing because still locked
	}
});

$('.nv_save').w_click(function(){
	save_flag = true;
	var t = $(this);
	$('.nv_error').each(function(){
		if($(this).html() != ''){
			save_flag = false;
		}
	});

	if(save_flag){
		if($('.time_source').length > 0 && $('.time_source').val() != 'None' && ptc_enabled_flag && datetime_changed){
			ConfirmDialog('Nv Config','Time source is set to '+$('.time_source').val()+'.<br>Your changes might be overwritten?',function(){
				nv_save(t);
			},function(){
				$('.ajax-loader').hide();
			});
		}else{
			var element =  document.getElementById('enum_62');
			if (typeof(element) != 'undefined' && element != null)
			{
				if(!confirm("This change will restart the server.\nDo you want to continue?"))
				{
					return false;
				}		
			}
			nv_save(t);
		}
	}
});

function nv_save(t){
	var nv_id = get_id_from_nv_title('ATCS Address');
	if( $('#'+ nv_id).length  > 0  && typeof $('#'+ nv_id).attr('disabled') === 'undefined' && (typeof OCE_MODE !== 'undefined' && !OCE_MODE)){
		save_atcs(nv_id, $('#'+ nv_id).val());
	}else{
		$('.ajax-loader').show();		
		$('.nv_error').html(''); //clears the errors
		var save_obj = {}; //creates json object
		var inputs = t.closest('#contentcontents').find('input,select');
		
		//indexs through all inputs
		inputs.each(function(){
			var key = $(this).attr('id');
			var val = $(this).val();
			
			if (key != null && !isNaN(parseInt(key.split('_')[1])) && typeof $(this).attr('disabled') === "undefined"){
				//stores the key and val in the array
				save_obj[key] = val;
			}
		});

		//default data
		if(parseInt($('input[name=default]').val()) == 1){
			save_obj['default'] = 1;
			save_obj['group_id'] = $('input[name=group_id]').val();
			save_obj['group_ch'] = $('input[name=group_ch]').val();
			$('input[name=default]').val(0);
		}

		var save_obj_count = 0;
		$.each(save_obj, function(key, val) {
		    save_obj_count++;
		});
		
		if(save_obj_count > 0){
			if ($('#' + date_id).length > 0 && $('#' + hour_id).length > 0 && $('#' + min_id).length > 0 && $('#' + sec_id).length > 0) {
				save_obj['date'] = $('#' + date_id).val();
				save_obj['hour'] = $('#' + hour_id).val();
				save_obj['min'] = $('#' + min_id).val();
				save_obj['sec'] = $('#' + sec_id).val();
			}

			if (timezone_id != '' && $('#' + timezone_id ) != null && date_timezone_changed && !oce_enable()){
				//time zone was saved
				ConfirmDialog('NV Convig', 'Apache has to restart for time to change.<br><br>The application may be down for a couple minutes.', function(){
					nv_save_object(save_obj)
				},function(){
					$('.ajax-loader').hide();
				});
			}else{
				nv_save_object(save_obj);
			}
		}
	}
}

$('.atcs_only_save').w_click(function(){
	var t = $(this);
	var save_atcs_address = true;
	$('.nv_error').each(function(){
		if($(this).html()!=''){
			save_atcs_address = false;
		}
	});

	var nv_id = get_id_from_nv_title('ATCS Address');
	if(save_atcs_address && typeof $('#'+ nv_id) !== 'undefined' && typeof $('#'+ nv_id).attr('disabled') === 'undefined'){
		save_atcs(nv_id, $('#'+ nv_id).val());		
	}
});

function nv_save_object(save_obj){
	var bReload = false;
	save_obj = build_sscc_save_obj(save_obj)
	// ajax off to save nv config parameters
	$.post('/nv_config/save',save_obj,function(nv_save_resp){
		if(nv_save_resp.split(',').length  > 1 || nv_save_resp.split('=>').length > 1){
			$('.nv_config_message').html('');
			var messages = nv_save_resp.split(',');
			for(var i = 0; i < messages.length; i++){
				var id = messages[i].split('=>')[0];
				var message = messages[i].split('=>')[1];

				$('#'+id).closest('.nv_row').find('.nv_error').html(message);
			}
		}else{
			if($('.rc2_key').length > 0){
				var val_1 = $('.rc2_key').eq(0).val();
				var val_2 = $('.rc2_key').eq(1).val();

				if(val_1 == val_2){
					$('.rc2_key').closest('.nv_row').find('.nv_error').html('');
					var def_flg = $("#default_flag").val();
					if(def_flg == 'true' || rc2_key_orginal != val_2 || rc2_key_orginal.length==0){
						ConfirmDialog('Nv Config','Did you want to save RC2 Key?',function(){
							$.post('/nv_config/save_rc2_key/',{
								val		:val_1
							},function(rc2_key_resp){
								check_rc2_interval = setInterval(function(){
									$.post('/nv_config/check_rc2_key/',{
										request_id:rc2_key_resp
									},function(check_rc2_resp){

										if(parseInt(check_rc2_resp.request_state) == 2){
											clearInterval(check_rc2_interval);

											$.post('/nv_config/get_rc2key_status/',{
												//no params
											},function(rc2key_status){
												$('.nv_config_message').success_message('Saved Successfully...');
												$('.rc2_key').eq(0).closest('.nv_row').find('.nv_rc2keycrc').html(rc2key_status);
												val_change = false;
												preload_page = '';
												date_timezone_changed = false;
												datetime_changed = false;
												rc2_key_orginal = $('.rc2_key').eq(0).val();
                                                bReload = true;  
											});											
										}
									},'json');

								},1000);
							});
						},function(){
							$('.nv_config_message').error_message('Save R2C Key canceled...');
							
							val_change = false;
							preload_page = '';

							if(atcs_id != ''){
								rebuild_site_info();
							}
						});
					}else{
						finish_save();
					}
				}else{
					$('.rc2_key').eq(0).closest('.nv_row').find('.nv_error').html('Keys do not match.');
				}
				$('.ajax-loader').hide();
			}else{
				var element =  document.getElementById('enum_62');
				if (typeof(element) != 'undefined' && element != null)
				{
					var webserver_val_org = $('#enum_62').val();
					var webserver_val = 0;
					if(webserver_val_org == '191' || webserver_val_org == 191 ){
						webserver_val = 1;
					}
					
				  	$.post('/nv_config/set_web_server/',{
						webserver_val : webserver_val
					},function(webserver_resp){
					    if (webserver_resp.request_id == "-1") {
							$('.ajax-loader').hide();
							$('.nv_config_message').error_message("Unable to change the Browser Access. Please try again after some time.").show();
							if(webserver_val_org == 191 || webserver_val_org == '191'){
								$("#enum_62").val(192);	
							}else{
								$("#enum_62").val(191);
							}
							setTimeout("$('.nv_config_message').hide();", 5000);							
						}else {
						    var webserver_check_state_process = false;
							check_webserver_interval = setInterval(function(){
								if(!webserver_check_state_process){
									webserver_check_state_process = true;
									
									var xhr = $.ajax({
										type: "post",
										url: "/nv_config/web_server_req_state",
										data_type: "json",
										data: {
											request_id:webserver_resp.request_id
										},
										success: function(response, textStatus, jqXHR){
											if (jqXHR.status == null || jqXHR.status == 0 ) {
												$('.nv_config_message').success_message("Server Configuration changed. Restarting web server...");
												change_protocol(webserver_val_org);
											}
											else {
												if (response.request_state == "2") {
													clearInterval(check_webserver_interval);
													$('.ajax-loader').hide();
													if (response.result == -1) {
														$('.nv_config_message').error_message("Unable to change the Browser Access. Please try again after some time.").show();
														if(webserver_val_org == 191 || webserver_val_org == '191'){
															$("#enum_62").val(192);	
														}else{
															$("#enum_62").val(191);
														}
														setTimeout("$('.nv_config_message').hide();", 5000);
													}else {
														if (response.result == 1) {
															$('.nv_config_message').error_message("Unable to change the Browser Access. Please try again after some time.").show();
															setTimeout("$('.nv_config_message').hide();", 5000);
														}
														else {
															$('.nv_config_message').success_message("Server Configuration changed. Restarting web server...");
															change_protocol(webserver_val_org);
														}
													}
												}
												webserver_check_state_process = false;
											}
										},
										failure: function(response, textStatus, jqXHR){
											$('.nv_config_message').success_message("Server Configuration changed. Restarting web server...");
											change_protocol(webserver_val_org);
										},
										error: function(response, textStatus, jqXHR){
											$('.nv_config_message').success_message("Server Configuration changed. Restarting web server...");
											change_protocol(webserver_val_org);
										}
									})
								}
							},2000);
						}
					});
				}else{
				  finish_save();
				  $('.ajax-loader').hide();	
				}
			}
		}
        
		//checks if there is a table to update
		if($('.nv_config_channels_wrapper').length > 0){
			var current_page = 1; 
			var io_assignment = ($('.template_select').length>0);

			if($('.pagination .current').length > 0){
				current_page = parseInt($('.pagination .current').html()); 
			}

			if(!isNaN(current_page) && nv_group_id != 'array'){
				$('.nv_name.selected_row').html($('#'+get_id_from_nv_title('Name')).val());
			}
		}

		if (bReload){
			bReload = false;
			load_page("Emp", get_current_url()); // Reload the page - to get the updated Rc2key.bin encrypted value
		}
		
	});
}

function change_protocol(value){
	if(value == 191 )
	{
		var restOfUrl = window.parent.location.href.substr(5);
		window.parent.location = "https:" + restOfUrl;
	}else{
		var restOfUrl = window.parent.location.href.substr(6);
		window.parent.location = "http:" + restOfUrl;
	}
}

function finish_save(){
	if (timezone_id != '' && $('#' + timezone_id != null) && date_timezone_changed && !oce_enable()){
		$('.nv_config_message').success_message('Saved Successfully. Web Server will restart to load the new timezone. WebUI will disconnect. Please wait for 3 minutes.');
		setTimeout("window.location = '/access/logout'", 5000);
	}else{
		$('.nv_config_message').success_message('Saved Successfully...');
	}
	
	val_change = false;
	preload_page = '';

	date_timezone_changed = false;
	datetime_changed = false;

	if(atcs_id != ''){
		rebuild_site_info();
	}
}

function save_atcs(atcs_id, atcs_val){	
	// ajax off to save ATCS SIN
	$("#contentcontents").mask("Saving parameters, please wait...");
	$.post('/programming/save_atcs_sin', {atcs_id:atcs_id, atcs_address: atcs_val},function(sin_save_resp){
		if(sin_save_resp.error){
			$('.nv_config_message').error_message(sin_save_resp.message);
			$("#contentcontents").unmask("Saving ATCS SIN, please wait...");
		}else{
			var req_counter = 0;
			var request_in_process = false;
			var delete_request = false;
			if(save_sin_interval != null)
				clearInterval(save_sin_interval);
			var new_sin_value = sin_save_resp.new_sin_value;
			var sin_id = sin_save_resp.sin_id;	
			save_sin_interval = setInterval(function(){
				// ajax off to check save request state
				if (!request_in_process) {
					request_in_process = true;
					$.post('/programming/check_save_atcs_sin_req', {
						request_id: sin_save_resp.request_id,
						new_sin_value: new_sin_value,
						sin_id: sin_id,
						delete_request: delete_request
					}, function(save_resp){
						req_counter += 1;
						if (save_resp.error && (!save_resp.request_state || save_resp.request_state != "2")) {
							clearInterval(save_sin_interval);
							$('.nv_config_message').error_message(save_resp.message);
							$("#contentcontents").unmask("Saving ATCS SIN, please wait...");
						} else {
							if (save_resp.request_state == "2") {
								clearInterval(save_sin_interval);
								if (save_resp.error) {
									$('.nv_config_message').error_message(save_resp.message);
								} else {
									if(save_resp.confirmed == "400"){
										$('.nv_config_message').error_message(save_resp.message);

									} else {
										clearInterval(save_sin_interval);
										reset_logout_session();

										if ($('#atcs_address_hdr').length > 0) {
											$('#atcs_address_hdr').html(new_sin_value);
										}

										if(atcs_sin_only){
											$('.nv_config_message').success_message(save_resp.message);
											
											if (save_resp.html.length > 0){
												window.parent.document.getElementById("mainheader").innerHTML = "";
												window.parent.document.getElementById("mainheader").innerHTML = save_resp.html;
											}
											preload_page = '';
											reload_page();
										}else{

											$('.nv_error').html(''); //clears the errors
											var save_obj = {}; //creates json object
											var inputs = $('#contentcontents').find('input,select');
											
											//indexs through all inputs
											inputs.each(function(){
												var key = $(this).attr('id');
												var val = $(this).val();
												
												if (key != null && !isNaN(parseInt(key.split('_')[1])) && typeof $(this).attr('disabled') === "undefined"){
													//stores the key and val in the array
													save_obj[key] = val;
												}
											});
											
											var save_obj_count = 0;
											$.each(save_obj, function(key, val) {
											    save_obj_count++;
											});
											
											if(save_obj_count > 0){
												if (timezone_id != '' && $('#' + timezone_id != null) && date_timezone_changed && !oce_enable()){
													//time zone was saved
													ConfirmDialog('NV Config', 'Apache has to restart for time to change.<br><br>The application may be down for a couple minutes.', function(){
														nv_save_object(save_obj)
													},function(){
														$('.ajax-loader').hide();
													});
												}else{
													if ($('#' + date_id) != null && $('#' + hour_id) != null && $('#' + min_id) != null && $('#' + sec_id) != null) {
														save_obj['date'] = $('#' + date_id).val();
														save_obj['hour'] = $('#' + hour_id).val();
														save_obj['min'] = $('#' + min_id).val();
														save_obj['sec'] = $('#' + sec_id).val();
													}
													
													nv_save_object(save_obj);
												}
											}
										}
									}
									remove_v_preload_page();
								}
								$("#contentcontents").unmask("Saving ATCS SIN, please wait...");
							}else {
								if (req_counter >= 15) {
									clearInterval(save_sin_interval);

									$('.nv_config_message').error_message('Save request timeout');
									$("#contentcontents").unmask("Saving ATCS SIN, please wait...");
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
		
	});
}


$.each(["input","select"], function(index, value){
	$(value).w_change(function(){
		val_change = true;
		preload_page = function(){
			var popup_title; 
			if(atcs_sin_only){
				popup_title = 'Vital Config'; 
			}else{
				popup_title = 'Non-Vital Config'; 
			}
			ConfirmDialog(popup_title,'Changes were not saved.<br>Would you like to discard them?',function(){
				if(typeof item_clicked == 'object'){
					preload_page_finished();		
				}
				preload_page = '';
			},function(){
				$('.ajax-loader').hide();
			});
		};
	});
});

/**********************************************************************
 validation
**********************************************************************/
$('select').w_click(function(event){
	var object = $(this);

	if(object.attr('default_value') == object.val()){
		object.closest('.nv_row').find('.is_default').show();
	}else{
		object.closest('.nv_row').find('.is_default').hide();
	}
});	


function not_key(ar,value){
	var not_in_array_flag = true;
	for(var ar_i = 0; ar_i < ar.length; ar_i++){	
		if($.isNumeric(ar[ar_i])){
			if(parseInt(value) == parseInt(ar[ar_i])){
				not_in_array_flag = false;
			}
		}else{
			var ar_split = ar[ar_i].split('-');
			if(ar_split.length == 2){
				if(parseInt(ar_split[0]) <= parseInt(value) && parseInt(value) <= parseInt(ar_split[1])){
					not_in_array_flag = false;
				}
			}
		}
	}

	return not_in_array_flag;
}

$('input').w_keyup(function(event){
	var object = $(this);
	var error = '';

	object.closest('.nv_row').find('.nv_error').html('');	//clear the error for this input

	if(typeof object.attr('id') !== 'undefined'){
		var type = object.attr('id').split('_')[0];
		var id = object.attr('id').split('_')[1];
		var val = object.val();
		
		if(object.attr('default_value') == object.val()){
			object.closest('.nv_row').find('.is_default').show();
		}else{
			object.closest('.nv_row').find('.is_default').hide();
		}
		
		if(type == 'string'){
			var min = parseInt(object.attr('min'));
			var max = parseInt(object.attr('max'));
			var mask = object.attr('mask');


			if(min <= val.length && val.length <= max){
				if(mask.length > 0){
					if(mask.split(':').length > 0){
						var mask_type = mask.split(':')[0];
						mask = mask.split(':')[1];
						if(object.closest('.nv_row').find('.nv_title').html().indexOf('IP Addr') != -1 && $.trim(mask) != ''){
							error = ip_validate(mask,val);
						}else if(object.closest('.nv_row').find('.nv_title').html().toUpperCase().indexOf('ATCS ADDRESS') != -1){
							error = ATCS_validation(val, mask);
							if ($.trim(error) != ''){
								disable_save = true;
							}							
						}else{
							if(mask_type == 'M' || mask_type == 'N'){
								error = m_n_validate(mask,val);
							}else if(mask_type == 'H' && val.length != 0){	//hex
								//checks if the number is a hex
								if(val.toString().match(/^[0-9A-Fa-f]+$/g) == null){
									error = 'Should be in Hexadecimal format';
								}						
							}else if(mask_type != 'S' && mask_type != 'P' && object.closest('.nv_row').find('.nv_title').html().indexOf('IP Addr') != -1){
								error = m_n_validate(mask,val);
							}
						}
					}
				}
			}else{
				disable_save = true;
				error = 'Length should be in the range of ('+min+' to '+max+')';
			}

			if(object.hasClass('site_config') && (val.toString().match(/^[0-9A-Za-z-_\s]+$/g) == null)){
				error = 'Site name should only contain letters, numbers, "-", and "_".';
			}

			
		}else if(type == 'int'){
			var min = parseInt(object.attr('min'));
			var max = parseInt(object.attr('max'));
			var mask = object.attr('mask');
			var base = 10; 

			//checks if there is a mask
			if(mask.split(':').length > 1){
				var mask_type = $.trim(mask.split(':')[0]);
				mask = mask.split(':')[1];

				if(mask_type == 'H'){	//hex
					min = min.toString(16);
					max = max.toString(16);

					base = 16;

					//checks if the number is a hex
					if(val.toString().match(/^[0-9A-Fa-f]+$/g) == null){
						error = 'Should be in Hexadecimal format';
					}
				}else{
					//checks if the number is a hex
					if(val.toString().match(/^-?[0-9]\d*(\.\d+)?$/g) == null){
						error = 'Should be in the numeric Range of ('+min +' to '+ max+' )';
					}
				}
				
			}
			else{
				//checks if the number is a hex
				if(val.toString().match(/^-?[0-9]\d*(\.\d+)?$/g) == null){
					error = 'Should be in the numeric Range of ('+min +' to '+ max+' )';
				}
			}

			if(error == '' && (val.indexOf('-') > 0 || val.split('-').length > 2)){
				error = 'Invalid number';
			}
			
			if(error == '' && ((parseInt(min,base) > parseInt(val,base) ) || (parseInt(max,base) < parseInt(val,base)))){
				error = 'Should be in the numeric Range of ('+min+' to '+max+')';
			}

			object.closest('.nv_row').find('.nv_error').html(error);
		}else if(type == 'byte'){
			var size = parseInt(object.attr('size'));

			if(error == '' && val.length > size){
				error = 'Should be less than '+size+' characters.';
			}

			if(error == '' && val.toString().match(/^[0-9A-Fa-f]+$/g) == null){
				error = 'Should be in Hexadecimal format';
			}
		} 

		object.closest('.nv_row').find('.nv_error').html(error);
	}else{
		if(object.hasClass('rc2_key')){
			var val = object.val();
			var size = 20;

			var val_1 = $('.rc2_key').eq(0).val();
			var val_2 = $('.rc2_key').eq(1).val();
			var keys_match_error = false;

			if(val_1 != val_2){
				$('.rc2_key').eq(0).closest('.nv_row').find('.nv_error').html('Keys do not match.');
				keys_match_error = true;
			}else{
				$('.rc2_key').closest('.nv_row').find('.nv_error').html('');
			}

			if(!keys_match_error && error == '' && val.length > size){
				error = 'Should be less than '+size+' characters.';
			}

			if(!keys_match_error && error == '' && val.indexOf(' ') != -1){
				error = 'Should not contain to spaces.';
			}

			if(error != ''){
				$('.rc2_key').eq(0).closest('.nv_row').find('.nv_error').html(error);
			}
		}
	}
});

//validates
function m_n_validate(mask,val){
	error = false;

	var m = mask.split('.');
	var v = val.split('.');

	if(m.length == v.length){
		for(var m_index = 0; m_index < m.length; m_index++){

			if(!isNaN(v[m_index])){	
				if(isNaN(m[m_index])){	//mask is ###
					if(0 > v[m_index] || v[m_index].trim()  == '' || v[m_index] > parseInt(m[m_index].replace(/#/gi, '9'))){
						error = true; 
					}
				}else{
					if(parseInt(v[m_index]) != parseInt(m[m_index])){
						error = true; 
					}
				}
			}else{
				error = true; 
			}
		}
	}else{
		error = true; 
	}

	if(error){ 
		return "Should be in the range ('"+mask.replace(/M:/gi, "").replace(/N:/gi, "").replace(/#/gi, '0')+"' - '"+mask.replace(/M:/gi, "").replace(/N:/gi, "").replace(/#/gi, '9')+"')";
	}
	
}

function ip_validate(mask,val){
	error = false;

	var m = mask.split('.');
	var v = val.split('.');

	if(m.length == v.length){
		for(var m_index = 0; m_index < m.length; m_index++){
			if(!isNaN(v[m_index])){
				if(v[m_index].trim() == '' || 0 > v[m_index] || v[m_index] > 255){
					error = true; 
				}
			}else{
				error = true; 
			}
		}
	}else{
		error = true; 
	}

	if(error){ 
		return "Should be in the range of (0.0.0.0 - 255.255.255.255)";
	}
	
}

function ATCS_validation(sin_value, mask) { 
	var len = mask.length;
	var name;

	if (len == 16){
		name = "SIN"
	}
	else {
		name = "ATCS Addr"
	}

	 if(sin_value.length !=  len){
	 	return name + " should have " + len + " characters";
	 }else if(!(/^7/i.test(sin_value))){
	 	 return "SIN should start with 7.";
	 }else if(!(/^[0-9.]*$/i.test(sin_value))){
	 	return name + " should contain only numbers and '.'";
	 }else 
	 if (sin_value.length == 16){
		 if(!(/^7\.(\d{3})\.(\d{3})\.(\d{3})\.(\d{2})$/i.test(sin_value))){
		 	return name + " should be in 7.XXX.XXX.XXX.XX format containing only numbers";
		 }
	}
	else if (sin_value.length == 19){
		 if(!(/^7\.(\d{3})\.(\d{3})\.(\d{3})\.(\d{2})\.(\d{2})$/i.test(sin_value))){
		 	return name + " should be in 7.XXX.XXX.XXX.XX format containing only numbers";
		 }
	}
	 else{
	 	return '';
	 }
}


/**********************************************************************
 refresh
**********************************************************************/
$('.nv_refresh').w_click(function(){
	reload_page();
});

$('.nv_table_refresh').w_click(function(){
	$('.selected_row img').click();
});

/**********************************************************************
 defaults
**********************************************************************/
$('.nv_default').w_click(function(){
	reload_page({default:'true'});
	$('.ajax-loader').show();
});

$('.nv_table_default').w_click(function(){
	var save_params = {};

	var current_page = 1; 
	var io_assignment = ($('.template_select').length>0);
	var io_type = '';

	if($('.pagination .current').length > 0){
		current_page = parseInt($('.pagination .current').html()); 
	}

	if(!isNaN(current_page) && nv_group_id != 'array' && io_assignment){
		var io_type = current_url.split('/')[2];
	}

	save_params["page_number"] = current_page;
	save_params["io_type"] = io_type;


	load_subgroup($('.selected_row img'),'/nv_config/get_io_assignment_build','true',save_params);
});



/**********************************************************************
 sub group change
**********************************************************************/
$('.subgroup_anchor').w_change(function(){
	
	var anchor_id = $(this).attr('id').split('_')[1];
	var t = $(this);

	$('.ajax-loader').show();
	var current_group_id = (typeof $(this).attr('group_ID')  !== 'undefined' ? $(this).attr('group_ID') : nv_group_id);

	if(current_group_id != 'array'){
		$.post('/nv_config/get_subgroup',{
			group_id: current_group_id,
			group_ch:nv_group_channel,
			selected_id:parseInt($(this).val()),
			enum_id:anchor_id,
			selected_readable:$(this).find("option:selected" ).text()
		},function(subgroup_resp){
			$('.subgroup_parameters_'+anchor_id).html(subgroup_resp);
			$('.ajax-loader').hide();

			$('.subgroup_parameters').children().each(function(){
				var parent_id = $(this).attr('class').split('_')[2];

				if($('#enum_'+parent_id).length == 0){
					$(this).html('');
				}

			});
			sscc_document_ready();

			if(t.closest('.nv_config_channels_right_wrapper').length != 0){
				$('.nv_config_channels_content_wrapper').custom_scroll(435);
			}else{
				$('.nv_config_wrapper').custom_scroll(435);
			}
		});
	}
});

/**********************************************************************
 sub group change
**********************************************************************/
$('.nv_arrow').w_click(function(){
	$('.selected_row').removeClass('selected_row');
	$(this).closest('tr').find('td').addClass('selected_row');

	var current_page = 1; 
	var io_assignment = ($('.template_select').length>0);
	var io_type = '';

	if($('.pagination .current').length > 0){
		current_page = parseInt($('.pagination .current').html()); 
	}

	if(!isNaN(current_page) && nv_group_id != 'array' && io_assignment){
		var io_type = current_url.split('/')[2];
	}

	var save_params = {};
	save_params["page_number"] = current_page;
	save_params["io_type"] = io_type;

	load_subgroup($(this),'/nv_config/get_sear_mod_build','',save_params);
});

function load_subgroup(t,url,default_flag,post_params){
	$('.ajax-loader').show();
	nv_group_channel = parseInt(t.closest('tr').find('.nv_channel').html());
	
	if(nv_group_id != 'array'){
		if(typeof post_params === 'undefined'){
			var post_params = {};
		}
		post_params['group_id'] = nv_group_id;
		post_params['group_ch'] = nv_group_channel;

		if(default_flag=='true'){
			post_params['default'] = 'true';
		}

		$.post(url,post_params,function(build_resp){
			$('.nv_config_channels_content_wrapper').html(build_resp);
			$('.ajax-loader').hide();
			
			if($('.subgroup_anchor').closest('.nv_config_channels_right_wrapper').length != 0){
				$('.nv_config_channels_content_wrapper').custom_scroll(435);
			}else{
				$('.nv_config_wrapper').custom_scroll(435);
			}
			sscc_document_ready();
		});
	}
}

$('.nv_io_assignment_arrow').w_click(function(){
	$('.selected_row').removeClass('selected_row');
	$(this).closest('tr').find('td').addClass('selected_row');

	var current_page = 1; 
	var io_assignment = ($('.template_select').length>0);
	var io_type = '';

	if($('.pagination .current').length > 0){
		current_page = parseInt($('.pagination .current').html()); 
	}

	if(!isNaN(current_page) && nv_group_id != 'array' && io_assignment){
		var io_type = current_url.split('/')[2];
	}

	var save_params = {};
	save_params["page_number"] = current_page;
	save_params["io_type"] = io_type;

	load_subgroup($(this),'/nv_config/get_io_assignment_build','',save_params);
});

$('.page_anchor ').w_click(function(){
	var page = $(this).attr('page');

	if(typeof page == "string"){
		reload_page({'page':page});
	}
});



/**********************************************************************
 add calender date
**********************************************************************/
function add_cal_event(){
	var date_format_obj = $('#'+date_id);
	if(typeof date_format_obj === 'object' && date_format_obj.length > 0){

		date_format_obj.datepicker({
		    showOn: "button",
		    buttonImage: "/images/calendar.gif",
		    buttonImageOnly: true,
			dateFormat: 'mm-dd-yy',
			changeYear:true
		}).attr('readonly', true);
	}
}



/**********************************************************************
gets an input id from the title of a parameter
**********************************************************************/
function get_id_from_nv_title(title){
	var id = '';
	$('.nv_title').each(function(){
		if($.trim($(this).html()) == title){
			if($(this).closest('.nv_row').find('input').length > 0){
				id = $(this).closest('.nv_row').find('input').attr('id');
			}else if($(this).closest('.nv_row').find('select').length > 0){
				id = $(this).closest('.nv_row').find('select').attr('id');
			}
		}
	});

	return id;
}
$('.nv_set_all_default').w_click(function(){
	ConfirmDialog('Defaults','Are you sure you want to<br>set non-vital parameters to defaults?',function(){
		set_to_default();
	},function(){
		//cancelled do nothing
	});
});


function set_to_default(){
	$('.ajax-loader').show();

	$.post('/nv_config/save_rc2_key/',{
		val		: '',
		def_flg	: true
	},function(rc2_key_resp){
		check_rc2_default_interval = setInterval(function(){
			$.post('/nv_config/check_rc2_key/',{
				request_id:rc2_key_resp
			},function(check_rc2_resp){

				if(parseInt(check_rc2_resp.request_state) == 2){
					clearInterval(check_rc2_default_interval);

					$.post('/nv_config/get_rc2key_status/',{
						//no params
					},function(rc2key_status){
						$.post('/nv_config/set_to_defaults',{
							//no params
						},function(defaults_resp){
							$('.nv_config_message').success_message('Parameters are set to default values.');
							$('.ajax-loader').hide();
						});

					});											
				}
			},'json');

		},1000);
	});
}

$('.nv_set_all_sear_default').w_click(function(){
	ConfirmDialog('Defaults','Are you sure you want to<br>set sear parameters to defaults?',function(){
		$('.ajax-loader').show();

		$.post('/nv_config/sear_set_to_default',{
			//no params
		},function(defaults_resp){
			$('.nv_config_message').success_message('Parameters are set to default values.');
			$('.ajax-loader').hide();
		});				
	},function(){
		//cancelled do nothing
	});
});



$('.site_info_time ').w_change(function(){
	datetime_changed = true;
});
$('#date').w_change(function(){
	datetime_changed = true;
});


$('.template_select').w_change(function(){
	var val = $(this).val();

	//searches throught the option tags to get the rest of the information
	$('.template_select option').each(function(){
		if($(this).html() == val){
			var name = $(this).html();
			var tag = $(this).attr('tag');
			var off_state_name = $(this).attr('off_state_name');
			var on_state_name = $(this).attr('on_state_name'); 
			
			if(typeof name !== "undefind" && typeof tag !== "undefind" && typeof off_state_name !== "undefind" && typeof on_state_name !== "undefind"){
				$('.nv_title').each(function(){
					if($(this).text().replace(/^\s+|\s+$/g,'') == 'Name'){
						if(!$(this).parent().find('input').is('[readonly]') && !$(this).parent().find('input').is(':disabled')){
							$(this).parent().find('input').val(name);
						}
					}else if($(this).text().replace(/^\s+|\s+$/g,'') == 'Tag'){
						if(!$(this).parent().find('input').is('[readonly]') && !$(this).parent().find('input').is(':disabled')){
							$(this).parent().find('input').val(tag);
						}
					}else if($(this).text().replace(/^\s+|\s+$/g,'') == 'Off State Name'){
						if(!$(this).parent().find('input').is('[readonly]') && !$(this).parent().find('input').is(':disabled')){
							$(this).parent().find('input').val(off_state_name);
						}
					}else if($(this).text().replace(/^\s+|\s+$/g,'') == 'ON State Name'){
						if(!$(this).parent().find('input').is('[readonly]') && !$(this).parent().find('input').is(':disabled')){
							$(this).parent().find('input').val(on_state_name);
						}
					}
				});
			}
		}
	});
})


function sscc_document_ready(){
  if(typeof select_group_channel !== 'undefined' && select_group_channel != null && $('.sscc_'+select_group_channel+'_0').length > 0){
  	
  	$('.sscc_loading').hide();

    var row = $('.sscc_'+select_group_channel+'_0').closest('tr');
    row.css({'color':'#C3CF21'});

    $('.sscc_list tr').css({'color':''})
    
    var locked = parseInt(row.find('.locked').val());
    var num_items = parseInt($('.num_of_items').val());
    var group_channel = parseInt(row.attr('group_channel'));
    var table = '<table class="sscc_info">'
    var tr_id = row.find('.name').attr('group_channel');



    for (var i=0;i<num_items;i++){
      var item_locked = parseInt($('.sscc_'+group_channel+'_'+i).closest('tr').find('.locked').val());

      table += '<tr sort_number = "'+i+'" group_channel = "'+group_channel+'" tr_id="'+tr_id+'">'+
                  '<td class="sscc_info_title">'+$('.sscc_'+group_channel+'_'+i).attr('name')+'</td>'+
                  '<td class="sscc_info_input"><input type="text" class="sscc_info_name '+(item_locked == 1 ? 'disabled ' :'')+'" value="'+$('.sscc_'+group_channel+'_'+i).html()+'" min="'+$('.sscc_'+group_channel+'_'+i).attr('min')+'" max="'+$('.sscc_'+group_channel+'_'+i).attr('max')+'" '+(item_locked == 1 ? 'readonly' :'')+'/></td>'+
                  '<td>'+(item_locked == 1 ? '<img src="/images/green-lock.png"  alt = "locked" style ="position: relative;top: 5px;left: 5px;"/>' :'')+'</td>'+
                  '<td class="error" style="color:#FFF380;width: 155px;"></td>'+
                '</tr>';
    }

    table += '</table>';
    $('.sscc_mod_info').html(table);


    update_sscc_height();
    

    $('.sscc_error').hide();


    
    $('.sscc_mod_info input[type="text"]').focusout(function(){
        var row = $(this).closest('tr');
        var group_channel = row.attr('group_channel');
        var sort_number = row.attr('sort_number');
        var string_val = $(this).val();
        var name = row.find('.sscc_info_title').html();

        var item= $('.sscc_'+group_channel+'_'+sort_number);

        item.html(string_val);
        item.attr('name',name);

        if(!inArray(group_channel, sscc_save_ar)){
          sscc_save_ar[sscc_save_ar.length] = group_channel;
          save_flag = true;
        } 
    });

	  $('.button_get_sscc').w_click(function(){
	  	select_group_channel = parseInt($(this).closest('tr').attr('group_channel'));

	  	sscc_document_ready();
	  });  

	  $('.sscc_tabs td').w_click(function(){
		  if(preload_page!=''){
		    var confirm_save = confirm("Do you want to leave the page without saving?");

		    if(confirm_save)
		      get_sscc($(this),0);

		  }else{
		    get_sscc($(this),0);
		  }
		});
	}
}

function get_sscc(t,group_channel){
  t.closest('table').find('.sscc_tab_selected').removeClass('sscc_tab_selected').addClass('sscc_tab_off');
  t.removeClass('sscc_tab_off ').addClass('sscc_tab_selected');

  $('.sscc_loading').show();

  $('#msg').html('');
  var start_index_val = parseInt(t.attr('start_index')); 

  $('.start_index').val(start_index_val);


  $.post('/nv_config/get_sscc_content_render',{
      stat_index : start_index_val,
      channel : nv_group_channel,
      select_group_channel: group_channel
  },function(get_page_feedback){
    $('.sscc_wrapper').html(get_page_feedback);
    
    sscc_document_ready();

    update_sscc_height();
   
    sscc_save_ar = Array();
    save_flag = false;
    $('.sscc_loading').hide();

  });
}

function update_sscc_height(){
	$('.sscc_info').custom_scroll(287);

	setTimeout(function(){
		var new_height = parseInt($('.nv_config_channels_right_wrapper').height())+20;

    	set_content_height(new_height);
	},100);
}
 

function inArray(needle, haystack){
  var flag = false; 

  for(var i = 0; i < haystack.length;i++){
    if(needle == haystack[i]){
      i = haystack.length;
      flag = true;
    }
  }
  return flag;
}


//save is for both echelon and sscc
function build_sscc_save_obj(param_obj){
	var save_sscc_obj = {};
	for(var save_i = 0; save_i < sscc_save_ar.length; save_i++){
		if($('.sscc_list').find('tr[group_channel='+sscc_save_ar[save_i]+']').length > 0){
			$('.sscc_list').find('tr[group_channel='+sscc_save_ar[save_i]+']').each(function(){
				if(typeof $(this).attr('db_id') !== 'undefined' && $(this).find('.name').length > 0 && typeof $(this).find('.name').html() !== 'undefined'){
					save_sscc_obj['string_'+$(this).attr('db_id')] = $(this).find('.name').html();
				}
			});
		}
	}
	$.extend( param_obj, save_sscc_obj )
	return param_obj;
}
