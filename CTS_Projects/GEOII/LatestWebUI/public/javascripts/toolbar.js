/****************************************************************************************************************************************
Authoer: Kevin Ponce
Requirements: JQuery 1.9.1, jquery_wrapper.js
Description: Library used to for generic toolbar functions

****************************************************************************************************************************************/

var unlock_req_timer;
var check_user_presence_xhr = null;

$(document).ready(function(){
	add_to_destroy(function(){
		$(document).bind("ready",function(){});
	
		//kills all wrapper events
		$('.unlock').w_die('click');
		
		//clear intervals
		if (typeof unlock_req_timer !== 'undefined' && unlock_req_timer != null) {
			clearInterval(unlock_req_timer);
		}
		if(typeof check_user_presence_xhr !== 'undefined' && check_user_presence_xhr != null){
		        check_user_presence_xhr.abort();  //cancels previous request if it is still going
		}
		
		//clear functions 
		//no functions

		//clears global variables
		delete window.unlock_req_timer;
		delete window.check_user_presence_xhr;
	});
});	


(function($){
	$.extend({
	  	check_user_presence: function(callback){
	      $.post('/access/check_user_presence',{
	      	//no params
	      },function(resp_check){
	      		if(typeof callback === 'function'){

	      			var bool_resp = (resp_check == 'true' ? true : false);
	      			callback(bool_resp);
	      		}
	      });
	  	}
	});

	$.fn.extend({
	  	unlock: function(feedback,callback){
	  		$(this).w_click(function(){
				
		      	if(!$(this).hasClass("disabled")){
					var unlock_confirm = confirm("Are you sure you want to unlock parameters?"); 
					if (unlock_confirm) {

						$('.ajax-loader').show();
						$(feedback).html("");
						$("#contentcontents").mask("Unlocking parameters, Please wait");

						var unlock_req_timer_counter = 0;
						var session_flag = true;
						if ($(this).hasClass("session_flag")) {
							session_flag = false;
						}
                        
						$.post('/access/request_user_presence', {
							session_flag : session_flag
						},function(response){
							if(response.user_presence){
								$(feedback).html("").removeClass("error_message").removeClass("warning_message").addClass("success_message").html("Parameters already unlocked").show().fadeOut(6000);
								$('.ajax-loader').hide();
								$("#contentcontents").unmask();

							}else{
								var unlock_req_timer_process = false;
								var delete_request = false;
								unlock_req_timer = setInterval(function(){
									if (unlock_req_timer_process == false) {
										unlock_req_timer_process = true;
										check_user_presence_xhr = $.post("/access/check_user_presence_request_state", {
											request_id: response.request_id,
											delete_request: delete_request
										}, function(resp){
											unlock_req_timer_counter++;
											if (resp.request_state == "2") {
												clearInterval(unlock_req_timer);
												$('.ajax-loader').hide();
												$("#contentcontents").unmask();
												if (resp.error == true) {
													$(feedback).html("").removeClass("success_message").removeClass("warning_message").addClass("error_message").html("Unlock failed! System is not in edit mode.").show();
												}else {
													$(feedback).html("").removeClass("error_message").removeClass("warning_message").addClass("success_message").html("Unlock Successful. System is in edit mode now.").show().fadeOut(6000);
												}

												if(typeof callback === 'function'){
													var bool_resp = (resp.error == 'true' || resp.error == true ? false : true);

													callback(bool_resp);
												}
											}else {
												if (unlock_req_timer_counter >= 50) {
													$(feedback).html("").removeClass("success_message").removeClass("warning_message").addClass("error_message").html("Unlocked reuqest timeout").show();
													$('.ajax-loader').hide();
													$("#contentcontents").unmask();
													clearTimeout(unlock_req_timer);
												}	
											}
											if (unlock_req_timer_counter >= 49) {
												delete_request = true;
											}
											unlock_req_timer_process = false;
										}, "json");
									}
								}, 2000);
							}
						}, "json");
					}
				}
			});
	  	}
  	});


	$.fn.extend({
	  	success_message: function(message){
	      $(this).html('<div class="success_message"><img src="/images/check.png" style="float: left;width: 20px;margin: 0px 5px;"><div style="float: left;margin: 2px;">'+message+'</div>').show().delay(6000).fadeOut(6000);
	  	}
	});

	$.fn.extend({
	  	error_message: function(message){
	      $(this).html('<div class="error_message"><img src="/images/error.png" style="float: left;width: 20px;margin: 0px 5px;"><div style="float: left;margin: 2px;">'+message+'</div>').show().delay(6000).fadeOut(6000);
	  	}
	});

})(jQuery);
