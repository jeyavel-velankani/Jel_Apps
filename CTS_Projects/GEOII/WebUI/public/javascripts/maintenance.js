/**
 * @author Jeyavel Natesan
 */
var upload_vital_nonvital_interval;
var ecd_cic_interval;
var upload_status_xhr = null;
var mcf_name = '';

add_to_destroy(function(){
	$(document).bind("ready",function(){});

	//kills all wrapper events
	$('.unlock').w_die('click');
	$('.update_mef').w_die('click');
	$('#softwareupdate_form').w_die('submit')
	$('input').w_die('change');
	$('.update_ecd_cic').w_die('click');
	$('.unlock_required').w_die('click');
	
	//clear intervals
	clearInterval(upload_vital_nonvital_interval);
	clearInterval(ecd_cic_interval);
    
	//cancels previous request if it is still going
	if(typeof upload_status_xhr !== 'undefined' && upload_status_xhr != null){
        upload_status_xhr.abort();  
    }

	//clears global variables
	delete window.upload_vital_nonvital_interval;
	delete window.upload_status_xhr;
	delete window.ecd_cic_interval;
	delete window.clear_ecd_cic_inprog;
	delete window.mcf_name;

	//clears function
	delete window.upload_vital_nonvital_form;
	delete window.update_uploadfile_status;
	delete window.display_progress;
	delete window.validate_hexval;
	delete window.showpopupfunc;
	delete window.extractFileName;
	delete window.check_for_file_extention;
});

$(document).ready(function(){
	$('.unlock').addClass('session_flag');
	$('.unlock_required').addClass('session_flag');
	var user_presence = $("#user_presence").val();
    if (user_presence == 1){
		$('#fileToUpload').removeAttr("disabled");		
	 	$(".update_mef").removeClass("disabled");
		$(".unlock").addClass("disabled");
		$('#mcfcrc').removeAttr("disabled");
	}else{
	 	$('#fileToUpload').attr('disabled', 'disabled');
		$(".update_mef").addClass("disabled");
		$(".unlock").removeClass("disabled");
		$('#mcfcrc').attr('disabled', 'disabled');
	}
	
	$('.unlock').unlock('.status_message',function(unlock_resp){
		if(unlock_resp){
			var toolbar_items = $('.toolbar_button ')
			
			//updates the toolbar to not be locked anymore
			$(toolbar_items).removeClass('disabled');
			$(toolbar_items[0]).addClass('disabled');

			$('#softwareupdate_form input[type=file]').attr('disabled',false);

			//only remove disable and readonly if it is not locked
			$('.contentcontents').find('select, input').each(function(){
				if(!$(this).hasClass('locked')){
					$(this).removeClass('disable').removeClass('readonly').removeAttr('disabled').attr('disabled',false)
				}
			})
		}else{
			//do nothing because still locked
		}
	});

	$('.unlock_required').unlock('.status_message',function(unlock_resp){
		if(unlock_resp){
			reload_page();
		}else{
			//do nothing because still locked
		}
	});
});


function upload_vital_nonvital_form(resp){
	$('#fileToUpload').attr('disabled', 'disabled');
	var value_receive_flag = false;
	var msg ="";
	var count = 0; 
	if(resp == -2){
		$('#fileToUpload').removeAttr("disabled");
		$(".update_mef").removeClass("disabled");
		$('#status_message').html('');
		$("#status_message").html("<span class='error_message text_font'>Uploading Failed.</span>").show();
		return false;
	}
	if(resp){
		value_receive_flag = true;
	}
	if (value_receive_flag == true){
		$("#select_box").hide();
		var type_file = $("#type").attr('value');
		display_progress(true , type_file);
		update_uploadfile_status(0);
		var upload_status_check_process = false;
		upload_vital_nonvital_interval = setInterval(function(){
		    if(!upload_status_check_process){
		    	upload_status_check_process = true;
			    upload_status_xhr = $.post("/softwareupdate/upload_status",{
			    	request_id: resp
			    },function(response){
					update_uploadfile_status(response.percentage_complete);
					if (response.req_state == 2){
						display_progress(false , type_file);
						$('#fileToUpload').removeAttr("disabled");
						
						var file_wrapper = $('input[type=file]').parent();
						var inner_file = file_wrapper.html();
						file_wrapper.html('');
						file_wrapper.html(inner_file);
	
						$('#fileToUpload_path').attr('value','');
	
						clearInterval(upload_vital_nonvital_interval);
						$(".update_mef").removeClass("disabled");
						$('#status_message').html('');
						if (response.result == 200) {
							if (type_file == "MCF") {
								msg = "<span class='success_message text_font'>MCFCRC uploaded successfully and MCF file uploaded successfully.</span>";
								$('.current_mcf').html('MCF: '+mcf_name);
								$("#type").attr('value','MCF_WITH_MCFCRC');
								$('.current_mcf').show();
								$('.current_mcfcrc').show();
							}
							else if (type_file == "MEF") {
								msg = "<span class='success_message text_font'>MEF file uploaded successfully.</span>";
							}else if (type_file == "tgz") {
								var answer = confirm ("Reboot is required to load the new software.\nPress OK to continue.");
								if (answer){
									$.post("softwareupdate/rebootrequest", {}, function(request_state){});
									msg = "<span class='success_message text_font'>File uploaded successfully. System will reboot to load the new software. This may take several minutes.</span>";
								}
								else{
									msg = "<span class='success_message text_font'>File uploaded successfully.</span>";	
								}
							}
							$("#status_message").html(msg).show();
						}else{
							msg = "<span class='error_message text_font'>"+response.error_message+"</span>"
							$("#status_message").html(msg).show();
						}
					}else{
						count++;
						if (count == 300){ // 10 minutes TimeOUT - 600 seconds
							display_progress(false , type_file);
							$('#fileToUpload').removeAttr("disabled").attr('value','');
							$('#fileToUpload_path').attr('value','');
							clearInterval(upload_vital_nonvital_interval);
							$(".update_mef").removeClass("disabled");
							$('#status_message').html('');
							msg = "<span class='error_message text_font'>Uploading file Timed Out</span>"
							$("#status_message").html(msg).show();
						}
					}
					upload_status_check_process = false;
			    });
		    }
		},2000);
	}
}

