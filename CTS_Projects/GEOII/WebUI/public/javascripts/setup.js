var setup_interval; 
var update_in_session = false;
var save_interval = '';
var page_ajax; 

$(document).bind("ready",function(){
	add_to_destroy(function(){
		$(document).unbind("ready",function(){});
	
		//kills all wrapper events
		$('.card_save_button img').w_die('click');
		$('.card_warpper  input[type=text]').w_die('keyup');
		$('.card_warpper  input[type=text]').w_die('keydown');
		$('input').w_die('change');

		//can request
		if(page_ajax != null){
			page_ajax.abort();
		}

		//clear intervals
		clearInterval(setup_interval);

		//clear functions 
		delete window.lamp_setup;
		delete window.track_setup;
		delete window.update_rxtx;
		delete window.update_setup_inputs;

		//clears global variables
		delete window.update_in_session;
		delete window.page_ajax;
		delete window.setup_interval;
		delete window.save_interval;
		delete window.save_obj;
	});

	//gets and sets the height of the setup area
	set_content_deminsions(954,parseInt($('.lamp_container_wrapper').height()));


	//startst periodic calls
	if($('.setup_type').val() == 'lamps'){
		lamp_setup();
	}else if($('.setup_type').val() == 'tracks'){
		track_setup();
	}
	
	var milli_array = new Array('VCOVoltage','CurrentLimit','LampVoltage','TransmitVoltage','ReceiveThreshold');

	$('.card_warpper').each(function(){
		var card_wrapper = $(this);

		card_wrapper.find('input').each(function(){
			var ids = $(this).attr('id');

			if(typeof ids !== 'undefined'){
				ids = ids.split(' ');
				if(typeof ids !== 'undefined'){
					for(var id_i = 0; id_i < ids.length; id_i++){
						var current_id = ids[id_i];
						var id = current_id.replace(/[0-9]+(?!.*[0-9])/, '');

						if($.inArray(id,milli_array) != -1){
							//changes the value
							card_wrapper.find('#'+current_id).addClass('milliConvert');
							card_wrapper.find('#'+current_id).val(card_wrapper.find('#'+current_id).val()/1000);

							//removes the m in the units
							var current_element = card_wrapper.find('#'+current_id).closest('.card_input_row').find('.card_input_title');
							var current_title = current_element.html();

							var unit_postition = current_title.lastIndexOf('m');

							current_title = current_title.substr(0,unit_postition) + current_title.substr(unit_postition+1);
							
							current_element.html(current_title);


							//changes from int to float
							card_wrapper.find('#'+current_id).attr('param_type','float');
						}
					};
				}
			}
		})
	});

	//gets the max height of each card type
	setTimeout(function(){
		var max_height = 0; 
		$('.card_warpper ').each(function(){
			var new_height = parseInt($(this).height());

			if(new_height > max_height){
				max_height = new_height; 
			}
		});
		//sets all cards height to be the max height
		if(max_height != 0){
			$('.card_warpper ').css({'height':max_height+'px'});
		}
	},5);


	//fixes inputs to have a single decimal place
	update_setup_inputs();
});
function update_setup_inputs(){
	$('.card_warpper  input[type=text]').each(function(){
	var cur_val = parseFloat($(this).val()); 
		if(cur_val % 1 ==0){
			$(this).val(cur_val +'.0')
		}
	})
}


