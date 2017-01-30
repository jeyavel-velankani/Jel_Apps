var options_status_interval;
var update_console_interval;
var console_text_interval;
var update_answer_interval;
var show_progress_interval;
var cancel_mcfcrc_interval;
var exit_software_interval;
var question_ans_interval;
var get_update_options_interval;
var user_presence_process_interval;
var user_level_status_interval;
var softwareupdate_unlock_process = false;
var user_presence_req_check_process = false;

var options_status_xhr = null;
var update_console_xhr = null;
var console_text_xhr = null;
var update_answer_xhr = null;
var show_progress_xhr = null;
var cancel_mcfcrc_xhr = null;
var exit_software_xhr = null;
var question_ans_xhr = null;
var update_options_xhr = null;
var user_presence_process_xhr = null;
var user_level_status_xhr = null;

$(document).ready(function(){
	add_to_destroy(function(){
		$(document).bind("ready",function(){});
	
		//kills all wrapper events
		$('#cancel_upload_mcfcrc').w_die('click');
		$('#upload_mcfcrc').w_die('keyup');
		$('#upload_mcfcrc').w_die('click');
		$('.question_ans').w_die('click');
		$('.leftnavtext_opt').w_die('click');
		$('.question_ans').w_die('click');
		$('#install_software').w_die('click');
		$('#show_console').w_die('click');
		$('#unlock_software_update').w_die('click');
		$('.cancel_upload_file_process').w_die('click');
		$('#dwonload_console_log').w_die('click');
		$('#fileToUpload').w_die('change');

		//clear intervals
		if(typeof options_status_interval !== 'undefined' && options_status_interval != null){
			clearInterval(options_status_interval);
	    }
		clearInterval(update_console_interval);
		clearInterval(console_text_interval);
		clearInterval(update_answer_interval);
		clearInterval(show_progress_interval);
		clearInterval(cancel_mcfcrc_interval);
		clearInterval(exit_software_interval);
		clearInterval(question_ans_interval);
		clearInterval(get_update_options_interval);
		clearInterval(user_presence_process_interval);
		clearInterval(user_level_status_interval);
		
		//cancels previous request if it is still going
		if(typeof options_status_xhr !== 'undefined' && options_status_xhr != null){
	        options_status_xhr.abort();  
	    }
		if(typeof update_console_xhr !== 'undefined' && update_console_xhr != null){
	        update_console_xhr.abort();  
	    }
		if(typeof console_text_xhr !== 'undefined' && console_text_xhr != null){
	        console_text_xhr.abort();  
	    }
		if(typeof update_answer_xhr !== 'undefined' && update_answer_xhr != null){
	        update_answer_xhr.abort();  
	    }
		if(typeof show_progress_xhr !== 'undefined' && show_progress_xhr != null){
	        show_progress_xhr.abort();  
	    }
		if(typeof cancel_mcfcrc_xhr !== 'undefined' && cancel_mcfcrc_xhr != null){
	        cancel_mcfcrc_xhr.abort();  
	    }
		if(typeof exit_software_xhr !== 'undefined' && exit_software_xhr != null){
	        exit_software_xhr.abort();  
	    }
		if(typeof question_ans_xhr !== 'undefined' && question_ans_xhr != null){
	        question_ans_xhr.abort();  
	    }
		if(typeof update_options_xhr !== 'undefined' && update_options_xhr != null){
	        update_options_xhr.abort();  
	    }
		if(typeof user_presence_process_xhr !== 'undefined' && user_presence_process_xhr != null){
	        user_presence_process_xhr.abort();  
	    }
		if(typeof user_level_status_xhr !== 'undefined' && user_level_status_xhr != null){
	        user_level_status_xhr.abort();  
	    }

		//clear functions 
		delete window.update;
		delete window.show_submit_progress;
		delete window.options_enable_and_disable;
		delete window.check_console_text;
		delete window.update_console_timer;
		delete window.module_userpresence_request;
		delete window.module_userpresence_request_status;
		delete window.options_enable_poll;
		delete window.upload_inprogress_display;
		delete window.upload_inprogress_display_cancel;

		//clears global variables
		delete window.options_status_interval;
		delete window.update_console_interval;
		delete window.console_text_interval;
		delete window.update_answer_interval;
		delete window.show_progress_interval;
		delete window.cancel_mcfcrc_interval;
		delete window.exit_software_interval;
		delete window.question_ans_interval;
		delete window.get_update_options_interval;
		delete window.user_presence_process_interval;
		delete window.user_level_status_interval;
		
		delete window.options_status_xhr;
		delete window.update_console_xhr;
		delete window.console_text_xhr;
		delete window.update_answer_xhr;
		delete window.show_progress_xhr;
		delete window.cancel_mcfcrc_xhr;
		delete window.exit_software_xhr;
		delete window.question_ans_xhr;
		delete window.update_options_xhr;
		delete window.user_presence_process_xhr;
		delete window.user_level_status_xhr;
	});
});
$("#upload_mcfcrc").w_keyup(function(){
	var strVal = $('#upload_mcfcrc').val().toUpperCase();
	$(this).val(strVal);
});
$("#cancel_upload_mcfcrc").w_click(function(){
	if (!$(this).hasClass('disable_button')) {
		$('#cancel_upload_mcfcrc').addClass('disable_button');
		$('#upload_mcfcrc').addClass('disable_button');
		var mcfcrc_val = 0;
		var console_id = $('#console_id_and_upload_id').val();
		var file_type = $('#update_type').val();
		$('.ajax-loader').show();
		$.post("/softwareupdate/update_answer", {
			answer: mcfcrc_val,
			console_id: console_id,
			file_type: file_type
		}, function(resp){
			var cancel_mcfcrc_request_in_process = false;
			cancel_mcfcrc_interval = setInterval(function(){
				if (!cancel_mcfcrc_request_in_process){
					cancel_mcfcrc_request_in_process = true;
					cancel_mcfcrc_xhr = $.post("/softwareupdate/questions_status", {
						console_id: console_id
					}, function(questions_status_resp){
						if (questions_status_resp && questions_status_resp.result == '202') {
							clearInterval(cancel_mcfcrc_interval);
							$.post("/softwareupdate/read_questions", {
								console_id: questions_status_resp.console_id
							}, function(questions){
								$('.ajax-loader').hide();
								$('#upload_question_display').html('');
								$('#upload_question_display').hide();
								$('#install_software').addClass('disable_button');
							});
						}
						cancel_mcfcrc_request_in_process = false;
					});
				}
			}, 1000);
		});
	}
});

