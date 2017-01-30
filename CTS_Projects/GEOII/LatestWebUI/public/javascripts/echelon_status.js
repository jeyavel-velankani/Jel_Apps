/**
 * @author 248869
 */

var echelon_status_interval = null;
var echelon_status_xhr;

$(document).ready(function(){
	add_to_destroy(function(){
		$(document).bind("ready",function(){});
	
		//clear intervals
		if(typeof echelon_status_interval !== 'undefined'){
			clearInterval(echelon_status_interval);
		}
		
		if(typeof echelon_status_xhr !== 'undefined' && echelon_status_xhr != null){
		        echelon_status_xhr.abort();  //cancels previous request if it is still going
		}
		
		//clears global variables
		delete window.echelon_status_interval;
		delete window.echelon_status_xhr;		
	});
	
  	var request_in_process = false;
	echelon_status_interval = setInterval(function(){
		if (!request_in_process) {
			request_in_process = true;
			$(".ajax-loader").show();
			echelon_status_xhr = $.post('/status_monitor/echelon_status',  {auto_refresh: true}, function(response){
				request_in_process = false;
				$('#div-one').html(response);
				$(".ajax-loader").hide();
			});			
		}	
	}, 5000);	
});