function lamp_setup(){
	setup_interval = setInterval(function(){
		//checks if gets lamps is in session

			page_ajax = $.post('/setup/refresh_lamps_table/',{
				//no params
			},function(refresh_resp){

				for(var card_i = 0; card_i < refresh_resp.length; card_i++){
					var health = refresh_resp[card_i]['health'] == 'active' ? 'green' : 'red';
					var slot = refresh_resp[card_i]['slot_no'];
					var card_index = refresh_resp[card_i]['card_index'];
					var card_type = parseInt(refresh_resp[card_i]['card_type']);

					if(card_type == 2){
						var table = '';

						for(var channel_i = 0; channel_i < 2; channel_i++){
							var channel_name = refresh_resp[card_i]['data'][channel_i]['PCO']['name'];
							var channel_status = refresh_resp[card_i]['data'][channel_i]['PCO']['param']['lamp_status'];
							var channel_led = refresh_resp[card_i]['data'][channel_i]['PCO']['param']['lamp_image'];
                            var fe = refresh_resp[card_i]['data'][channel_i]['PCO']['param']['foreign_energy']  == true ? "style='background-color:yellow;'" :"";
                            var text_color = (fe=="")?"color:#FFFFFF" : "color:#000000";
							var mech_failure =  refresh_resp[card_i]['data'][channel_i]['PCO']['param']['mech_failure'];
							var cmd_armature = refresh_resp[card_i]['data'][channel_i]['PCO']['param']['cmd_armature'];
							var status_armature = refresh_resp[card_i]['data'][channel_i]['PCO']['param']['status_armature'];
							var mech_failure_img = '<span style="padding-left:5px;'+text_color+'">'+cmd_armature+'</span><img style="padding-left:5px;padding-right:5px;" src="/images/'+mech_failure+'"/><span style="padding-left:5px;padding-right:15px;'+text_color+'">'+status_armature+'</span>';
							
							table += '<tr><td>'+channel_name+'</td><td class="vlo1_value" '+fe+'><img class="lamp_led" src="'+channel_led+'"/>'+mech_failure_img+'<span style='+text_color+'>'+channel_status+'</span></td></tr>';
						}

						$('.card_warpper[slot_no='+slot+']').find('.lamp_table table').html(table);
					}else if(card_type == 3){
						var table = '';

						for(var channel_i = 0; channel_i < 6; channel_i++){
							var channel_name = refresh_resp[card_i]['data'][channel_i]['Colorlight']['name'];
							var channel_status = (refresh_resp[card_i]['data'][channel_i]['Colorlight']['code']['lamp_status'] != null ? refresh_resp[card_i]['data'][channel_i]['Colorlight']['code']['lamp_status'] : refresh_resp[card_i]['data'][channel_i]['Colorlight']['params']['status']);
							var channel_led = refresh_resp[card_i]['data'][channel_i]['Colorlight']['code']['lamp_image'];
                            var fe = refresh_resp[card_i]['data'][channel_i]['Colorlight']['code']['foreign_energy']  == true ? "style='background-color:yellow;'" :"";
                            var text_color = (fe=="")?"style='color:#FFFFFF'" : "style='color:#000000'";
							table += '<tr><td>'+channel_name+'</td><td class="vlo1_value" '+ fe+'><img class="lamp_led" src="'+channel_led+'"/><span '+text_color+'>'+channel_status+'</span></td></tr>';
						}

						$('.card_warpper[slot_no='+slot+']').find('.lamp_table table').html(table);
					}

					var health_img = $('.card_warpper[slot_no='+slot+']').find('.card_status img').attr('src');

					health_img = health_img.substr(0,health_img.lastIndexOf('/')+1)+health+'.png';

					$('.card_warpper[slot_no='+slot+']').find('.card_status img').attr('src',health_img);
				}

				update_in_session = false;
				page_ajax = null;
			});	
		
	},4000);
}

