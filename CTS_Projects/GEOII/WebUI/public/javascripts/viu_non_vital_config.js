/**
 * @author Jeyavel Natesan
 */

var input_selet_w_change_ar = [];

add_to_destroy(function(){
	$(document).unbind("ready");
	
	//kills all wrapper events
	$(".refresh_icon").w_die('click');
	$(".discard_icon").w_die('click');
	$(".default_icon").w_die('click');
	$('input').w_die('change');
	$('select').w_die('change');
	$("#SER_PORT_LAP_PROTO").w_die('change');
	$("#SER_PORT_1_PROTO").w_die('change');
	$(".update_viu_config").w_die('click');
	$('#myform1').w_die('submit');
	$('.rc2key_anchor').w_die('keyup');
	$('.rc2key_Confirm').w_die('keyup');
	if (typeof input_selet_w_change_ar !== 'undefined' && 				input_selet_w_change_ar != null) {
		for (var c_i = 0; c_i < input_selet_w_change_ar.length; 				c_i++) {
			$(input_selet_w_change_ar[c_i]).w_die('change');
		}
	}

	//clear functions 
	delete window.showValues;
	delete window.timeout;
	delete window.viu_parameter_validation;
	delete window.rc2key_check;
	delete window.enabled_attr;
	delete window.rc2key_changed;
	delete window.disabled_hide_viu_input;
	delete window.enabled_show_viu_input;
	delete window.init_enabled_show_attr;
	delete window.enabled_show_attr;

	//clear var

	delete window.input_selet_w_change_ar;
});

