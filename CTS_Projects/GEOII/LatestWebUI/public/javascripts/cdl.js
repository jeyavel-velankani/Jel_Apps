var show_cdl_qna = true; 
var show_cdl_prev = false; 
var show_cdl_next = false; 
var show_cdl_restart = true; 
var show_cdl_start = true; 
var show_cdl_remove = true; 
var show_cdl_view = true; 
var show_cdl_upload = true; 
var show_cdl_download = true; 
var log_id = -1; 

var DOWNLOAD_CDL_LOG = 17;
var DLOWLOAD_CDL_FILE = 13

var DOWNLOAD_PATH = '/mnt/ecd/0/';//'/tmp/download/';

var next_count = 0;
var q_num = 0;
var reset_state_var = 0; 
var log_file_name = '';
var log_path = '';
var uploaded_interval;

//intervals
var periodic_call_finish;
var periodic_call;
var session_interval;
var periodic_upload_request_check;


add_to_destroy(function(){
	$(document).unbind("ready");

	//kills all wrapper events
	$('.cdl_qna').w_die('click');
	$('.cdl_prev').w_die('click');
	$('.cdl_next').w_die('click');
	$('.cdl_start').w_die('click');
	$('.cdl_restart').w_die('click');
	$('.cdl_remove').w_die('click');
	$('.cdl_view_cdl_log').w_die('click');
	$('.cdl_upload').w_die('click');
	$('.cdl_download_log_file').w_die('click');
	$('.cdl_download_file').w_die('hover');
	$('#fileToUpload').w_die('change');
	$('.upload_cdl_form').w_die('submit');

	//clear intervals
	clearInterval(periodic_call_finish);
	clearInterval(periodic_call);
	clearInterval(session_interval);
	clearInterval(periodic_upload_request_check);

	//clear functions 
	delete window.cdlfilecheck;

	//clears global variables
	delete window.show_cdl_qna; 
	delete window.show_cdl_prev; 
	delete window.show_cdl_next; 
	delete window.show_cdl_restart; 
	delete window.show_cdl_start; 
	delete window.show_cdl_remove; 
	delete window.show_cdl_view; 
	delete window.show_cdl_upload; 
	delete window.show_cdl_download; 
	delete window.log_id; 
	delete window.DOWNLOAD_CDL_LOG;
	delete window.DLOWLOAD_CDL_FILE;
	delete window.DOWNLOAD_PATH;
	delete window.next_count;
	delete window.q_num;
	delete window.reset_state_var;
	delete window.log_file_name;
	delete window.log_path
	delete window.uploaded_interval;


});
/************************************************************************************************************************
 Navigation
************************************************************************************************************************/
$(document).bind("ready",function(){
//	set_content_deminsions(910,500);

	
	//adds the drop dop for the navigation
	$('.cdl_download').append('<div class="unordered_cdl_list" id= "list" ><ul><li><a class="cdl_download_file">CDL File</a></li><li><a class="cdl_download_log_file">CDL Log</a></li></ul></div>');

	$('.cdl_start').show();
	$('.cdl_restart').hide();

	if(parseInt($('#q_no').val())  != 0 && $('#q_no').val() != '/'){
		show_cdl_prev = true; 
		show_cdl_next = true; 
		$('.cdl_start').hide();
		$('.cdl_restart').show();
	}
	
	//gets the cdl file name
	var filename = $('.cdl_filename').val();

	if ($("#show_prev_next").val() == "0") {
		show_cdl_prev = false;
		show_cdl_next = false;
		show_cdl_upload = false;
	}
	//sets the name of the cdl file
	if (filename != ""){
		$('#cdlfilename').html("CDL File Name : " + filename);	
		$('.cdl_filename').val(filename)
	}else{
		$('#cdlfilename').html("CDL File Name : None");
		$('.cdl_filename').val('');

		//if there is not cdl it disable buttons
		show_cdl_qna = false; 
		show_cdl_start = false;
		show_cdl_remove = false; 
		show_cdl_view = false;
		show_cdl_download = false;
		show_cdl_upload = true; 
	}
	
	$('#cdl_message').custom_scroll(400);
	update_buttons();


	$('.submit_button').addClass("disabled");
	$('.submit_button').attr('disabled','disabled');
	$('.cdl_upload_wrapper').hide();
	$('.cdl_site_setup').show();
});	