$("#upload_mcfcrc").w_click(function(){
	if (!$(this).hasClass('disable_button')) {
		$('#cancel_upload_mcfcrc').addClass('disable_button');
		$('#upload_mcfcrc').addClass('disable_button');
		var intRegex = /^[0-9A-Fa-f]+$/;
		var mcfcrc_val = $('#mcfcrc_uploadtext').val();
		if (mcfcrc_val && parseInt(mcfcrc_val, 16) != 0) {
			mcfcrc_val = pad(mcfcrc_val, 8);
			$('#mcfcrc_uploadtext').val(mcfcrc_val);
			if (intRegex.test(mcfcrc_val)) {
				var console_id = $('#console_id_and_upload_id').val();
				var file_type = $('#update_type').val();
				$('.ajax-loader').show();
				$.post("/softwareupdate/update_answer", {
					answer: mcfcrc_val,
					console_id: console_id,
					file_type: file_type
				}, function(resp){
					var request_in_process_2 = false;
					update_answer_interval = setInterval(function(){
						if (!request_in_process_2){
							request_in_process_2 = true;
						update_answer_xhr = $.post("/softwareupdate/questions_status", {
							console_id: console_id
						}, function(questions_status_resp){
							if (questions_status_resp && questions_status_resp.result == '200') {
								clearInterval(update_answer_interval);
								$.post("/softwareupdate/read_questions", {
									console_id: questions_status_resp.console_id
								}, function(questions){
									if (!questions) {
										$('.ajax-loader').hide();
										$('#upload_question_display').html('');
										$('#upload_question_display').hide();
										$('#install_software').addClass('disable_button');
									}
								});
							}
							request_in_process_2 = false;
						});
						}
					}, 3000);
				});
			}
			else {
				$('#cancel_upload_mcfcrc').removeClass('disable_button');
				$('#upload_mcfcrc').removeClass('disable_button');
				alert("Please enter valid hexa decimal value");
				$('#mcfcrc_uploadtext').focus();
			}
		}
		else {
			$('#cancel_upload_mcfcrc').removeClass('disable_button');
			$('#upload_mcfcrc').removeClass('disable_button');
			alert("Please enter MCFCRC and try again.");
			$('#mcfcrc_uploadtext').focus();
		}
	}
});