$(document).ready(function(){
	init_enabled_show_attr();
	reorder_inputs();

	$(":checkbox, :radio").change(showValues);
    $(":input").blur(showValues);
    $("select").change(showValues);
    showValues();

	if ($("#tagname").val() == '1'){
		var sitename = $("#hd_site_name").val();
		var atcs_addr = $("#hd_atcs_addr").val();
		var mile_post = $("#hd_mile_post").val();
		var dot_number = $("#hd_dot_number").val();
		window.parent.document.getElementById("mainheader").innerHTML = "";
		window.parent.document.getElementById("mainheader").innerHTML = "Site Name: " + sitename + "| ATCS Address: " + atcs_addr + "| Mile Post: " + mile_post + "| DOT Number: " + dot_number;
	}
	
	$(".update_viu_config").w_click(function(){
		if(viu_parameter_validation()){
			$('#contentcontents').mask('Processing request, please wait...');
			$('#myform1').submit();
		}
	});
	
	$(".refresh_icon").w_click(function(){
		reload_page();
	});
	
	$(".discard_icon").w_click(function(){
		reload_page();	
	});
	
	$(".default_icon").w_click(function(){
		reload_page({default:'true'});
	});
	
	$('#myform1').submit(function(e) {
		var options = {
		    success:    function(resp_tagname) { 
			   if (resp_tagname && resp_tagname != null) {
			   		preload_page = '';
					
					reload_page({'tagname':resp_tagname,'reload':0});
			   }
		    } 
		};
	    $(this).ajaxSubmit(options);
		return false; 
	});
	
	function ser_port_lap_proto(value){
		if (value == 1){
			$("#PROTO_PORT_LAP_BCP_NUMBER").hide();
			$("#PROTO_PORT_LAP_NMEA_RECV_TIMEOUT").show();
			$("#PROTO_PORT_LAP_NMEA_TIME_DIFF").show();
			$("#PROTO_PORT_LAP_BCP_NUMBER_div").hide();
			$("#PROTO_PORT_LAP_NMEA_RECV_TIMEOUT_div").show();
			$("#PROTO_PORT_LAP_NMEA_TIME_DIFF_div").show();			
		}
		else if (value == 3){
			$("#PROTO_PORT_LAP_NMEA_RECV_TIMEOUT").hide();
			$("#PROTO_PORT_LAP_NMEA_TIME_DIFF").hide();			
			$("#PROTO_PORT_LAP_BCP_NUMBER").show();
			$("#PROTO_PORT_LAP_NMEA_RECV_TIMEOUT_div").hide();
			$("#PROTO_PORT_LAP_NMEA_TIME_DIFF_div").hide();
			$("#PROTO_PORT_LAP_BCP_NUMBER_div").show();		
		}
		else{
			$("#PROTO_PORT_LAP_BCP_NUMBER").hide();
			$("#PROTO_PORT_LAP_NMEA_RECV_TIMEOUT").hide();
			$("#PROTO_PORT_LAP_NMEA_TIME_DIFF").hide();
			$("#PROTO_PORT_LAP_BCP_NUMBER_div").hide();
			$("#PROTO_PORT_LAP_NMEA_RECV_TIMEOUT_div").hide();
			$("#PROTO_PORT_LAP_NMEA_TIME_DIFF_div").hide();			
		}
	}
	ser_port_lap_proto($("#SER_PORT_LAP_PROTO").val());
	
	//Laptop port
	$("#SER_PORT_LAP_PROTO").w_change(function(){
		ser_port_lap_proto($("#SER_PORT_LAP_PROTO").val());
	},true);
	
	function ser_port_l_proto(value){
		if (value == 1){
			$("#PROTO_PORT_1_BCP_NUMBER").hide();
			$("#PROTO_PORT_1_NMEA_RECV_TIMEOUT").show();
			$("#PROTO_PORT_1_NMEA_TIME_DIFF").show();
			$("#PROTO_PORT_1_BCP_NUMBER_div").hide();
			$("#PROTO_PORT_1_NMEA_RECV_TIMEOUT_div").show();
			$("#PROTO_PORT_1_NMEA_TIME_DIFF_div").show();
		}
		else if (value == 3){
			$("#PROTO_PORT_1_NMEA_RECV_TIMEOUT").hide();
			$("#PROTO_PORT_1_NMEA_TIME_DIFF").hide();			
			$("#PROTO_PORT_1_BCP_NUMBER").show();
			$("#PROTO_PORT_1_NMEA_RECV_TIMEOUT_div").hide();
			$("#PROTO_PORT_1_NMEA_TIME_DIFF_div").hide();			
			$("#PROTO_PORT_1_BCP_NUMBER_div").show();			
		}
		else{
			$("#PROTO_PORT_1_BCP_NUMBER").hide();
			$("#PROTO_PORT_1_NMEA_RECV_TIMEOUT").hide();
			$("#PROTO_PORT_1_NMEA_TIME_DIFF").hide();
			$("#PROTO_PORT_1_BCP_NUMBER_div").hide();
			$("#PROTO_PORT_1_NMEA_RECV_TIMEOUT_div").hide();
			$("#PROTO_PORT_1_NMEA_TIME_DIFF_div").hide();			
		}
	}	
	
	ser_port_l_proto($("#SER_PORT_1_PROTO").val());
	
	//Port one
	$("#SER_PORT_1_PROTO").w_change(function(){
		ser_port_l_proto($("#SER_PORT_1_PROTO").val());
	},true);
	
	$.each(["input","select"], function(index, value){
		$(value).w_change(function(){
			val_change = true;
			preload_page = function(){
				var popup_title = 'Non-Vital Config'; 
				
				ConfirmDialog(popup_title,'Changes were not saved.<br>Would you like to discard them?',function(){
					if(typeof item_clicked == 'object'){
						preload_page_finished();		
					}
					preload_page = '';
				},function(){
					//don't load the next page
				});
			};
		},true);
	});

	$('.rc2key_anchor').w_keyup(function(){
		rc2key_check();
	});

	$('.rc2key_Confirm').w_keyup(function(){
		rc2key_check();
	});

});
var rc2key_changed = false;
function rc2key_check(){
	rc2key_changed = true;

	if($('#EMP_RC2_KEY_confirm_error').length == 0){
		$('.rc2key_Confirm').closest('.nv_row').append('<div class="nv_error" id="EMP_RC2_KEY_confirm_error"></div>');

	}

	if($('.rc2key_Confirm').val() == '' || $('.rc2key_anchor').val() == $('.rc2key_Confirm').val()){
		$('.rc2key_Confirm').closest('.nv_row').find('.nv_error').html('');
	}else{
		$('.rc2key_Confirm').closest('.nv_row').find('.nv_error').html('RC2 key does not match RC2 key confirm');
	}
}

function showValues() {
     var str = $("form").serialize();
     if (str.length > 0) {
	 	    replaced = str.replace(/&/g,",");
     }
      $("#results").text(replaced);
}

function timeout() {
	var msg = '<%= flash[:message] %>';
	var errormessage = '<%= flash[:errormessage] %>';
	if(msg){
		$('#message').fadeOut(10000,function(){
			$('#message').html("");
		});
	}else if(errormessage){
		$('#errormessage').fadeOut(30000,function(){
			$('#errormessage').html("");
		});
	}
	return false;
}

