/* ATCS SIN form updation*/
var check_state_interval;
var object_name_xhr = null;

$(document).ready(function(){ 	
	add_to_destroy(function(){
		$(document).bind("ready",function(){});
		//kills all events
		$("form.sin_update").w_die("submit");
		
		//clear intervals
		if (typeof check_state_interval !== 'undefined' && check_state_interval != null) {
			clearInterval(check_state_interval);
		}
		
		if(typeof object_name_xhr !== 'undefined' && object_name_xhr != null){
		        object_name_xhr.abort();  //cancels previous request if it is still going
		}
		
		//clears global variables
		delete window.check_state_interval;
		delete window.object_name_xhr;
	});
    $('form.sin_update').submit(function(){
        var page_url = $(this).attr('action');
        var req_id = $('#request_id').val();
        var sin_data = $(this).serialize();
        if (sin_validation($("#sin").val())) {
			alert("To update the SIN Change. Please click 'SEL' button on CPU card");
            $('.ajax-loader').show();
            $('.ajax-loader span').html("Updating parameters").css('color', '#55AB27');
            $('.ajax-loader span').html("Updating parameters").css('width', '140px');
            $.post(page_url, sin_data, function(data){
                var request_progress = false;
                check_state_interval = setInterval(function(){
                    if (!request_progress) {
                        request_progress = true;
                        object_name_xhr = $.post('/atcs_sin/check_state', {id: req_id}, function(sin_data){
                            request_progress = false;
                            if (sin_data.request_state == "2"){
                            	if (sin_data.result == "0") {
                                    //$('.mcfcontent_data').html(sin_data.request_state);
                                    $('.ajax-loader span').html("");
                                    $('.ajax-loader').hide();
                                    $("#submit_button").hide();
                                    $("#sin").attr("readonly", true);
     								$('#status_message').html("SIN has been updated successfully. <br/> GCP will be updated with the new SIN. <br /> <b>Please login after 3 minutes.</b>");
									setTimeout("window.parent.document.location = '/'", 30000);
                                    clearInterval(check_state_interval);
                            	}
                            	else if (sin_data.result == "1" || sin_data.result == "2") {
                                    //$('.mcfcontent_data').html(sin_data.request_state);
                                    $('.ajax-loader span').html("");
                                    $('.ajax-loader').hide();
     								$('#status_message').html("<span style='color:#FF3333'>SIN update failed. <br/> 'SEL' button on CPU card was not pushed.</span>");
     								clearInterval(check_state_interval);
                            	}
                            }
                        });
                    }
                }, 2000);
            });
        }
        return false;
    });
	setTimeout('if($("#userpresence_mesg").length > 0){$("#userpresence_mesg").hide();}', 5000);
});