$(".question_ans").w_click(function(){
	var children = $('.upload_question_display').children();
	children.each(function(i, ele){
         $(ele).removeClass('question_ans').addClass('disabled_link');
    });	
	var file_type = $('#update_type').val();
	$('.ajax-loader').show();
	var ele_value = $(this).attr('value');
	var console_id = $('#console_id_and_upload_id').val();
	$.post("/softwareupdate/update_answer", {answer : ele_value , console_id : console_id , file_type : file_type }, function(resp){
		var question_ans_request_in_process = false;
		question_ans_interval = setInterval(function(){
			if (!question_ans_request_in_process) {
				question_ans_request_in_process = true;
				question_ans_xhr = $.post("/softwareupdate/questions_status", { console_id : console_id }, function(questions_status_resp){
				if(questions_status_resp && questions_status_resp.result == '200'){
					clearInterval(question_ans_interval);
					$.post("/softwareupdate/read_questions", { console_id : questions_status_resp.console_id }, function(questions){
						$('.ajax-loader').hide();
						if (questions) {
							$('#upload_question_display').html('');
							document.getElementById('upload_question_display').style.display = 'block';
							$('#upload_question_display').show();
							var sub_questions_display = "";
							if (parseInt(questions.question_type) == 1) {
								//YES/No Question 
								if(questions.question.length > 80){
									questions.question = "Erase the Flash Area (Y/N)?";
								}
								sub_questions_display = questions.question + "&nbsp;&nbsp;<a href='javascript:void(0)' class='question_ans' value='Yes'>Yes</a>&nbsp;&nbsp;<a href='javascript:void(0)' class='question_ans' value='No'>No</a>";
								$('#upload_question_display').html(sub_questions_display);
							}else if (parseInt(questions.question_type) == 2) {
								//CRC Question 
								sub_questions_display = "Enter the MCFCRC(HEX)"+"&nbsp;&nbsp;<input type='text' id='mcfcrc_uploadtext' class='mcfcrc_uploadtext' maxlength ='8'/>&nbsp;&nbsp;<a href='javascript:void(0)' id='upload_mcfcrc' title='Update'><img alt='Update_arte' src='/images/update_arte.png?1340814543'/></a>";
								sub_questions_display += "&nbsp;<a href='javascript:void(0)' id='cancel_upload_mcfcrc' title='Cancel'><img alt='Cancel' src='/images/cancelmouseover.png'/></a>"
								$('#upload_question_display').html(sub_questions_display);
							}else if (parseInt(questions.question_type) == 3) {
								//TEXT Question 
							}else if (parseInt(questions.question_type) == 4) {
								//File Question 
								$("#fileToUpload").removeAttr('disabled');
								document.getElementById('fileToUpload_path').value = "";
								document.getElementById('serial_outer_upload').style.display = 'block';
							}
						}else{
							$('#upload_question_display').html("");
						}
					});
				}
				question_ans_request_in_process = false;
			});
			}
		},2000);
	});
});

