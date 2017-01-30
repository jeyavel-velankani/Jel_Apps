/**
 * @author Jeyavel Natesan
*/

var check_log_req_status_interval;
var event_count_timer = 0;
var log_request_inprogress = false;
var log_req_status_xhr = null;	
var req_inprogress = true;

$(document).ready(function(){
	add_to_destroy(function(){
		$(document).bind("ready",function(){});
		
		//kills all events
		$('.log_dl_link').w_die('click');
		$('#dup_q').w_die('keyup');
		$('#clear_button').w_die('click');
		$(".set_filter").w_die('click');
		$(".logs a").w_die('click');
		$(".add_row").w_die('click');
		$(".row_delete").w_die('click');
		$("#new_log_filter").w_die('submit');
		$('#log_filter').w_die('change');
		
		//cancels previous request if it is still going
		if (typeof log_req_status_xhr !== 'undefined' && log_req_status_xhr != null) {
			log_req_status_xhr.abort();
		}
		
		//clear intervals
		if (typeof check_log_req_status_interval !== 'undefined' && check_log_req_status_interval != null) {
			clearInterval(check_log_req_status_interval);	
		}
		
		//clears functions
		delete window.get_event_details;
		delete window.make_request;
		delete window.do_log_search;
		delete window.check_request_log_status;
		delete window.download_selected;
		delete window.downloadURL;
		delete window.dropdown_hover;
		delete window.log_in_progress;
		delete window.log_finished;
	
		//clears global variables
		delete window.check_log_req_status_interval;
		delete window.log_req_status_xhr;
		delete window.req_inprogress;
		
		//removes and kills the functionality of the scroll bar
		$('.nv_config_wrapper').remove_custom_scroll();
	});

	$('#log_updater').html("");
	$("#log_update").remove_custom_scroll();
    $("#log_update").custom_scroll(430);
    make_request('/logreplies/udp_call?cmd=4',true)

    if($('.content_title p').html() == 'Event Log'){
    	$('#log_filter').show();
    }else{
    	$('#log_filter').hide();
    }	

    set_content_deminsions(954,481);
	
	$.each(['start_time_begin_hour','start_time_begin_minute','start_time_begin_second','end_time_begin_hour','end_time_begin_minute','end_time_begin_second'], function( index, value ){
		var select_id = '#'+value;
		$(select_id).data('pre', $(select_id).val());
	});

	$('#datepicker2, #datepicker').change(function(){
		if (Date.parse($('#datepicker').val()) < Date.parse($('#datepicker2').val())) {
			alert("\t \t Please select valid date: \n End Date should be greater than the Start Date");
			$('#datepicker2').val($('#valid_start_date').val());
			$('#datepicker').val($('#valid_end_date').val());
		}
		else if (Date.parse($('#datepicker').val()) == Date.parse($('#datepicker2').val())) {
			var valid_range = validate_time();
			if(valid_range == false){
				alert("\t \t Please select valid Time: \n End Time should be greater than the Start Time");
				$('#datepicker2').val($('#valid_start_date').val());
				$('#datepicker').val($('#valid_end_date').val());				
			}
			else{
				$('#valid_start_date').val($('#datepicker2').val());
				$('#valid_end_date').val($('#datepicker').val());
			}
		}		
		else {
			$('#valid_start_date').val($('#datepicker2').val());
			$('#valid_end_date').val($('#datepicker').val());
		}
	});

	$('#start_time_begin_hour, #start_time_begin_minute, #start_time_begin_second, #end_time_begin_hour, #end_time_begin_minute, #end_time_begin_second').change(function(){
		var before_change = $(this).data('pre');//get the pre data of time
		if (Date.parse($('#datepicker').val()) == Date.parse($('#datepicker2').val())) {
			var valid_range = validate_time();
			if(valid_range == false){
				alert("\t \t Please select valid Time: \n End Time should be greater than the Start Time");
				$(this).val(before_change);//set the current value to previous time value
			}
			else{
				$(this).data('pre', $(this).val());//update the pre data of time
			}
		}
		else{
			$(this).data('pre', $(this).val());//update the pre data of time
		}
	});
		
});
dropdown_hover();
$("#datepicker").datepicker({
	showOn: 'button',
	buttonImage: '../../images/calendar.gif',
	buttonImageOnly: true,
	dateFormat: "mm/dd/yy",
    changeYear:true
}).attr('readonly', true);
$("#datepicker2").datepicker({
	showOn: 'button',
	buttonImage: '../../images/calendar.gif',
	buttonImageOnly: true,
	dateFormat: "mm/dd/yy",
    changeYear:true
}).attr('readonly', true);

