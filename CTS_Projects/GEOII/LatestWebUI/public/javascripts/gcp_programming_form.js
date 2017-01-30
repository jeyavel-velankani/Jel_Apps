/**
 * @author 305777
 */
var update_req_timer;
$(document).ready(function(){
    add_to_destroy(function(){
        $(document).bind("ready", function(){});
        
        //kills all wrapper events
        $('.no_presence').w_die('click');
        $('.disabled_field').w_die('change');
        $("input select").w_die('change');
        $('.invalid_select').w_die('change');
        $('.save_parameter').w_die('click');
        
        //clear intervals
        clearInterval(update_req_timer);
        
        //clear functions 
        //no functions
        
        //clears global variables
        update_req_timer = null;
    });
    
    $(".ui-spinner-up").attr('disabled', true);
    $(".ui-spinner-down").attr('disabled', true);
    //$(".parameters_reset_vlp").addClass("disable");
    if (ui_state != '') {
        if ($("#template_set_to_defaults").length > 0) 
            $("#template_set_to_defaults").removeClass("disable");
        $(".ui-spinner-up").removeAttr('disabled');
        $(".ui-spinner-down").removeAttr('disabled');
    }
});

$.each(["input","select"], function(index, value) {
	window.parent.myValue = true;
	$(value).w_change(function(){
		val_change = true;
		add_v_preload_page();	
	});
});

var mcf_4000_version = $(".mcf_version").html();

if (mcf_4000_version == '' && mcf_4000_version != undefined) {
    var page_header_name = '<%= params[:page_name] %>';
    if (page_header_name == 'SSCCIV Control and Setup') {
        page_header_name = '<%= params[:menu_link] %>';
    }
    $("#page_header").html(page_header_name);
    $("#page_header").attr("name", page_header_name);
}

//Select box validation //
$(".invalid_select").w_change(function(){
    var current_value = $(this).attr("current_value");
    if (current_value == $(this).val()) {
        $(this).attr("style", "border: 1px solid #FF0000 !important;");
    }
    else {
        $(this).attr("style", "border: 1px solid #888888 !important;");
    }
});

function validate_4k_params(this_id){
    var invalid_parameters = $("#hd_error_field").val();
    if (invalid_parameters) {
        var split_params = invalid_parameters.split('|')
        var loop_val = 0;
        for (var i = 0; i < split_params.length; i++) {
            var split_comma = split_params[i].split(',');
            if (split_comma[0] == this_id) {
                if (!validatate_invalid_params(split_comma[0], split_comma[1])) {
                    loop_val = loop_val + 1
                }
            }
        }
        if (loop_val == 0) {
            return true;
        }
        else {
            return false;
        }
    }
    else {
        return true;
    }
}

function validatate_invalid_params(param_id, param_ct_val){
    var current_value = $('#' + param_id).val();
    var invalid_value = param_ct_val;
    if (current_value == invalid_value) {
        return false;
    }
    else {
        return true;
    }
}

// To update forms for 4k
$(".save_parameter").each(function(index, element){
    $(element).click(function(){
    
        window.parent.myValue = false;
        
        $.post("/application/get_user_presence", {}, function(response){
            if (response.user_presence == true) {
                var parent_window = $('#parent_window', window.parent.document);
                var template_field = $("#MTFIndex");
                if (template_field.length > 0 && template_field.val() != template_field.attr("current_value")) {
                    var page_name = $.trim($('#page_header').attr('name'));
                    if (page_name == "TEMPLATE:  selection") {
                        var reboot_confirmation = confirm("Changing the Template will set the GCP configuration back to default\r\n\r\nDo you want to continue?");
                        if (reboot_confirmation == false) {
                            return false;
                        }
                    }
                    $(parent_window).mask("Saving parameters, please wait...");
                }
                else 
                    $("#site_content").mask("Saving parameters, please wait...");
                
                if ($(element).attr('param_name') != 'remote_sin') {
                    update_4k_params(element, false);
                }
                else {
                    update_4k_remotesin(element, false);
                }
            }
            else {
                alert("Parameters lock timedout!.\nBefore saving unlock parameters.");
                $('.parameters_unlock').removeClass("disabled_buttons");
            }
        }, "json");
    });
});

