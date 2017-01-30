
	var gCancelSubmit = false;
	
    $(document).ready(function(){    	
    	start_verify_screen_request();    	
    });
    
    function submit_geo_mcf_form(form){   
    	var oerrval = $("#error_value");
        var form_content = $(form).serialize();
        var form_url = $(form).attr("action");
    	
        if (oerrval && oerrval.val() == 1)
          alert("Please correct the errors and try again.");
        
        $("#show_status").show();
        
        $.post(form_url, form_content, function(response){
        	$("#show_status").hide();
        	$("#mcfcontent").html(response);
        });

    	return false;
    }

    var check_set_to_default_rq = false;
    var set_default_req_counter = 0;
    var check_set_to_default_timer = null;
    
    function show_progress(bShow){
        if (bShow) 
            document.getElementById('show_status').style.display = 'block';
        else 
            document.getElementById('show_status').style.display = 'none';
    }
    
    function parameter_validation(){
        var oerrval = document.getElementById("error_value");
        
        if (oerrval) {
            if (oerrval.value == 1) {
                alert("Please correct the errors and try again.")
                return false;
            }
        }
        if (gCancelSubmit) {
            return false;
        }
        
        return true;
    }
    
    function validate_int_param_old(name, long_name, min, max){
        var o = document.getElementById(name);
        var b = document.getElementById("update");
        var c = document.getElementById("check");
        c.innerHTML = '0';
        if (o) {
            o.value = o.value.replace(/[^0-9]/g, '');
            
            if (o.value >= min && o.value <= max) {
                return true;
            }
        }
        alert("Error: value of '" + long_name + "' must be between " + min + " and " + max + ".");
        return false;
    }
    
    function validate_int_param(name, long_name, min, max){
        var oerr = document.getElementById("err_" + name);
        var oerrval = document.getElementById("error_value");
        var o = document.getElementById(name);
        var b = document.getElementById("update");
        var c = document.getElementById("check");
        
        if (oerr) {
            oerr.innerHTML = "";
        }
        
        if (oerrval) {
            oerrval.value = 0;
        }
        
        if (o) {
            o.value = o.value.replace(/[^0-9]/g, '');
            
            if (o.value >= min && o.value <= max) {
                return true;
            }
        }
        if (oerrval) {
            oerrval.value = 1;
        }
        if (oerr) {
            oerr.innerHTML = "<h3>Parameter Invalid:</h3>"
            oerr.innerHTML += "<br>Error: value of '" + long_name + "' must be between " + min + " and " + max + ".";
        }
        //alert("Error: value of '" + long_name + "' must be between " + min + " and " + max + ".");
        return false;
    }
    
    function check_condition(){
        var c = document.getElementById("check").innerHTML;
        if (c != "") {
            if (c == 0 || c == 1) {
                show_progress(true);
                return true;
            }
        }
        show_progress(false);
        return false;
    }
    
    
    function check_set_to_default(){
    
        var c = document.getElementById("check_set_to_default").innerHTML;
        
        if (c != "") {
            if (c == 0 || c == 1) {
                show_progress(true);
                return true;
                document.getElementById('check_set_to_default').innerHTML = "It will take some time to update the default values";
            }
        }
        document.getElementById('check_set_to_default').innerHTML = "It will take some time to update the default values";
        show_progress(false);
        return false;
    }
    
    function check_verify_screen_condition(){
        var o = document.getElementById("check");
        if (o) {
            o.innerHTML = "";
        }
        
        var c = document.getElementById("check_screen").innerHTML;
        if (c != "") {
            if (c == 0 || c == 1) {
                show_progress(true);
                return true;
            }
        }
        show_progress(false);
        return false;
    }
    
    /*	function check_set_edit_mode_condition()
     {
     var c = document.getElementById("check_set_edit_mode").innerHTML;
     if (c != "")
     {
     if (c == 0 || c == 1)
     {
     show_progress(true);
     return true;
     }
     
     }
     show_progress(false);
     return false;
     }*/
    function start_set_prop_request(s){
        gCancelSubmit = false;
        var o = document.getElementById("ui_command")
        //alert(0);
        if (o) {
            o.value = "1"
        }
        document.getElementById('show_status').style.display = 'block';
        document.getElementById("check").innerHTML = "0";
        //clear_messages();
    }
    
    
    function clear_messages(){
        var c = document.getElementById("successmesg");
        if (c) {
            c.innerHTML = "";
            c.style.display = "none";
        }
        c = document.getElementById("screen_crc_err");
        if (c) {
            c.innerHTML = "";
            c.style.display = "none";
        }
    }
    
    function start_set_edit_mode_request(){
        //clear_messages();
        gCancelSubmit = false;
        var msg = "Continuing to unlock configuration parameters for \n";
        msg += "editing will cause system to go into a restrictive state.\n";
        msg += "Changing UCN protected parameters will require a new UCN\n";
        msg += "to be entered for system to be operational.\n"
        msg += "Unlock configuration parameters?";
        var a = confirm(msg);
        if (!a) {
            gCancelSubmit = true;
            return;
        }
        
        var o = document.getElementById("ui_command")
        if (o) {
            o.value = "3"
        }
        document.getElementById("check_set_edit_mode").innerHTML = "0"
    }
    
    
    function start_verify_screen_request(){
        clear_messages();
        gCancelSubmit = false;
        var o = document.getElementById("ui_command")
        if (o) {
            o.value = "2"
        }
        $("#check_screen").html("0");	
    }
    
    function set_mcf_param_msg(b){
        var c = $("#successmesg");
        if (c) {
            if (b) {
                c.innerHTML = "Successfully updated the parameters!";
            }
            else {
                c.innerHTML = "Successfully updated the parameters";
                setTimeout('document.getElementById("successmesg").style.display="none"', 3000);
            }
            c.style.display = 'block';
        }
    }
    
    function crc_err(b){
        var o = document.getElementById("verify screen")
        if (o) {
            alert("a");
            o.disabled = true;
        }
        var c = document.getElementById("screen_crc_err");
        if (c) {
            if (b) {
                document.getElementById("successmesg").style.display = "none";
                c.innerHTML = "Screen verification failed!";
                c.style.display = 'block';
            }
            else {
                c.innerHTML = ""; //"Screen verification Success!";
                c.style.display = 'block';
            }
        }
    }
    
    function check_verify_default_condition(a){
        var c = a;
        //alert(c);
        if (c != 0) {
            return true;
        }
        window.location.href = '/mcfiviu';
        return false;
    }
    
    // Enum and integer validation for the mcf controller starts 
    
    function get_int_param_value(layout_index, layout_type, name, card_index, param_index, param_type){
        setConfirmUnload(false);
        
        var p = document.getElementById("parameter_name");
        if (p) {
            p.value = name;
        }
        p = document.getElementById("cur_cardindex");
        if (p) {
            p.value = card_index;
        }
        p = document.getElementById("cur_paramindex");
        if (p) {
            p.value = param_index;
        }
        p = document.getElementById("cur_paramtype");
        if (p) {
            p.value = param_type;
        }
        p = document.getElementById("cur_layout_type");
        if (p) {
            p.value = layout_type;
        }
        p = document.getElementById("cur_layout_index");
        if (p) {
            p.value = layout_index;
        }
        var o = document.getElementById(name);
        if (o) {
            if (o.value) {
                p = document.getElementById("parameter_value");
                if (p) {
                    p.value = o.value;
                }
                return o.value;
            }
        }
        
        
        return false;
    }
    
    function check_set_edit_mode_condition(){
        var c = document.getElementById("check_set_edit_mode").innerHTML;
        if (c != "") {
            if (c == 0 || c == 1) {
                show_progress(true);
                return true;
            }
            else 
                if (c == 2) {
                    show_progress(false);
                    return false;
                }
        }
        show_progress(false);
        return false;
    }
    
    function on_update_enum_param_value(layout_index, layout_type, name, card_index, param_index, param_type){
        setConfirmUnload(false);
        var p = document.getElementById("parameter_name");
        if (p) {
            p.value = name;
        }
        p = document.getElementById("cur_cardindex");
        if (p) {
            p.value = card_index;
        }
		
        p = document.getElementById("cur_paramindex");
        if (p) {
            p.value = param_index;
        }
        p = document.getElementById("cur_paramtype");
        if (p) {
            p.value = param_type;
        }

        p = document.getElementById("cur_layout_type");
        if (p) {
            p.value = layout_type;
        }
        p = document.getElementById("cur_layout_index");
        if (p) {
            p.value = layout_index;
        }
        var o = document.getElementById(name);
        if (o) {
            if (o.value) {
                p = document.getElementById("parameter_value");
                if (p) {
                    p.value = o.value;
                }				
                return o.value;
            }
        }        
        return 0;
    }
    
    
    /*	function start_set_prop_request(s)
     {
     gCancelSubmit = false;
     var o = document.getElementById("ui_command")
     if (o){
     o.value = "1"
     }
     document.getElementById("check").innerHTML = "0";
     }
     */
    function check_set_to_defaults_condition(){
        if (check_set_to_default_rq) {
            if (set_default_req_counter >= 18) {
                document.getElementById("check_default").innerHTML = "Request Timeout";
                check_set_to_default_rq = false;
                set_default_req_counter = 0;
                clearTimeout(check_set_to_default_timer);
                return false;
            }
            return true;
        }
        else {
            //window.location.href='/mcfiviu';	
            return false;
        }
    }
    
    // Enum and integer validation for the mcf controller 
    var title = 'Switches1'