function track_setup(){
	setup_interval = setInterval(function(){

		page_ajax = $.post('/setup/refresh_tracks_table/',{
			//no params
		},function(refresh_resp){
			for(var card_i = 0; card_i < refresh_resp.length; card_i++){
				var health = refresh_resp[card_i]['health'] == 'active' ? 'green' : 'red';
				var slot = refresh_resp[card_i]['slot_no'];
				var card_index = refresh_resp[card_i]['card_index'];
				var card_type = parseInt(refresh_resp[card_i]['card_type']);

				if(typeof refresh_resp !== 'undefined' && typeof refresh_resp[card_i] !== 'undefined' && typeof refresh_resp[card_i]["data"] !== 'undefined'){
					rf_resp = refresh_resp[card_i]["data"];
					if(typeof rf_resp[0] !== 'undefined' && typeof rf_resp[0]['Code'] !== 'undefined' && typeof rf_resp[0]['Code']['vco'] !== 'undefined' && rf_resp[0]['Code']['Vti'] !== 'undefined'){
						var vco = rf_resp[0]['Code']['vco'];
						var vti = rf_resp[0]['Code']['Vti'];
						var tx_current = vco['track_values']["current"];
						var tx_voltage = vco['track_values']["voltage"];
						var rx_current = vti['current'];

						$('.card_warpper[slot_no='+slot+']').find('.tx_voltage_value').html(tx_voltage);
						$('.card_warpper[slot_no='+slot+']').find('.tx_current_value').html(tx_current);
						$('.card_warpper[slot_no='+slot+']').find('.rx_current_value').html(rx_current);

						//gets all of the tx data from hash
						var tx_1 = vco['track_params']["track1"];
						var tx_2 = vco['track_params']["track2"];
						var tx_3 = vco['track_params']["track3"];
						var tx_4 = vco['track_params']["track4"];
						var tx_hw_error = vco['track_params']["hw_error"];

						//updates the GUI with the corrent data
						update_rxtx(slot,'tx',tx_1,tx_2,tx_3,tx_4,tx_hw_error);

						//gets all of the rx data from hash
						var rx_1 = vti['track_params']["track1"];
						var rx_2 = vti['track_params']["track2"];
						var rx_3 = vti['track_params']["track3"];
						var rx_4 = vti['track_params']["track4"];
						var rx_hw_error = vti['track_params']["hw_error"];

						//updates the GUI with the corrent data
						update_rxtx(slot,'rx',rx_1,rx_2,rx_3,rx_4,rx_hw_error);

					}else if(typeof rf_resp[1] !== 'undefined' && typeof rf_resp[1]['LineAnalog'] !== 'undefined' && typeof rf_resp[0]['LineAnalog']['vco'] !== 'undefined' && rf_resp[0]['LineAnalog']['vti'] !== 'undefined'){
						var vco = rf_resp[1]['LineAnalog']['vco'];
						var vti = rf_resp[1]['LineAnalog']['vti'];
						var tx_current = vco['track_values']['current'];
						var tx_voltage = vco['track_values']['voltage'];
						var rx_current = vti['current'];

						$('.card_warpper[slot_no='+slot+']').find('.tx_voltage_value').html(tx_voltage);
						$('.card_warpper[slot_no='+slot+']').find('.tx_current_value').html(tx_current);
						$('.card_warpper[slot_no='+slot+']').find('.rx_current_value').html(rx_current);

						//gets all of the tx data from hash
						var tx_1 = vco['track_params']["track1"];
						var tx_2 = vco['track_params']["track2"];
						var tx_3 = vco['track_params']["track3"];
						var tx_4 = vco['track_params']["track4"];

						//updates the GUI with the corrent data
						update_rxtx(slot,'tx',tx_1,tx_2,tx_3,tx_4,tx_hw_error);

						//gets all of the rx data from hash
						var rx_1 = vti['track_params']["track1"];
						var rx_2 = vti['track_params']["track2"];
						var rx_3 = vti['track_params']["track3"];
						var rx_4 = vti['track_params']["track4"];

						//updates the GUI with the corrent data
						update_rxtx(slot,'rx',rx_1,rx_2,rx_3,rx_4,rx_hw_error);

					}else if(typeof rf_resp[0] !== 'undefined' && typeof rf_resp[0]['Code'] !== 'undefined' && typeof rf_resp[0]['Code']['vco'] !== 'undefined' && rf_resp[0]['Code']['Vti'] !== 'undefined'){
						var vco = rf_resp[0]['Code']['vco'];
						var vti = rf_resp[0]['Code']['Vti'];
						var tx_current = vco['track_values']["current"];
						var tx_voltage = vco['track_values']["voltage"];
						var rx_current = vti['current'];

						$('.card_warpper[slot_no='+slot+']').find('.tx_voltage_value').html(tx_voltage);
						$('.card_warpper[slot_no='+slot+']').find('.tx_current_value').html(tx_current);
						$('.card_warpper[slot_no='+slot+']').find('.rx_current_value').html(rx_current);

						var rx = rf_resp[2]['rx'];
						var tx = rf_resp[2]['tx'];

						$('.card_warpper[slot_no='+slot+']').find('.tx_params').html(tx);
						$('.card_warpper[slot_no='+slot+']').find('.rx_params').html(rx);
					}
				}

				var health_img = $('.card_warpper[slot_no='+slot+']').find('.card_status img').attr('src');

				health_img = health_img.substr(0,health_img.lastIndexOf('/')+1)+health+'.png';

				$('.card_warpper[slot_no='+slot+']').find('.card_status img').attr('src',health_img);

				page_ajax = null;
			}
		},'json');
	},4000);
}

