/*********************************************************************************
 *  I M M E D I A T E   F U N C T I O N S - VLP/IO  C A R D L O G P A G E 
 *********************************************************************************/
var check_verbosity_status_interval;
var set_geo_event_verbosity_interval;
var check_UDP_req_state_interval;
var checking_request_busy = false;
var downloadinprogress = false;
var requestinprogress = false;
var event_count_timer = 0;
var verbosity_status_xhr = null;
var set_verbosity_status_xhr = null;
var UDP_req_state_xhr = null;

$(document).ready(function(){
	add_to_destroy(function(){
		$(document).unbind("ready");
	
		//kills all events
		$("#log_verbo_level").w_die('change');
		$("#logtype").w_die('change');
		
		//clear intervals
		clearInterval(check_verbosity_status_interval);
		clearInterval(set_geo_event_verbosity_interval);
		clearInterval(check_UDP_req_state_interval);
		
		//cancels previous request if it is still going
		if (typeof verbosity_status_xhr !== 'undefined' && verbosity_status_xhr != null) {
			verbosity_status_xhr.abort();
		}
		if (typeof set_verbosity_status_xhr !== 'undefined' && set_verbosity_status_xhr != null) {
			set_verbosity_status_xhr.abort();
		}
		if (typeof UDP_req_state_xhr !== 'undefined' && UDP_req_state_xhr != null) {
			UDP_req_state_xhr.abort();
		}
		
		//clears functions
		delete window.get_slot_log_verbo;
		delete window.geo_event_logs;
		delete window.all_request;
		delete window.download_report;
		delete window.geo_event_make_request;
		delete window.check_request;
		delete window.request_timeout_actions;
		delete window.downloadURL;
		delete window.cancel_all_event_request;
		delete window.log_in_progress;
		delete window.log_finished;
	
		
		//clears global variables
		delete window.check_verbosity_status_interval;
		delete window.set_geo_event_verbosity_interval;
		delete window.check_UDP_req_state_interval;
		delete window.verbosity_status_xhr;
		delete window.set_verbosity_status_xhr;
		delete window.UDP_req_state_xhr;
	});	

    DebugMsg("===============================================");
    DebugMsg("Loading Geo Event Log Page...");
    DebugMsg("===============================================");
	var atcs_address = $('#geo_event_atcs').val();
	var card_type = $('#card_details').attr('card_type');
	var card_slot = $('#card_details').attr('slot');
	if(atcs_address != ""){
		$("#contentcontents").mask("Loading contents, please wait...");
	    $(this).attr("disabled", "disabled")
	    $('#ajax-loader').show();
	    $.post("/geo_event_log/geo_event_slots", {
			atcs_addr: atcs_address ,
			card_type: card_type,
			card_slot:card_slot
		}, function(response_data){
	            DebugMsg("just loaded index, calling geo_event_slots")
	            $('.geo_event_log').html(response_data);
				$("#contentcontents").unmask("Loading contents, please wait...");
	            $('#ajax-loader').hide();
	            $('#change_track').val("0"); /* setting the prev_direction value to '0' by default */
	            get_slot_log_verbo();
	    });
	}
}); 

/*********************************************************************************
 *  F U N C T I O N S
 *********************************************************************************/
/*
 * Trigger a log update when the type dropdown is changed
 */
$("#logtype").w_change(function(){
    get_slot_log_verbo();
});


/*
 * Change the log verbosity, trigger log update
 */
$("#log_verbo_level").w_change(function(){
	  DebugMsg("Changed Verbosity Level")
	  $('.ajax-loader').show();
	  $('#ajax_spinner').show();
	  $("#clear_button").hide();
	  $('#geo_log_update').html('');
	  $('#logtype').attr("disabled", "disabled");
	  $('#log_verbo_level').attr("disabled", "disabled");
	  var atcs_addr  = $('#geo_event_atcs').attr('value');
	  var card_slot  = $('#card_details').attr('slot');
	  var card_type  = $('#card_details').attr('card_type');
	  var log_verbo_level =  $('#log_verbo_level').attr('value');
	  var RequestID = 0;
	  var set_verbosity_timeout_count = 0;
	  $.post("/geo_event_log/set_geo_event_verbosity",{
        atcs_addr:       atcs_addr,
        card_slot:       card_slot,
        log_verbo_level: log_verbo_level
	  },function(data){
	      DebugMsg("Set Verbosity request made");
	      RequestID = data.request_id;
	      DebugMsg("Request ID = " + RequestID);
	      // Set verbo checking interval
	      checking_verbo_progress = false;
          set_geo_event_verbosity_interval = setInterval(function(){
	          if(!checking_verbo_progress){
	              DebugMsg("Checking Verbosity Request")
	              checking_verbo_progress = true;
	              // Periodical call after update to check the location request state.
	              set_verbosity_status_xhr = $.post('/geo_event_log/set_geo_event_verbosity_status',{
				  	id: RequestID, 
					card_type: card_type
				  },function(log_data){
				  	  set_verbosity_timeout_count ++;
	                  if (log_data != "0" && log_data != "1"){
	                      DebugMsg("4k Verbosity Request Complete")
	                      $("#logtype").removeAttr("disabled");
	                      $('#log_verbo_level').removeAttr("disabled");
	                      clearInterval(set_geo_event_verbosity_interval);
	                      $.post("/geo_event_log/delete_logverbo_req",{request_id: RequestID});
	                      $('#geo_log_update').html('');
						  geo_event_make_request(4);
	                  }else{
					  	  if(set_verbosity_timeout_count >= 10){
						  	   DebugMsg("Verbosity Timeout")
					           $("#logtype").removeAttr("disabled");
					           $('#log_verbo_level').removeAttr("disabled");
					           clearInterval(set_geo_event_verbosity_interval);
					           $.post("/geo_event_log/delete_logverbo_req",{request_id: RequestID});
							   $('.ajax-loader').hide();
							   $('#ajax_spinner').hide();
							   $('#geo_log_update').html("<h2 class='display_information'>Verbosity Set Timeout</h2>");
						   }
					  }
	                  checking_verbo_progress = false;
	              });
	          }
          }, 2000);
	  });  
});

