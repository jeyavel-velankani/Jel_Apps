var remotesetup_debug_flag = true;
var remotesetup_time_field;
var user_pres;
var save_user_pres = -1;
var save_password = "_none_";

$(document).ready(function(){

    var iframe = $('#iframe', window.parent.document);
    var content_contents = $("#contentcontents", window.parent.document);


    $(iframe).css({'height': '504px', 'min-height':'504px'});
    $(content_contents).css({'height': '504px', 'min-height':'504px'});


    $('.remotesetup_save_button').hide();
    $('.remotesetup_discard_button').hide();


    $('.remotesetup_get').addClass('disabled_buttons');
    $('.remotesetup_cancel').addClass('disabled_buttons');

    remotesetup_time_field = parseInt($('.remotesetup_time_field').val());


    if($('#password_field').val() == '' || isNaN(parseInt($('#password_field').val())) || parseInt($('#password_field').val())==0){
        $("#password_field").hide();
        $("#track_elements").hide();
    }else{
        $("#password_field").show();
        $("#track_elements").show();
    }

    if($('.user_presence').val() == "true"){
        $(".remotesetup_get").removeAttr('disabled');

        $("#msg").html("<p style="+"color:green"+">Local User Presence Verified</p>").show();
        $("#msg").fadeOut(3000);

        $('.remotesetup_get').removeClass('disabled_buttons');
        $('.remotesetup_cancel').removeClass('disabled_buttons');
        $('.remotesetup_unlock').addClass('disabled_buttons');

    }else{
        $('.remotesetup_time_field').attr("disabled",true);
        $('#track_elements').hide();

    }

    time_changed_detection();
    password();

    auto_refresh_1 = setInterval(function () { password() },5000);
});


function setHiddenOnClick(){
    $('.remotesetup_save_button').hide();
    $('.remotesetup_discard_button').hide();
}




//=====================================================================================================
/*
 * calibrate() function:
 *
 * This is similar to the calibrate_sscc() function except for track cards instead of sscc cards due to the
 * different request parameters that need to be made. When one of the track checkboxes are clicked (if available),
 * this function goes sends data to the calibrate action in the remotesetup controller. This action
 * then sees if the checkbox was checked or unchecked on click. If it was checked, it will make a
 * request to the request_reply database as appropriate. It it was unchecked, it will also make the
 * appropriate request. Afterwards, a timer is created using Javascript's setInterval function.
 *
 * This creates a periodic_call to the check_sscc_state action in the controller. This action polls
 * the database to see if the request is completed or not and passes that information back to the view
 * using JSON. When the request is completed, the checkboxes will be re-enabled and another request can
 * be made.
 *
 * References:
 * http://www.techchorus.net/disable-and-enable-input-elements-div-block-using-jquery
 * http://api.jquery.com/category/selectors/
 */
//=====================================================================================================
$('.remotesetup_calibrate').w_click(function(){
    var row = $(this).closest('tr');
    var index = $('.remotesetup_row_count').val();
    var tracknum_data = row.find('.remotesetup_trackNum').val();

    //var index = 2; NOTE - FP: For future reference. This works.
    var trackarray = document.getElementsByName("track");   //Obtains all elements named "track" and puts into trackarray
    var millisecondInterval = 2000;                         //Timer for setInterval function

    var is_checkbox_checked = 0;
    //Checks if checkbox was checked
    if($(this).parent().find('input[name="track"]:checked').length!=0){
        is_checkbox_checked = 1;
    }

    $.post('/remotesetup/calibrate_track',{
        tracknum: tracknum_data,        //tracknum converted to string for JSON use
        is_checkbox_checked: is_checkbox_checked
    },function(calibrate_track_resp){

    if(calibrate_track_resp.ui_state_value == 1 && calibrate_track_resp.remote_password > 0){

        if(is_checkbox_checked == 1){
            $("html").mask("Selecting track. Please wait...");}
        else{
            $("html").mask("Unselecting track. Please wait...");}

        var periodic_call_flag = true;
        var periodic_call = setInterval(function(){
            if(periodic_call_flag){
                periodic_call_flag = false;
                $.post('/remotesetup/check_cal_state',{
                    request_id: calibrate_track_resp.request_id
                },function(check_cal_state_resp){

                    if(check_cal_state_resp.request_state == 2)
                    {
                        clearInterval(periodic_call);
                        $("html").unmask("Updating track. Please wait...");
                    }
                    periodic_call_flag = true;
                },"json");
            }
        }, millisecondInterval);

    }else if(calibrate_track_resp.ui_state_value != 1 && calibrate_track_resp.remote_password > 0){

        $(".remotesetup_get").attr('disabled',true);
        $("#msg").html("<p style="+"color:red"+">Local User Presence Not Verified</p>").show();
        $("#msg").fadeOut(3000);

    }else if(calibrate_track_resp.ui_state_value == 1 && calibrate_track_resp.remote_password == 0){

        $("#password_field").hide();
        $("#track_elements").hide();

        $("#msg").html("<p style="+"color:red"+">Remote password timed out</p>").show();
        $("#msg").fadeOut(3000);

    }else{

        $(".remotesetup_get").attr('disabled',true);
        $("#password_field").hide();
        $("#track_elements").hide();

        $("#msg").html('<p style="color:red">Local User Presense Not Verified and Remote Password Timed Out</p>').show();
        $("#msg").fadeOut(5000);
    }
    },"json");


});
//=====================================================================================================
/*
 * calibrate_sscc() function:
 *
 * This is similar to the calibrate() function except for sscc cards instead of track cards due to the
 * different request parameters that need to be made. When the SSCC checkbox is clicked (if available),
 * this function goes sends data to the calibrate_sscc action in the remotesetup controller. This action
 * then sees if the checkbox was checked or unchecked on click. If it was checked, it will make a
 * request to the request_reply database as appropriate. It it was unchecked, it will also make the
 * appropriate request. Afterwards, a timer is created using Javascript's setInterval function.
 *
 * This creates a periodic_call to the check_sscc_cal_state action in the controller. This action polls
 * the database to see if the request is completed or not and passes that information back to the view
 * using JSON. When the request is completed, the checkboxes will be re-enabled and another request can
 * be made.
 *
 * References:
 * http://www.techchorus.net/disable-and-enable-input-elements-div-block-using-jquery
 * http://api.jquery.com/category/selectors/
 */
