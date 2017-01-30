/**
 * @author 248869
 */

var set_to_default_interval = null;
var set_to_default_xhr =  null;

$(document).ready(function(){
	add_to_destroy(function(){
		$(document).bind("ready",function(){});
	
		//kills all wrapper events
		$('.unlock').w_die('click');
		$('.set_to_default').w_die('click');
		
		
		//clear intervals
		clearInterval(set_to_default_interval);

		if(typeof set_to_default_xhr !== 'undefined' && set_to_default_xhr != null){
		        set_to_default_xhr.abort();  //cancels previous request if it is still going
		}
		
		//clear functions 
		//no functions

		//clears global variables
		delete window.set_to_default_interval;
		delete window.set_to_default_xhr;
	});
	
	$('.unlock').unlock('.message_container',function(unlock_resp){
		if(unlock_resp){
			reload_page();
			$('.set_to_default').removeClass('disabled');
		}else{
			//do nothing because still locked
		}
	});	
	
	var req_id = $('.req_id').val();
	if ($('.user_pres').val() != 'true'){
		$('.set_to_default').addClass('disabled');
	}
	$('.set_to_default').click(function(){
		if(!($(this).hasClass('disabled'))){
			var set_to_default_counter = 0;
			var set_to_default_req_process = false;
			var msg = '';
			$("#contentcontents").mask("Set to default operation in progress, please wait...");
			$.post('/programming/set_to_default',{
				send_request: true
			},function(){
				set_to_default_interval = setInterval(function(){
					if (!set_to_default_req_process) {
						set_to_default_req_process = true;
						if (set_to_default_counter == 30) {
							clearTimeout(set_to_default_interval);
							$("#contentcontents").unmask();
							$('.message_container span').html("").removeClass("success_message").removeClass("warning_message").addClass("error_message").html("Request timeout.").show();
						}
						else {
							set_to_default_counter++;
							set_to_default_xhr = $.post("/programming/check_set_to_default", {}, function(resp){
								//Check GEO session after set to default and display success message. 
								if((resp.geo_session == true) && (set_to_default_counter >1)){
									$("#contentcontents").unmask();
									$('.message_container span').html("").removeClass("error_message").removeClass("warning_message").addClass("success_message").html(resp.message).show().fadeOut(6000);
									clearInterval(set_to_default_interval);
									$('#leftnavtree').html('');
									load_content_flag = true;
									setTimeout('build_vital_config_object("Configuration")', 5000);
								}
								set_to_default_req_process = false;
							});
						}
					}
				}, 3000);
			});
	}})	
});	