/****************************** Nav Q&A Button ******************************/
// gets the cdl questions that were already answered and displays them to the user
$('.cdl_qna').w_click(function(){
	if(!$(this).hasClass('disabled')){
		$('.cdl_upload_wrapper').hide();
		$('.cdl_site_setup').show();

		//updates the buttons
		disable_buttons();

		$('#cdl_flash').css({'display':'none'});
		$(".ajax-loader").show();

		//gets the questions and answers
		$.post('/cdlsitesetup/display_q_n_s', {}, function(display_q_n_s_resp){
			$(".ajax-loader").hide();
			$('.cdl_site_setup').html(display_q_n_s_resp.page_content);
			
			$('#cdl_message').custom_scroll(400);

			//sets the hidden input to be the last question answered
			$('#q_no').val(display_q_n_s_resp.ques_num);
			if(q_num >= 1){

				//if this is the first question there is no previous question
				if(display_q_n_s_resp.ques_num == 1){
					show_cdl_prev = false; 
				}else{
					show_cdl_prev = false; 
				}

				show_cdl_next = true;
			}
		},"json");

		//updates the buttons
		update_buttons();	
		clearInterval(uploaded_interval);		
	}
});

/****************************** Nav Prev Button ******************************/
$('.cdl_prev').w_click(function(){
	if(!$(this).hasClass('disabled')){
		$('.cdl_upload_wrapper').hide();
		$('.cdl_site_setup').show();

		disable_buttons();

		//gets the current question number
		q_num = $('#q_no').val();
		if(q_num >= 1){
			if(q_num==1){
				show_cdl_prev = false; 
			}else{
				show_cdl_prev = true; 
			}
			$(".ajax-loader").show();

			$.post('/cdlsitesetup/prev', {
				ques_num: parseInt($('#q_no').val())
			}, function(prev_data){
				if(prev_data.message != "start"){
					$(".ajax-loader").hide();
					$('.cdl_site_setup').html(prev_data.page_content);
				}
				//If the Previous button is clicked while on the first question the CDL runs through menu phase compilation
				else if(prev_data.message == "start"){
					$(".cl_sitesetup_start").click();
				}

				show_cdl_next = true; 

				//updates the 
				$('#q_no').val(prev_data.ques_num);
				$('#cdl_message').custom_scroll(400);

				//updates the buttons
				update_buttons();
			},"json");			
		} 	

		clearInterval(uploaded_interval);	
	}
});



