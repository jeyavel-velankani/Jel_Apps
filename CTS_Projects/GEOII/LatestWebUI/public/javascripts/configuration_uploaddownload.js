/**
 * @author Jeyavel Natesan
 */
var check_download_status_interval;
var check_upload_status_interval;
var check_unlock_status_interval;
var user_presence_req_check_process = false;
var configuration_upload_download_unlock_process = false;
var get_download_status_xhr = null;
var upload_status_xhr = null;
var unlock_status_xhr = null;

$(document).ready(function(){
	add_to_destroy(function(){
		$(document).bind("ready",function(){});
	
		//kills all events
		$('#upload_configuration').w_die('click');
		$('#configuration_options_select').w_die('change');
		$('#download_configuration').w_die('click');
		$('#unlock_configuration_upload_download').w_die('click');
		$('#software_update_form').w_die('submit');
		$('#fileToUpload').w_die('change');
		
		if(typeof get_download_status_xhr !== 'undefined' && get_download_status_xhr != null){
			get_download_status_xhr.abort();
		}
		if(typeof upload_status_xhr !== 'undefined' && upload_status_xhr != null){
			upload_status_xhr.abort();
		}
		if(typeof unlock_status_xhr !== 'undefined' && unlock_status_xhr != null){
			unlock_status_xhr.abort();
		}
			
		//clear intervals
		clearInterval(check_download_status_interval);
		clearInterval(check_upload_status_interval);
		clearInterval(check_unlock_status_interval);
		
		//clear functions 
		delete window.upload_status;
		delete window.download_inprogress;
		delete window.check_for_file_extention;
		delete window.extractFileName;
		delete window.userpresence_for_configuration_upload_download;
		delete window.upload_download_user_presence_req_state;

		//clears global variables
		delete window.check_download_status_interval;
		delete window.check_upload_status_interval;
		delete window.check_unlock_status_interval;
		delete window.user_presence_req_check_process;
		delete window.configuration_upload_download_unlock_process;
		delete window.get_download_status_xhr;
		delete window.upload_status_xhr;
		delete window.unlock_status_xhr;
		delete window.user;
		delete window.upload_in_progress;
		delete window.download_in_progress;
	});	

});


var configuration_upload_download_unlock_process = false;
var user = $('#user_presence').val();
var upload_in_progress = false;
var download_in_progress = false;
if (parseInt(user) == 0) {
	$("#configuration_options_select").attr('disabled','disabled');
	$('.unlock_configuration_upload_download').removeClass('disable_button');
	$('#upload_configuration').addClass('disable_button');
	$('#download_configuration').addClass('disable_button');
}else if(parseInt(user) == 1){
	$("#configuration_options_select").removeAttr('disabled');
	$('.unlock_configuration_upload_download').addClass('disable_button');
	$('#upload_configuration').removeClass('disable_button');
	$('#download_configuration').removeClass('disable_button');
}

$('#fileToUpload').removeAttr("disabled");
$('#serial_outer_upload').show();

$('#unlock_configuration_upload_download').w_click(function(){
	if (!$(this).hasClass('disable_button')) {
		userpresence_for_configuration_upload_download();
	}
});

$('#software_update_form').w_submit(function(e) {
      var options = {
          success: function(request_id) { 
		  	 upload_status(request_id)
          }
      };
      $(this).ajaxSubmit(options);
     return false; 
});

$('#fileToUpload').w_change(function(){
	var upload_config_type = document.getElementById('configuration_options_select').options[document.getElementById('configuration_options_select').selectedIndex].value;
  	$("#update_type").val(upload_config_type);
	var target = $('#configuration_options_select').find(":selected").attr('target'); 		
	$("#target").val(target);

	var filename = $(this).val();

	if(filename.indexOf('\\') != -1){
		//windows
		filename = filename.split('\\'); 

		filename = filename[filename.length-1];
	}else if(filename.indexOf('/') != -1){
		//mac
		filename = filename.split('/'); 

		filename = filename[filename.length-1];
	}
	
	$('#fileToUpload_path').val(filename);
});

	$("#upload_configuration").w_click(function() {
	if (!$(this).hasClass('disable_button')) {
		$("#download_options_status").hide();
		$('#resultsft').html("");
		var upload_config_type = document.getElementById('configuration_options_select').options[document.getElementById('configuration_options_select').selectedIndex].value;
		$("#update_type").val(upload_config_type);
		var target = $('#configuration_options_select').find(":selected").attr('target');
		$("#target").val(target);
		$("#configuration_options_select").attr('disabled', 'disabled');
		var valid_file_ext = check_for_file_extention(upload_config_type, extractFileName($("#fileToUpload").val()));
		if (valid_file_ext) {
			$("#software_update_form").submit();
		}
		else {
			$("#configuration_options_select").removeAttr("disabled");
		}
	}
});