function get_slot_log_verbo() {
	$('#geo_log_update').html("");
	$(".dl_link_style").addClass('disable');
    var atcs_addr  = $('#geo_event_atcs').val();
    var card_index = $('#card_details').attr('card_index');
    var card_type  = $('#card_details').attr('card_type');
    var card_slot  = $('#card_details').attr('slot');
    var check_verbo_state = false;
    var RequestID = 0;
    $('#logtype').attr("disabled", "disabled");
    $('#log_verbo_level').attr("disabled", "disabled");
    $('.ajax-loader').show();
	$('#ajax_spinner').show();
    $.post("/geo_event_log/get_log_verbosity",{    
		atcs_addr:        atcs_addr,
        card_index:       card_index,
        card_type:        card_type,
        card_slot:        card_slot,
        information_type: 10
    },function(response_data){
        RequestID = response_data.request_id;
		var get_verbosity_timeout_count = 0;
		DebugMsg("Initial Verbosity request made, request = " + RequestID)
        // Get verbo checking interval

        if(RequestID != -1){
	        check_verbosity_status_interval = setInterval(function(){
	            if (check_verbo_state == false){
	                check_verbo_state = true;
	                DebugMsg("Checking Verbosity Request");
	                verbosity_status_xhr = $.post("/geo_event_log/check_verbo_state",{
	                     atcs_addr:  atcs_addr,
	                     id:         RequestID,
	                     card_index: card_index,
	                     card_slot: card_slot,
	                     card_type:  card_type
	                },function(response_data){
						get_verbosity_timeout_count ++;
						DebugMsg("check_verbo_state response:  " + response_data)
	                    DebugMsg("response_data.request_state :  " + response_data.request_state)
	                    if (response_data.request_state == 2){
	                    	if(typeof response_data.message === "undefined"){
								$(".dl_link_style").removeClass('disable');
		                        $("#logtype").removeAttr("disabled");
		                        $('#log_verbo_level').removeAttr("disabled");
		                        clearInterval(check_verbosity_status_interval);
		                        $('#log_verbo_level').find("option[value=" + response_data.slot_verbosity + "]").attr('selected', 'selected');
		                        $('.ajax-loader').hide();
								$('#ajax_spinner').hide();
		                        $.post("/geo_event_log/delete_geo_io_status_req_rep_vals",{
									request_id: RequestID
								},function(){
		                            geo_event_make_request(4, this);
		                        });
		                    }else{
		                    	$(".dl_link_style").removeClass('disable');
								DebugMsg("Initial Verbosity Timeout")
								$("#logtype").removeAttr("disabled");
								$('#log_verbo_level').removeAttr("disabled");
								clearInterval(check_verbosity_status_interval);
								$('.ajax-loader').hide();
								$('#ajax_spinner').hide();
								$('#geo_log_update').html('');
								$('#geo_log_update').html("<h2 class='display_information'>"+response_data.message+"</h2>");
		                    }
	                	}else{
							if(get_verbosity_timeout_count >= 10) {
								$(".dl_link_style").removeClass('disable');
								DebugMsg("Initial Verbosity Timeout")
								$("#logtype").removeAttr("disabled");
								$('#log_verbo_level').removeAttr("disabled");
								clearInterval(check_verbosity_status_interval);
								$.post("/geo_event_log/delete_geo_io_status_req_rep_vals", {
									request_id: RequestID
								});
								$('.ajax-loader').hide();
								$('#ajax_spinner').hide();
								$('#geo_log_update').html('');
								$('#geo_log_update').html("<h2 class='display_information'>Initial Verbosity Check Timeout</h2>");
							}
						}
	                    check_verbo_state = false;
	                }); // end of check_verbo_state post
	        	}
	    	}, 2000); // end set interval
		}else{
			$('.ajax-loader').hide();
			$('#ajax_spinner').hide();
			$('#geo_log_update').html('');
			$('#geo_log_update').html("<h2 class='display_information'>Log request failed please try again</h2>");

		} // end request != -1
    });  // end of get_log_verbosity post
}  // end of: function get_slot_log_verbo() {