/****************************** Nav Next Button ******************************/
$('.cdl_next').w_click(function(){
	if(!$(this).hasClass('disabled')){
		$('#answer_ID').attr('disabled','disabled');
		$('.cdl_upload_wrapper').hide();
		$('.cdl_site_setup').show();

		disable_buttons();

		//disable the button until it is finished
		show_cdl_prev = false; 
		show_cdl_next = false; 

		$('#cdl_flash').css({'display':'none'});

		var element_data = $('#answer_ID').val();
		var min_val = $('#ans_minval').val();
		var max_val = $('#ans_maxval').val();
		
		if (element_data != null && element_data !== undefined) {
		
			if($.trim(element_data) == '' || (parseInt(element_data)) < (parseInt(min_val)) || (parseInt(element_data)) > (parseInt(max_val)) || (isNaN(element_data))){

				alert("Please correct the error and try again");
				show_cdl_next=true;
				update_buttons();
				$('#answer_ID').prop('disabled',false);
			}else{
		
				$(".ajax-loader").show();
			
				$.post('/cdlsitesetup/next', {
					answer_ID: element_data,
					ques_num: parseInt($('#q_no').val())
				}, function(next_data){		

					$(".ajax-loader").hide();

					if(next_data.message != "" && next_data.message !== undefined){

						if(next_data.message == "no_next"){

							$('.cl_sitesetup_restart').hide();
							$('.cl_sitesetup_start').show();

							compile(reset_state_var);
						}else{
							$('.cl_sitesetup_restart').show();
							$('.cl_sitesetup_start').hide();	
						

							next_count += 1;

							$('.cdl_site_setup').html(next_data.page_content);
							$('#q_no').val(next_data.ques_num);
							$('#cdl_message').custom_scroll(400);	
							
							setTimeout(function(){
								$('#cdl_message').scroll_to_bottom();
							},10)
							
							//remove the disable from the  button
							show_cdl_prev = true; 
							show_cdl_next = true; 
						}
					}else{
						compile(reset_state_var);
					}	
					update_buttons();
					
				},"json");
			}
		}else{
			if(parseInt($('#q_no').val()) > 0){
				$.post('/cdlsitesetup/check_question',{
					ques_num: parseInt($('#q_no').val())
				},function(check_question_resp){
					if(check_question_resp == "false"){
						// there is no more questions so it can compile
						
						compile(reset_state_var);
	
					}
				});
			}
		}	

		clearInterval(uploaded_interval);
	}
});

function compile(reset_var){
	//else if called when the question and answer process is finished
	var cdlfile = $('.cdl_filename').val();

	ConfirmDialog('CDL',"Do you want to compile the CDL file "+ cdlfile,function(){
		//yes
		compile_confirm(reset_var);
	},function(){
		//no
		show_cdl_prev = true; 
		show_cdl_next = true; 

		update_buttons();
		$(".ajax-loader").hide();
	});
}

function compile_confirm(reset_var){
	disable_buttons();
		
	$(".ajax-loader").show();
	$('.cl_sitesetup_restart').hide();
	$('.cl_sitesetup_start').show();

	$.post("/cdlsitesetup/finish", {
		reset:reset_var
	}, function(finsih_id){
		$('#q_no').val(0);

		
		var periodic_call_finish_flag = true;
		periodic_call_finish = setInterval(function(){

			if(periodic_call_finish_flag){
				periodic_call_finish_flag = false;
			
				$.post('/cdlsitesetup/check_finish', {
					request_id: finsih_id
				}, function(check_finish_resp){

					if(check_finish_resp.request_state == 2){
						if(parseInt(check_finish_resp.result) == 0){
							
							$('.cdl_site_setup').html("<div style='color:green;font-weight:bold;padding:15px 0 0 5px;'> All phase CDL compilation complete</div>");					
						
							show_cdl_qna = true; 
							show_cdl_prev = false; 
							show_cdl_next = false; 
							show_cdl_restart = true; 
							show_cdl_start = true; 
							show_cdl_remove = true; 
							show_cdl_view = true; 
							show_cdl_upload = false; 
							show_cdl_download = true; 

							
						}else{
							show_cdl_qna = false; 
							show_cdl_prev = false; 
							show_cdl_next = false; 
							show_cdl_restart = false; 
							show_cdl_start = false; 
							show_cdl_remove = true; 
							show_cdl_view = true; 
							show_cdl_upload = true; 
							show_cdl_download = true; 

							$('.cdl_site_setup').html("<div style='color:red;font-weight:bold;padding:15px 0 0 5px;'>Error: "+check_finish_resp.error_message+"</div>");
						}
						
						$(".ajax-loader").hide();
						clearInterval(periodic_call_finish);
						update_buttons();
					}else{

						var precent = parseInt(check_finish_resp.percentage_complete);

						if(precent == 100){
							$('.cdl_site_setup').html("All Phase Compilation Complete");
						}else{
							$('.cdl_site_setup').html("<p> All Phase Compilation Percentage Complete: "+ (isNaN(precent) ? '0': precent) + "</p>");
						}
					}
					periodic_call_finish_flag = true;
				}, "json");	
			}
		},2000);
	});
}