function update_rxtx(slot,type,data_1,data_2,data_3,data_4,tx_hw_error){
	if(tx_hw_error == 'true'){
		$('.card_warpper[slot_no='+slot+']').find('.'+type+'_params').html('hw error');
	}else{
		if($('.card_warpper[slot_no='+slot+']').find('.'+type+'_params table').length > 0 ){
			$('.card_warpper[slot_no='+slot+']').find('.'+type+'_params table td').eq(0).html(data_1);
			$('.card_warpper[slot_no='+slot+']').find('.'+type+'_params table td').eq(1).html(data_2);
			$('.card_warpper[slot_no='+slot+']').find('.'+type+'_params table td').eq(2).html(data_3);
			$('.card_warpper[slot_no='+slot+']').find('.'+type+'_params table td').eq(3).html(data_4);
		}else{
			var rx_table = '<table><tr>';
			rx_table += '<td>'+data_1+'</td>';
			rx_table += '<td>'+data_2+'</td>';
			rx_table += '<td>'+data_3+'</td>';
			rx_table += '<td>'+data_4+'</td>';
			rx_table += '<tr><table>';

			$('.card_warpper[slot_no='+slot+']').find('.'+type+'_params').html(rx_table);
		}
	}
}
var save_obj = {};
$('.card_save_button img').w_click(function(){
	var card_warpper  = $(this).closest('.card_warpper');

	update_setup_inputs();

	save_obj = {};	//creates json object
	var inputs = card_warpper.find('input,select');
	
	
	//indexs through all inputs
	inputs.each(function(){
		var key = $(this).attr('id');
		var val = $(this).val();

		if($(this).hasClass('milliConvert')){
			val = val * 1000;
		}
		//stores the key and val in the array
		save_obj[key] = parseInt(val);
	});

	save_obj['card_type'] = card_warpper.attr('card_type');

	card_warpper.find('.card_feedback').html("");
	// ajax off to save vital config parameters
	$("#contentcontents").mask("Saving parameters, please wait...");

	card_warpper.find('.card_error').html('').show().removeClass('error_message');;

	if($('.setup_type').val() == 'lamps'){
		var save_url = '/setup/save_lamp_data/'; 
	} else if($('.setup_type').val() == 'tracks'){
		var save_url = '/setup/save_track_data/'; 
	}

	if(typeof save_url !== 'undefined'){
		$.post(save_url,save_obj,function(v_save_resp){
			save_obj['request_id'] = v_save_resp.request_id;
			if(v_save_resp.error){
				if(v_save_resp.message != ''){
					card_warpper.find('.card_feedback').error_message(v_save_resp.message);
				}else{
					var v_errors = v_save_resp.errors;
					v_errors = v_errors.substring(0, v_errors.length - 1);
					v_errors = v_errors.split(','); 

					for(var error_i = 0; error_i < v_errors.length; error_i++){
						var v_error = v_errors[error_i];
						var error_id = v_error.split('=>')[0];
						var error_msg = v_error.split('=>')[1];

						$('#'+error_id).closest('.card_input_row').find('.card_error').html(error_msg).addClass('error_message');;
					}

					card_warpper.find('.card_save_button').hide();
				}
				$("#contentcontents").unmask("Saving parameters, please wait...");
			}else{
				var req_counter = 0;
				var request_in_process = false;
				if(save_interval != null){
					clearInterval(save_interval);
					save_interval = setInterval(function(){
						// ajax off to check save request state
						if(!request_in_process){
							request_in_process = true;
							$.post('/setup/check_save',save_obj, function(v_save_resp){
								if(req_counter == 15){
									clearInterval(save_interval);
									card_warpper.find('.card_feedback').error_message('Save request timeout');
									$("#contentcontents").unmask("Saving parameters, please wait...");
								}else if(v_save_resp.error && (!v_save_resp.request_state || v_save_resp.request_state != "2")){
									clearInterval(save_interval);
									card_warpper.find('.card_feedback').error_message(v_save_resp.message);
									$("#contentcontents").unmask("Saving parameters, please wait...");
								}else{
									req_counter += 1;
									if(v_save_resp.request_state == "2"){
										if(v_save_resp.error){
											card_warpper.find('.card_feedback').error_message(v_save_resp.message);
										}else{
											if(v_save_resp.confirmed == "400"){
												card_warpper.find('.card_feedback').success_message(v_save_resp.message);
											}else{
												card_warpper.find('.card_feedback').success_message(v_save_resp.message);
												remove_v_preload_page();
											}
										}
										clearInterval(save_interval);
										$("#contentcontents").unmask("Saving parameters, please wait...");
									}
								}
								request_in_process = false;
							});
						}
					}, 2000);
				}
			}
			
		});
	}else{
		card_warpper.find('.card_feedback').error_message('Card type unkown...');
	}
});