function geo_event_logs(req_id){
    DebugMsg("geo_event_logs start")
    if(req_id){
       $.get('/geo_event_log/geo_event_logs',{
	   	   request_id:req_id
	   },function(data){
           DebugMsg("geo_event_logs return")
           $('#geo_log_update').html(data);
		   $(".dl_link_style").removeClass('disable');
           $('.ajax-loader').hide();
		   $('#ajax_spinner').hide();
		   $("#clear_button").show();
           $("#logtype").removeAttr("disabled");
           $("#geo_event_atcs").removeAttr("disabled");
           $("#all_events").removeAttr("disabled");
           $('#log_verbo_level').removeAttr("disabled");
      });
    }
    requestinprogress = false;
    downloadinprogress = false;
}

/*
 * Set up view for download function
 */
function all_request(){
	if (!$(".dl_link_style").hasClass('disable')) {
		if (downloadinprogress == false) {
			$(".dl_link_style").addClass('disable');
			downloadinprogress = true;
			geo_event_make_request(10, "All");
			$("#geo_log_update").html("");
			$('#geo_log_update').html("");
			$("#verbositydiv").hide();
			$("#first_icon").hide();
			$("#last_icon").hide();
			$("#next_icon").hide();
			$("#previous_icon").hide();
			$("#geo_download_icon").hide();
			$("#clear_button").hide();
			$("#cancel_all_event").show();
		}
	}
}

/*
 * Downloads the report that was created with "All Events"
 */
function download_report(){
    DebugMsg("Download button pressed");
    $.post("/geo_event_log/get_mile_post_val", {}, function(response){
		 var download_path = "/geo_event_log/download_txtfile?logtype=" + $('#logtype').val() +
                              "&slot_number=" + $('#card_details').attr('slot') + "&mile_post=" + response.mile_post;
         downloadURL(download_path);
	});
    // Clear downloading in progress messages
    $('#geo_log_update').html("<h1 class='display_information'>Download Complete</h1>");
    $('.ajax-loader').hide();
	$('#ajax_spinner').hide();
    $("#logtype").removeAttr("disabled");
    $("#first_icon").show();
    $("#last_icon").show();
    $("#next_icon").show();
    $("#previous_icon").show();
    $("#geo_download_icon").show();
    $("#verbositydiv").show();
	$(".dl_link_style").removeClass('disable');
    requestinprogress = false;
    downloadinprogress = false;
}



/*
 * Creates a log request and starts periodic checking of request progress
 */
function geo_event_make_request(cmd, slot){
  if(requestinprogress == false){
  	clearInterval(check_UDP_req_state_interval);
  	$(".dl_link_style").addClass('disable');
    // Number of display elements
    numofevents = 20
    //prevent multiple requests
    requestinprogress = true;
    DebugMsg("geo_event_make_request, cmd = " + cmd);
    $('.ajax-loader').show();
	$('#ajax_spinner').show();
    $('#geo_log_update').html('');
    // Check for download command
    if(cmd != 10){
      $("#first_icon").show();
      $("#last_icon").show();
      $("#next_icon").show();
      $("#previous_icon").show();
      $("#geo_download_icon").show();
      $("#verbositydiv").show();
    }else{
      // On download event, this is initial number of to show received events
      numofevents = 5
	  log_in_progress();
	}
        
    $.ajax({
      type: "post",
      url:  "/geo_event_log/geo_event_udp_call",
      data: { atcs_addr:  $('#geo_event_atcs').attr('value'),
              cmd:        cmd,
              logtype:    $('#logtype').attr('value'),
              slot:       $('#card_details').attr('slot'),
              num_events: numofevents},
      success: function(result){
              DebugMsg("geo_event_make_request returning- geo_event_udp_call")
              DebugMsg("request_id = " + result.request_id)
              $('#logtype').attr("disabled", "disabled");
              $('#log_verbo_level').attr("disabled", "disabled");
			  $(".dl_link_style").addClass('disable');
              check_request(result.request_id)
      }
    });
  }
}

/*
 * Check to see if the request made by "geo_event_make_request" is complete
 */
