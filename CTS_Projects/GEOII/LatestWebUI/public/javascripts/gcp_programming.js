var screen_verify_timer;
var update_req_timer;
$(document).ready(function(){
	add_to_destroy(function(){
         $(document).bind("ready", function(){
         });
         
         //kills all wrapper events
         $('#template_set_to_defaults').w_die('click');
		 $('#MTFIndex').w_die('change');
         $('.integer_only').w_die('keyup');
         $('.contentCSPsel').w_die('change');
         $('#remote_sin').w_die('keyup');
		 $('.discard_changes').w_die('click');
		 $('.navigation').w_die('click');
		 $('.parameter_menu_link').w_die('click');
		 $('.parameters_unlock').w_die('click');
		 $('.parameters_save').w_die('click');
		 $('.parameters_form').w_die('submit');
		 $('.parameters_refresh').w_die('click');
		 $('.parameters_default').w_die('click');
        
         //clear intervals
         clearInterval(update_req_timer);
		 clearInterval(screen_verify_timer);
         
         //clear functions 
         delete window.validate;
         delete window.update_offset_values;
         delete window.sin_validation;
         delete window.run_set_to_default;
         delete window.open_newwindow;
         delete window.user_presence_request_state;
         delete window.request_screen_verification;
         delete window.check_screen_verification_state;
         delete window.request_template_details;
         delete window.DebugMsg;

         //clears global variables
         update_req_timer = null;
		 screen_verify_timer = null;
         delete window.hd_report_template_name;

     });
	var mcf_4000_version = $(".mcf_version").html();
    //if the page name has a ':' in it the name might have been updated so it will rebuild it to make sure
    if(mcf_4000_version != '' && mcf_4000_version != undefined && $('#page_name').length != 0 && $('#page_name').val().indexOf(':') != -1 && $("#track_setup").length <= 0){
		$('#contentareahdr',window.parent.document).html($('#page_name').val());
    }
	
    $("#template_set_to_defaults").w_click(function(){
        if (!$(this).hasClass("disable")) {
            if (confirm("Set Template defaults?")) {
                run_set_to_default();
            }
        }
    });

    $("#MTFIndex").w_change(function(){
        var mtf_index = $(this).val();
        request_template_details(mtf_index);
    });

    // GCP - 4K & 5K Integer parameters validation and display error message
    $(".integer_only").w_keyup(function(event){
		val_change = true;
	    add_v_preload_page();
    	if(!$(this).attr('disabled') && !$(this).attr('readonly') && !$(this).hasClass('disabled')){
	        var mcf_4000_version = $(".mcf_version").html();
	        if ((mcf_4000_version != '') && (mcf_4000_version != undefined) && (mcf_4000_version !="false")) {
	        }	        
	        var element_id = $(this).attr('modified_field');
	        var intRegex = /^[-]?[0-9]+$/;
	        var min = $(this).attr('min');
	        var max = $(this).attr('max');
	        var val = $(this).attr('value');
	        var param_id = $(this).attr('id');
	        var int_param_type = $(this).attr('int_param_type');
	        var unsigned_min = 0;
	        var unsigned_max = 0;
	        var current_val = $(this).attr('current_value');
	        var msg = "#prog_warning_msg_"+element_id
	        var valid_int = false;
        	var unit_measure = $(this).attr('unit_measure');			
	        var display_msg = "";
	        if (intRegex.test(val)) {
	            valid_int = true;
	            if (int_param_type == "signed"){
	                if ((parseInt(val,10) < parseInt(min,10)) || (parseInt(val,10) > parseInt(max,10))) {
	                    display_msg = "<span style='color:red;'>Value must be with in the range of " + min + " and " + max + "</span>";
	                    valid_int = false;
	                }
	            }
	            else{
	                unsigned_min = $(this).attr('unsigned_lower');
	                unsigned_max = $(this).attr('unsigned_upper');
	                valid_int = true;
	                
					if ((parseInt(val, 10) < parseInt(min, 10)) || (parseInt(val, 10) > parseInt(max, 10))) {
						if (parseInt(unsigned_min, 10) < parseInt(unsigned_max, 10)) {
							if ((parseInt(val, 10) < parseInt(unsigned_min, 10)) || (parseInt(val, 10) > parseInt(unsigned_max, 10))) {
								display_msg = "<span style='color:red;'>Value must be with in the range of " + min + " and " + max + " OR " + unsigned_min + "(" + (32768 - unsigned_min) + ") and " + unsigned_max + "(" + (32768 - unsigned_max) + ") </span>";
								valid_int = false;
							}
						}
						else 
							if ((parseInt(unsigned_min, 10) == parseInt(unsigned_max, 10)) && (parseInt(unsigned_min, 10) > 0)) {
								if (parseInt(val, 10) != parseInt(unsigned_min, 10)) {
									display_msg = "<span style='color:red;'>Value must be with in the range of " + min + " and " + max + " OR " + unsigned_min + "(" + (32768 - unsigned_min) + ") </span>";
									valid_int = false;
								}
							}
							else {
								display_msg = "<span style='color:red;'>Value must be with in the range of " + min + " and " + max + "</span>";
								valid_int = false;
							}
					}
	            }
	            if(valid_int){
	                $(msg).html("");
	                $(msg).hide();
	            }
	            else{
	                //$("#buttons_" + element_id).hide();
	                $(msg).show();
	                $(msg).html(display_msg);
	            }
	            display_msg = "";
	            $(this).focus();        // Bring the focus back to text field after validation
	        }
	        else {
	            $("#buttons_" + element_id).hide();
	            $(msg).show();
	            $(msg).html("<span style='color:red;'>Invalid format!! number only allowed</span>");
	            $(this).focus();        // Bring the focus back to text field after validation
	        }
	    }
    });

    // GCP-4000 validate the programming parameters
    $(".contentCSPsel").w_change(function(event){
    	if(!$(this).attr('disabled') && !$(this).attr('readonly') && !$(this).hasClass('disabled')){
	        var mcf_4000_version = $(".mcf_version").html();
	        if (!$(this).hasClass('integer_only') && !$(this).hasClass('atcs_sin_only')) {
	            if ((mcf_4000_version != '') && (mcf_4000_version != undefined) && (mcf_4000_version !="false")) {
	                var element_id = $(this).attr('modified_field');
	                if (validate_4k_params($(this).attr('id'))) {
	                    $(this).focus();
	                }
	            }
	        }
	    }
    });

    $("#remote_sin").w_keyup(function(){
    	if(!$(this).attr('disabled') && !$(this).attr('readonly') && !$(this).hasClass('disabled')){
	        var validate_sin = false;
	        var remote_sin = $(this).val();
	        var actual_sin = $("#hd_actual_sin").val();
	        var element_id = $(this).attr('modified_field');
	        //buttons_remote_sin_16
	        var mcf_4000_version = $(".mcf_version").html();	        
	        validate_sin = sin_validation(remote_sin);
	        $("#prog_warning_msg_remote_sin_16").html( validate_sin).css('color', 'red');
	        $("#prog_warning_msg_remote_sin_16").show();
	        if (validate_sin.length == 0){
	            if(update_offset_values(remote_sin, actual_sin, "#prog_warning_msg_remote_sin_16", ".integer_only")){
	                if(remote_sin != $(this).attr('current_value')){
	                	$("#buttons_" + element_id).show();
	                }
	                else{
	                	$("#buttons_" + element_id).hide();
	                	$(".contentCSPsel").each(function(index, ele){
                            $(ele).removeAttr('disabled');
                            $('button').removeAttr('disabled');
                        });
	                }
	            }
	        }
	        else{
	            $(this).focus();
	            $("#buttons_" + element_id).hide();
	            return validate_sin;
	        }
	    }
    });

    //GCP-4000 Discard the parameters values
    $(".discard_changes").w_click(function(){
        var current_value = $(this).attr('current_value');
        var param_name = $(this).attr('param_name');
        var modified_field = $(this).attr('modified_field');
        $("[modified_field='"+modified_field+"']").val(current_value);
        $("#buttons_"+modified_field).hide();
        if(param_name == 'MTFIndex'){
            request_template_details(current_value);
        }
        else if(param_name == 'remote_sin'){
            var actual_sin = $("#hd_actual_sin").val();
            update_offset_values(current_value, actual_sin, "", ".integer_only");
        }
        window.parent.myValue = false;
        $(".contentCSPsel").each(function(index, ele){
            $(ele).removeAttr('disabled');
            $('button').removeAttr('disabled');
        });
        if($("#"+param_name).length > 0 && $("#"+param_name).hasClass("invalid_select")){
            $("#"+param_name).attr("style", "border: 1px solid #FF0000 !important;");
        }
		remove_v_preload_page();
    });

    $(".navigation").w_click(function(event){
        if ($(this).parent().hasClass("disable")) 
			event.preventDefault();
		
		else 
		   var url = $(this).attr('page_href');
		   if (preload_page != "") {
		   	add_preload_page(url);
		   }
		   else{
		   	 loads_content('',$(this).attr("page_href"));
		   }   
        //$("#contentcontents").mask("Loading parameters, please wait...");
        //    $("#site_content").mask("Loading parameters, please wait...");
        return true;
    });
    
    $(".parameter_menu_link").w_click(function(event){
    	loads_content('',$(this).attr("page_href"));
    	return true;
    });
    

    $(".parameters_save").w_click(function(event){
        if($(this).hasClass("disabled_buttons"))
            return
            
        var has_error = false;	
		var errors = $('.v_error');
		if(errors.length > 1){
			errors.each(function(index, ele){			
				if ($(ele).html() != "") {
					has_error = true;
				}
			});
		}
		else if(errors.length == 1 && errors.html() != ""){
			has_error = true;
		}
		if(has_error == true)
			return;
        
		$(".parameters_form").submit();

    });

    $(".parameters_form").w_submit(function(event){
        event.preventDefault();
        event.stopPropagation();
		
        var parameters = $(this).serialize();
        var save_obj = {};	//creates json object
        var inputs = $(this).closest('#contentcontents').find('input,select');
		//indexs through all inputs
		inputs.each(function(){
			var key = $(this).attr('name');
			var val = $(this).val();
			//stores the key and val in the array
			save_obj[key] = val;
		});
		//save_obj["menu_link"] = $('#menu_link').val();
		//save_obj["page_name"] = $('#page_name').val();
        
        var update_req_process = false;
        var update_req_timer = false;
        var update_req_timer_process = false;
        var screen_verification_stop = false;
        //$("#ajax_spinner").show();
        var page_name = $.trim($("#page_name").val());
        //var parent_window = $('body', window.parent.document);
        var parent_window = $('#parent_window', window.parent.document);
        var template_field = $("#MTFIndex");
        if (template_field.length > 0 && template_field.val() != template_field.attr("current_value")) {
            var page_name = $.trim($("#page_name").val());
            if ((page_name == "Set Template") || (page_name == "TEMPLATE:  selection")) {
                var reboot_confirmation = confirm("Changing the Template will set the GCP configuration back to default\r\n\r\nDo you want to continue?");
                if (reboot_confirmation == false) {
                    if (page_name == "Set Template"){
                        $(".parameters_refresh").click();
                    }
                    var page_name = $("#page_name").val();
                    if ($("#setup_wizard").length > 0) {
                        url = "/gcp_programming/page_parameters?setup_wizard=true&refresh_parameters=true&page_name=" + page_name;
                        programming_req_progress = true;
                        $.get(url, function(response){
                            $("#ajax_spinner").hide();
                            $(".programming_parameters").html(response)
                            programming_req_progress = false;
                        })
                    }
                    return false;
                }

            }
            $(parent_window).mask("Saving parameters, please wait...");
        }
        else
            //$("#site_content").mask("Saving parameters, please wait...");
            $("#contentcontents").mask("Saving parameters, please wait...");

        programming_req_progress = true;
        if (!update_req_process) {
            update_req_process = true;
            $.post("/gcp_programming/update_parameters", save_obj, function(response){
                if (response.error == true) {
                    //$("#ajax_spinner").hide();
                    $("#basic_site").html(response.html);
					$(parent_window).unmask("Saving parameters, please wait...");
                    $("#response_message").html("<span class='mcf_errormesg'>"+response.error_msg+"</span>").show();
                    if($('.hd_linker_message').length > 0){
                        $('.hd_linker_message').html("<span class='mcf_errormesg'>"+response.error_msg+"</span>").show();
                    }
                    update_req_process = true;
                    programming_req_progress = false;
                }else {
                    var timer = 0;
                    update_req_timer = setInterval(function(){
                        if (update_req_timer_process == false) {
                            update_req_timer_process = true;
                            $.post("/gcp_programming/check_update_state", {
                                id: response.request_id,
                                menu_link: page_name,
                                parameters_values: response.parameters_values
                            }, function(resp){
                                timer += 1;
                                if (resp.request_state == "2" || timer == 10) {
                                    clearInterval(update_req_timer);
                                    //$("#ajax_spinner").hide();
                                    if(resp.request_state == '2'){
                                        $(".programming_parameters").html(resp.html).show();
                                        $("#contentcontents").unmask("Saving parameters, please wait...");
                                        if ($(parent_window).isMasked()) {
                                            $(parent_window).unmask("Saving parameters, please wait...");
                                        }
                                        if (resp.error == true){
                                            $("#response_message").html("<span class='mcf_errormesg'>Failed to save parameres</span>").show();
                                            if($('.hd_linker_message').length > 0){
                                                $('.hd_linker_message').html("<span class='mcf_errormesg'>Failed to save parameres</span>").show();
                                            }
                                        }else {
                                            $("#response_message").html("<span class='mcf_successmesg'>Successfully saved parameters</span>").show().fadeOut(6000);
                                            if($('.hd_linker_message').length > 0){
                                                $('.hd_linker_message').html("<span class='mcf_successmesg'>Successfully saved parameters</span>").show().fadeOut(6000);
                                            }
                                            remove_v_preload_page();
                                            if ((page_name == "Set Template") || (page_name == "TEMPLATE:  selection")) {
                                                screen_verification_stop = true;
                                                    $(parent_window).mask("Vital CPU rebooting,display will disconnect, please wait...");
                                                    setTimeout(function(){$(parent_window).unmask();},20000);
                                            }
                                            window.parent.myValue = false;
                                            update_hd_linker_button();  //function from hd_linker.js
                                        }
                                        //$("#site_content").unmask("Saving parameters, please wait...");
                                        $("#page_header").html(page_name).attr('name',page_name);
                                        var content_header = $('#contentareahdr', window.parent.document);
                                        if (content_header && content_header.html() == "Track Setup") {
                                            if (template_field.length > 0 && template_field.val() != template_field.attr("current_value")) {
                                                $(parent_window).unmask("Saving parameters, please wait...");
                                            }
                                            else
                                                $("#site_content").unmask("Saving parameters, please wait...");
                                        }else {
                                            if (screen_verification_stop == false) {

                                                var current_page_name = document.URL.split('?')[1]
                                                var current_menu_link = document.URL.split('?')[1]

                                                if(typeof current_page_name !== 'undefined'){
                                                    current_page_name = current_page_name.split('&')[0]
                                                    current_menu_link = current_menu_link.split('&')[1]

                                                    if(typeof current_page_name !== ""){
                                                        current_page_name = current_page_name.split('=')[1]
                                                    }

                                                    if(current_menu_link != undefined && typeof current_menu_link !== ""){
                                                        current_menu_link = current_menu_link.split('=')[1]
                                                    }
                                                }
                                                if(typeof current_page_name !== "undefined"){
                                                    var mrf_rebuild_tree = ['Module Selection','GCP Frequency','Dax','Prime','SSCC Configuration','Preemption','Preempt','Set Template','Set to Default']

                                                    var name_search = $.trim(current_page_name.replace(/%20/g,' ').replace(/^\s+|\s+$/g, ''));


                                                    if(name_search.split(' ')[0] == 'Dax'){
                                                        name_search = 'Dax'
                                                    }else if(name_search.split(' ')[0] == 'Prime'){
                                                       name_search = 'Prime' 
                                                    }else if(name_search.split(' ')[0] == 'Preempt'){
                                                       name_search = 'Preempt' 
                                                    }

                                                    if($.inArray(name_search, mrf_rebuild_tree) != -1){
                                                        window.location = '/gcp_programming/index?page_name='+current_page_name+'&menu_link='+page_name;

                                                    }else{
                                                        //request_screen_verification();
                                                    }
                                                }												

												if (page_name.toUpperCase() == "BASIC:  MODULE CONFIGURATION") {
												    load_content_flag = true;
												    $("#site_content").mask("Saving parameters, please wait...");
												    if (page_name.indexOf('(') == -1) {
												        build_vital_config_object("Configuration", $('.leftnavtext_D').last().closest('li').attr('page_href'));
												    }
												    else {
												        var partial_title = page_name.substr(0, page_name.indexOf('('));
												        var partial_title_trace = [];
												        
												        //gets all of the trace to the partial_title
												        var ul = $('.leftnavtext_D').last().closest('ul');
												        
												        while (ul.parent().is('li')) {
												            var text = ul.parent().find('span').first().text();
												            ul = ul.parent().closest('ul');
												            
												            partial_title_trace.unshift(text);
												        }
												        
												        var build_settings = {
												            'partial_title': partial_title,
												            'partial_title_trace': partial_title_trace
												        };
												        build_vital_config_object("Configuration", $('.leftnavtext_D').last().closest('li').attr('page_href'), build_settings);
												    }
												}									
                                            }
                                        }
										$("#site_content").unmask("Saving parameters, please wait...");
                                        programming_req_progress = false;
                                    }else if(timer == 10){
                                        $("#response_message").html("<span class='mcf_errormesg'>Request timed out!!</span>").show();
                                        if($('.hd_linker_message').length > 0){
                                            $('.hd_linker_message').html("<span class='mcf_errormesg'>Request timed out!!</span>").show();
                                        }
                                        if (template_field.length > 0 && template_field.val() != template_field.attr("current_value"))
                                            $(parent_window).unmask("Saving parameters, please wait...");
                                        else
                                            $("#site_content").unmask("Saving parameters, please wait...");
                                        programming_req_progress = false;
                                    }
                                    update_req_process = true;

                                    // Done, cleanup request
                                    //$.post("/gcp_programming/cleanup_config_property_iviu_request", {request_id: response.request_id}, function(response){});
                                }
                                update_req_timer_process = false;
                            }, "json");
                        }
                    }, 2000);
                }
                remove_v_preload_page();
            }, "json");
        }
    });

    $(".parameters_refresh").w_click(function(){
        $("#ajax_spinner").show();
        $("#message").html("");
        var page_name = $("#page_name").val();
        if($("#setup_wizard").length > 0)
            url = "/gcp_programming/page_parameters?setup_wizard=true&refresh_parameters=true&page_name="+page_name;
        else
            url = "/gcp_programming/page_parameters?page_name="+page_name;
        programming_req_progress = true;
        $.get(url, function(response){
            $("#ajax_spinner").hide();
            $(".programming_parameters").html(response);
            programming_req_progress = false;
        })
    });

    $(".parameters_default").click(function(){
        $("#message").html("");
        var page_name = $("#page_name").val();

    });
	
	$('.parameters_discard').w_click(function(){
	if($(this).hasClass("disabled"))
		return;
	var page_name = $("#page_name").val();
	var menu_link = $("#menu_link").val();
	$("#contentcontents").mask("Loading parameters, please wait...");
	$.post("/gcp_programming/page_parameters",{
        page_name: $("#page_name").val(), 
		menu_link: $("#menu_link").val(),
    },function(response){
		if (response!="" || response != null) {
			$("#contentcontents").html(response);
			$("#contentcontents").unmask("Saving parameters, please wait...");
			remove_v_preload_page();
		}
    });
});

    
});
function validate(param_id, param_ct_val){
    var current_value = $('#' + param_id).val();
    var invalid_value = param_ct_val;
    if (current_value == invalid_value) {
        return false;
    }else {
        return true;
    }
}