$('.card_warpper  input[type=text]').w_keydown(function(event){
	if($(this).attr('param_type') == 'int'){
		validate_integer(event);
	}else if($(this).attr('param_type') == 'float'){
		validate_float($(this),event,1);
	}
});


$('.card_warpper  input[type=text]').w_keyup(function(){
	var card_warpper  = $(this).closest('.card_warpper');
	var card_error = false; 


	if($(this).val().trim() != ''){

		card_warpper.find('input[type=text]').each(function(){
			var card_input = $(this);
			
			var scale = parseInt($(this).attr('scale'));
			var min = parseInt($(this).attr('min'));
			var max = parseInt($(this).attr('max'));
			if($(this).attr('param_type') == 'int'){
				var value = parseInt($(this).val());
			}else{
				var value = parseFloat($(this).val());
			}	
			if($(this).hasClass('milliConvert')){
				scale = scale/1000;
			}

			if(scale.length != 0 && min.length != 0 && max.length != 0){
				var scaled_value = (value * 1000)/scale;

				if(scaled_value < min || scaled_value > max){
					card_error = true;

					var error_string = 'should be between ' + (min*scale/1000) + ' and '+ (max*scale/1000);

					$(this).closest('.card_input_row ').find('.card_error').html(error_string).show().addClass('error_message');
				}else{
					$(this).closest('.card_input_row ').find('.card_error').html('').show().removeClass('error_message');
				}
			}

		});
	}else{
		card_error = true;
		$(this).closest('.card_input_row ').find('.card_error').html('parameter should not be blank').show().addClass('error_message');
	}

	if(!card_error){
		$(this).closest('.card_warpper').find('.card_save_button').show();
	}else{
		$(this).closest('.card_warpper').find('.card_save_button').hide();
	}	
});
$('input').w_change(function(){
	add_v_preload_page();
});