//=====================================================================================================
$('.calibrate_sscc').w_click(function(){

    var sscc = document.getElementsByName("sscc");              //Obtains all elements named "sscc" and puts into sscc. THIS IS STILL AN ARRAY
    var millisecondInterval = 2000;
                            //Timer for setInterval function

    var is_checkbox_checked = 0;

    //Checks if checkbox was checked
    if($(this).parent().find('input[name="sscc"]:checked').length!=0){
        is_checkbox_checked = 1;
    }

    $.post('/remotesetup/calibrate_sscc',{
        is_checkbox_checked: is_checkbox_checked
    },function(calibrate_sscc_resp){

        // Display appropriate message based on if checkboxe is checked/unchecked
        if(is_checkbox_checked == 1){
            $("html").mask("Selecting SSCC. Please wait...");}
        else{
            $("html").mask("Unselecting SSCC. Please wait...");}

        if(calibrate_sscc_resp.ui_state_value == 1 && calibrate_sscc_resp.remote_password > 0){

            var periodic_call_flag = true;
            var periodic_call;
            periodic_call = setInterval(function(){
                if(periodic_call_flag){
                    periodic_call_flag = false;
                    $.post('/remotesetup/check_sscc_cal_state',{
                        request_id: calibrate_sscc_resp.request_id
                    },function(check_sscc_cal_state_resp){


                        if(check_sscc_cal_state_resp.request_state == 2){
                            clearInterval(periodic_call);
                            $("html").unmask("Calibrating SSCC. Please wait...");
                        }
                        periodic_call_flag = true;
                    },"json");
                }
            }, millisecondInterval);
        }else if(calibrate_sscc_resp.ui_state_value != 1 && calibrate_sscc_resp.remote_password > 0){

            $(".remotesetup_get").attr('disabled',true);
            $("#msg").html("<p style="+"color:red"+">Local User Presence Not Verified</p>").show();
            $("#msg").fadeOut(3000);

        }else if(calibrate_sscc_resp.ui_state_value == 1 && calibrate_sscc_resp.remote_password == 0){

            $("#password_field").hide();
            $("#track_elements").hide();
            $("#msg").html("<p style="+"color:red"+">Remote password timed out</p>").show();
            $("#msg").fadeOut(3000);

        }else{

            $(".remotesetup_get").attr('disabled',true);
            $("#password_field").hide();
            $("#track_elements").hide();
            $("#msg").html("<p style="+"color:red"+">Local User Presense Not Verified and Remote Password Timed Out</p>").show();
            $("#msg").fadeOut(5000);

        }
    },"json");


});

//=====================================================================================================
/*
 * Unlock function:
 *
 * This function is used to facilitate any Javascript needs from the 'Unlock' button on the remotesetup
 * page. When this button is clicked, Javascript is used to create a Popup Box known as a 'Confirm Box'.
 * This box requires the user to click 'OK' or 'Cancel' and the response will be saved into a variable
 * for further processing by the 'Unlock' action in the remotesetup controller.
 *
 * References:
 * http://www.w3schools.com/js/js_popup.asp
 */
