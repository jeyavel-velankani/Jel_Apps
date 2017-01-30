/**
 * @author 248869
 */
var auto_refresh_interval;
var request_in_process = false;
var cdl_status_xhr = null;

$(document).ready(function(){
	add_to_destroy(function(){
		$(document).bind("ready",function(){});
	
		//kills all wrapper events
		$('.clear_cdl').w_die('click');
		//clear intervals
		clearInterval(auto_refresh_interval);
		
		if(typeof cdl_status_xhr !== 'undefined' && cdl_status_xhr != null){
		        cdl_status_xhr.abort();  //cancels previous request if it is still going
		}		
		//clear functions
		delete window.auto_refresh_alarms;

		//clears global variables
		delete window.auto_refresh_interval;
		delete window.request_in_process;
		delete window.cdl_status_xhr;
	});
		
	auto_refresh_interval = setInterval(function(){
		if (!request_in_process) {
			request_in_process = true;
			cdl_status_xhr = $.post('/cdl_status', {}, function(response){
				if (response.error != true) {
					$("#cdl_messages").html(response.html);
				}
				else {
					$('.err_message').text(response.message).show().fadeOut(8000);
				}
			}, 'json');
			request_in_process = false;
		}		
	}, 3000);
	
	$('.clear_cdl').w_click(function(){
		$.post("/cdl_status/clear_cdl_messages",{},function(res){
			if (res.error == true){
				$('.err_message').text(res.message);
				$('.err_message').show().fadeOut(8000);
			}else{
				reload_page();
			}
		},"json");
	});
});