function update_uploadfile_status(percentage_complete){
	var parcent_val =0;
	if (percentage_complete) {
		parcent_val = percentage_complete;
	}
	$("#display_progressbar").progressbar({value: parcent_val});
	document.getElementById("display_progressbar_val").innerHTML = "Uploading Status - " + parcent_val + "% Completed";
}

function display_progress(display_flag , type){
	if ((display_flag == true) && (type != 'MCFCRC')){
		$("#display_process_status").show();
		$("#display_progressbar").show();
		$("#display_progressbar_image").hide();
		$("#select_box").hide();
		$("#progress_without_percentage").hide();
	}else if ((display_flag == true) && (type == 'MCFCRC')) {
		$("#display_process_status").hide();
		$("#select_box").hide();
		$("#progress_without_percentage").show();
	}else {
		$("#display_process_status").hide();
		$("#progress_without_percentage").hide();
		$("#select_box").show();
		if(type != 'MCFCRC'){
			$('#softwareupdate_mrfcrc').show();
		}
	}
}

function validate_hexval(mcfcrc){
	var objPattern = /^[0-9A-Fa-f]+$/i;
	if ((mcfcrc != null) && (mcfcrc != "")) {
		if (!objPattern.test(mcfcrc)){
			alert("Please enter the MCFCRC value in Hexa Decimal[0-9, A-F]");
			document.getElementById('mcfcrc').value = "";
			return false;
		}else {
			return true;
		}
	}else{
		alert("Please enter the MCFCRC");
		return false;
	}
}

function showpopupfunc(){
	var file_name = extractFileName($("#fileToUpload").val());
	var valid_file_ext = check_for_file_extention($('#update_type').val(), file_name );
    if(valid_file_ext){
		return file_name;
	}	
}

function extractFileName(string) {
    if (string.indexOf('/') > -1) {
        fileName = string.substring(string.lastIndexOf('/') + 1, string.length);
    }else {
        fileName = string.substring(string.lastIndexOf('\\') + 1, string.length);
    }    
	return fileName;
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
		case '1':
			if( f_ext != "mcf")
				msg = "MCF";
			break;		
		case '2':
			if( f_ext != "mef")
				msg = "MEF";
			break;
		case '16':
			if( f_ext != "tgz")
				msg = "TGZ";
			break;			
	}
	if (msg != "") {
		$("#status_message").html('');
		var error_msg = "<span class='error_message text_font'> Please select valid " + msg + " file </span>";
		$("#status_message").html(error_msg).show();
		return false;
	}
	return true;	
}

$('#softwareupdate_form, #softwareupdate_mrfcrc').submit(function(e) {
	var options = {
	    success:    function(resp) { 
		   if (resp && resp != null) {
		   		upload_vital_nonvital_form(resp);
		   }else{
		   		if($("#type").attr('value') == 'MCF_WITH_MCFCRC'){
			   		$("#type").attr('value',"MCF");
			   		$('input[name=update_type]').val(1);
			   		
			   		$('.current_mcf').hide();
			   		$('.current_mcfcrc').hide();
			   		$('.current_mcfcrc').html('MCFCRC: '+$('input[name=mcfcrc]').val());
			   		var cur_mcfname  = $('#fileToUpload_path').val().split('\\');
					mcf_name = cur_mcfname[cur_mcfname.length-1];

					$('#softwareupdate_form').submit();
			   	}else{
			   		var msg = "<span class='success_message text_font'>MCFCRC uploaded successfully.</span>";
					$("#status_message").html(msg).show();
					$('#mcfcrc').attr('value','');
					$(".update_mef").removeClass("disabled");
			   	}
		   }
	    } 
	};
    $(this).ajaxSubmit(options);
	return false; 
});