$(".leftnavtext_opt").w_click(function(){
	document.getElementById('serial_outer_upload').style.display = 'none';
	$("#download_options_status").hide();
	var options_selected = this.innerHTML;
	var id = this.id;
	$('#target').attr('value',4);
	if(parseInt(id) == 21){
		options_enable_and_disable(false)
		$('#install_software').addClass('disable_button');
		$('.ajax-loader').show();
		var exit_setup_counter = 0;
		var console_id = $('#console_id_and_upload_id').val();
		$.post('/softwareupdate/exit_softwareupdate', { console_id : 	console_id		
		}, function(response){
			if (response){
				$('.ajax-loader').show();
				var exit_software_request_in_process = false;
				exit_software_interval = setInterval(function(){
					exit_setup_counter++;
					if(!exit_software_request_in_process){
						exit_software_request_in_process = true;
						exit_software_xhr = $.post('/softwareupdate/exit_setup_status', {console_id : 	console_id}, function(response_exit_setup){
							if ((parseInt(response_exit_setup.request_state) == 2) || (exit_setup_counter >= 15) ){
								clearInterval(exit_software_interval);
								if(exit_setup_counter >= 15){
									$.post('/softwareupdate/exit_setup_timeout', {}, function(resp_exit_setup_timeout){});
								}
								upload_inprogress_display_cancel(); // Cancel the in-progress message display while navigate away from this page
								$('#stop_sw_update_timer').attr('value','yes');
								$('#stop_sw_options_reading').attr('value','yes');
								$('#upload_question_display').html('');
								$('#upload_question_display').hide();
								document.getElementById('serial_outer_upload').style.display = 'none';
								$('#files_category').html();
								$('#upload_files_list').html('');
								$('#files_category').hide();
								$('#upload_files_list').hide('');
								$('.ajax-loader').hide();
								$('#install_software').removeClass('disable_button');	
							}
							exit_software_request_in_process = false;
						});
					}
				},2000);
			}
		});
	}else{

		$('#update_type').attr('value',id);	
		var file_type = $('#update_type').val();
		var console_id = $('#console_id_and_upload_id').val();
		$('.ajax-loader').show();
		var request_get_ques_progress = false;
		$.post("/softwareupdate/get_questions", {options_selected : id , console_id : console_id , file_type : file_type }, function(questions_resp){
			get_questions_interval = setInterval(function(){
				if (!request_get_ques_progress) {
					request_get_ques_progress = true;
					$.post("/softwareupdate/questions_status", {
						console_id: questions_resp.console_id
					}, function(questions_status_resp){
						request_get_ques_progress = false;
						if (questions_status_resp && parseInt(questions_status_resp.result) == 200) {
							if (questions_status_resp.console_id){
								console_id = questions_status_resp.console_id
							}
							clearInterval(get_questions_interval);
							$.post("/softwareupdate/read_questions", {
								console_id: console_id
							}, function(questions){
								$('#upload_question_display').html('');
								document.getElementById('upload_question_display').style.display = 'block';
								var type_of_question = "";
								if (parseInt(questions.question_type) == 1) {
									//YES/No Question 
									if (questions.question.length > 80) {
										questions.question = "Erase the Flash Area (Y/N)?";
									}
									type_of_question = questions.question + "&nbsp;&nbsp;<a href='javascript:void(0)' class='question_ans' value='Yes'>Yes</a>&nbsp;&nbsp;<a href='javascript:void(0)' class='question_ans' value='No'>No</a>";
									$('#upload_question_display').html(type_of_question);
									$('.ajax-loader').hide();
								}else if (parseInt(questions.question_type) == 2) {
									//CRC Question 
									type_of_question = "Enter the MCFCRC(HEX)" + "&nbsp;&nbsp;<input type='text' id='mcfcrc_uploadtext' class='mcfcrc_uploadtext' maxlength ='8'/>&nbsp;&nbsp;<a href='javascript:void(0)' id='upload_mcfcrc' title='Update'><img alt='Update_arte' src='/images/update_arte.png?1340814543'/></a>";
									type_of_question += "&nbsp;<a href='javascript:void(0)' id='cancel_upload_mcfcrc' title='Cancel'><img alt='Cancel' src='/images/cancelmouseover.png'/></a>"
									$('#upload_question_display').html(type_of_question);
									$('.ajax-loader').hide();
								}else if (parseInt(questions.question_type) == 3) {
									//TEXT Question 
									$('.ajax-loader').hide();
								}else if (parseInt(questions.question_type) == 4) {
									//File Question 
									 $("#fileToUpload").removeAttr('disabled');
									document.getElementById('fileToUpload_path').value = "";
									document.getElementById('serial_outer_upload').style.display = 'block';
									$('.ajax-loader').hide();
								}
							});
						}
					});
				}
			},2000);
			
		});
	}
});