/****************************** Nav Start Button ******************************/
$('.cdl_start').w_click(function(){
	if(!$(this).hasClass('disabled')){
		$('.cdl_upload_wrapper').hide();
		$('.cdl_site_setup').show();

		cdl_start_compile();
		clearInterval(uploaded_interval);
	}
});

function cdl_start_compile(){
	if(!$(this).hasClass('disabled')){
		
		disable_buttons();
		$('.cdl_site_setup').html("");
		//updates the gui
		$('#cdl_flash').css({'display':'none'});
		$(".ajax-loader").show();
		$('.cdl_restart').show();
		$('.cdl_start').hide();

		//updates the current question 
		$('#q_no').val(0)

		//start to compile
		$.post('/cdlsitesetup/start', {}, function(start_data){

			//check if it is a number
			if(!isNaN(parseInt(start_data))){
				var periodic_call_flag = true; 
				periodic_call = setInterval(function(){

					if(periodic_call_flag){
						periodic_call_flag = false;
						$.post('/cdlsitesetup/check_start', {
							request_id: parseInt(start_data)
						}, function(check_data){

							//cdl file does not exsist
							if(parseInt(check_data.request_state) == -1){
								$('.cdl_site_setup').html("<div style='color:red;font-weight:bold;padding:15px 0 0 5px;'>There is no CDL file</div>");
							} else { 

								//complete
								if(check_data.request_state == 2){
									//Start request complete and succeeds
									
									clearInterval(periodic_call);
									jQuery.ajax({
										url: '/cdlsitesetup/start_questions',
										type: 'POST',
										success: function(result){
											ConfirmDialog('CDL','Reset Names/Modules?',function(){
												//yes
												reset_state_var = 1;

												if(result =="No CDL Questions found"){												
													compile(reset_state_var);
													
												}else{
													$(".cdl_site_setup").html(result);
													$('#cdl_message').custom_scroll(400);	
													show_cdl_next = true; 
													update_buttons();
													$('.ajax-loader').hide();
												}
											},function(){
												//no
												if(result =="No CDL Questions found"){												
													compile(reset_state_var);
													
												}else{
													$(".cdl_site_setup").html(result);
													$('#cdl_message').custom_scroll(400);	
													show_cdl_next = true; 
													update_buttons();
													$('.ajax-loader').hide();
												}
											});					
										}
									});
								} else {
									var precent = parseInt(check_data.percentage_complete);
									precent = (isNaN(precent) ? 0:precent);
									$('.cdl_site_setup').html("<div style='color:#fff;padding:15px 0 0 5px;'><p>Percentage Complete: "+precent+"</p></div>");
								}
								
							}
							periodic_call_flag = true;
						}, "json");
					}
				},2000);	
						
			}else{
				$('#contentcontents').html('<div style="color:#fff;font-size:30px;">Not in session...</div>');
			}
		});
	}
}

/****************************** Nav Restart Button ******************************/
$('.cdl_restart').w_click(function(){
	if(!$(this).hasClass('disabled')){
		$('.cdl_upload_wrapper').hide();
		$('.cdl_site_setup').show();

		cdl_start_compile();
		clearInterval(uploaded_interval);
	}
});