/*
* Disable logic for downloading displayed events
*/
$(".log_dl_link").w_click(function(){
    if( !$(this).hasClass("disabled_link") && !req_inprogress)
    	req_inprogress = true;
        downloadURL('/logreplies/download_txtfile/'+ $('#log_type_id').attr('value'));
	});

$('#searchwrapper').html($('#searchbox').show());
$('#searchbox form').submit(do_log_search);
$('#dup_q').w_keyup(function(){
	if ($(this).val() !=''){
		$('#clear_button').show()
	}else{
		$('#clear_button').hide()
	}
});

$('#clear_button').w_click(function(){
	if(!req_inprogress){
		req_inprogress = true;
		$('#dup_q').attr('value', '');
		$(this).hide();
		do_log_search();
	}
})

$('.pSearch').hide();

$('#log_table').hide();

$(".set_filter").w_click(function(){
	if(!req_inprogress){
		$.fn.colorbox({title: 'Log Filters',href : "/logreplies/set_filter" ,fixed: true});
	}
});

$('.dl_link_sel').html('Last 24 hours');

$(".logs a").w_click(function(){
	if(!req_inprogress){
		req_inprogress = true;
		make_request($(this).attr('href'),false);
	}
	return false;
});

function do_change_values(){
	$('#dup_q').attr('value', $('input[name=q]', "div .sDiv").val());
	$('#search_on').attr('value', $('select[name=qtype]',"div .sDiv").val());
}

function do_log_search(){
	get_event_details( $('#current_request_id').val() );
}

function make_request(_url,clear_logs){
	if(typeof clear_logs === 'undefined'){
		var clear_logs = true;
	}

	clearInterval(check_log_req_status_interval);
	DebugMsg("make_request,url = " + _url);
	var logtypeid = $('#log_type_id').attr('value');
	$('.ajax-loader').show();
	$('#log_update').hide();
	$('#log_updater').show();
	$('#log_updater').html('<div width="90%" align=center><br><div class="text_white text_font">Loading Please wait ...</div></div>');
	$("#log_update").remove_custom_scroll();

	log_in_progress(_url);
	$.ajax({
	    type: "post",
	    url: _url,
	    data: "number_of_entries=" + $('#report').attr('value') +
	    '&search_type=' + $('#search_type').attr('value') +
	    '&start_date=' +$('#datepicker2').attr('value') +
	    '&end_date=' +$('#datepicker').attr('value') +
	    '&start_hour=' +$('#start_time_begin_hour').attr('value') +
	    '&start_minute=' +$('#start_time_begin_minute').attr('value') +
	    '&start_second=' +$('#start_time_begin_second').attr('value') +
	    '&end_hour=' +$('#end_time_begin_hour').attr('value') +
	    '&end_minute=' +$('#end_time_begin_minute').attr('value') +
	    '&end_second=' +$('#end_time_begin_second').attr('value') +
	    '&diag=' +$('#diag_log_type').attr('value')+
	    '&log_type_id=' +$('#log_type_id').attr('value')+
	    '&log_filter='+$('#log_filter').val()+
	    '&clear_logs='+clear_logs,
	    success: function(result){
			if (result.request_id != '-1') {
				check_request_log_status(result.request_id);
			}
			else{
				$('#log_updater').html("<h2 class='display_information'>Record not found.</h2>'");
				req_inprogress = false;
			}
			
	    }
	});
}