$('.remotesetup_unlock').w_click(function(){
    if(!$(this).hasClass("disabled_buttons")){
        var timeoutInterval = 10000000;
        var millisecondInterval = 2000;

        if(confirm("Are you sure you want to unlock parameters?")){

            $("html").mask("Unlocking. Please wait...");

            $.post('/remotesetup/unlock',{
                //no params
            },function(unlock_resp){

                var timeout;
                timeout = setTimeout(function(){

                    clearInterval(periodic_call);
                    clearTimeout(timeout);

                    $("html").unmask("Unlocking. Please wait...");
                    $("#msg").html("<p style="+"color:red"+">The process has timed out!</p>").show();
                    $("#msg").fadeOut(3000);

                }, timeoutInterval);

                var periodic_call_flag = true;
                var periodic_call;
                periodic_call = setInterval(function(){
                    if(periodic_call_flag){
                        periodic_call_flag = false;

                        $.post('/remotesetup/check_unlock_state',{
                            request_id:parseInt(unlock_resp)
                        },function(unlock_check_resp){
                            if(parseInt(unlock_check_resp.request_state) == 2 && parseInt(unlock_check_resp.result) == 0){

                                clearTimeout(timeout);
                                clearInterval(periodic_call);

                                $("html").unmask("Unlocking. Please wait...");
                                $(".remotesetup_get").removeAttr('disabled');
                                $('.remotesetup_unlock').addClass('disabled_buttons');

                                $("#msg").html("<p style="+"color:green"+">Local User Presence Verified!</p>").show();
                                $("#msg").fadeOut(3000);

                                $('.remotesetup_get').removeClass('disabled_buttons');
                                $('.remotesetup_cancel').removeClass('disabled_buttons');

                                $('.remotesetup_time_field').removeAttr("disabled");

                                if(!isNaN(parseInt($('#password_field').val())) && parseInt($('#password_field').val())!=0){
                                    $('#track_elements').show();
                                    user_pres = 1;
                                }

                            }
                            //If the local user presses the 'Back' button, the request is completed and the result is 1
                            else if(unlock_check_resp.request_state == 2 && unlock_check_resp.result == 1){
                                clearTimeout(timeout);
                                clearInterval(periodic_call);

                                $("html").unmask("Unlocking. Please wait...");
                                $(".remotesetup_get").attr('disabled',true);

                                $("#msg").html("<p style="+"color:red"+">Local User Presence Failed!</p>");
                                $("#msg").show();
                                $("#msg").fadeOut(3000);
                            }
                            periodic_call_flag = true;
                        });
                    }
                }, millisecondInterval);
            });
        }
    }
});

//=====================================================================================================


$('.remotesetup_get').w_click(function(){
    if(!$(this).hasClass("disabled_buttons")){
        var millisecondInterval = 2000;

        //alert("Push button on front of the CPU card and press OK to continue");
        var a = confirm("Press OK and then push button on front of the CPU to continue\nor press Cancel to cancel password request.");
        if (a != true)
            return;
        $.post('/remotesetup/get',{

        },function(get_resp){

            if(get_resp.ui_state_value == 1){

                $("html").mask("Obtaining password. Please wait...");

                var periodic_call_flag = true;
                var periodic_call = setInterval(function(){
                    if(periodic_call_flag){
                        periodic_call_flag = false;

                        $.post('/remotesetup/wait_for_password',{
                            request_id: get_resp.request_id
                        },function(wait_resp){

                            if(parseInt(wait_resp) == 2){

                                clearInterval(periodic_call);

                                $("html").unmask("Obtaining password. Please wait...");
                                password();
                            }
                            periodic_call_flag = true;
                        });
                    }
                }, millisecondInterval);
            }else{

                $(".remotesetup_get").attr('disabled',true);
                $("#msg").html("<p style="+"color:red"+">Local User Presence Not Verified</p>").show();
                $("#msg").fadeOut(3000);
            }
        },"json");
    }
});


//=====================================================================================================
/*
 * Function password():
 *
 * The sole purpose of this function is to obtain the password from the database and rendering the resulting partial
 * into the info_table div.
 */