/****************************** Nav remove-cdl Button ******************************/
$('.cdl_remove').w_click(function(){	
	if(!$(this).hasClass('disabled')){
		$('.cdl_upload_wrapper').hide();
		$('.cdl_site_setup').show();

		disable_buttons();

		$.post('/cdlsitesetup/remove_cdl_request', {}, function(response)
		{

			if(response.oce_mode){
				$("#cdlfilename").html("CDL File Name : None");
				$('.cdl_filename').val('')
				$("#cdlfilename").next().html("<div style='color:green;font-weight:bold;font-size:12px;padding:15px 0 0 5px;'> " + response.message + " </div>").fadeOut(10000);
				$('.cdl_site_setup').html('');
				show_cdl_qna = false; 
				show_cdl_prev = false; 
				show_cdl_next = false; 
				show_cdl_restart = false; 
				show_cdl_start = false; 
				show_cdl_remove = false; 
				show_cdl_view = false; 
				show_cdl_upload = true; 
				show_cdl_download = false; 
				update_buttons();
			}else{
				var request_progress = false;
				session_interval = setInterval(function(){

					if (!request_progress){
						request_progress = true;
						$.post("/cdlsitesetup/check_remove_cdl", {
							request_id: response.request_id
						}, function(sec_response){


							if(parseInt(sec_response.request_state) ==  2){

								clearInterval(session_interval);
								$(".ajax-loader").hide();
								
								$("#cdlfilename").html("CDL File Name : None");
								$('.cdl_filename').val('')
								
								$("#cdlfilename").next().html("<div style='padding-left: 10px;'>"+sec_response.message+"</div>").fadeOut(10000);
								$('.cdl_site_setup').html('');
								show_cdl_qna = false; 
								show_cdl_prev = false; 
								show_cdl_next = false; 
								show_cdl_restart = false; 
								show_cdl_start = false; 
								show_cdl_remove = false; 
								show_cdl_view = false; 
								show_cdl_upload = true; 
								show_cdl_download = false; 

								update_buttons();
							}
							request_progress = false;
						}, "json");
					}
				}, 2000);
			}
		}, "json");

		clearInterval(uploaded_interval);
	}
});

/****************************** Nav View-CDL-Log Button ******************************/
$('.cdl_view_cdl_log').w_click(function(){
	if(!$(this).hasClass('disabled')){
		$('.cdl_upload_wrapper').hide();
		$('.cdl_site_setup').show();
		disable_buttons();

		$('#cdl_flash').css({'display':'none'});
		$(".ajax-loader").show();

		$.post('/cdlsitesetup/check_cdl_log/',{
			//no params
		},function(log_resp){
			if(log_resp == 'file'){
				$.post('/cdlsitesetup/view_cdl_log/',{
					//no params
				},function(view_resp){
					if(view_resp != ''){
						$('.cdl_site_setup').html('<div class="log_wrapper">'+view_resp+'</div>'); 
						$('.log_wrapper').custom_scroll(400);
					}else{
						$('#cdl_message').html('<div class="error_message">Log is empty.</div>');
					}
					update_buttons();
					$(".ajax-loader").hide();
				})
			}else{
				$('#cdl_message').html('<div class="error_message">No log file to view.</div>');
				update_buttons();
				$(".ajax-loader").hide();
			}
		});

		clearInterval(uploaded_interval);
	}
});

/****************************** Nav Upload Button ******************************/
$('.cdl_upload').w_click(function(){
	if(!$(this).hasClass('disabled')){

		disable_buttons();
		$('.cdl_site_setup').hide();
		$('.cdl_upload_wrapper').show();
			
		update_buttons();
	}
});


/****************************** Nav Download Button ******************************/

	$('.cdl_download').w_hover(function(){		
			if(!$('.cdl_download').hasClass('disabled')){
				$('.unordered_cdl_list').css({'display':'block'});
			}  		
		},function(){
			$('.unordered_cdl_list').css({'display':'none'})
		}	
	);