function update_4k_params(element_id, screen_verification_stop){
    var parent_window = $('#parent_window', window.parent.document);
    var template_field = $("#MTFIndex");
    var parameter_name = $(element_id).attr('param_name');
    var parameter_type = $(element_id).attr('param_type');
    var parameter_index = $(element_id).attr('param_index');
    var card_index = $(element_id).attr('card_index');
    var modified_field = $(element_id).attr('modified_field');
    var current_value = $(element_id).attr('current_value');
    var selected_field = $('select[modified_field=\"' + modified_field + '\"] option:selected');
    if (selected_field.length <= 0) 
        selected_field = $('input[modified_field=\"' + modified_field + '\"]');
    var updated_value = selected_field.val();
    var updated_name = selected_field.text().replace('*', '');
    var param_long_name = $(element_id).attr('param_long_name')
    var page_name = $.trim($('#page_header').attr('name'));
    
    $("#ajax_spinner").show();
    programming_req_progress = true;
    $.post('/gcp_programming/update', {
        updated_name: updated_name,
        page_name: page_name,
        param_long_name: param_long_name,
        updated_value: updated_value,
        parameter_name: parameter_name,
        parameter_type: parameter_type,
        parameter_index: parameter_index,
        card_index: card_index,
        current_value: current_value
    }, function(response){
        var update_req_timer_process = false;
        var timer = 0;
        if ($("#track_setup").val() != '') {
            var card_number = $("#card_number").val();
            var request_parameters = {
                id: response.request_id,
                menu_link: page_name,
                track_setup: true,
                card_number: card_number
            };
        }
        else 
            var request_parameters = {
                id: response.request_id,
                menu_link: page_name,
                parameters_values: response.parameters_values
            };
        update_req_timer = setInterval(function(){
            if (update_req_timer_process == false) {
                update_req_timer_process = true;
                $.post("/gcp_programming/check_update_req_state", request_parameters, function(resp){
                    timer += 1;
                    if (resp.request_state == "2" || timer == 10) {
                        clearInterval(update_req_timer);
                        $("#ajax_spinner").hide();
                        $("#buttons_" + parameter_name).hide();
                        $(".contentCSPsel").removeAttr('disabled');
                        $('button').removeAttr('disabled');
                        
                        if (template_field.length > 0 && template_field.val() != template_field.attr("current_value")) 
                            $(parent_window).unmask("Saving parameters, please wait...");
                        else 
                            $("#site_content").unmask("Saving parameters, please wait...");
                        
                        update_req_process = true;
                        programming_req_progress = false;
                        
                        if (resp.request_state == "2") {
                            $(".programming_parameters").html(resp.html);                           
                            if (resp.error == true) 
                                $("#response_message").html("<span class='mcf_errormesg'>Failed to save parameter").show();
                            else {
                                $("#response_message").html("<span class='mcf_successmesg'>Successfully saved parameter ").show().fadeOut(6000);
                                screen_verification_stop = true;
                                window.parent.myValue = false;
								remove_v_preload_page();
                            }
                            
                            var content_header = $('#contentareahdr', window.parent.document);
                            if (content_header && content_header.html() == "Track Setup") {
                                if (template_field.length > 0 && template_field.val() != template_field.attr("current_value")) 
                                    $(parent_window).unmask("Saving parameters, please wait...");
                                else 
                                    $("#site_content").unmask("Saving parameters, please wait...");
                            }
                            else {
                                if (screen_verification_stop == false) 
                                    request_screen_verification();
                            }
							if (page_name.toUpperCase() == "BASIC:  MODULE CONFIGURATION") {
                                $('#leftnavtree').html('');
                                load_content_flag = true;
								$("#site_content").mask("Saving parameters, please wait...");
                                build_vital_config_object("Configuration");
                            }
							$("#site_content").unmask("Saving parameters, please wait...");
                        }
                        else 
                            if (timer == 10) {
                                $("#response_message").html("<span class='mcf_errormesg'>Request timed out!! ").show();
                            }
                        
                        // Done, cleanup request
                        $.post("/gcp_programming/cleanup_config_property_request", {
                            request_id: response.request_id
                        }, function(result){
                        });
                    }
                    else {
                        update_req_timer_process = false;
                    }
                }, "json");
            }
        }, 2000);
    }, "json");
}