function password(){

    $.post('/remotesetup/password',{
        //no params
    },function(resp){

        var password_resp = resp.page_content
        user_pres = resp.local_user_presence

        if (resp.password != save_password){
            save_password = resp.password;
            $("#remote_setup_info_table").html(password_resp);
            $('.remotesetup_save_button').hide();
            $('.remotesetup_discard_button').hide();

            if(!isNaN(parseInt($('#password_field').val())) && parseInt($('#password_field').val()) > 0 && user_pres == 1){
                $("#track_elements").show();
            }
            else{
                $('#track_elements').hide();
            }

        }


        if(user_pres != save_user_pres){
            save_user_pres = user_pres
            if(user_pres == 1){
                $('.remotesetup_get').removeClass('disabled_buttons');
                $('.remotesetup_cancel').removeClass('disabled_buttons');
                $('.remotesetup_time_field').attr("disabled",false);
                $('.remotesetup_unlock').addClass('disabled_buttons');
            }else{
                $('.remotesetup_get').addClass('disabled_buttons');
                $('.remotesetup_cancel').addClass('disabled_buttons');
                $('.remotesetup_time_field').attr("disabled",true);
                $('.remotesetup_unlock').removeClass('disabled_buttons');
            }
        }
        time_changed_detection();
    },"json");
}
function time_changed_detection(){
    var remotesetup_time_field_var = parseInt($('.remotesetup_time_field').val());
    $('.remotesetup_time_field').keyup(function(event) {
        var temp = parseInt($(this).val());

        if(!isNaN(temp)){
            $(this).val(temp);
            if(temp != remotesetup_time_field_var){
                remotesetup_time_field_var = temp;

                $('.remotesetup_save_button').show();
                $('.remotesetup_discard_button').show();
            }
        }else{
            //$(this).val(0);
        }

    });
}

//=====================================================================================================

function timeout(){

    var millisecondInterval = 2000;

    var time_reference = document.forms["remote_time_field"]["time"].value

    $.post('/remotesetup/change_timeout',{
        time: time_reference
    },function(change_timeout_resp){
        if(change_timeout_resp.ui_state_value == 1 ){

            if(change_timeout_resp.validation == 0){
                var err_desc = "<p style=\"color:red\"> Invalid Remote Setup Timeout: valid range is from " +
                    change_timeout_resp.lower_bound.toString() + " to " +
                    change_timeout_resp.upper_bound.toString() + "</p>";
                $("#msg").html(err_desc).show();
                $("#msg").fadeOut(10000);
                $(".remotesetup_get").attr('disabled',true);
            }else{
                $("html").mask("Changing remote timeout. Please wait...");
                var periodic_call;
                var periodic_call_flag = true;
                periodic_call = setInterval(function(){
                    if(periodic_call_flag){
                        periodic_call_flag = false;

                        $.post('/remotesetup/wait_for_time',{
                            request_id: parseInt(change_timeout_resp.request_id)
                        },function(wait_for_time_resp){

                            if(parseInt(wait_for_time_resp) == 2){

                                clearInterval(periodic_call);
                                $("html").unmask("Changing remote timeout. Please wait...");
                                time();
                            }
                            periodic_call_flag = true;
                        });
                    }
                }, millisecondInterval);
            }


        }else{

            $("#msg").html("<p style="+"color:red"+">Local User Presence Not Verified</p>").show();
            $("#msg").fadeOut(3000);
            $(".remotesetup_get").attr('disabled',true);

        }
    },"json");

}

//=====================================================================================================
/*
 * Function time():
 *
 * The sole purpose of this function is to obtain the password from the database and rendering the resulting partial
 * into the info_table div.
 */
function time(){

    $.post('/remotesetup/time',{},function(time_resp){
        $("#remote_setup_info_table").html(time_resp);
        $('.remotesetup_save_button').hide();
        $('.remotesetup_discard_button').hide();
        time_changed_detection();
    });
}

//=====================================================================================================

$('.remotesetup_cancel').w_click(function(){
    if(!$(this).hasClass("disabled_buttons")){
        var millisecondInterval = 2000;
        $.post( '/remotesetup/cancel',{
            //no params
        },function(cancel_resp){

            if(cancel_resp.ui_state_value == 1){

                $("html").mask("Cancelling remote setup. Please wait...");

                var periodic_call_flag = true;
                var periodic_call = setInterval(function(){
                    if(periodic_call_flag){
                        periodic_call_flag = false;

                        $.post('/remotesetup/wait_for_cancel',{
                            request_id : cancel_resp.request_id
                        },function(wait_cancel_resp){

                            if(parseInt(wait_cancel_resp) == 2){

                                clearInterval(periodic_call);

                                $("html").unmask("Cancelling remote setup. Please wait...");
                                $("#track_elements").hide();

                                password();
                            }
                            periodic_call_flag = true;
                        });
                    }
                }, millisecondInterval);

            }else{

                $(".remotesetup_get").attr('disabled',true);
                $("#msg").html("<p style="+"color:red"+">Local User Presence Not Verified</p>").show();
                $("#msg").fadeOut(3000);

                password();
            }
        },"json");
    }
});

//=====================================================================================================
$(".remotesetup_save_button").w_click(function(){
    timeout();
    setHiddenOnClick();
});

$(".remotesetup_discard_button").w_click(function(){
    $(this).closest("table").find('.time_field').val($(this).closest("table").find('.reset_time').val());
    setHiddenOnClick();
});

