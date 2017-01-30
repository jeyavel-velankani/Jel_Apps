/**
 * @author Jeyavel Natesan
 */
var ll_upload_interval = null;
$(document).ready(function(){
	add_to_destroy(function(){
		//kills all wrapper events
		$('#ladderlogic_update_form').w_die('submit')
	
		//clear intervals
		clearInterval(ll_upload_interval);
	});
	change($("#ladderlogic").val());
});
	
$('#ladderlogic_update_form').submit(function(e) {
	var llw_file_path = $('#llw_file_upload').val();
	var llb_file_path = $('#llb_file_upload').val();
	var llw_valid_extension = /(.llw)$/i;
    var llw_valid = llw_valid_extension.test(llw_file_path);
	var llb_valid_extension = /(.llb)$/i;
    var llb_valid = llb_valid_extension.test(llb_file_path);
	if ((llw_file_path == "") || (llb_file_path == "")) {
		alert("Please add Ladder Logic file");
		return false;
	}
	else {
		if (!llw_valid && !llw_valid) {
			alert("Invalid Ladder Logic File");
			return false;
		}
	}
    var options = {
       	success: function(response){
        	if(response.error){
				$('.ll_message_container span').html("").removeClass("ll_success_message").removeClass("ll_warning_message").addClass("ll_error_message").html(response.message).show();
				$("#llb_file_upload_path").val("");
				$("#llw_file_upload_path").val("");
			}else{
				if(response.oce_mode){
					$('.ll_message_container span').html("").removeClass("ll_error_message").removeClass("ll_warning_message").addClass("ll_success_message").html(response.message).show().fadeOut(6000);
					$("#llb_file_upload_path").val("");
					$("#llw_file_upload_path").val("");
				}else {
					$('#ladder_logic_content').hide();
					$('#upload_progress').show();
					var req_counter = 0;
					var request_in_process = false;
					var delete_request = false;
					if(ll_upload_interval != null)
						clearInterval(ll_upload_interval);
					$("llw_request_id").val(response.llw_request_id);
					$("llb_request_id").val(response.llb_request_id);	
					ll_upload_interval = setInterval(function(){
						if (!request_in_process) {
							request_in_process = true;
							$.post('/ladderlogic/ll_update_process', {
								llw_request_id: response.llw_request_id,
								llb_request_id: response.llb_request_id
							}, function(resp){
								if (resp.llw_done && resp.llb_done) {
									var msg = "LLW: " + resp.llw_message + " LLB: " + resp.llb_message;
									if(resp.llw_error || resp.llb_error){
										$('.ll_message_container span').html("").removeClass("ll_success_message").removeClass("ll_warning_message").addClass("ll_error_message").html(msg).show();
									}else {
										$('.ll_message_container span').html("").removeClass("ll_error_message").removeClass("ll_warning_message").addClass("ll_success_message").html(msg).show().fadeOut(6000);
									}
									$('#upload_progress').hide();
									$('#ladder_logic_content').show();
									clearInterval(ll_upload_interval);
									$("llw_request_id").val("");
									$("llb_request_id").val("");
								} else {
									$('#llw_percentage').html(resp.llw_percentage);
									$('#llb_percentage').html(resp.llb_percentage);
									$('#llw_upload_filename').html(resp.llw_filename);
									$('#llw_upload_filepath').html(resp.llw_path);
									$('#llb_upload_filename').html(resp.llb_fielname);
									$('#llb_upload_filepath').html(resp.llb_path);
								}	
								request_in_process = false;
							});	
						}
					}, 2000);
				}
			}
	  	},
	    error: function(data, status, e){
	    	alert(e);
	    }
   	};
   	$(this).ajaxSubmit(options);
   	return false;  
});

$('#cancel_upload').w_click(function(e) {
	var llw_request_id = $("llw_request_id").val();
	var llb_request_id = $("llb_request_id").val();
	$.post('/ladderlogic/cancel_softwareupdate', {
			llw_request_id: llw_request_id,
			llb_request_id: llb_request_id
		}, function(resp){
		if (resp.error) {
			$('.ll_message_container span').html("").removeClass("ll_success_message").removeClass("ll_warning_message").addClass("ll_error_message").html(resp.message).show();
		}
		else {
			$('#upload_progress').hide();
			$('#ladder_logic_content').show();
			clearInterval(ll_upload_interval);
			$('.ll_message_container span').html("").removeClass("ll_error_message").removeClass("ll_warning_message").addClass("ll_success_message").html(resp.message).show().fadeOut(6000);
			$("llw_request_id").val("");
			$("llb_request_id").val("");
		}	
	});	
});
    
function change(str)
{
	if (str == true || str == 'true')
	{
		$('#btnfileupload').removeAttr("disabled");
		$('#llb_file_upload').removeAttr("disabled");
		$('#llw_file_upload').removeAttr("disabled");
	}else{
		$('#btnfileupload').attr("disabled", "disabled");
		$('#llb_file_upload').attr("disabled", "disabled");
		$('#llw_file_upload').attr("disabled", "disabled");
	}
	$.post("/ladderlogic/updatenvladderlogicstatus", { nvladderlogicstatus : str });
}
  
function llwfilecheck()
{
	var llwfilepath = $("#llw_file_upload").val();
	var valid = llwfilepath.split('.');
	var validllw = valid[valid.length-1];
	if ((validllw == "llw") || (validllw == "LLW")) {
		return true;			
	}else{
		alert("Please select llw file only");
		$("#llw_file_upload_path").val("");
		return false;
	}
	return false;
}
  
function llbfilecheck()
{
	var llwfilepath = $("#llb_file_upload").val();
	var valid = llwfilepath.split('.');
	var validllb = valid[valid.length-1];
	if ((validllb == "llb") || (validllb == "LLB")) {
		return true;			
	}else{
		alert("Please select llb file only");
		$("#llb_file_upload_path").val("");
		return false;
	}
	return false;
}
//window.onload = function() {  }; 