function check_request_log_status(log_request_id){
	var reqID = log_request_id;
	var check_log_req_timeout_count = 0;
	var diag = $('#diag_log_type').attr('value');
	var log_type_id = $('#log_type_id').attr('value');
	$('.ajax-loader').show();
    check_log_req_status_interval = setInterval(function(){
	  if(!log_request_inprogress){
		    log_request_inprogress = true;
			log_req_status_xhr = $.post("/logreplies/check_log_status",{
		        request_id: reqID,
				log_type_id: log_type_id,
				diag: diag
		    },function(response_log_status){
				check_log_req_timeout_count ++;
				DebugMsg("make_request, reqID = " + response_log_status.request_id);
				DebugMsg("make_request, reqState = " + response_log_status.req_state);
				DebugMsg("make_request, logsize = " + response_log_status.logs_size);
				$('#current_request_id').attr('value', response_log_status.request_id);
				var event =  $('#current_event_count').attr('value');
				var timeout =  $('#log_download_timeout').attr('value');
				if ((event_count_timer >= (timeout * 60) / 3) && (response_log_status.req_all == true)) {
					clearInterval(check_log_req_status_interval);
					$('.ajax-loader').hide();
					$('#log_updater').html('').hide();
					$('#all_event_count').html('');
					$('#all_event_count').html("<span class='display_information'>Log Download Request Timeout</span>").show();
				}else {
					DebugMsg("make_request, EVENT COUNT  = " + response_log_status.event_count);
					DebugMsg("make_request, event_count_timer = " + event_count_timer);
					DebugMsg("make_request, event = " + event);
					if (response_log_status.req_all == true) {
						$('#current_event_count').attr('value', response_log_status.event_count)
						if ((event) && (event != response_log_status.event_count)) {
							event_count_timer = 0;
						}
						event_count_timer++;
						var count_val = 0;
						if (response_log_status.event_count) {
							count_val = response_log_status.event_count;
						}
						$('#all_event_count').html("<span class='display_information'>Event count : " + count_val + "</span>").show();
					}
					
					// Check if request is complete
					if (response_log_status.req_state == 2) {
						$('.ajax-loader').hide();
						$('#log_updater').html('');
						// Check if it was a request for all events
						if (response_log_status.req_all == false) {
							log_finished();
							clearInterval(check_log_req_status_interval);
							// Check if there are events
							if (parseInt(response_log_status.event_count) > 0) {
								// No request for all, show events
								get_event_details(response_log_status.request_id)
								// Enable "Displayed" download option
								$('.log_dl_link').removeClass('disabled_link');
							}
							else {
								// Disable "Displayed" download option
								$('.log_dl_link').addClass('disabled_link');
								// No new events, Display appropriate message
								$('#log_updater').html("<h2 class='display_information'>No logs found!</h2>'");
							}
							req_inprogress = false;
						}else {
							// Disable "Displayed" download option
							$('.log_dl_link').addClass('disabled_link');
							clearInterval(check_log_req_status_interval);
							$('#all_event_count').html("<span class='display_information'>Event count : " + response_log_status.event_count + "</span>").show();
							log_finished();
							downloadURL('/logreplies/download_txtfile/' + $('#log_type_id').attr('value'));
						}
					}else{
						if((check_log_req_timeout_count >= 10) && (response_log_status.req_all == false)){
							clearInterval(check_log_req_status_interval);
							$.post("/logreplies/delete_log_request", { request_id: reqID });
							$('.ajax-loader').hide();
							$('.log_dl_link').removeClass('disabled_link');
							$('#log_updater').html("<h2 class='display_information'>Log Request Timeout</h2>'");
							log_finished();
							req_inprogress = false;
						}
					}
				    log_request_inprogress = false;
				}
			
			});
	  	}
	},3000)
}

