 /**
 * @author NNSV
 */      
// Delay Times (in msecs)
var CheckReqDelay = 2000;
var TimeoutDelay  = 30000;

// Global variables used by javascripts
var TimersStarted = false;
var ReqTimerID;
var ReqTimeoutID;

var auto_refresh_process = false;
var auto_refresh = null;
var req_obj = null;
var replies_xhr_request = null;
var req_aborted = false;

$(document).ready(function(){
	add_to_destroy(function(){
		$(document).bind("ready",function(){});

		//kills all wrapper events
		$('.get_properties').w_die('click');
		$('.set_properties').w_die('click');
		$('#download_logicstates').w_die('click');
		$("#first_value").w_die('keyup');
		$("#last_value").w_die('keyup');
		$("#range_submit").w_die('click');

		//clear intervals
		clearTimeout(auto_refresh);
		clearInterval(auto_refresh);
		if(typeof req_obj !== 'undefined' && req_obj != null){
	        req_obj.abort();  //cancels previous request if it is still going
	    }	
	    if(typeof replies_xhr_request !== 'undefined' && replies_xhr_request != null){
	        replies_xhr_request.abort();  //cancels previous request if it is still going
	    }

		//clears global variables
		auto_refresh = null;
		req_aborted = true;
	});
	
	var request_progress = false;
	var geo_non_am = false;
	stop_system_state_replies();
	req_aborted = true;
		
	var atcs_addr = $("#atcs_addr").val();
	if (atcs_addr == "") {
		$('.mcf').html("");
		$(".set_properties").attr("disabled", "disabled").addClass("disabled_buttons");
		$(".get_properties").attr("disabled", "disabled").addClass("disabled_buttons");
		$(".download_properties").attr("disabled", "disabled").addClass("disabled_buttons");
		$(".set_properties").hide();
		$(".get_properties").hide();
		$(".download_properties").hide();
		geo_non_am = false;
	}else {
	    $('#ajax-loader').show();
	    $(this).attr("disabled", "disabled")
	    $.post("/system_state/system_states", {atcs_addr: atcs_addr}, function(response){
			if (response.non_am) {
				$('.mcf').html(response.data);
				geo_non_am = true;
				$('#ajax-loader').hide();
				$("#atcs_addr").removeAttr("disabled");
				$(".set_properties").hide();
				$(".get_properties").hide();
				$(".download_properties").hide();
			}
			else {
				geo_non_am = false;
				$('.mcf').html(response.data);
				$('#ajax-loader').hide();
				$("#atcs_addr").removeAttr("disabled");
				$(".get_properties").show();
				$(".set_properties").show();
				$(".download_properties").show();
			}
	    });
	}
	
	$(".get_properties").w_click(function(){
		stop_system_state_replies();
		$('.mcfcontent_data').html('');
		if (!$(this).attr("disabled")) {
			if (!geo_non_am) {
				$(".set_properties").attr("disabled", "disabled");
				$(".download_properties").attr("disabled", "disabled");
				var name = $("#system_state_name").val();
				var parent_name = $("#system_state_parent_name").val();
				var sat_index = $("#system_state_sat_index").val();
				var atcs_addr = $('#atcs_addr').val();
				var system_state_req = "/system_state/get_system_replies";
				if (sat_index != "" && name != "") {
					$('.ajax-loader').show();
					replies_xhr_request = $.post(system_state_req, {
						atcs_addr: atcs_addr,
						sat_index: sat_index,
						name: name,
						parent_name: parent_name
					}, function(data){
						$('.mcfcontent_data').html(data);
						$(".set_properties").removeAttr("disabled");
						$("#download_logicstates").removeAttr("disabled");
						$(".download_properties").removeAttr("disabled").removeClass("disabled_buttons");
						$('.ajax-loader').hide();
						req_aborted =  false;
						if (data.indexOf("Request Timed Out") < 0){
							 auto_refresh = setInterval(function(){
							 	if(!req_aborted){
									auto_refresh_system_state();
								}else{
									stop_system_state_replies();
								}
							}, 8000);
						}
					});
				}
			}	
		}
	});
	
	$(".set_properties").w_click(function(){
                stop_system_state_replies();
		req_aborted = true;
		
		if(!$(this).attr("disabled")){
			var atcs_addr = $('#atcs_addr').val();
			if (geo_non_am) {
				$.post("/system_state/system_states", {atcs_addr: atcs_addr}, function(response){
					if (response.non_am) {
						$('.mcf').html(response.data);
						geo_non_am = true;
						$('#ajax-loader').hide();
						$("#atcs_addr").removeAttr("disabled");
						$("#download_logicstates").removeAttr("disabled");
						$(".set_properties").hide();
						$(".download_properties").hide();
					}
				});
			}
			else {
				$(".get_properties").attr("disabled", "disabled");
				var name = $("#system_state_name").val();
				var sat_index = $("#system_state_sat_index").val();
				$('.ajax-loader').show();
				$.post("/system_state/set_range", {
					sat_index: sat_index,
					name: name,
					atcs_addr: atcs_addr
				}, function(data){
					$('.mcfcontent_data').html(data);
					$(".get_properties").removeAttr("disabled");
					$("#download_logicstates").removeAttr("disabled");
					$(".download_properties").removeAttr("disabled").removeClass("disabled_buttons");
					$('.ajax-loader').hide();
				});
			}		
		}
	});
	
	$("#download_logicstates").w_click(function(){
		top.document.getElementById('download_iframe').src = "/system_state/download_logic_state";		
	});	

 	$("#first_value").w_keyup(function(){
		if (validate_rage_fields(this, 'First')){
			$("#contentactionbar").removeClass('disabled');
		}
		else{
			$("#contentactionbar").addClass('disabled');
		}
	});
 
 	$("#last_value").w_keyup(function(){
		if (validate_rage_fields(this, 'Last')){
			$("#contentactionbar").removeClass('disabled');
		}
		else{
			$("#contentactionbar").addClass('disabled');
		}
	});
	
	$("#range_submit").w_click(function(event){
			event.preventDefault();
			$(".set_properties").attr("disabled", "disabled");
			$(".get_properties").attr("disabled", "disabled");
			$(".download_properties").attr("disabled", "disabled");
			var atcs_addr = $('#atcs_address').val();
			var min = $("#first_value").val();
			var max = $("#last_value").val();
			var url = "/system_state/set_range_values";
			var non_am = $("#non_am").val();
			if (non_am == "true")
				$('#ajax-loader').show();
			else
				$('.ajax-loader').show();
			$.post(url, {atcs_addr: atcs_addr, min: min, max: max, non_am: non_am}, function(data){
				$('.mcfcontent_data').html(data);
				$(".set_properties").removeAttr("disabled");
				$(".get_properties").removeAttr("disabled");
				$(".download_properties").removeAttr("disabled");
				if (non_am == "true") {
					$(".set_properties").show();
					$(".set_properties").removeClass("disabled_buttons");
					$(".download_properties").show();
					$(".download_properties").removeClass("disabled_buttons");
					$('#ajax-loader').hide();
				}
				else
					$('.ajax-loader').hide();	
			});
		});

}); 