function update_4k_remotesin(element_id, screen_verification_stop,callback){
    var parent_window = $('#parent_window', window.parent.document);
    var template_field = $("#MTFIndex");
    var parameter_name = $(element_id).attr('param_name');
    var parameter_type = $(element_id).attr('param_type');
    var parameter_index = $(element_id).attr('param_index');
    var card_index = $(element_id).attr('card_index');
    var modified_field = $(element_id).attr('modified_field');
    var current_value = $(element_id).attr('current_value');
    var selected_field = $('input[modified_field=\"' + modified_field + '\"]');
    var updated_value = selected_field.val();
    var param_long_name = $(element_id).attr('param_long_name')
    var page_name = $.trim($('#page_header').attr('name'));
    var atcs_sin = $("#hd_actual_sin").val();
    
    $("#ajax_spinner").show();
    programming_req_progress = true;
    $.post('/gcp_programming/update_remote_sin_4k', {
        page_name: page_name,
        menu_link: page_name,
        param_long_name: param_long_name,
        updated_value: updated_value,
        parameter_name: parameter_name,
        parameter_type: parameter_type,
        parameter_index: parameter_index,
        card_index: card_index,
        current_value: current_value,
        atcs_sin: atcs_sin
    }, function(response){
        var update_req_timer_process = false;
        var timer = 0;      
        var request_parameters = {
                req_id: response.request_id,
                menu_link: page_name,
                parameters_values: response.parameters_values
            };
        update_req_timer = setInterval(function(){
            if (update_req_timer_process == false) {
                update_req_timer_process = true;
                $.post("/gcp_programming/check_update_req_state_remotesin", request_parameters, function(resp){
                    timer += 1;
                   if (resp.request_state == "2" || timer == 10) {
                        clearInterval(update_req_timer);
                        $("#ajax_spinner").hide();
                        $("#buttons_" + parameter_name).hide();
                        $(".contentCSPsel").removeAttr('disabled');
                        $('button').removeAttr('disabled');
                                                
                        update_req_process = true;
                        programming_req_progress = false;

                        if (resp.request_state == "2") {
							$(".programming_parameters").html(resp.html);
							if (resp.error == true) {
                                var saved_msg = "<span class='mcf_errormesg'>Failed to save parameter</span>";
								$("#response_message").html(saved_msg).show();
								$("#site_content").unmask("Saving parameters, please wait...");
                                if(typeof callback === 'function'){
                                    callback(saved_msg);
                                }
							}
							else {
                                var saved_msg = "<span class='mcf_successmesg'>Successfully saved parameter</span>";
                                
								$("#response_message").html(saved_msg).show().fadeOut(6000);
								remove_v_preload_page();
								$("#site_content").unmask("Saving parameters, please wait...");		
                                if(typeof callback === 'function'){
                                    callback(saved_msg);
                                }				      
							}
							
							if (screen_verification_stop == false) {
								request_screen_verification();
							}
							
						}
						else 
							if (timer == 10) {
                                var saved_msg = "<span class='mcf_errormesg'>Request timed out!!</span>";
								$("#response_message").html(saved_msg).show();
								$("#site_content").unmask("Saving parameters, please wait...");
                                if(typeof callback === 'function'){
                                    callback(saved_msg);
                                }
							}
                        
                        // Done, cleanup request
                        $.post("/gcp_programming/cleanup_config_property_request", {
                            request_id: response.request_id
                        }, function(result){
                        });
                    }
                    else {
                        update_req_timer_process = false;
                    }
                }, "json");
            }
        }, 2000);
    }, "json");
}