/*
 * Send set_to_default request, check for status, and clean request db when complete
 */
function run_set_to_default()
{
    var parent_window = $('.parent_class', window.parent.document);
    $(parent_window).mask("Setting default values, please wait...");

    $.get("/gcp_programming/set_to_default",
          function(reply){

            DebugMsg("return from set_to_default:");
            DebugMsg("request_id = " + reply.request_id);
            if (reply.error == 'true' || reply.error == true) {
				$(parent_window).unmask("Setting default values, please wait...");
				$("#response_message").show().html(reply.message).addClass('v_error_message');
			}
			else {
				var request_progress = false;
				var request_timer = 0;
				update_req_timer = setInterval(function(){
					if (!request_progress) {
						if (request_timer == 120) {
							clearInterval(update_req_timer);
							$(parent_window).unmask("Setting default values, please wait...");
							$("#response_message").show().html("<span class='mcf_errormesg' style='font-size:16px;'>Set to Default Request Timeout</span>");
							// Done, remove request from database
							$.post("/gcp_programming/cleanup_simplerequest", {
								request_id: reply.request_id
							}, function(response){
							});
							request_progress = false;
						}
						else {
							request_progress = true;
							request_timer++;
							$.post("/gcp_programming/check_set_to_defaults", {
								id: reply.request_id
							}, function(result){
								DebugMsg("return from check_set_to_defaults:");
								
								// Handle if result is not what was expected
								if (typeof(result.req_state) === "undefined") {
									DebugMsg("error catch");
									// Non JSON data, just render data as html
									$("#response_message").show().html(result);
								}
								else {
									DebugMsg("request state = " + result.req_state);
									
									if (result.req_state == 2) {
										DebugMsg("In case 2");
										clearInterval(update_req_timer);
										$(parent_window).unmask("Setting default values, please wait...");
										$("#response_message").show().html("<span class='mcf_successmesg' style='font-size:16px;'>Set to default process completed successfully</span>");
										// Done, remove request from database
										$.post("/gcp_programming/cleanup_simplerequest", {
											request_id: reply.request_id
										}, function(response){
										});
										request_progress = true;
									}
								}
								request_progress = false;
							});
						}
					}
				}, 2000);
			}
    });
}