// /*
 // * Clean up databases upon leaving page
 // */
// $(window).unload(function(){
	// DebugMsg("Leaving Searlog page...");
// 	
	// jQuery.ajax({
		// url: '/system_state/database_cleanup',
		// type: 'POST',
		// async: false,
		// dataType: 'JSON',
		// data:{ requestid:  $('#current_request_id').attr('value') },
		// beforeSend: function(){ 
						// DebugMsg("AJAX Call: cleaning up databases...")				
						// },
		// success: function() {
					// DebugMsg("AJAX Success: database cleanup complete")
					// }
	// });
// 	
// });

/*********************************************************************************
 *  F U N C T I O N S
 *********************************************************************************/
 function auto_refresh_system_state(){
	if(auto_refresh_process == false){
		var name = $("#system_state_name").val();
		var parent_name = $("#system_state_parent_name").val();
		var sat_index = $("#system_state_sat_index").val();
        var req_id = $("#system_state_req_id").val();
		var atcs_addr = $('#atcs_addr').val();
		var system_state_req = "/system_state/get_system_replies";
		if (sat_index != "" && name != "") {
			$('.ajax-loader').show();
			auto_refresh_process = true;
			req_obj = $.post(system_state_req, {
				atcs_addr: atcs_addr,
				sat_index: sat_index,
				name: name,
				auto_refresh: true,
				req_id: req_id,
				parent_name: parent_name
			}, function(data){
				if (!req_aborted) {
					if (data != "No Change") {
						$('.mcfcontent_data').html(data);
					}
					$(".set_properties").removeAttr("disabled");
					$("#download_logicstates").removeAttr("disabled");
					$('.ajax-loader').hide();
				}
				auto_refresh_process = false;
			});
		}
	}
 }
 
 function stop_system_state_replies(){
 	clearTimeout(auto_refresh);
	clearInterval(auto_refresh);
	
	if(typeof replies_xhr_request !== 'undefined' && replies_xhr_request != null){
        replies_xhr_request.abort();  //cancels previous request if it is still going
    }
	if(typeof req_obj !== 'undefined' && req_obj != null){
        req_obj.abort();  //cancels previous request if it is still going
    }
    
    	
 }

 /*
  * Validating range field values.
  */
 function validate_rage_fields(obj, str){
 	var element = $(obj);
 	var first_val = $("#first_value").val();
	var second_val = $("#last_value").val();
	var validate_flg = false;
	
	var intRegex = /^[0-9]+$/;
	if (!intRegex.test(first_val) || !intRegex.test(second_val)) {
		element.addClass("error");
		$("#range_error_message").html("Invalid format!! number only allowed.");		
	}
	else if (!((parseInt(first_val) > 0) && (parseInt(first_val) < 15000))){
		element.addClass("error");
		$("#range_error_message").html("First logic state should be in the range of 1 to 14999");
	}else if ((parseInt(first_val) > parseInt(second_val)) || (parseInt(second_val) > 15000)){
		element.addClass("error");
		if (str == "First")
			$("#range_error_message").html("First logic state should be less then Last logic state and greater then or equal to 1.");
		else
			$("#range_error_message").html("Last logic state should be greater then First logic state and less then or equal to 15000.");
	}else if((parseInt(second_val) - parseInt(first_val)) > 599){
		element.addClass("error");
		$("#range_error_message").html("Maximum largest states(range) should be 600");
	}else{
		$("#range_error_message").html("&nbsp;");
		$("#first_value").removeClass("error");
		$("#last_value").removeClass("error");
		validate_flg = true;
	}
	$("#hd_validate_flg").attr('value', validate_flg);
	return validate_flg;
 }

