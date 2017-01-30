/**
 * @author 248869
 */

var timer_interval = null;
var high_availabilities_xhr = null;

$(document).ready(function(){
	add_to_destroy(function(){
		$(document).bind("ready",function(){});
	
		//clear intervals
		clearInterval(timer_interval);
		
		if(typeof high_availabilities_xhr !== 'undefined' && high_availabilities_xhr != null){
			high_availabilities_xhr.abort();	//cancels previous request if it is still going
		}
		//clears global variables
		delete window.timer_interval;
		delete window.high_availabilities_xhr;
	});

	var request_in_process = false;
	timer_interval= setInterval(function(){
		if (!request_in_process) {
			request_in_process = true;
			high_availabilities_xhr = $.post('/high_availabilities/connections', {
				auto_refresh: true
			}, function(response){
				$("#contentcontents").html(response);
				request_in_process = false;
			});
		}	
	}, 5000);
});