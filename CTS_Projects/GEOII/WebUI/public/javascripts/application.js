var timer_flag = true;
var ptc_page;

var check_atcs_sec_interval = null;

function trim(stringToTrim){
   	return stringToTrim.replace(/^\s+|\s+$/g, "");
}

function validate_integer(event, decimal){
	// Allow: backspace, delete, tab, escape, and enter
    if (event.keyCode == 46 || event.keyCode == 8 || event.keyCode == 9 || event.keyCode == 27 || event.keyCode == 13 ||
    // Allow: Ctrl+A
    (event.keyCode == 65 && event.ctrlKey === true) ||
    // Allow: home, end, left, right
    (event.keyCode >= 35 && event.keyCode <= 39) ||
	// all decimals if decimal parameter is true
	(decimal && (event.keyCode == 190 ||event.keyCode == 110)) ||
    // Allow: -
    (event.keyCode == 189 || event.keyCode == 109 || event.keyCode == 173)) {
        // let it happen, don't do anything
        return;
    }
    else {
        // Ensure that it is a number and stop the keypress
        if (event.shiftKey || (event.keyCode < 48 || event.keyCode > 57) && (event.keyCode < 96 || event.keyCode > 105)) {
            event.preventDefault();
        }
    }
}

function validate_float(t,event,places){
	// Allow: backspace, delete, tab, escape, and enter
    if (event.keyCode == 46 || event.keyCode == 8 || event.keyCode == 9 || event.keyCode == 27 || event.keyCode == 13 ||
    // Allow: Ctrl+A
    (event.keyCode == 65 && event.ctrlKey === true) ||
    // Allow: home, end, left, right
    (event.keyCode >= 35 && event.keyCode <= 39)) {
        // let it happen, don't do anything
        return;
    }else if((event.which == 190 || event.which == 110)){
    	//allows only one decimal
    	if(t.val().indexOf('.') == -1){
    		return;
    	}else{
    		event.preventDefault();
    	}
    }else {
        // Ensure that it is a number and stop the keypress
        if (event.shiftKey || (event.keyCode < 48 || event.keyCode > 57) && (event.keyCode < 96 || event.keyCode > 105)) {
            event.preventDefault();
        }
    }
}

/*Validations for SIN*/
function sin_validation(sin_value) {
     if(sin_value.length > 16){
        return "SIN should not be morethan 16 characters"
     }
     if(!(/^7/i.test(sin_value))){
        return "SIN should start with 7.";
     }
     if(!(/^[0-9\ .]{0,16}$/i.test(sin_value))){
        return "SIN should contain only numbers and '.'";
     }
     if(!/^7\.(\d{3})\.(\d{3})\.(\d{3})\.(\d{2})$/i.test(sin_value)){
        return "SIN should be in 7.XXX.XXX.XXX.XX format, <br>X containing only numbers";
     }
     return "";
}
/*End of SIN validations*/


function update_offset_values(remote_sin, actual_sin, sin_erro_msg, class_name){
    var sin_arr = remote_sin.split('.');
    var actual_arr = actual_sin.split('.');
    var actual_val = 0;
    var offset_val = 0;
    var ele_min = 0;
    var ele_max = 0;
    var ele_val = 0;
    var val_flag = true;
    var error_flag = false;
    var ele_id = "";
    var int_param_type = "";
    var valid_sin = false;
    var display_msg = "";

    $(class_name).each(function(index, ele){
        if(!error_flag){
            ele_id = $(ele).attr('id');
            ele_min = parseInt($("#"+ele_id).attr('min'),10);
            ele_max = parseInt($("#"+ele_id).attr('max'),10);
            val_flag = true;
            if (ele_id.toLowerCase() == "rrroffset")
            {
                int_param_type = $(this).attr('int_param_type');
                ele_val = sin_arr[1] - actual_arr[1];
                actual_val = actual_arr[1];
                offset_val = sin_arr[1];
                ele_min = 0;
                ele_max = 999;
            }
            else if (ele_id.toLowerCase() == "llloffset")
            {
                int_param_type = $(this).attr('int_param_type');
                ele_val = sin_arr[2] - actual_arr[2];
                actual_val = actual_arr[2];
                offset_val = sin_arr[2];
                ele_min = 0;
                ele_max = 999;
            }
            else if (ele_id.toLowerCase() == "gggoffset")
            {
                int_param_type = $(this).attr('int_param_type');
                ele_val = sin_arr[3] - actual_arr[3];
                actual_val = actual_arr[3];
                offset_val = sin_arr[3];
                ele_min = 0;
                ele_max = 999;
            }
            else if (ele_id.toLowerCase() == "ssoffset")
            {
                int_param_type = $(this).attr('int_param_type');
                ele_val = sin_arr[4] - actual_arr[4];
                actual_val = actual_arr[4];
                offset_val = sin_arr[4];
                ele_min = 0;
                ele_max = 99;
            }
            else{
                val_flag = false;
            }

            if (val_flag){
                if(offset_val <= ele_max){
                    if (int_param_type == "unsigned"){
                        if(ele_val < 0){
                            ele_val = 32768 - ele_val;
                        }
                    }
                    $("#"+ele_id).val(ele_val);
                }
                else{
                    display_msg = "<span style='color:red;'> Remote SIN " + ele_id + " Value must be with in the range of 0 to "+ ele_max + " </span>";
                    error_flag = true;
                }
            }
        }
    });
    if (!error_flag){
        $(sin_erro_msg).html("");
        $(sin_erro_msg).show();
        return true;
    }
    else
    {
        return false;
    }
}


// Ajax request to get the Site information for CPUII
function make_header_request(){
    $.ajax({
        url: '/application/make_header_request',
        data: "",
        dataType: 'json',
        beforeSend: function(){
        },
        success: function(request_id){
        	if(parseInt(request_id) != -1){
	            var request_progress = false;
				var delete_request = false;
				var req_counter = 0;
	            var header_info_interval = setInterval(function(){
	                if((!request_progress)){
	                    request_progress = true;
	                    $.post('/application/check_header_status', {request_id: request_id, delete_request: delete_request}, function(response){
	                        req_counter += 1;
							if (response.request_state == 2) {
								if ($('#site_name_hdr').length > 0) {
									$('#site_name_hdr').html(response.sname_4000);
									$('#atcs_address_hdr').html(response.atcs_address_4000);
									$('#mile_post_hdr').html(response.m_post_4000);
									$('#dot_number_hdr').html(response.dot_num_4000);
								}
								else{
									window.parent.document.getElementById("mainheader").innerHTML = "Site Name: " + response.sname_4000 + "| ATCS Address: " + response.atcs_address_4000 + "| Mile Post: " + response.m_post_4000 + "| DOT Number: " + response.dot_num_4000;
								}
								clearInterval(header_info_interval);
							}
							else{
								if (req_counter >= 15) {
									clearInterval(header_info_interval);
									$("#mainheader").html("<span class='error_message'></span>");
								}
							}
							if (req_counter >= 14) {
								delete_request = true;
							}
	                        request_progress = false;
	                    }, 'json');
	                }
	            }, 2000);
			}
        }
    });
}	