function open_newwindow(menu_name, link_name, menu_id)
{
    if (!($("#div_link_ui_state").attr('disabled'))){    	
    	if($("#" + menu_id).hasClass('param_menu_link')){
        	$.fn.colorbox({href: "/gcp_programming/link_parameter?link_name=" + escape(link_name) + "&menu_name="+ escape(menu_name), width:"600px" , height :"250px"});
       }
    }
}


function request_template_details(mtf_index){
    $.ajax({
        url: '/gcp_programming/load_template_details',
        type: 'POST',
        data: {mtf_index: mtf_index},
        success: function(response){
            $("#template_details").html(response)
        }
    });
}

function add_preload_page(url){
    ConfirmDialog('Vital Config', 'You did not save all parameters.<br>Would you like to leave page?', function(){
        if (typeof item_clicked == 'object') {
            loads_content('', url);
        }
        preload_page = '';
    }, function(){
        //don't load the next page
    });
}

function run_set_to_default_pso()
{
    var parent_window = $('.parent_class', window.parent.document);
    $(parent_window).mask("Setting default values, please wait...");

    $.get("/gcp_programming/set_to_default_pso",
          function(reply){
				var request_progress = false;
				var request_timer = 0;
				update_req_timer = setInterval(function(){
					if (!request_progress) {
						if (request_timer == 120) {
							clearInterval(update_req_timer);
							$(parent_window).unmask("Setting default values, please wait...");
							$("#response_message").show().html("<span class='mcf_errormesg' style='font-size:16px;'>Set to Default Request Timeout</span>");
							// Done, remove request from database
							$.post("/gcp_programming/cleanup_simplerequest", {
								request_id: reply.request_id
							}, function(response){
							});
							request_progress = false;
						}
						else {
							request_progress = true;
							request_timer++;
							$.post("/gcp_programming/check_set_to_default", {
								id: reply.request_id
							}, function(result){								
								// Handle if result is not what was expected
								if (typeof(result.req_state) === "undefined") {
									// Non JSON data, just render data as html
									$("#response_message").show().html(result);
								}
								else {									
									if (result.req_state == 2) {
										clearInterval(update_req_timer);
										$(parent_window).unmask("Setting default values, please wait...");
										$("#response_message").show().html("<span class='mcf_successmesg' style='font-size:16px;'>Set to default process completed successfully</span>");
										// Done, remove request from database
										$.post("/gcp_programming/cleanup_simplerequest", {
											request_id: reply.request_id
										}, function(response){
										});
										request_progress = true;
									}
								}
								request_progress = false;
							});
						}
					}
				}, 2000);
    });
}


/*
 * An easy way to turn debugging messages on or off
 */
var DebugON = false;

function DebugMsg(message)
{
    if(DebugON)
        console.log(message);
}
