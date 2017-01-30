/*
 * Show report progress.
 */
var check_report_create_status_interval;
var maxprogress_px      = 300; // Should be same value as width in .css file
var actualprogress_px   = 0;   // current value
var maxProgressPossible = 110;
var report_create_status_xhr = null;

$(document).ready(function(){
	add_to_destroy(function(){
		$(document).bind("ready",function(){});
	
		//kills all events
		$('#create_report').w_die('click');
		$('#download_report').w_die('click');
		
		//clear intervals
		clearInterval(check_report_create_status_interval);
		
		if (typeof report_create_status_xhr !== 'undefined' && report_create_status_xhr != null) {
			report_create_status_xhr.abort();
		}
		
		//clear functions 
		delete window.download_report;
		delete window.downloadURL;
		delete window.update_progress_bar;
		delete window.show_progress_bar;
		delete window.hide_progress_bar;
		delete window.report_in_progress
		delete window.report_finished;
			
		//clears global variables
		delete window.check_report_create_status_interval;
		delete window.report_create_status_xhr;
	});	

    hide_progress_bar();
    /*
     * Create report button click
     */ 
    $("#create_report").w_click(function(){
		if (!jQuery(this).hasClass('disable')) {
			// update display
			$('#reportcontent').html('');
			update_progress_bar(0);
			show_progress_bar();
			// prevent report select from being accessed
			// Get the report type that was selected
			var selected_report_type = $("#report_type").val(); 
			// Verify there is a valid report type
			if (selected_report_type != "") {
				report_in_progress();
				$.post("/versionreport/UDP_call", {
					report_type: selected_report_type
				}, function(response_data){
					// Verify there was response data from AJAX post call
					if (response_data) {
						// Periodically check the report state
						var running_report_check = false;
						check_report_create_status_interval = setInterval(function(){
							if (running_report_check == false) {
								running_report_check = true;
								report_create_status_xhr = $.post("/versionreport/check_report_state", {
									request_id: response_data,
									report_type: selected_report_type
								}, function(data){
									// Update report progress.
									if (data.PercentComplete != null || data.PercentComplete != "")
										update_progress_bar(data.PercentComplete);
									if (data.requeststate == 2) {
										report_finished();
										clearInterval(check_report_create_status_interval);
										hide_progress_bar();
										$.post("/versionreport/render_report", {
											request_id: response_data,
											report_type: selected_report_type
										}, function(result){
											$("#report_update").custom_scroll(430);
											$(".ajax-loader").hide();
											$("#report_update").html(result);
										});
									}
									running_report_check = false;
								});
							}
						}, 3000);
					}
					else {
						hide_progress_bar();
						$(".ajax-loader").hide();
						$('#reportcontent').html('<span class="text_font text_white">Report generation already in progress, please wait</span>');
						return false;
					}
				});
			}
		}
    });
    
	/*
     * download report button click
     */ 
	$("#download_report").w_click(function(){
		if (!jQuery(this).hasClass('disable')) {
			var path = $('#download_path').attr('value');
			if (path) {
				download_report();
			}else{
				$('#reportcontent').html("");
				setTimeout("$('.ajax-loader').hide();",1000);
				$('#reportcontent').html("Create the report and try again.").show().css({"color": "red" , "font-family": "Arial" , "font-size":"13px" ,"font-weight": "600"}).fadeOut(5000);
			}
		}
	});
});

function download_report(){
    downloadURL('/versionreport/download_txt_file/?download_path='+ $('#download_path').attr('value') + 
                '&report_type=' + $('#report_type').attr('value'));
}

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
	setTimeout("$('.ajax-loader').hide();",4000);
	iframe.src = dl_url;   
}

function update_progress_bar(newprogress){
  // Calculate the new amount of pixals to show
  actualprogress_px = (newprogress/maxProgressPossible)*maxprogress_px;
  // Verify we don't go over the max amount
  if(actualprogress_px >= maxprogress_px){     
    actualprogress_px = maxprogress_px;
  } 
  // Get indicator reference
  var indicator = document.getElementById("indicator");
  // Update indicator
  indicator.style.width=actualprogress_px + "px";
  return;
}

function show_progress_bar(){
    $('#create_report').addClass('disable');
	$('#download_report').addClass('disable');
    $('#progressbar').show();
    $('#report_status_msg').show();
    return;
}

function hide_progress_bar(){
    $('#create_report').removeClass('disable');
	$('#download_report').removeClass('disable');
	$('#progressbar').hide();
    $('#report_status_msg').hide();   
    return;
}

function report_in_progress(){
	preload_page = function(){
		ConfirmDialog('Reports','Your request to create report is not complete.<br>Would you like to leave anyways?',function(){
			preload_page_finished();
			preload_page = '';
		},function(){
			//don't load the next page
		});
	};
}

function report_finished(){
	preload_page = '';
}