$('.cdl_download_log_file').w_click(function(){    
	if(!$(this).hasClass('disabled')){
		$('.cdl_upload_wrapper').hide();
		$('.cdl_site_setup').show();
		disable_buttons();

		$('#cdl_flash').css({'display':'none'});
		$(".ajax-loader").show();

		$.post('/cdlsitesetup/check_cdl_log/',{
			//no params
		},function(log_resp){
			if(log_resp == 'file'){
				var dl_url = "/cdlsitesetup/download_cdl_log";
			
				$('.cdl_site_setup').html('');

				downloadURL(dl_url);
			}else{
				$('#cdl_message').html('<div class="error_message">No log file to view.</div>');
				update_buttons();
				$(".ajax-loader").hide();
			}
		});

		clearInterval(uploaded_interval);
	}
});

$('.cdl_download_file').w_click(function(){
	if(!$(this).hasClass('disabled')){
		$('.cdl_upload_wrapper').hide();
		$('.cdl_site_setup').show();
		disable_buttons();

		$('#cdl_flash').css({'display':'none'});
		$(".ajax-loader").show();

		$.post('/cdlsitesetup/check_cdl_file/',{
			//no params
		},function(log_resp){
			if(log_resp == 'file'){
				var dl_url = "/cdlsitesetup/download_cdl_file";
			
				$('.cdl_site_setup').html('');

				downloadURL(dl_url);
			}else{
				$('#cdl_message').html('<div class="error_message">No log file to view.</div>');
				update_buttons();
				$(".ajax-loader").hide();
			}
		});

		clearInterval(uploaded_interval);
	}
});


/************************************************************************************************************************
 Nav Basic Functions
************************************************************************************************************************/
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
    update_buttons();
    $(".ajax-loader").hide();
}


/************************************************************************************************************************
 uploads
************************************************************************************************************************/
function upload_cdl(){
	$('.cdlfilename').html('')
	$('.cdl_filename').val('');
	$('.ajax-loader').show();
	var periodic_upload_request_check_flag = true;
	periodic_upload_request_check = setInterval(function(){

		if(periodic_upload_request_check_flag){
			periodic_upload_request_check_flag = false;
			$.post('/cdlsitesetup/check_cdl_upload', {}, function(response){

				if(response.request_state == 2 && response.result == 200){
					clearInterval(periodic_upload_request_check);
					$('#cdl_upload_progress').html("<p style='color:green;font-weight:bold;padding:15px 0 0 5px;'> The CDL File: " + response.file_name +" has been successfully uploaded</p>");
					$('.cdl_start').removeClass("disabled");
					$('.cdl_view_cdl_log').removeClass("disabled");
					$('.cdl_download').removeClass("disabled");

					$('#cdlfilename').html("CDL File Name : " + response.file_name );	
					$('.cdl_filename').val(response.file_name);

					show_cdl_restart = true; 
					show_cdl_start = true; 
					show_cdl_remove = true;
					show_cdl_upload = false;  

					$('.cdl_start').show();
					$('.cdl_restart').hide();
					$('.ajax-loader').hide();
					$('.cdl_upload_wrapper').hide();
					
					update_buttons();
				}else if(response.request_state == 2 && response.result != 200){

					clearInterval(periodic_upload_request_check);
					$('#cdl_upload_progress').html("<p style='color:red;font-weight:bold;padding:15px 0 0 5px;'> The CDL File: " + response.file_name + " has failed to upload. <br>Error Message: "+ response.error_message +"</p>");
					$('.cdlfilename').html('CDL File Name: '+response.file_name);
					$('.cdl_filename').val(response.file_name)
					update_buttons();
					$('.ajax-loader').hide();
				}
				periodic_upload_request_check_flag = true;
			},"json");
		}
	},2000);
}

/****************************** start partial ******************************/
function ans_validation_num(obj){		
	var text_value = obj.value;
	var min_val = parseInt($('#ans_minval').val());
	var max_val = parseInt($('#ans_maxval').val());
	var error = false;
	if($.trim(text_value) == ''){
		$(".errormesg").html("Answer value should be in the numeric range of (" + min_val + " to " + max_val + ")");
		disable_buttons();
		return false;
	}else{
		var cur_value = parseInt(text_value);		
		
		if (isNaN(text_value)){
			$(".errormesg").html("Answer value should be in the numeric range of (" + min_val + " to " + max_val + ")");
			disable_buttons();
			return false;
		}

		if ((cur_value > max_val) || (cur_value < min_val)) {			
			$(".errormesg").html("Answer value should be in the numeric range of (" + min_val + " to " + max_val + ")");
			disable_buttons();
		}
		else {			
			$(".errormesg").html("");
			update_buttons();
		}
	}
}	