function showdiv(){
	clearInterval(check_log_req_status_interval);
	if (typeof log_req_status_xhr !== 'undefined' && log_req_status_xhr != null) {
		log_req_status_xhr.abort();
	}
	var log_type = $('#log_type_id').attr('value');
	$('#datepicker').attr('value', "");
	$('#datepicker2').attr('value', "");
	if($('#search_type').attr('value') == 'advanced'){
	  var yesterday = $('#yesterday_date').attr('value');
	  var today = $('#today_date').attr('value');
	  $('#datepicker2').attr('value',yesterday );
	  $('#datepicker').attr('value',today );
	  $('.dl_link_sel').html('Selected Range');
	  $('#advanced_filter_options').show();
	}else if($('#search_type').attr('value') == 'traceevents'){
	  $.post("/logreplies/clear_filters", {
	  	log_filter:''
	  }, function(){
	  	var log_type_name = $('#log_type').attr('value');
	  	$.post("/logreplies/start_trace_events/" + log_type + "?log_type_name=" + log_type_name,{},function(response){
			if (response.request_id != '-1') {
				$("#contentcontents").html(response.html_content);
			}
			else{
				$('#log_updater').html("<h2 class='display_information'>Failed to start trace events.</h2>'");
			}
		},"json");
	  });
	}else{
	  $.post("/logreplies/clear_filters", {}, function(){});
	  // Set download option text
	  $('.dl_link_sel').html('Last 24 hours');
	  $('#advanced_filter_options').hide();
	  if ($('#log_type').attr('value') == 'status') {
	        $(".contentareahdr", window.parent.document).html("Event Log");
			$.post("/logreplies/index?id=1",{},function(response){
				$("#contentcontents").html(response);
			});
	  }else if ($('#log_type').attr('value') == 'diagnosticeventlog') {
	        $(".contentareahdr", window.parent.document).html("Diagnostic Log");
	        $.post("/logreplies/index?id=6&diaglog=ALARM",{},function(response){
				$("#contentcontents").html(response);
			});
	  }
	}
}

/* Get rendered, event table details and display them*/
function get_event_details(reqID){
	$.post("/logreplies/get_event_data", {
		requestid:  reqID,
		log_type_id: $('#log_type_id').val()  ,
		qtype:      $('#search_on').val(),
		query:      $('#dup_q').val()
	}, function(result_resp){
		$('#log_updater').html('');
		$("#log_update").html(result_resp);
		$("#log_update").remove_custom_scroll();
		$("#log_update").custom_scroll(430);
		$('#log_update').show();
		req_inprogress = false;
	});
}

function download_selected(dl_type){
	if( !$(this).hasClass("disabled_link") && !req_inprogress){
    	req_inprogress = true;

		// Check for basic search type
		if ( $('#search_type').attr('value') == 'basic'){
		    // Check if a specific range was selected
		    if(dl_type == 'range'){
				// set the 24 hours start date and end date
				var yesterday = $('#yesterday_date').attr('value');
	 		    var today = $('#today_date').attr('value');
			    $('#datepicker2').attr('value',yesterday );
			    $('#datepicker').attr('value',today );
		    }else{
				// clear the start and end date
		        $('#datepicker2').attr('value', "");
				$('#datepicker').attr('value', "");
		    }
		}else if ( $('#search_type').attr('value') == 'advanced'){
			if(dl_type == 'all'){
				$('#datepicker2').attr('value', "");
				$('#datepicker').attr('value', "");
			}
		}

		make_request('/logreplies/udp_call?cmd=5',false)
	}
}

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

	req_inprogress = false;
}

/*
* An easy way to turn console.log debugging messages on or off
*/
var DebugON = false;
function DebugMsg(message){
	if(DebugON)
	  console.log(message);
}

$('#log_filter').w_change(function(){
	if (typeof log_req_status_xhr !== 'undefined' && log_req_status_xhr != null) {
		log_req_status_xhr.abort();
	}
	
	clearInterval(check_log_req_status_interval);

	req_inprogress = false;

	$.post("/logreplies/clear_filters", {
		log_filter:$('#log_filter').val()
	}, function(){
		make_request('/logreplies/udp_call?cmd=4',true);
	});
});