function viu_parameter_validation(){
	var result = true;
	jQuery.each(nvital_params_json_obj, function(name, parameters) {
		if (parameters["datatype"] != undefined && parameters["datatype"] != "" ) {
			var is_valid = false;
			var value = $("#" + name).val();
			var min = parseInt(parameters["min"]);
			var max = parseInt(parameters["max"]);
						
			switch(parameters["datatype"]){
				case 'integer':
					if((RegExp(parameters["validate"]).test(value)) && ((parseInt(value) >= min) && (parseInt(value) <= max)))
					{
						$("#"+name+"_error").html("").hide();
						is_valid = true;
					}else {
						$("#" + name + "_error").html("Should be in numbers between " + min + " - " + max + ".").show();
						is_valid = false;
					}
					break;
				case 'string':
					if((RegExp(parameters["validate"]).test(value)) && ((value.length >= min) && (value.length <= max)))
					{
						$("#"+name+"_error").html("").hide();
						is_valid = true;
					}else{
						$("#" + name + "_error").html("Should be minimum " + min + " characters and maximun " + max + " characters." ).show();
						is_valid = false;
					}
					break;
				case 'ip':
					if((RegExp(parameters["validate"]).test(value)) && ((value.length >= min) && (value.length <= max)))
					{
						$("#"+name+"_error").html("").hide();
						is_valid = true;
					}else{
						$("#" + name + "_error").html("Should be in XXX.XXX.XXX.XXX format containing only numbers.").show();
						is_valid = false;
					}
					break;	
				case 'boolean':						
					if((RegExp(parameters["validate"]).test(value)) && ((parseInt(value) >= min) && (parseInt(value) <= max)))
					{
						$("#"+name+"_error").html("").hide();
						is_valid = true;
					}else{
						$("#" + name + "_error").html("Should be in boolean.").show();
						is_valid = false;
					}
					break;
				case 'sin':
					if((RegExp(parameters["validate"]).test(value)) && ((value.length >= min) && (value.length <= max)))
					{
						$("#"+name+"_error").html("").hide();
						is_valid = true;
					}else{
						$("#" + name + "_error").html("Should be in 7.XXX.XXX.XXX.XX format containing only numbers.").show();
						is_valid = false;
					}						
					break;
				case 'bytearray':
					min = min * 2;
					max = max * 2;
					if (value.length > 0 || min > 0){
						if ((RegExp(parameters["validate"]).test(value)) && (value.length >= min) && (value.length <= max) && ((value.length % 2) == 0)){
							$("#"+name+"_error").html("").hide();
							is_valid = true;
						}
						else{
							$("#" + name + "_error").html("Should be even number of charactors and in hexa decimal with length " + min + " - " + max + ".").show();
							is_valid = false;
						}
					}
					else{
						$("#"+name+"_error").html("").hide();
						is_valid = true;
					}
					break;
				case 'hex':
					var param_min_len = 0;
					var param_max_len = 0;
					var str_min = parameters["min"];
					var str_max = parameters["max"];
					
					if (RegExp(parameters["validate"]).test(value)){
						if ((str_min.indexOf("0x") >= 0) || (str_min.indexOf("0X") >= 0)){
							param_min_len = str_min.substring(2, str_min.length).length;
						}
						else{
							str_min = Number(str_min).toString(16).toUpperCase();
							param_min_len = str_min.length;
						}
						if ((str_max.indexOf("0x") >= 0) || (str_max.indexOf("0X") >= 0)){
							param_max_len = str_max.substring(2, str_max.length).length;
						}
						else{
							str_max = Number(str_max).toString(16).toUpperCase();
							param_max_len = str_max.length;
						}
						if((value.indexOf("0x") >= 0) || (value.indexOf("0X") >= 0))
						{
							value = value.substring(2,value.length);						
						}
						var int_value = parseInt(value,16);
						min = parseInt(str_min,16);
						max = parseInt(str_max,16);
						if ((value.length >=param_min_len) && (value.length <= param_max_len) && (int_value >= min) && (int_value <= max)){
							$("#"+name+"_error").html("").hide();
							is_valid = true;
						}
						else{
							$("#" + name + "_error").html("Should be in hexa decimal with range of " + str_min + " - " + str_max + ".").show();
							is_valid = false;
						}						
					}
					else{
						$("#" + name + "_error").html("Should be in hexa decimal format.").show();
						is_valid = false;
					}
					break;
				default:
			}

			if(rc2key_changed && $('.rc2key_anchor').val() != $('.rc2key_Confirm').val()){
				is_valid = false;
			}

			if(result){
				result = is_valid;
			}
		}			
	});
	return result;	
}