$(".update_mef").w_click(function(){
	$('#status_message').html('');
    if (!jQuery(this).hasClass('disabled')) {
		if ($("#type").attr('value') == "MCFCRC") {
			var mcfcrc = $('input[name=mcfcrc]').val();
			if (validate_hexval(mcfcrc)) {
				$(".update_mef").addClass("disabled");
				remove_v_preload_page();
				$('#softwareupdate_form').submit();
			}
		}else{
			if($("#type").attr('value') == "MCF_WITH_MCFCRC"){
				var mcfcrc = $('input[name=mcfcrc]').val();
				if (validate_hexval(mcfcrc)) {
					var file_name = showpopupfunc();
					if (file_name) {
						$(".update_mef").addClass("disabled");
						remove_v_preload_page();
						$('#softwareupdate_form').submit();
						$('#softwareupdate_mrfcrc').hide();
					}
				}
			}else if($("#type").attr('value') == "MCF"){
				var mcfcrc = $('input[name=mcfcrc]').val();
				if (validate_hexval(mcfcrc)) {
					var file_name = showpopupfunc();
					if (file_name) {
						$(".update_mef").addClass("disabled");
						remove_v_preload_page();
						$('#softwareupdate_form').submit();
						$('#softwareupdate_mrfcrc').hide();
					}
				}
			}else{
				var file_name = showpopupfunc();
				if (file_name) {
					remove_v_preload_page();
					$(".update_mef").addClass("disabled");
					$('#softwareupdate_form').submit();
				}
			}
		}
	}
});

//will notify user that they did not save or submit there changes
$('input').w_change(function(){
	preload_page = function(){
		ConfirmDialog('Software Update','You did not update software.<br>Would you like to leave page?',function(){
			if(typeof item_clicked == 'object'){
				preload_page_finished();
			}
			preload_page = '';
		},function(){
			//don't load the next page
		});
	};
});

var clear_ecd_cic_inprog = false;
$('.update_ecd_cic').w_click(function(){
	 if (!$(this).hasClass('disabled')) {
		if(usb_enabled_flag && $.trim($('#clear_type').val()) == 'ecd'){
			ConfirmDialog('ECD','Clearing ECD will reboot the CPU.<br>Do you still want to clear it?',function(){
				clear_ecd_cic();
			},function(){
				//don't clear ecd.
			});
		}else{
			clear_ecd_cic();
		}
	}
});

function clear_ecd_cic(){
	if(!clear_ecd_cic_inprog){
		clear_ecd_cic_inprog = true;

		if(!usb_enabled_flag || (usb_enabled_flag && $('#clear_type').val() != 'ecd')){
			$( "#progressbar" ).show();
			$( "#progressbar" ).progressbar({
		      value: 0
		    });
		}

		$.post('/softwareupdate/ecd_cic_request/',{
			type:$('#clear_type').val()
		},function(request_id){
			var check_in_progress = false;
			var prev_precent = 0;
			var timeout_counter = 0;

			ecd_cic_interval = setInterval(function(){
				if(!check_in_progress){
					check_in_progress = true;
					
					$.post('/softwareupdate/check_ecd_cic_request/',{
						request_id:request_id
					},function(ecd_cic_resp){
						if(timeout_counter == 12){
							clear_ecd_cic_inprog = false;
							clearInterval(ecd_cic_interval);
							timeout_counter = 0; 
							prev_precent = 0;
							$( "#progressbar" ).hide();
						}else if(parseInt(ecd_cic_resp['request_state']) == 2){
							clear_ecd_cic_inprog = false;
							clearInterval(ecd_cic_interval);
							$( "#progressbar" ).hide();
							$('.status_message').success_message($('#clear_type').val()+' is cleared');
						}else{
							if(parseInt(ecd_cic_resp['percentage']) != prev_precent){
								prev_precent = parseInt(ecd_cic_resp['percentage']);
								timeout_counter = 0; 
								if(prev_precent==100 && usb_enabled_flag && $.trim($('#clear_type').val()) == 'ecd'){
									$('.status_message').success_message($('#clear_type').val()+' is cleared. CP is rebooting.');
									setTimeout("window.location = '/access/logout'", 2000);
								}else{
									$( "#progressbar" ).progressbar({
								      value: prev_precent
								    });
								}
							}else{
								timeout_counter++;
							}
						}

						check_in_progress = false;
					},'json');	
				}
			},5000);
		});
	}
}
