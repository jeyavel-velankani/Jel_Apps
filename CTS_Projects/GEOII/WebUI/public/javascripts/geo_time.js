/*
####################################################################
# Company: Siemens 
# Author: Gopu
# File: geo_time.js
# Description: This js is used for geo time settings page
####################################################################
*/

var geo_time_interval;
var geo_time_xhr = null;

$(document).ready(function(){
	add_to_destroy(function(){
		$(document).bind("ready",function(){});
	
		//kills all wrapper events
		$('.geo_time_update').w_die('submit');
		$('.get_time').w_die('click');
		$('.pc_time').w_die('click');
		
		
		//clear intervals
		if(typeof geo_time_interval !== 'undefined' && geo_time_interval != null){
		       clearInterval(geo_time_interval);
		}

		if(typeof geo_time_xhr !== 'undefined' && geo_time_xhr != null){
		        geo_time_xhr.abort();  //cancels previous request if it is still going
		}
		
		//clear functions
		delete window.timer; 
		delete window.auto_update;

		//clears global variables
		delete window.geo_time_interval;
		delete window.geo_time_xhr;
	});
});

/* Time form updation */
	$('#sitedate').val($('#calendar').val());
	$('#datetime_hour').val($('#date_hour').val());
	$('#datetime_minute').val($('#date_minute').val());
	$('#datetime_second').val($('#date_second').val());
	
	$("#hd_time_zone").val($("#enum_1").val());   	
    Date.firstDayOfWeek = 0;
    Date.format = 'mm/dd/yy';
    
    jQuery("#calendar").datepicker({
        showOn: 'button',
        buttonImage: '/images/calendar.gif',
        buttonImageOnly: true,
        dateFormat: "mm/dd/yy",
        yearRange: '1900:2199',
		changeYear:true
    }).attr('readonly', true);
    
	$('.get_time').w_click(function(){
		auto_update();
    });
	
	$('.v_save').w_click(function(){
		$('form.geo_time_update').submit();
	});

	$('.pc_time').w_click(function(){
		var currentdate = new Date(); 
		var selected_id;

		//this will get the time zone off set
		var rightNow = new Date();
		var jan1 = new Date(rightNow.getFullYear(), 0, 1, 0, 0, 0, 0);
		var temp = jan1.toGMTString();
		var jan2 = new Date(temp.substring(0, temp.lastIndexOf(" ")-1));
		var std_time_offset = (jan1 - jan2) / (1000 * 60 * 60);

		$('#time_zone_container select option').each(function(){
			var option = $(this).html();
			var time_zone = option.split('GMT')[1];
			time_zone = parseInt(time_zone.split(':')[0]);

			if(std_time_offset == time_zone){
				selected_id = $(this).attr('value');
			}
		});

		if(typeof selected_id !== 'undefined'){
			$('#time_zone_container select').val(selected_id);
		}

		$('#calendar').val((currentdate.getMonth()+1)+'/'+currentdate.getDate()+'/'+currentdate.getFullYear());

		var hours = (currentdate.getHours() > 9 ? '' : '0')+currentdate.getHours();
		var min = (currentdate.getMinutes() > 9 ? '' : '0')+currentdate.getMinutes();
		var sec = (currentdate.getSeconds() > 9 ? '' : '0')+currentdate.getSeconds();

		$('#date_hour').val(hours);
		$('#date_minute').val(min);
		$('#date_second').val(sec);
	});
	
jQuery('form.geo_time_update').submit(function(){
    var org_tz = $('#hd_time_zone').val();
	var sel_tz = $('#time_zone_container select').val();
	if (org_tz != sel_tz) {
		var msg = "Changing Timezone will restart Web Server to load the new timezone.\nDo you want to continue?";
		if(confirm(msg) == false){
			$('#time_zone_container select').val(org_tz);
			$('#date_hour').val($('#datetime_hour').val());
			$('#date_minute').val($('#datetime_minute').val());
			$('#date_second').val($('#datetime_second').val());
			return false;
		}
	}
	$("#contentcontents").mask("Updating Time Settings., please wait..."); 		
	var page_url = $(this).attr('action');
	var geo_time_data = $(this).serialize();
    $.post(page_url, geo_time_data, function(data){
		if (data.error) {
			$("#contentcontents").unmask();
			var msg = '';
			msg = "<span class='error_message'> "+ data.message + "</span>";
			$('.message').html(msg).show();
		}
		else {
			// Periodical call after update to check the time request state.
			timer(data.req_id, true)
		}
    });
    return false;
});


function timer(req_id, flag){
	var request_progress = false;
	var counter = 0;
	var msg = '';
    geo_time_interval = setInterval(function(){
		if(!request_progress){
			request_progress = true;
			if (counter == 15){
				$("#contentcontents").unmask();
				msg = "<span class='error_message'> Time Settings request timeout </span>"
				$('.message').html(msg).show();
				clearInterval(geo_time_interval);
			}
			else{
				geo_time_xhr = $.post('/geo_time/check_state', {id: req_id}, function(geo_time_data){
					if (geo_time_data.error) {
						$("#contentcontents").unmask();
						msg = "<span class='error_message'>"+ geo_time_data.message +" </span>"
						$('.message').html(msg).show();
					}
					else {
		                if (geo_time_data.req_state == '2') {
		                    var org_tz = $('#hd_time_zone').val();
							var sel_tz = $('#time_zone_container select').val();
							$('.geo_time').html(geo_time_data.html_content);
		                    if (flag) {
		                    	reset_logout_session();
								if (org_tz != sel_tz) {
									$("#contentcontents").unmask();
									msg = "<span class='success_message'> Timezone changed, Web Server will restart to load the new timezone. WebUI will disconnect. Please wait for 3 minutes. </span>"
									$('.message').html(msg).show();
									setTimeout("window.location = '/access/logout'", 5000);
								}else {
									$("#contentcontents").unmask();
									msg = "<span class='success_message'> Time Settings have been updated successfully. </span>"
									$('.message').html(msg).show();
									$('.message').fadeOut(15000, function(){
									});
								}
		                    }
		                    clearInterval(geo_time_interval);
		                }
					}
					request_progress = false;
	            });
			}
			counter ++;
		}            
    }, 2000);
}

function auto_update(){
	$("#contentcontents").mask("Getting Time parameters, please wait...");
	$.post("/geo_time/get_geo_time",{get_time: true},function(geo_time_response){
		$('#geo_time').html(geo_time_response.html_content);
		$("#contentcontents").unmask();
	});		
}