$('#configuration_options_select').w_change(function(){
	$('#resultsft').html("");
	
	$("#download_options_status").hide();
	$('.uploadfilemessage').html('');
	$('.uploadfilemessage').html("Select File :").css({"color":"#F2F2F2" ,"font-size":"13px" , "font-family":"Arial"});
	$('#fileToUpload').removeAttr("disabled");
	$("#serial_outer_upload").show();
});
	
$('#download_configuration').w_click(function(){
	if (!$(this).hasClass('disable_button')) {
		$('#resultsft').html("");
		$("#download_options_status").hide();
		$("#configuration_options_select").attr('disabled', 'disabled');
		var download_config_type = document.getElementById('configuration_options_select').options[document.getElementById('configuration_options_select').selectedIndex].value;
		if (download_config_type != 20) {
			download_inprogress(true);
			$('#serial_outer_upload').hide();
			$(".update_message_without_percentage").html("");
			$(".update_message_without_percentage").html("Downloading file ");
			$("#progress_without_percentage").show();
		    $.post("/softwareupdate/download_system_file", {
				id: download_config_type
			}, function(response){
				$(".ajax-loader").hide();
				download_inprogress(false);
				$(".update_message_without_percentage").html("");
				$("#progress_without_percentage").hide();
				$("#configuration_options_select").removeAttr("disabled");
				if (response.full_path) {
					var download_path = "/softwareupdate/download_txtfile?id=" + response.full_path + "&filename=" + response.file_name;
					top.document.getElementById('uploader_iframe').src = download_path;
				}
				else {
					$('#resultsft').html();
					var msg = "<span class='error_message text_font'>" + response.error + " </span>";
					$("#resultsft").html(msg).show();
				}
				$('#serial_outer_upload').show();
			}, "json");
		}
		else {
			$("#resultsft").html('');
			user = $('#user_presence').val();
			if (user == 1) {
				if (!download_in_progress) {
					download_inprogress(true);
					$("#resultsft").html('');
					$('#serial_outer_upload').hide();
				    $.post("/softwareupdate/udp_request_download", {}, function(response){
						var download_request_process = false;
						if (response == "" || response == null) {
							$("#configuration_options_select").removeAttr("disabled");
							$("#download_options_status").hide();
							download_inprogress(false);
							var msg = "<span class='text_white text_font'>Configuration package download in progress, please try later</span>";
							$('#resultsft').html(msg).show();
						}
						else {
							$("#download_options_status").show();
							$("#display_progressbar").progressbar({
								value: 0
							});
							document.getElementById("display_progressbar_val").style.color = '#F2F2F2';
							document.getElementById("display_progressbar_val").innerHTML = "Downloading configuration package 0% Completed";
							check_download_status_interval = setInterval(function(){
								if (!download_request_process) {
									download_request_process = true;
								    get_download_status_xhr = $.post("/softwareupdate/get_download_status", {
										request_id: response
									}, function(resp){
										$("#display_progressbar").progressbar({
											value: resp.percent_complete
										});
										document.getElementById("display_progressbar_val").innerHTML = "Downloading configuration package " + resp.percent_complete + "% Completed ";
										if (resp.request_state == "2") {
											$("#configuration_options_select").removeAttr("disabled");
											clearInterval(check_download_status_interval);
											download_in_progress = false;
											document.getElementById("display_progressbar_val").innerHTML = "Downloading configuration package " + resp.percent_complete + "% Completed ";
											$("#configuration_options_select").removeAttr("disabled");
											$("#download_options_status").hide();
											download_inprogress(false);

											$("#serial_outer_upload").show();
											var msg = "";
											if (resp.result == 200) {
												msg = "<span class='success_message text_font'>Successfully downloded configuration package file</span>";
												$('#resultsft').html(msg).show().fadeOut(15000);
												var download_path = "/softwareupdate/download_txtfile?id=" + resp.full_path + "&filename=" + resp.file_name;
												top.document.getElementById('uploader_iframe').src = download_path;
											}
											else {
												msg = "<span class='error_message text_font'>" + resp.status_message + "</span>";
												$('#resultsft').html(msg).show();
											}
											$('.download_configuration').removeClass('disable_button');
											$('.upload_configuration').removeClass('disable_button');
										}
										download_request_process = false;
									}, "json");
								}
							}, 2000);
						}
					});
				}
			}
			else {
				return false;
			}
		}
	}
});