function init_enabled_show_attr(){
	var attrs = ['enable','show'];

	for(var attrs_i =0; attrs_i<attrs.length;attrs_i++){
		var attr = attrs[attrs_i];

		//indexes through each input/select that has enable or show
		$('input['+attr+'],select['+attr+']').each(function(){
			var t = $(this);
			var expr = $(this).attr(attr);

			if(expr != ''){

				expr = expr.split(']');
				var name = expr[0].split('[')[1];
				var logic = expr[1].split('=')[0]+'=';
				var value_name = expr[1].split('=')[1];

				var input_type = '';

				//determins if the input is a select or input
				if($('select[id="'+name+'"]').length > 0){
					input_selet_w_change_ar[input_selet_w_change_ar.length] = 'select[id="'+name+'"]';

					$('select[id="'+name+'"]').w_change(function(){

						enabled_show_attr();
					});
				}else if($('input[id="'+name+'"]').length > 0){
					input_selet_w_change_ar[input_selet_w_change_ar.length] = 'input[id="'+name+'"]';

					$('input[id="'+name+'"]').w_keyup(function(){
						enabled_show_attr();
					});
				}
			}
		});
	}

	enabled_show_attr();
}

function enabled_show_attr(){

	var attrs = ['enable','show'];

	for(var attrs_i =0; attrs_i<attrs.length;attrs_i++){
		var attr = attrs[attrs_i];

		//indexes through each input/select that has enable or show
		$('input['+attr+'],select['+attr+'],option['+attr+']').each(function(){
			var t = $(this);
			var expr = $(this).attr(attr);

			if(expr != ''){

				expr = expr.split(']');
				var name = expr[0].split('[')[1];
				var logic = expr[1].split('=')[0]+'=';
				var value_name = expr[1].split('=');

				value_name = value_name[value_name.length-1];

				var input_type = '';

				//determins if the input is a select or input
				if($('select[id="'+name+'"]').length > 0){
					input_type = 'select';
				}else if($('input[id="'+name+'"]').length > 0){
					input_type = 'input';
				}

				var enum_val = $(input_type+'[id="'+name+'"]').val();

				if(input_type == 'select'){
					$(input_type+'[id="'+name+'"] option').each(function(){

						var option_val = $(this).attr('value');
						var optoin_html = $(this).html();

						
						if($(this).html() == value_name){
							

							if(logic == '!='){

								if(enum_val != option_val){
									enabled_show_viu_input(t,attr);
								}else{
									disabled_hide_viu_input(t,attr);
								}
							}else if(logic == '='){

								if(enum_val == option_val){
									enabled_show_viu_input(t,attr);
								}else{
									disabled_hide_viu_input(t,attr);
								}
							}else{
								enabled_show_viu_input(t,attr);
							}
						}
					});
				}else{
					if(logic == '!='){

						if(enum_val != value_name){
							enabled_show_viu_input(t,attr)
						}else{
							disabled_hide_viu_input(t,attr);
						}
					}else if(logic == '='){

						if(enum_val == value_name){
							enabled_show_viu_input(t,attr);
						}else{
							disabled_hide_viu_input(t,attr);
						}
					}else{
						enabled_show_viu_input(t,attr);
					}
				}
			}
		});	
	}

	$('.viu_non_vital_wrapper').custom_scroll(430);  
}

function enabled_show_viu_input(t,attr){
	if(attr=='enable'){
		t.removeAttr('disabled');
		t.removeClass('disabled');
	}else{
		if(t.is('option')){
			t.show();
		}else{
			t.closest('.nv_row').show();
		}
	}
}

function disabled_hide_viu_input(t,attr){
	if(attr=='enable'){
		t.attr('disabled','disabled');
		t.addClass('disabled');
	}else{
		if(t.is('option')){
			t.hide();
		}else{
			t.closest('.nv_row').hide();
		}
	}
}

function reorder_inputs(){
	if($('#myform1').find('input[display_order], select[display_order]').index() != -1){
		$('#myform1').append('<input type="hidden" name="reorder_params" value="true"/>')
		var input_i = 0;
		$('#myform1').find('input[name], select[name]').each(function(){
			var name = $(this).attr('name');
			if(name != 'tagname' && name != 'reorder_params'){
				name = name+'_'+input_i
				$(this).attr('name',name);
				input_i++;
			}
		});

		$('#myform1').find('input[display_order], select[display_order]').each(function(){
			var new_order = parseInt($(this).attr('display_order'))
			if(new_order > -1){
				var row_relocate = $(this).closest('.nv_config_generic_wrapper')

				row_relocate.insertBefore($('.nv_config_generic_wrapper').eq(new_order))
			}
		})
	}
}