function ans_validation(){
	$('#cdl_ss').validate({			
		rules: {
			answer_ID: {
				required: true,
				range: [document.getElementById('ans_minval').value, document.getElementById('ans_maxval').value]
			}
		}
	});
}


function update_buttons(){
	if(show_cdl_qna){
		$('.cdl_qna').removeClass("disabled");
	}else{
		$('.cdl_qna').addClass("disabled");
	}

	if(show_cdl_prev){
		$('.cdl_prev').removeClass("disabled");
	}else{
		$('.cdl_prev').addClass("disabled");
	}
	
	if(show_cdl_next){
		$('.cdl_next').removeClass("disabled");
	}else{
		$('.cdl_next').addClass("disabled");
	}
	
	if(show_cdl_restart){
		$('.cdl_restart').removeClass("disabled");		
	}else{
		$('.cdl_restart').addClass("disabled");
	}
	
	if(show_cdl_start){
		$('.cdl_start').removeClass("disabled");		
	}else{
		$('.cdl_start').addClass("disabled");
	}
	
	if(show_cdl_remove){
		$('.cdl_remove').removeClass("disabled");		
	}else{
		$('.cdl_remove').addClass("disabled");
	}
	
	if(show_cdl_view){
		$('.cdl_view_cdl_log').removeClass("disabled");		
	}else{
		$('.cdl_view_cdl_log').addClass("disabled");
	}
	
	if(show_cdl_upload){
		$('.cdl_upload').removeClass("disabled");		
	}else{
		$('.cdl_upload').addClass("disabled");
	}

	if(show_cdl_download){
		$('.cdl_download').removeClass("disabled");		
	}else{
		$('.cdl_download').addClass("disabled");
	}
}


function disable_buttons(){
	$('.cdl_qna').addClass("disabled");
	$('.cdl_prev').addClass("disabled");
	$('.cdl_next').addClass("disabled");
	$('.cdl_restart').addClass("disabled");
	$('.cdl_start').addClass("disabled");
	$('.cdl_remove').addClass("disabled");
	$('.cdl_view_cdl_log').addClass("disabled");
	$('.cdl_upload').addClass("disabled");
	$('.cdl_download').removeClass("disabled");		
	$('.cdl_download').addClass("disabled");
}

/****************************** upload partial ******************************/

function cdlfilecheck() {
	var llwfilepath = document.getElementById("fileToUpload").value;

	var valid = llwfilepath.split('.');
	var validcdl = valid[valid.length-1];
	validcdl = validcdl.toUpperCase();
	if (validcdl.toUpperCase() != "CDL") {
		alert("Please select a cdl file only");
		document.getElementById("cdlfileToUpload_path").value ="";
		return false;
	}else{
		return true;
	}
return false;
}

$('#fileToUpload').w_change(function(){
	var filename = $(this).val();
	filename = filename.split('\\');
	filename = filename[filename.length-1];
	$('#cdlfileToUpload_path').val(filename);
	cdlfilecheck();

	if(filename.length == 0){
		$('.submit_button').addClass("disabled");
		$('.submit_button').attr('disabled','disabled');
	}else{
		$('.submit_button').removeClass("disabled");
		$('.submit_button').removeAttr('disabled');
	}
});		


$('.upload_cdl_form').submit(function() {
 	var options = {
      success: function(response) { 
      	$('#ajax_fileupload').hide();
		upload_cdl();
      } 
 	};
 	$(this).ajaxSubmit(options);
 	return false; 
});