function upload_status(request_id){
	$("#configuration_options_select").attr('disabled','disabled');
	$("#serial_outer_upload").hide();
	var upload_config_type = document.getElementById('configuration_options_select').options[document.getElementById('configuration_options_select').selectedIndex].value;
	var request_id_val = request_id;
	$("#download_options_status").show();
	if (upload_config_type == 20) {
		$(".update_message_without_percentage").html("");
		$("#progress_without_percentage").hide();
		$("#download_options_status").show();
		$("#display_progressbar").progressbar({value: 0});
		document.getElementById("display_progressbar_val").style.color = '#F2F2F2';
		document.getElementById("display_progressbar_val").innerHTML = "Uploading Configuration Package 0% Completed";
	}else {
		$("#download_options_status").hide();
		$(".update_message_without_percentage").html("");
		$(".update_message_without_percentage").html("Uploading file ");
		$("#progress_without_percentage").show();
	}
	download_inprogress(true);
	upload_in_progress = false;
	check_upload_status_interval = setInterval(function(){
		if(!upload_in_progress){
			upload_in_progress = true;
			upload_status_xhr = $.post("/softwareupdate/configuration_upload_status", {
				request_id: request_id_val
			}, function(resp){
				if (resp.request_state == 2){ 
					if (upload_config_type == 20) {
						$("#download_options_status").hide();
						document.getElementById("display_progressbar_val").innerHTML = "Uploading Configuration Package " + resp.percent_complete + "% Completed ";
					}
					clearInterval(check_upload_status_interval);
					$("#progress_without_percentage").hide();
					$(".update_message_without_percentage").html("");
					upload_in_progress = false;
					download_inprogress(false);
					$("#configuration_options_select").removeAttr("disabled");
					
					$('#fileToUpload_path').val('');
					$('#fileToUpload').val('');
	
					$("#serial_outer_upload").show();
					if (resp.result == 200) {
						var msg = "";
						msg = "<span class='success_message text_font'> File Uploaded Successfully. Non-Vital CPU is rebooting."+(upload_config_type == 10 ? '' : '')+"</span>";
						$('#resultsft').html(msg).show().fadeOut(15000);
					}else if(resp.result == 217){
						ConfirmDialog('Configuration',"MCFCRC does not match. Can't proceed with configuration upload.<br>Please update MCF first and try again.<br>Do you want to update MCF now?",function(){
							set_current_url('/softwareupdate/upload_vital_nonvital?page=vlp_mcf');
							loads_content("MCF",get_current_url());
						},function(){
							var msg = "<span class='error_message text_font'>Configuration upload cancelled by user</span>";
							$('#resultsft').html(msg).show();
						});
					}else {
						var msg = "<span class='error_message text_font'>" + resp.error_message + " </span>";
						$('#resultsft').html(msg).show();
					}
				}else{
					if(upload_config_type == 20){
						$("#download_options_status").show();
						if (resp.percent_complete) {
							$("#display_progressbar").progressbar({
								value: resp.percent_complete
							});
							document.getElementById("display_progressbar_val").style.color = '#F2F2F2';
							document.getElementById("display_progressbar_val").innerHTML = "Uploading Configuration Package " + resp.percent_complete + "% Completed";
						}
					}
				}
				upload_in_progress = false;
			});
		}
	}, 4000);
}

function download_inprogress(download_process_flag){
	if(download_process_flag == true){
		download_in_progress = true;
		$('.download_configuration').addClass('disable_button');
		$('.upload_configuration').addClass('disable_button');
	}else{
		download_in_progress = false;
		$('.download_configuration').removeClass('disable_button');
		$('.upload_configuration').removeClass('disable_button');	
	}
}