$("#install_software").w_click(function(){
	if (!$(this).hasClass('disable_button')) {
		if (confirm("Please check the serial port connection\nbefore uploading")) {
			if (confirm("Installing software will cause the\nCPU/Module to reboot and\ncommunication will be lost.\n\nContinue with the software update?\n")) {
					//clears file input for ie
			var file_input = $('#fileToUpload_path');

			if ($.browser.msie) {
	            file_input.replaceWith(file_input.clone());
		    }else{
		        file_input.val('');
		    }

				$('#install_software').addClass('disable_button');
				$('#files_category').hide();
				$('#upload_question_display').html();
				$('#upload_question_display').hide();
				$('.ajax-loader').show();
				$('#upload_files_console_log').html('');
				$.post("/softwareupdate/initiate_softwareupdate", {}, function(init_resp){
					check_console_text();
					$("#current_req_id").val(init_resp.request_id);
					if (init_resp.request_id) {
						upload_inprogress_display(); // display the in-progress message while navigate away from the page
						update_console_timer();
						var request_id_init = init_resp.request_id;
						var get_update_options_request_in_process = false;
						get_update_options_interval = setInterval(function(){
							if(!get_update_options_request_in_process){
								get_update_options_request_in_process = true;
							update_options_xhr = $.post("/softwareupdate/get_software_update_options_status", {
								console_id: request_id_init
							}, function(init_status_resp){
								if (init_status_resp.percentage_complete) {
									$('#download_options_status').show();
									$("#display_progressbar").progressbar({
										value: init_status_resp.percentage_complete
									});
									document.getElementById("display_progressbar_val").innerHTML = "Processing Status - " + init_status_resp.percentage_complete + "% Completed";
								}
								else {
									$('#download_options_status').hide();
								}
								if (init_status_resp.result == '200') {
									clearInterval(get_update_options_interval);
									$.post("/softwareupdate/get_software_update_options", {
										console_id: init_status_resp.request_id
									}, function(resp){
										$('.ajax-loader').hide();
										$('#download_options_status').hide();
										$('#files_category').show();
										options_enable_poll();
									});
								}
								else 
									if (init_status_resp.result == '202') {
										clearInterval(get_update_options_interval);
										$('.ajax-loader').hide();
										upload_inprogress_display_cancel(); // Cancel the in-progress message display while navigate away from this page
										alert(init_status_resp.error_message);
										reload_page();
									}
									get_update_options_request_in_process = false;
							});
							}
						}, 2000);
					}else {
						upload_inprogress_display_cancel(); // Cancel the in-progress message display while navigate away from this page
						$.post("/softwareupdate/get_software_update_options", {
							console_id: init_resp.request_id
						}, function(resp){
							$('.ajax-loader').hide();
							$('#files_category').show();
							$('#download_options_status').hide();
							var user_level_status_request_in_process = false;
							user_level_status_interval = setInterval(function(){
								if(!user_level_status_request_in_process){
									user_level_status_request_in_process = true;
									user_level_status_xhr = $.post("/softwareupdate/get_fileupload_user_level_status", {//no params
									}, function(fileupload_user_level_status_resp){
										if (fileupload_user_level_status_resp.percentage_complete && fileupload_user_level_status_resp.percentage_complete != '100') {
											clearInterval(user_level_status_interval);
											$('#download_options_status').show();
											$("#display_progressbar").progressbar({
												value: fileupload_user_level_status_resp.percentage_complete
											});
											document.getElementById("display_progressbar_val").innerHTML = "Uploading files - " + fileupload_user_level_status_resp.percentage_complete + "% Completed";
										}
										else {
											$('#download_options_status').hide();
										}
										user_level_status_request_in_process = false;
									});
								}
							}, 2000);
						});
					}
				});
			}
			else {
				document.getElementById('serial_outer_upload').style.display = 'none';
				$('#files_category').hide();
			}
		}else{
			document.getElementById('serial_outer_upload').style.display = 'none';
			$('#files_category').hide();
		}
	}
});