function check_request(reqID){
  DebugMsg("check_request, reqID = " + reqID);
  var check_udp_req_timeout_count = 0;
  check_UDP_req_state_interval = setInterval(function(){
	  if(checking_request_busy == false){
		    checking_request_busy = true;
		    UDP_req_state_xhr = $.post("/geo_event_log/check_UDP_req_state",{
		        request_id: reqID
		    },function(result){
				 check_udp_req_timeout_count ++;
	             // Display number of events being processed if it's a download all request
				 var event =  $('#current_event_count').attr('value');
				 var timeout =  $('#log_download_timeout').attr('value');
				 DebugMsg("check_request: result.reqstate = " + result.reqstate +'Count'+((timeout*60)/3)+':'+event_count_timer);
				 if ((event_count_timer >= (timeout*60)/3)  && (result.command == 10)) {
				 	log_finished();
				 	$(".dl_link_style").removeClass('disable');
				  	clearInterval(check_UDP_req_state_interval);
					request_timeout_actions(reqID);
				 }else{
				  	 if (result.command == 10) {
					 	$('#ajax_spinner').hide();
						$('#current_event_count').attr('value', result.numofevents)
						if ((event) && (event != result.numofevents)) {
							event_count_timer = 0;
						}
						event_count_timer ++;
	                    var count_val = 0;
						if(result.numofevents){
							count_val = result.numofevents ;
						}
						$('#geo_log_update').html("<span class='text_white text_font'>Number of Events : " + count_val + "</span>");
	              	  }
		              // Check if request is complete
		              if(result.reqstate == 2){
					  	
					  	$(".dl_link_style").removeClass('disable');
		                clearInterval(check_UDP_req_state_interval);
		                DebugMsg("request complete");
		                // Check if it was a download all command
		                if (result.command == 10) {
							log_finished();
							$("#cancel_all_event").hide();
							download_report();
						}else {
							geo_event_logs(reqID);
						}
		              }else if(result.reqstate == -1){
					  	log_finished();
					  	$('.ajax-loader').hide();
  						$('#ajax_spinner').hide();
		                // Render error message
						$(".dl_link_style").removeClass('disable');
		                clearInterval(check_UDP_req_state_interval);
		                DebugMsg("Request was not found");
						$('#geo_log_update').html('');
						$('#geo_log_update').html("<h2 class='display_information'>Request was not found</h2>");
		              }else{
					  	if((check_udp_req_timeout_count >= 10) && (result.command != 10 )){
							clearInterval(check_UDP_req_state_interval);
						 	request_timeout_actions(reqID);
						 }
					  }
		              checking_request_busy = false;
				  }
			});
		}
	},2000)
}

// Clear the timeout, adjust display and clean up request records
function request_timeout_actions(RequestID){
   DebugMsg("Check Request Timeout...")
   // clear timers and reset busy flag
   checking_request_busy = false;

   // Remove any disabled controls, remove ajax spinner
   $('.ajax-loader').hide();
   $('#ajax_spinner').hide();
   $("#logtype").removeAttr("disabled");
   $('#log_verbo_level').removeAttr("disabled");
   // Delete request ID and any related elements
   $.post("/geo_event_log/delete_geo_event_log_request_reply",{request_id: RequestID});

   // Display error message
   $('#geo_log_update').html('');
   $('#geo_log_update').html("<h2 class='display_information'>Event Request Timeout</h2>");
    
   // show the tool bar buttons and hide the cancel button
   $("#first_icon").show();
   $("#last_icon").show();
   $("#next_icon").show();
   $("#previous_icon").show();
   $("#geo_download_icon").show();
   $("#verbositydiv").show();
   $("#cancel_all_event").hide();
   requestinprogress = false;
}

// Download the requested file and display
function downloadURL(dl_url) {
    var iframe;
    var hiddenIFrameID = 'hiddenDownloader';
    iframe = document.getElementById(hiddenIFrameID);
    if (iframe === null) {
        iframe = document.createElement('iframe');
        iframe.id = hiddenIFrameID;
        iframe.style.display = 'none';
        document.body.appendChild(iframe);
    }
    iframe.src = dl_url;
}

// Cancel the all events download process
function cancel_all_event_request(){
	$.post("/geo_event_log/cancel_all_event_request", {});
}

function log_in_progress(){
	preload_page = function(){
		ConfirmDialog('Logs', 'Your request to download logs is not complete.<br>Would you like to leave anyways?', function(){
			if (typeof UDP_req_state_xhr !== 'undefined' && UDP_req_state_xhr != null) {
				UDP_req_state_xhr.abort();
			}
			cancel_all_event_request();
			preload_page_finished();
			preload_page = '';
		}, function(){
		//don't load the next page
		});
	};
}

function log_finished(){
	preload_page = '';
}

/*
 * An easy way to turn console.log debugging messages on or off
 */
var DebugON = false;
function DebugMsg(message){
    if(DebugON)
        console.log(message);
}