/* 
 * Call action to create a new request
 */
function create_request()
{
    TimersStarted = false;
	if ($("#hd_validate_flg").val() == 'false'){
		return false;
	}
    // Update page visuals
    $('#log_status_info').html('<div class ="warning_message">&nbsp;Requesting States....</div>');    
    
    // Make call to appropriate controller action
    jQuery.ajax({
        type:      'POST',
        url:       '/system_state/create_log_request',
        dataType:  'JSON',
        data:{ requestid: $('#current_request_id').attr('value'),
               start_num: $('#first_value').attr('value'),
               end_num:   $('#last_value').attr('value')},
        
        success: function(result)
        {   
            $('#current_request_id').attr('value', result.req_id);
            start_request_timers();
                                            
            if(result.req_state == -1)
            {
                // Stop timers
                stop_request_timers();
                // Display Error Message
                $('#log_status_info').html('<div class ="error_message">&nbsp;Error creating request.</div>');                     
            }                   
        }
    });
}

/* 
 * Called action to check request status and execute conditions
 * based on returned result.
 */
 var flag = true; 
function get_request_status()
{
    if(flag){
        flag = false;
            
        // Make call to appropriate controller action
        jQuery.ajax({
            type:       'POST',
            url:        '/system_state/check_request_status',
            dataType:   'JSON',
            data:       { requestid: $('#current_request_id').attr('value') },
            
            success: function(result)
            { 
                // Verify a Timeout did not occur
                if(TimersStarted == true)
                {
                    // Check to see if request was completed
                    if(result.req_state == 2)
                    {
                        
                        // Stop timers
                        stop_request_timers();
                        
                        // Clear status information
                        $('#log_status_info').html('<div class ="warning_message">&nbsp;Loading States....</div>');
                            
                        // Show table
                        $('#log_table').show();

                        // Call action to get logic states data
                        get_logic_states_data();
                    }
                    else if(result.req_state == -2)
                    {
                        // Stop timers
                        stop_request_timers();
                        // Display Error Message
                        $('#log_status_info').html('<div class ="error_message">&nbsp;Error checking request status... Request does not exist</div>');                     
                    }
                }
                flag = true;
            }
        });
    }
}

/*
 * Gets data and partial to display logic state data. 
 */
function get_logic_states_data()
{
    jQuery.ajax({
        url:        '/system_state/get_logic_state_data',
        type:       'POST',
        dataType:   'JSON',
        data:       { requestid:  $('#current_request_id').attr('value')},
        beforeSend: function(){
                    },
        success:    function(result){
                        $('#log_status_info').html('');
                        $("#log_table").html(result); 
                        custum_scroll(460,$("#log_table"));
                    }
    });
}

/*
 * Clear request timers and display error timeout message.
 */
function request_timeout_occured()
{   
    // Stop timers
    stop_request_timers();
    
    // Display timeout message
    $('#log_status_info').html('<div  class ="error_message">&nbsp;Request Timeout...</div>');
}


/*
 * Start request timers.  Includes a periodic timer to check request status
 * and a timeout timer to prevent periodic timer from running forever.
 */
function start_request_timers()
{
    if(TimersStarted == false)  
    {
        ReqTimerID   = setInterval(function(){ get_request_status() }, CheckReqDelay);
        ReqTimeoutID = setTimeout(function(){ request_timeout_occured() }, TimeoutDelay);
        TimersStarted = true;
    }       
}
 
/*
 * Stop request timers.  Periodic and timeout timers are cleared and
 * conditions reset for next use
 */
function stop_request_timers()
{   
    clearInterval(ReqTimerID);
    clearTimeout(ReqTimeoutID);
    TimersStarted = false;      
}

function download_data()
{
	if ($("#hd_validate_flg").val() == 'false'){
		return false;
	}
    window.location.href = "system_state/download_txtfile/0?requestid="+ $('#current_request_id').attr('value')
}