$("#show_console").w_click(function(){
	var img_src = $(this).find('img').attr('src');

	if(img_src.indexOf('/')!=-1){
		img_src = img_src.split('/');
	}else{
		img_src = img_src.split('\\');
	}
	img_src  =img_src[img_src.length-1];

	if(img_src == 'show_console_log.png'){
		img_src = '/images/hide_console_log.png';
	}else{
		img_src = '/images/show_console_log.png';
	}

	$(this).find('img').attr('src',img_src);

	$("#upload_files_console_log").fadeToggle("fast");
});

$("#unlock_software_update").w_click(function(){
	module_userpresence_request();
});

$(".cancel_upload_file_process").w_click(function(){
	if (!$(this).hasClass('disable_button')) {
		if (confirm("Do you want Cancel software upload process")) {
			$(".cancel_upload_file_process").addClass('disable_button');
			$('.ajax-loader').show();
			var cancel_console_id = $('#console_id_and_upload_id').val();
			$.post("/softwareupdate/abort_cancel_sw_update", {
				console_id: cancel_console_id
			}, function(abort_response){
				$('#software_download_progress').hide();
				var request_id = abort_response.request_id
				var abort_sw_status_request_in_process = false;
				var abort_sw_status_timer = setInterval(function(){
					if(!abort_sw_status_request_in_process){
						abort_sw_status_request_in_process = true;
						$.post("/softwareupdate/abort_cancel_sw_update_status", {
							request_id : request_id
						}, function(abort_cancel_sw_status_response){
							if (abort_cancel_sw_status_response.request_state == '2') {
								clearInterval(abort_sw_status_timer);
								$("#update_softwareupdate_status").html('');
								$('.ajax-loader').hide();
								$('#upload_question_display').html('');
								$('#upload_question_display').hide();
							}
							abort_sw_status_request_in_process = false;
						});
						}
				},4000);
			});
		}
	}
});

$("#dwonload_console_log").w_click(function(){
	if (!$(this).hasClass('disable')) {
		$('.ajax-loader').show();
		$('#dwonload_console_log').addClass('disable');
		var cancel_console_id = $('#console_id_and_upload_id').attr('value');
		if (!cancel_console_id){
			cancel_console_id ="";
		}
		$.post("/softwareupdate/download_console_log", {
			console_id: cancel_console_id
		}, function(response){
			var download_path = "/softwareupdate/download_txtfile?id=" + response.full_path + "&filename=" + response.file_name;
			$('#dwonload_console_log').removeClass('disable');
			$('.ajax-loader').hide();
			downloadURL(download_path);
		});
	}
});

function downloadURL(dl_url) {
	var iframe;
	var hiddenIFrameID = 'hiddenDownloader';
	iframe = document.getElementById(hiddenIFrameID);
	if (iframe === null) {
	    iframe = document.createElement('iframe');
	    iframe.id = hiddenIFrameID;
	    iframe.style.display = 'none';
	    document.body.appendChild(iframe);
	}
	iframe.src = dl_url;
}

function pad (str, max) {
	return str.length < max ? pad("0" + str, max) : str;
}

function update(){
	$("#software_update_form").submit();
}