function check_for_file_extention(val, file_name){
	var msg = "";
	var f_ext = "";
	if (file_name.indexOf('.') > -1) {
    	f_ext = file_name.substring(file_name.lastIndexOf('.') + 1, file_name.length);
		f_ext = f_ext.toLowerCase();
	}else{
		alert("Please select file");
		return false;
	}
	switch(val){
		case '9':
			if( f_ext != "bin")
				msg = "RC2 key";
			break;
		case '11':
			if( f_ext != "bin")
				msg = "cic";
			break;
		case '10':
			if( f_ext != "sql3")
				msg = "nvconfig";
			break;
		case '20':
			if( f_ext != "zip")
				msg = "Configuration Package (ZIP)";
			break;
	}
	if (msg != "") {
		$("#file_ext_check").show();
		$("#file_ext_check").html("<span style='color:red;font-weight:bold;padding:10px;'> Please select valid " + msg + " file </span>")
		$("#file_ext_check").show().fadeOut(5000, function(){
			$("#file_ext_check").html("");
		});
		return false;
	}
	return true;	
}

function extractFileName (string) {
    if (string.indexOf('/') > -1) {
        fileName = string.substring(string.lastIndexOf('/') + 1, string.length);
    }else {
        fileName = string.substring(string.lastIndexOf('\\') + 1, string.length);
    }    
	return fileName;
}
	
function userpresence_for_configuration_upload_download() {
	if (!configuration_upload_download_unlock_process) {
		var conf = confirm("Are you sure you want to unlock parameters?");
		if (conf) {
			$("#configuration_options_select").attr('disabled','disabled');
			$('#resultsft').html("");
			configuration_upload_download_unlock_process = true;
			$('.unlock_configuration_upload_download').addClass('disable_button');
			$('.ajax-loader').show();
			$("#contentcontents").mask("Unlocking parameters, Please wait");
			$.post("/access/request_user_presence", {}, function(response){
				if (response.user_presence) {
					$('#resultsft').html("<span class='success_message text_font'>"+response.message+"</span>").show().fadeOut(10000);
					$('.ajax-loader').hide();
					$("#contentcontents").unmask();
					$("#configuration_options_select").removeAttr("disabled");
					$("#user_presence").val("1");
					$('.unlock_configuration_upload_download').addClass('disable_button');
					$('#upload_configuration').removeClass('disable_button');
					$('#download_configuration').removeClass('disable_button');
				}else {
					upload_download_user_presence_req_state(response.request_id);
				}
			});
		}
	}else{
		configuration_upload_download_unlock_process = false;
	}
}

function upload_download_user_presence_req_state(req_id){
	var user_presence_req_id = req_id;
	var user_presence_timer_counter = 0;
	var delete_request = false;
	check_unlock_status_interval = setInterval(function(){
		if (!user_presence_req_check_process) {
			user_presence_req_check_process = true;
			unlock_status_xhr = $.post("/access/check_user_presence_request_state",{
				request_id: user_presence_req_id,
				delete_request: delete_request
			},function(response){
				user_presence_timer_counter++;
				if (response.request_state == "2") {
					var msg = "";
					configuration_upload_download_unlock_process = false;
					if (response.error == false) {
						$("#configuration_options_select").removeAttr("disabled");
						$("#user_presence").val("1");
						$('.unlock_configuration_upload_download').addClass('disable_button');
						msg = "<span class='success_message text_font'>" + response.message + "</span>";
						$('#upload_configuration').removeClass('disable_button');
						$('#download_configuration').removeClass('disable_button');
						$('#resultsft').html(msg).show().fadeOut(10000);
					}else {
						$("#configuration_options_select").attr('disabled','disabled');
						$("#user_presence").val("0");
						$('.unlock_configuration_upload_download').removeClass('disable_button');
						msg = "<span class='error_message text_font'>"+response.message +" </span>";
						$('#resultsft').html(msg).show();
					}
					$('.ajax-loader').hide();
					$("#contentcontents").unmask();
					clearInterval(check_unlock_status_interval);
				}else{
					if (user_presence_timer_counter >= 50) {
						$("#configuration_options_select").attr('disabled','disabled');
						var msg = "<span class='error_message text_font'>Unlocked reuqest timeout</span>";
						$('#resultsft').html(msg).show();
						configuration_upload_download_unlock_process = false;
						clearInterval(check_unlock_status_interval);
						$('.ajax-loader').hide();
						$("#contentcontents").unmask();
						$('.unlock_configuration_upload_download').removeClass('disable_button');
					}
				}
				if (user_presence_timer_counter >= 49) {
					delete_request = true;
				}
				user_presence_req_check_process = false;
			}, 'json');
		}
	}, 2000);
}
