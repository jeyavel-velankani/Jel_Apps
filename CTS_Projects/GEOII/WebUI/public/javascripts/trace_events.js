/**
 * @author Jeyavel Natesan
*/
var update_trace = false;
var trace_events_timer_interval;
var trace_events_xhr = null;
$(document).ready(function(){
	add_to_destroy(function(){
		$(document).bind("ready",function(){});
	
		//kills all events
		$('.stop_icon a').w_die('click');
		$('.start_icon a').w_die('click');
		$(".back_icon a").w_die('click');
		$(".clear_icon a").w_die('click');
		
		//cancels previous request if it is still going
		if (typeof trace_events_xhr !== 'undefined' && trace_events_xhr != null) {
			trace_events_xhr.abort();
		}
		
		//clear intervals
		if(typeof trace_events_timer_interval != 'undefined' && trace_events_timer_interval != null){
			clearTimeout(trace_events_timer_interval);			
		}
		
		//clear functions 
	    delete window.run_check_trace;
		delete window.check_trace;
		
		//clears global variables
		delete window.trace_events_timer_interval;
		delete window.trace_events_xhr;
		delete window.update_trace;
	});
	run_check_trace();
});
function run_check_trace(){
  // Verify periodic calling is enabled
  if($('#periodic_call_flag').val() == 'true'){
  	
    trace_events_timer_interval = setInterval(function(){
    	if(!update_trace){
    		update_trace = true;

	    	$('.ajax-loader').show();
		  	DebugMsg("1. check_trace called");

			trace_events_xhr = $.ajax({
			  type:     'POST',
			  url:      '/logreplies/check_trace_events/'+ $("#log_type_id").val()+"?request_id="+$("#log_request_id").val(),
			  dataType: 'html',
			  success:  function(result){
			  	$('.ajax-loader').hide();
			    
			      DebugMsg("2. check_trace returned.");
				  // Check for available results
			      if( (result != "no new events") && (result != "request not complete yet") ){
			        DebugMsg("3. check_trace: Displaying results")

			        $('#log_update').show();
			        $('#log_updater').hide();

					if(result == '-1'){
					   $("#log_update").html("<h2 class='display_information'>Record not found</h2>'");
					}else{
				          $('#log_update').custom_scroll_update_content(result,435,{'start_position':'auto','off_set':3,'delimeter':'tr'});
					}

			      }else{
			        DebugMsg("check_trace result = " + result);
			      }
			      update_trace = false;
			    }
			});
		}
    }, 3000);
  }
}


$(".start_icon a").w_click(function(){
	if ($('#periodic_call_flag').val() == 'true'){
	  alert("Tracing is already in progress");
	}else if(confirm("Are you sure you want to start the tracing?")){
	  $('#periodic_call_flag').attr('value', 'true');
	  $('#log_update').remove_custom_scroll();
	  $("#log_update").show();
	  $('.ajax-loader').show();
	  run_check_trace();
	}
});

$(".stop_icon a").w_click(function(){
  if (confirm("Are you sure you want to stop the tracing?")){
    clearTimeout(trace_events_timer_interval);
    $('#periodic_call_flag').attr('value', 'false');
	$('.ajax-loader').hide();
  }
});

$(".clear_icon a").w_click(function(){
	var log_type = $("#log_type_id").attr('value');
    clearTimeout(trace_events_timer_interval);
    $('#periodic_call_flag').attr('value', 'false');
	$('#log_updater').hide();
	var title ="";
	if (log_type == "1"){
	  title = "Event Log";
	}else{
	  title = "Diagnostic Log";
	}
    load_page(title,"/logreplies/start_trace_events?id=" + log_type );
});

$(".back_icon a").w_click(function(){
  req_inprogress = false;
  var log_type = $("#log_type_id").attr('value');
  clearTimeout(trace_events_timer_interval);
  $('#periodic_call_flag').attr('value', 'false');
  $('#log_updater').hide();
  var title ="";
  if (log_type == "1"){
  	title = "Event Log";
  }else{
  	title = "Diagnostic Log";
	log_type = log_type + "&diaglog=ALARM"
  }
  load_page(title,"/logreplies/index?id=" + log_type );
});
/*
 * An easy way to turn debugging messages on or off
 */
var DebugON = false;
function DebugMsg(message)
{
  if(DebugON)
    console.log(message);
}