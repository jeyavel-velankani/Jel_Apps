/**
 * @author 248869
 */

var viewptcstatus_interval = null;
var viewptcstatus_xhr = null;

$(document).ready(function(){
	add_to_destroy(function(){
		$(document).bind("ready",function(){});
	
		//clear intervals
		clearInterval(viewptcstatus_interval);
		
		if(typeof viewptcstatus_xhr !== 'undefined' && viewptcstatus_xhr != null){
		    viewptcstatus_xhr.abort();  //cancels previous request if it is still going
		}

		//clears global variables
		delete window.viewptcstatus_interval;
		delete window.viewptcstatus_xhr;
	});
	
  	var request_in_process = false;
	viewptcstatus_interval = setInterval(function(){
		if (!request_in_process) {
			request_in_process = true;
			$(".ajax-loader").show();
			viewptcstatus_xhr = $.post('/viewptcstatus',  {auto_refresh: true}, function(response){
				request_in_process = false;
				$('#div-one').html(response);
				$(".ajax-loader").hide();
			});			
		}	
	}, 5000);
});