function show_submit_progress(){
	$('#download_options_status').show();
	$('#fileToUpload').attr('disabled','disabled');
	document.getElementById('serial_outer_upload').style.display = 'none';
	$("#display_progressbar").progressbar({ value: 0 });
	document.getElementById("display_progressbar_val").innerHTML = "Uploading files - 0% Completed";
	var request_ct_id = $('#current_req_id').val();
	var show_progress_request_in_process = false;
	show_progress_interval = setInterval(function(){
		if (!show_progress_request_in_process){
			show_progress_request_in_process = true;
		    show_progress_xhr = $.post("/softwareupdate/softwareupdate_upload_status", {request_id:request_ct_id }, function(resp){
			if (resp) {
				if (resp.percentage_complete) {
					$('#download_options_status').show();
					$("#display_progressbar").progressbar({
						value: resp.percentage_complete
					});
					document.getElementById("display_progressbar_val").innerHTML = "Uploading files - " + resp.percentage_complete + "% completed";
					if (resp.result == '200') {
						if (resp.percentage_complete == '100') {
							$("#display_progressbar").progressbar({
								value: resp.percentage_complete
							});
							document.getElementById("display_progressbar_val").innerHTML = "Uploaded files successfully.";
							clearInterval(show_progress_interval);
							clearInterval(cancel_mcfcrc_interval);
							clearInterval(question_ans_interval);
						}
					}
					else 
						if (resp.result == '202') {
							clearInterval(show_progress_interval);
							if (resp.error_message) {
								document.getElementById("display_progressbar_val").innerHTML = "<span style='color:red;font-size:13px;'>" + resp.error_message + "</span>";
							}else {
								document.getElementById("display_progressbar_val").innerHTML = "<span style='color:red;font-size:13px;'>" + "Upload failed" + "</span>";
							}
						}
				}
			}else{
				$('#download_options_status').hide();
				clearInterval(show_progress_interval);
			}
			show_progress_request_in_process = false;
		});}
	}, 3000);		
}

function options_enable_and_disable(optionsflag){
	if (optionsflag == true) {
		var children = $('.optionslist').children();
		children.each(function(i, ele){
	         $(ele).removeClass('disable_options').addClass('leftnavtext_opt');
	    });	
	}else{
		var children = $('.optionslist').children();
		children.each(function(i, ele){
	         $(ele).removeClass('leftnavtext_opt').addClass('disable_options');
	    });	
	}
}

function check_console_text(){
	var display_text = "";
	var console_id ;
	var console_text_request_in_process = false;
	console_text_interval = setInterval(function(){
		if(!console_text_request_in_process){
			console_text_request_in_process = true;
			console_id = $('#console_id_and_upload_id').val();
			var stop_sw_update = $('#stop_sw_update_timer').val();
			if (stop_sw_update == 'yes') {
				clearInterval(console_text_interval);
				$('#upload_files_console_log').html('');
				reload_page();
			}else {
				if (console_id == undefined || console_id == null || console_id == "") {
					display_text = 'all'
				}
				console_text_xhr = $.post('/softwareupdate/get_console_text', {
					console_id: console_id,
					display_text: display_text
				}, function(console_texts){
					$('#upload_files_console_log').html('');
					$('#upload_files_console_log').html(console_texts.text.replace(/(\r\n|\n|\r)/gm, "<BR>"));
					$("#upload_files_console_log").scrollTop(document.getElementById('upload_files_console_log').scrollHeight);
				});
			}
		console_text_request_in_process = false;
		}
	}, 5000);
}

function update_console_timer(){
	var update_console_request_in_process = false;
	update_console_interval = setInterval(function(){
		if(!update_console_request_in_process){
			update_console_request_in_process = true;
			update_console_xhr = $.post("/softwareupdate/update_console_last_viewed", {}, function(resp){
				update_console_request_in_process = false;
				clearInterval(update_console_interval);
			});
		}
	},2000);
}

function module_userpresence_request() {
	if (!softwareupdate_unlock_process) {
		softwareupdate_unlock_process = true;
		var user = $('#user_presence').val();
		if (user == 0) {
			var conf = confirm("Are you sure you want to unlock parameters?"); 
			if (conf) {
				$('.unlock_software_update').addClass('disable_button');
				$('.ajax-loader').show();
				$("#contentcontents").mask("Unlocking parameters, Please wait");
				$.post("/access/request_user_presence", {session_flag: false}, function(response){
					if(response.user_presence){
						$('#resultsft').html("<span class='success_message text_font'>"+response.message+"</span>").show().fadeOut(10000);
						$('.ajax-loader').hide();
						$("#user_presence").val("1");
						$("#contentcontents").unmask();
						$('.unlock_software_update').addClass('disable_button');
						$('#install_software').removeClass('disable_button');
					}else{
						module_userpresence_request_status(response.request_id);
					}
				});
			}else{
				softwareupdate_unlock_process = false;
			}
		}
	}
}