function log_in_progress(url){
	var string_params = url.split('?')[1];
	var dl_logs = false;

	if(typeof string_params !== 'undefined'){
		var string_params_array = string_params.split('&')
		string_params = {};
		for(var string_i = 0; string_i < string_params_array.length; string_i++){
			var s_key = string_params_array[string_i].split('=')[0];
			var s_value = string_params_array[string_i].split('=')[1];

			string_params[s_key] = s_value;
		}

		if(parseInt(string_params['cmd']) == 5){
			dl_logs = true;
		}
	}
	
	if(dl_logs){
		preload_page = function(){
			ConfirmDialog('Logs','Your request to download logs is not complete.<br>Would you like to leave anyways?',function(){
				preload_page_finished();
				preload_page = '';
			},function(){
				//don't load the next page
			});
		};
	}
}

function log_finished(){
	preload_page = '';
}

function validate_time(){
	var start_time_hr = $('#start_time_begin_hour').val();
	var end_time_hr =  $('#end_time_begin_hour').val();
	var start_time_min = $('#start_time_begin_minute').val();
	var end_time_min =  $('#end_time_begin_minute').val();
	var start_time_sec = $('#start_time_begin_second').val();
	var end_time_sec =  $('#end_time_begin_second').val();
	var valid_range = false;
	if(end_time_hr > start_time_hr){
		valid_range = true;
	}
	else if(end_time_hr == start_time_hr){
		if(end_time_min > start_time_min){
			valid_range = true;	
		}
		else if(end_time_min == start_time_min){
			if(end_time_sec > start_time_sec){
				valid_range = true;	
			}
		}
	}
	return 	valid_range;
}



/************************************************************************************************************
	add fileters
*************************************************************************************************************/

$(".add_row").w_click(function(){
	if(!req_inprogress){
		var row_number = $(".filter_table tr:last").attr('class')
		
		// Cloning default row
		var newDomElememt = $(".filter_table tr:last").clone();
		
		// Manipulating cloned element
		row_number = Number(row_number) + 1;
		newDomElememt.attr('class', row_number);
		newDomElememt.attr('id', row_number+"_row");
		
		// Iterating over the children of each row and manipulating its attributes
		var dom_children = newDomElememt.children();
		var child_id = child_name = child = "";
		
		$(dom_children).each(function(index, value){
			$(value).children().each(function(){
				child = $(this);
				child_id = child.attr('id');
				child_name = child.attr('name');

				if(typeof child_name !== 'undefined' && typeof child_id !== 'undefined' && child_name.match(/[0-9]+[_]/) || child_id.match(/[0-9][_]/)){
				 child_name = child_name.replace(/[0-9]+[_]/, "")
				 child_id = child_id.replace(/[0-9]+[_]/, "")
				}
								
				child.attr('id', row_number + "_" + child_id);
				child.attr('name', row_number + "_" + child_name);
				child.val('');
			});
		});
		
		// Inserting new dom element at the end of the table
		$(".filter_table tr:last").after(newDomElememt);
		$.fn.colorbox.resize();	
	}
});

$(".row_delete").w_click(function(){
	if(!req_inprogress){
		var link_name = $(this).attr('name')
		if(link_name.match(/[0-9]/)){
			var button_id = $(this).attr('id');
			$("#" + button_id + "row").remove();
			$.fn.colorbox.resize();	
		}else{
			var del_confirm = confirm("Are you sure?");
			if(del_confirm){
				var button_id = $(this).attr('id');
				$.post("/logreplies/delete_fiter", {filter_id: button_id}, function(response){
					$("#" + button_id + "row").remove();
					$.fn.colorbox.resize();
				});						
			}				
		}
	}
});

$("#new_log_filter").w_submit(function(event){
	event.preventDefault();
	
	var selected_element = message = "";
	$(".filter_combo").each(function(index, element){
		selected_element = $(element);
		if(selected_element.val() == "" && !selected_element.attr('disabled')){
			message = "Please Select " + selected_element.attr('message');			
			return false;		
		}
	});
	
	if(message == ""){
		var form_data = $("#new_log_filter").serialize();
		$.fn.colorbox.close();
		$("#flash_message").html("");	
		$.post("/logreplies/apply_filter", form_data, function(response){});				
	}else{
		$("#flash_message").html("<span style='color:red;'>"+message+"</span>");
		$.fn.colorbox.resize();	
	}						
});