function module_userpresence_request_status(req_id){
	var user_presence_req_id = req_id;
	var user_presence_timer_counter = 0;
	var delete_request = false;
	user_presence_process_interval = setInterval(function(){
		if (!user_presence_req_check_process) {
			user_presence_req_check_process = true;
			user_presence_process_xhr = $.post("/access/check_user_presence_request_state",{
				request_id: user_presence_req_id,
				delete_request: delete_request
			}, function(response){
				user_presence_timer_counter++;
				if (response.request_state == "2") {
					var msg = "";
					softwareupdate_unlock_process = false;
					if (response.error == false) {
						$("#user_presence").val("1");
						$('.unlock_software_update').addClass('disable_button');
						msg = "<span class='success_message text_font'>" + response.message + "</span>";
						$('#install_software').removeClass('disable_button');
						$('#resultsft').html(msg).show().fadeOut(10000);
					}else {
						$("#user_presence").val("0");
						$('.unlock_software_update').removeClass('disable_button');
						msg = "<span class='error_message text_font'>" + response.message + "</span>";
						$('#resultsft').html(msg).show();
					}
					
					$('.ajax-loader').hide();
					$("#contentcontents").unmask();
					clearInterval(user_presence_process_interval);
				}else{
					if (user_presence_timer_counter >= 50) {
						$('#resultsft').html("<span class='error_message text_font'>Unlocked reuqest timeout</span>").show();
						softwareupdate_unlock_process = false;
						clearInterval(user_presence_process_interval);
						$('.ajax-loader').hide();
						$("#contentcontents").unmask();
						$('.unlock_software_update').removeClass('disable_button');
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

function options_enable_poll(){
	var console_id = $('#console_id_and_upload_id').val();
	if (console_id) {
		var options_status_request_in_process = false;
		options_status_interval = setInterval(function(){
			if(!options_status_request_in_process){
				options_status_request_in_process = true;
				var stop_sw_options_reading_timer = $('#stop_sw_options_reading').val();
				if (stop_sw_options_reading_timer == 'yes') {
					clearInterval(options_status_interval);
					$('#upload_files_list').html('');
					$('#files_category').html('');
					$('#upload_files_list').hide();
					$('#files_category').hide();
				}else {
					console_id = $('#console_id_and_upload_id').val();
					if (console_id) {
						options_status_xhr = $.post("/softwareupdate/get_software_update_options", {
							console_id: console_id
						}, function(resp){
							$('#files_category').show();
						});
					}
					else {
						clearInterval(options_status_interval);
						$('#files_category').hide();
					}
				}
				options_status_request_in_process = false;
			}
		}, 4000);
	}
}

function upload_inprogress_display(){
	val_change = true;
	preload_page = function(){
		var discard_message =  "Module is on setup mode.<br>If you leave this screen,<br>" +
                			"the module may not function correctly until manually rebooted.<br>" +
                			"Do you want to continue?<br>";
		ConfirmDialog("Modules",discard_message,function(){
			if(typeof item_clicked == 'object'){
				// OK - Clear the popup message and send the software update process cancel
              	$.post("/softwareupdate/exit_sw_update_page", {
               		 //no params
             	}, function(resp){
					preload_page_finished();
				});
			}
			preload_page = '';
		},function(){
			//don't load the next page
		});
	};
}

function upload_inprogress_display_cancel(){
	val_change = false;
	preload_page = '';
}
$('#fileToUpload').w_change(function(){
	document.getElementById('fileToUpload_path').value = this.value;
	if (document.getElementById('fileToUpload_path').value.length > 0){
		var valid = document.getElementById('fileToUpload_path').value.split('.');
		var validmef = valid[valid.length-1];
		if ((validmef == "mef") || (validmef == "MEF")) {
			update();
		}
		else{
			alert("Please select valid MEF file.");
		}
	}
});
