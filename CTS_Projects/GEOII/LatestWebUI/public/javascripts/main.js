function check_req(){
    var c = document.getElementById('signal').value;
    if (c != "") {
        if (c == 2) {
            return false;
        }
        if (c == 1) {
            return false;
        }
    }
    return true;
}

function rep_check(){
    var c = document.getElementById('report_sig').value;
    if (c) {
        if (c == 2) {
            return false;
        }
        if (c == 1) {
            return false;
        }
    }
    return true;
}

$(document).ready(function(){
    // SUCCESS AJAX CALL, replace "success: false," by:     success : function() { callSuccessFunction() }, 
    
    $("#formID").validationEngine({
        containerOverflow: true,
        containerOverflowDOM: "#divOverflown"
    })
    $("#ethernet").validationEngine({
        containerOverflow: true,
        containerOverflowDOM: "#divOverflown"
    })
    $("#serial").validationEngine({
        containerOverflow: true,
        containerOverflowDOM: "#divOverflown"
    })
});
function news(showdiv, showhead, nums){
    document.getElementById(showdiv).style.display = "block";
    var mod_type = document.getElementById("md" + nums + "_type").value;
    //alert(mod_type);
    if (mod_type == 140) {
        document.getElementById("show_name" + nums).style.display = 'none'
    }
    else {
        document.getElementById("show_name" + nums).style.display = 'block'
    }
    if (mod_type == 152) 
        document.getElementById('md' + nums + '_geo_pts').style.display = 'block'
    else 
        document.getElementById('md' + nums + '_geo_pts').style.display = 'none'
    if (mod_type == 154) 
        document.getElementById('mod' + nums + '_show_iopanel').style.display = 'block'
    else 
        document.getElementById('mod' + nums + '_show_iopanel').style.display = 'none'
    if (mod_type == 147) 
        document.getElementById('mod' + nums + '_show_vhfc').style.display = 'block'
    else 
        document.getElementById('mod' + nums + '_show_vhfc').style.display = 'none'
    if (mod_type == 151) 
        document.getElementById('mod' + nums + '_show_ulcp').style.display = 'block'
    else 
        document.getElementById('mod' + nums + '_show_ulcp').style.display = 'none'
    hidediv(nums);
}

function hidediv(nums){
    for (i = 1; i <= 16; i++) {
        if (i != nums) 
            document.getElementById('myContent' + i).style.display = "none";
    }
}

function conn_validation(){

    //alert('hi');
    $('#myformconn').validate({
    
        debug: true,
        rules: {
            module1name: {
                required: true,
                rangelength: [document.getElementById('mod1name_min_len').value, document.getElementById('mod1name_max_len').value]
            
            },
            mod1_vhfc_stx: {
                required: true
            },
            mod1_vhfc_etx: {
                required: true
            },
            mod1_vhfc_chl: {
                required: true,
                range: [document.getElementById('mod1_vhfc_data_min_len').value, document.getElementById('mod1_vhfc_data_max_len').value]
            },
            mod1_vhfc_voice: {
                required: true,
                range: [document.getElementById('mod1_vhfc_voice_min_len').value, document.getElementById('mod1_vhfc_voice_max_len').value]
            },
            mod1_vhfc_tonelg: {
                required: true,
                range: [document.getElementById('mod1_vhfc_tonelg_min_len').value, document.getElementById('mod1_vhfc_tonelg_max_len').value]
            },
            mod1_vhfc_tonesp: {
                required: true,
                range: [document.getElementById('mod1_vhfc_tonesp_min_len').value, document.getElementById('mod1_vhfc_tonesp_max_len').value]
            },
            mod1_vhfc_keyup: {
                required: true,
                range: [document.getElementById('mod1_vhfc_keyup_min_len').value, document.getElementById('mod1_vhfc_keyup_max_len').value]
            },
            mod1_vhfc_keydn: {
                required: true,
                range: [document.getElementById('mod1_vhfc_keydn_min_len').value, document.getElementById('mod1_vhfc_keydn_max_len').value]
            },
            mod1_switch_offset: {
                required: true,
                range: [document.getElementById('mod1_ulcp_swt_min_len').value, document.getElementById('mod1_ulcp_swt_max_len').value]
            },
            mod1_led_offset: {
                required: true,
                range: [document.getElementById('mod1_ulcp_led_min_len').value, document.getElementById('mod1_ulcp_led_max_len').value]
            },
            mod1_io_size: {
                required: true,
                range: [document.getElementById('mod1_io_size_min_len').value, document.getElementById('mod1_io_size_max_len').value]
            },
            mod1_io_offset: {
                required: true,
                range: [document.getElementById('mod1_io_offset_min_len').value, document.getElementById('mod1_io_offset_max_len').value]
            },
            mod1_io_outputoffset: {
                required: true,
                range: [document.getElementById('mod1_io_otoffset_min_len').value, document.getElementById('mod1_io_otoffset_max_len').value]
            },
            module1atcsaddress: {
                required: true
            },
            module2name: {
                required: true,
                rangelength: [document.getElementById('mod2name_min_len').value, document.getElementById('mod2name_max_len').value]
            
            },
            mod2_vhfc_stx: {
                required: true
            },
            mod2_vhfc_etx: {
                required: true
            },
            mod2_vhfc_chl: {
                required: true,
                range: [document.getElementById('mod2_vhfc_data_min_len').value, document.getElementById('mod2_vhfc_data_max_len').value]
            },
            mod2_vhfc_voice: {
                required: true,
                range: [document.getElementById('mod2_vhfc_voice_min_len').value, document.getElementById('mod2_vhfc_voice_max_len').value]
            },
            mod2_vhfc_tonelg: {
                required: true,
                range: [document.getElementById('mod2_vhfc_tonelg_min_len').value, document.getElementById('mod2_vhfc_tonelg_max_len').value]
            },
            mod2_vhfc_tonesp: {
                required: true,
                range: [document.getElementById('mod2_vhfc_tonesp_min_len').value, document.getElementById('mod2_vhfc_tonesp_max_len').value]
            },
            mod2_vhfc_keyup: {
                required: true,
                range: [document.getElementById('mod2_vhfc_keyup_min_len').value, document.getElementById('mod2_vhfc_keyup_max_len').value]
            },
            mod2_vhfc_keydn: {
                required: true,
                range: [document.getElementById('mod2_vhfc_keydn_min_len').value, document.getElementById('mod2_vhfc_keydn_max_len').value]
            },
            mod2_switch_offset: {
                required: true,
                range: [document.getElementById('mod2_ulcp_swt_min_len').value, document.getElementById('mod2_ulcp_swt_max_len').value]
            },
            mod2_led_offset: {
                required: true,
                range: [document.getElementById('mod2_ulcp_led_min_len').value, document.getElementById('mod2_ulcp_led_max_len').value]
            },
            mod2_io_size: {
                required: true,
                range: [document.getElementById('mod2_io_size_min_len').value, document.getElementById('mod2_io_size_max_len').value]
            },
            mod2_io_offset: {
                required: true,
                range: [document.getElementById('mod2_io_offset_min_len').value, document.getElementById('mod2_io_offset_max_len').value]
            },
            mod2_io_outputoffset: {
                required: true,
                range: [document.getElementById('mod2_io_otoffset_min_len').value, document.getElementById('mod2_io_otoffset_max_len').value]
            },
            module2atcsaddress: {
                required: true
            },
            module3name: {
                required: true,
                rangelength: [document.getElementById('mod3name_min_len').value, document.getElementById('mod3name_max_len').value]
            
            },
            mod3_vhfc_stx: {
                required: true
            },
            mod3_vhfc_etx: {
                required: true
            },
            mod3_vhfc_chl: {
                required: true,
                range: [document.getElementById('mod3_vhfc_data_min_len').value, document.getElementById('mod3_vhfc_data_max_len').value]
            },
            mod3_vhfc_voice: {
                required: true,
                range: [document.getElementById('mod3_vhfc_voice_min_len').value, document.getElementById('mod3_vhfc_voice_max_len').value]
            },
            mod3_vhfc_tonelg: {
                required: true,
                range: [document.getElementById('mod3_vhfc_tonelg_min_len').value, document.getElementById('mod3_vhfc_tonelg_max_len').value]
            },
            mod3_vhfc_tonesp: {
                required: true,
                range: [document.getElementById('mod3_vhfc_tonesp_min_len').value, document.getElementById('mod3_vhfc_tonesp_max_len').value]
            },
            mod3_vhfc_keyup: {
                required: true,
                range: [document.getElementById('mod3_vhfc_keyup_min_len').value, document.getElementById('mod3_vhfc_keyup_max_len').value]
            },
            mod3_vhfc_keydn: {
                required: true,
                range: [document.getElementById('mod3_vhfc_keydn_min_len').value, document.getElementById('mod3_vhfc_keydn_max_len').value]
            },
            mod3_switch_offset: {
                required: true,
                range: [document.getElementById('mod3_ulcp_swt_min_len').value, document.getElementById('mod3_ulcp_swt_max_len').value]
            },
            mod3_led_offset: {
                required: true,
                range: [document.getElementById('mod3_ulcp_led_min_len').value, document.getElementById('mod3_ulcp_led_max_len').value]
            },
            mod3_io_size: {
                required: true,
                range: [document.getElementById('mod3_io_size_min_len').value, document.getElementById('mod3_io_size_max_len').value]
            },
            mod3_io_offset: {
                required: true,
                range: [document.getElementById('mod3_io_offset_min_len').value, document.getElementById('mod3_io_offset_max_len').value]
            },
            mod3_io_outputoffset: {
                required: true,
                range: [document.getElementById('mod3_io_otoffset_min_len').value, document.getElementById('mod3_io_otoffset_max_len').value]
            },
            module3atcsaddress: {
                required: true
            },
            module4name: {
                required: true,
                rangelength: [document.getElementById('mod4name_min_len').value, document.getElementById('mod4name_max_len').value]
            
            },
            mod4_vhfc_stx: {
                required: true
            },
            mod4_vhfc_etx: {
                required: true
            },
            mod4_vhfc_chl: {
                required: true,
                range: [document.getElementById('mod4_vhfc_data_min_len').value, document.getElementById('mod4_vhfc_data_max_len').value]
            },
            mod4_vhfc_voice: {
                required: true,
                range: [document.getElementById('mod4_vhfc_voice_min_len').value, document.getElementById('mod4_vhfc_voice_max_len').value]
            },
            mod4_vhfc_tonelg: {
                required: true,
                range: [document.getElementById('mod4_vhfc_tonelg_min_len').value, document.getElementById('mod4_vhfc_tonelg_max_len').value]
            },
            mod4_vhfc_tonesp: {
                required: true,
                range: [document.getElementById('mod4_vhfc_tonesp_min_len').value, document.getElementById('mod4_vhfc_tonesp_max_len').value]
            },
            mod4_vhfc_keyup: {
                required: true,
                range: [document.getElementById('mod4_vhfc_keyup_min_len').value, document.getElementById('mod4_vhfc_keyup_max_len').value]
            },
            mod4_vhfc_keydn: {
                required: true,
                range: [document.getElementById('mod4_vhfc_keydn_min_len').value, document.getElementById('mod4_vhfc_keydn_max_len').value]
            },
            mod4_switch_offset: {
                required: true,
                range: [document.getElementById('mod4_ulcp_swt_min_len').value, document.getElementById('mod4_ulcp_swt_max_len').value]
            },
            mod4_led_offset: {
                required: true,
                range: [document.getElementById('mod4_ulcp_led_min_len').value, document.getElementById('mod4_ulcp_led_max_len').value]
            },
            mod4_io_size: {
                required: true,
                range: [document.getElementById('mod4_io_size_min_len').value, document.getElementById('mod4_io_size_max_len').value]
            },
            mod4_io_offset: {
                required: true,
                range: [document.getElementById('mod4_io_offset_min_len').value, document.getElementById('mod4_io_offset_max_len').value]
            },
            mod4_io_outputoffset: {
                required: true,
                range: [document.getElementById('mod4_io_otoffset_min_len').value, document.getElementById('mod4_io_otoffset_max_len').value]
            },
            module4atcsaddress: {
                required: true
            },
            module5name: {
                required: true,
                rangelength: [document.getElementById('mod5name_min_len').value, document.getElementById('mod5name_max_len').value]
            
            },
            mod5_vhfc_stx: {
                required: true
            },
            mod5_vhfc_etx: {
                required: true
            },
            mod5_vhfc_chl: {
                required: true,
                range: [document.getElementById('mod5_vhfc_data_min_len').value, document.getElementById('mod5_vhfc_data_max_len').value]
            },
            mod5_vhfc_voice: {
                required: true,
                range: [document.getElementById('mod5_vhfc_voice_min_len').value, document.getElementById('mod5_vhfc_voice_max_len').value]
            },
            mod5_vhfc_tonelg: {
                required: true,
                range: [document.getElementById('mod5_vhfc_tonelg_min_len').value, document.getElementById('mod5_vhfc_tonelg_max_len').value]
            },
            mod5_vhfc_tonesp: {
                required: true,
                range: [document.getElementById('mod5_vhfc_tonesp_min_len').value, document.getElementById('mod5_vhfc_tonesp_max_len').value]
            },
            mod5_vhfc_keyup: {
                required: true,
                range: [document.getElementById('mod5_vhfc_keyup_min_len').value, document.getElementById('mod5_vhfc_keyup_max_len').value]
            },
            mod5_vhfc_keydn: {
                required: true,
                range: [document.getElementById('mod5_vhfc_keydn_min_len').value, document.getElementById('mod5_vhfc_keydn_max_len').value]
            },
            mod5_switch_offset: {
                required: true,
                range: [document.getElementById('mod5_ulcp_swt_min_len').value, document.getElementById('mod5_ulcp_swt_max_len').value]
            },
            mod5_led_offset: {
                required: true,
                range: [document.getElementById('mod5_ulcp_led_min_len').value, document.getElementById('mod5_ulcp_led_max_len').value]
            },
            mod5_io_size: {
                required: true,
                range: [document.getElementById('mod5_io_size_min_len').value, document.getElementById('mod5_io_size_max_len').value]
            },
            mod5_io_offset: {
                required: true,
                range: [document.getElementById('mod5_io_offset_min_len').value, document.getElementById('mod5_io_offset_max_len').value]
            },
            mod5_io_outputoffset: {
                required: true,
                range: [document.getElementById('mod5_io_otoffset_min_len').value, document.getElementById('mod5_io_otoffset_max_len').value]
            },
            module5atcsaddress: {
                required: true
            },
            module6name: {
                required: true,
                rangelength: [document.getElementById('mod6name_min_len').value, document.getElementById('mod6name_max_len').value]
            
            },
            mod6_vhfc_stx: {
                required: true
            },
            mod6_vhfc_etx: {
                required: true
            },
            mod6_vhfc_chl: {
                required: true,
                range: [document.getElementById('mod6_vhfc_data_min_len').value, document.getElementById('mod6_vhfc_data_max_len').value]
            },
            mod6_vhfc_voice: {
                required: true,
                range: [document.getElementById('mod6_vhfc_voice_min_len').value, document.getElementById('mod6_vhfc_voice_max_len').value]
            },
            mod6_vhfc_tonelg: {
                required: true,
                range: [document.getElementById('mod6_vhfc_tonelg_min_len').value, document.getElementById('mod6_vhfc_tonelg_max_len').value]
            },
            mod6_vhfc_tonesp: {
                required: true,
                range: [document.getElementById('mod6_vhfc_tonesp_min_len').value, document.getElementById('mod6_vhfc_tonesp_max_len').value]
            },
            mod6_vhfc_keyup: {
                required: true,
                range: [document.getElementById('mod6_vhfc_keyup_min_len').value, document.getElementById('mod6_vhfc_keyup_max_len').value]
            },
            mod6_vhfc_keydn: {
                required: true,
                range: [document.getElementById('mod6_vhfc_keydn_min_len').value, document.getElementById('mod6_vhfc_keydn_max_len').value]
            },
            mod6_switch_offset: {
                required: true,
                range: [document.getElementById('mod6_ulcp_swt_min_len').value, document.getElementById('mod6_ulcp_swt_max_len').value]
            },
            mod6_led_offset: {
                required: true,
                range: [document.getElementById('mod6_ulcp_led_min_len').value, document.getElementById('mod6_ulcp_led_max_len').value]
            },
            mod6_io_size: {
                required: true,
                range: [document.getElementById('mod6_io_size_min_len').value, document.getElementById('mod6_io_size_max_len').value]
            },
            mod6_io_offset: {
                required: true,
                range: [document.getElementById('mod6_io_offset_min_len').value, document.getElementById('mod6_io_offset_max_len').value]
            },
            mod6_io_outputoffset: {
                required: true,
                range: [document.getElementById('mod6_io_otoffset_min_len').value, document.getElementById('mod6_io_otoffset_max_len').value]
            },
            module6atcsaddress: {
                required: true
            },
            module7name: {
                required: true,
                rangelength: [document.getElementById('mod7name_min_len').value, document.getElementById('mod7name_max_len').value]
            
            },
            mod7_vhfc_stx: {
                required: true
            },
            mod7_vhfc_etx: {
                required: true
            },
            mod7_vhfc_chl: {
                required: true,
                range: [document.getElementById('mod7_vhfc_data_min_len').value, document.getElementById('mod7_vhfc_data_max_len').value]
            },
            mod7_vhfc_voice: {
                required: true,
                range: [document.getElementById('mod7_vhfc_voice_min_len').value, document.getElementById('mod7_vhfc_voice_max_len').value]
            },
            mod7_vhfc_tonelg: {
                required: true,
                range: [document.getElementById('mod7_vhfc_tonelg_min_len').value, document.getElementById('mod7_vhfc_tonelg_max_len').value]
            },
            mod7_vhfc_tonesp: {
                required: true,
                range: [document.getElementById('mod7_vhfc_tonesp_min_len').value, document.getElementById('mod7_vhfc_tonesp_max_len').value]
            },
            mod7_vhfc_keyup: {
                required: true,
                range: [document.getElementById('mod7_vhfc_keyup_min_len').value, document.getElementById('mod7_vhfc_keyup_max_len').value]
            },
            mod7_vhfc_keydn: {
                required: true,
                range: [document.getElementById('mod7_vhfc_keydn_min_len').value, document.getElementById('mod7_vhfc_keydn_max_len').value]
            },
            mod7_switch_offset: {
                required: true,
                range: [document.getElementById('mod7_ulcp_swt_min_len').value, document.getElementById('mod7_ulcp_swt_max_len').value]
            },
            mod7_led_offset: {
                required: true,
                range: [document.getElementById('mod7_ulcp_led_min_len').value, document.getElementById('mod7_ulcp_led_max_len').value]
            },
            mod7_io_size: {
                required: true,
                range: [document.getElementById('mod7_io_size_min_len').value, document.getElementById('mod7_io_size_max_len').value]
            },
            mod7_io_offset: {
                required: true,
                range: [document.getElementById('mod7_io_offset_min_len').value, document.getElementById('mod7_io_offset_max_len').value]
            },
            mod7_io_outputoffset: {
                required: true,
                range: [document.getElementById('mod7_io_otoffset_min_len').value, document.getElementById('mod7_io_otoffset_max_len').value]
            },
            module7atcsaddress: {
                required: true
            },
            module8name: {
                required: true,
                rangelength: [document.getElementById('mod8name_min_len').value, document.getElementById('mod8name_max_len').value]
            
            },
            mod8_vhfc_stx: {
                required: true
            },
            mod8_vhfc_etx: {
                required: true
            },
            mod8_vhfc_chl: {
                required: true,
                range: [document.getElementById('mod8_vhfc_data_min_len').value, document.getElementById('mod8_vhfc_data_max_len').value]
            },
            mod8_vhfc_voice: {
                required: true,
                range: [document.getElementById('mod8_vhfc_voice_min_len').value, document.getElementById('mod8_vhfc_voice_max_len').value]
            },
            mod8_vhfc_tonelg: {
                required: true,
                range: [document.getElementById('mod8_vhfc_tonelg_min_len').value, document.getElementById('mod8_vhfc_tonelg_max_len').value]
            },
            mod8_vhfc_tonesp: {
                required: true,
                range: [document.getElementById('mod8_vhfc_tonesp_min_len').value, document.getElementById('mod8_vhfc_tonesp_max_len').value]
            },
            mod8_vhfc_keyup: {
                required: true,
                range: [document.getElementById('mod8_vhfc_keyup_min_len').value, document.getElementById('mod8_vhfc_keyup_max_len').value]
            },
            mod8_vhfc_keydn: {
                required: true,
                range: [document.getElementById('mod8_vhfc_keydn_min_len').value, document.getElementById('mod8_vhfc_keydn_max_len').value]
            },
            mod8_switch_offset: {
                required: true,
                range: [document.getElementById('mod8_ulcp_swt_min_len').value, document.getElementById('mod8_ulcp_swt_max_len').value]
            },
            mod8_led_offset: {
                required: true,
                range: [document.getElementById('mod8_ulcp_led_min_len').value, document.getElementById('mod8_ulcp_led_max_len').value]
            },
            mod8_io_size: {
                required: true,
                range: [document.getElementById('mod8_io_size_min_len').value, document.getElementById('mod8_io_size_max_len').value]
            },
            mod8_io_offset: {
                required: true,
                range: [document.getElementById('mod8_io_offset_min_len').value, document.getElementById('mod8_io_offset_max_len').value]
            },
            mod8_io_outputoffset: {
                required: true,
                range: [document.getElementById('mod8_io_otoffset_min_len').value, document.getElementById('mod8_io_otoffset_max_len').value]
            },
            module8atcsaddress: {
                required: true
            },
            module9name: {
                required: true,
                rangelength: [document.getElementById('mod9name_min_len').value, document.getElementById('mod9name_max_len').value]
            
            },
            mod9_vhfc_stx: {
                required: true
            },
            mod9_vhfc_etx: {
                required: true
            },
            mod9_vhfc_chl: {
                required: true,
                range: [document.getElementById('mod9_vhfc_data_min_len').value, document.getElementById('mod9_vhfc_data_max_len').value]
            },
            mod9_vhfc_voice: {
                required: true,
                range: [document.getElementById('mod9_vhfc_voice_min_len').value, document.getElementById('mod9_vhfc_voice_max_len').value]
            },
            mod9_vhfc_tonelg: {
                required: true,
                range: [document.getElementById('mod9_vhfc_tonelg_min_len').value, document.getElementById('mod9_vhfc_tonelg_max_len').value]
            },
            mod9_vhfc_tonesp: {
                required: true,
                range: [document.getElementById('mod9_vhfc_tonesp_min_len').value, document.getElementById('mod9_vhfc_tonesp_max_len').value]
            },
            mod9_vhfc_keyup: {
                required: true,
                range: [document.getElementById('mod9_vhfc_keyup_min_len').value, document.getElementById('mod9_vhfc_keyup_max_len').value]
            },
            mod9_vhfc_keydn: {
                required: true,
                range: [document.getElementById('mod9_vhfc_keydn_min_len').value, document.getElementById('mod9_vhfc_keydn_max_len').value]
            },
            mod9_switch_offset: {
                required: true,
                range: [document.getElementById('mod9_ulcp_swt_min_len').value, document.getElementById('mod9_ulcp_swt_max_len').value]
            },
            mod9_led_offset: {
                required: true,
                range: [document.getElementById('mod9_ulcp_led_min_len').value, document.getElementById('mod9_ulcp_led_max_len').value]
            },
            mod9_io_size: {
                required: true,
                range: [document.getElementById('mod9_io_size_min_len').value, document.getElementById('mod9_io_size_max_len').value]
            },
            mod9_io_offset: {
                required: true,
                range: [document.getElementById('mod9_io_offset_min_len').value, document.getElementById('mod9_io_offset_max_len').value]
            },
            mod9_io_outputoffset: {
                required: true,
                range: [document.getElementById('mod9_io_otoffset_min_len').value, document.getElementById('mod9_io_otoffset_max_len').value]
            },
            module9atcsaddress: {
                required: true
            },
            module10name: {
                required: true,
                rangelength: [document.getElementById('mod10name_min_len').value, document.getElementById('mod10name_max_len').value]
            
            },
            mod10_vhfc_stx: {
                required: true
            },
            mod10_vhfc_etx: {
                required: true
            },
            mod10_vhfc_chl: {
                required: true,
                range: [document.getElementById('mod10_vhfc_data_min_len').value, document.getElementById('mod10_vhfc_data_max_len').value]
            },
            mod10_vhfc_voice: {
                required: true,
                range: [document.getElementById('mod10_vhfc_voice_min_len').value, document.getElementById('mod10_vhfc_voice_max_len').value]
            },
            mod10_vhfc_tonelg: {
                required: true,
                range: [document.getElementById('mod10_vhfc_tonelg_min_len').value, document.getElementById('mod10_vhfc_tonelg_max_len').value]
            },
            mod10_vhfc_tonesp: {
                required: true,
                range: [document.getElementById('mod10_vhfc_tonesp_min_len').value, document.getElementById('mod10_vhfc_tonesp_max_len').value]
            },
            mod10_vhfc_keyup: {
                required: true,
                range: [document.getElementById('mod10_vhfc_keyup_min_len').value, document.getElementById('mod10_vhfc_keyup_max_len').value]
            },
            mod10_vhfc_keydn: {
                required: true,
                range: [document.getElementById('mod10_vhfc_keydn_min_len').value, document.getElementById('mod10_vhfc_keydn_max_len').value]
            },
            mod10_switch_offset: {
                required: true,
                range: [document.getElementById('mod10_ulcp_swt_min_len').value, document.getElementById('mod10_ulcp_swt_max_len').value]
            },
            mod10_led_offset: {
                required: true,
                range: [document.getElementById('mod10_ulcp_led_min_len').value, document.getElementById('mod10_ulcp_led_max_len').value]
            },
            mod10_io_size: {
                required: true,
                range: [document.getElementById('mod10_io_size_min_len').value, document.getElementById('mod10_io_size_max_len').value]
            },
            mod10_io_offset: {
                required: true,
                range: [document.getElementById('mod10_io_offset_min_len').value, document.getElementById('mod10_io_offset_max_len').value]
            },
            mod10_io_outputoffset: {
                required: true,
                range: [document.getElementById('mod10_io_otoffset_min_len').value, document.getElementById('mod10_io_otoffset_max_len').value]
            },
            module10atcsaddress: {
                required: true
            },
            module11name: {
                required: true,
                rangelength: [document.getElementById('mod11name_min_len').value, document.getElementById('mod11name_max_len').value]
            
            },
            mod11_vhfc_stx: {
                required: true
            },
            mod11_vhfc_etx: {
                required: true
            },
            mod11_vhfc_chl: {
                required: true,
                range: [document.getElementById('mod11_vhfc_data_min_len').value, document.getElementById('mod11_vhfc_data_max_len').value]
            },
            mod11_vhfc_voice: {
                required: true,
                range: [document.getElementById('mod11_vhfc_voice_min_len').value, document.getElementById('mod11_vhfc_voice_max_len').value]
            },
            mod11_vhfc_tonelg: {
                required: true,
                range: [document.getElementById('mod11_vhfc_tonelg_min_len').value, document.getElementById('mod11_vhfc_tonelg_max_len').value]
            },
            mod11_vhfc_tonesp: {
                required: true,
                range: [document.getElementById('mod11_vhfc_tonesp_min_len').value, document.getElementById('mod11_vhfc_tonesp_max_len').value]
            },
            mod11_vhfc_keyup: {
                required: true,
                range: [document.getElementById('mod11_vhfc_keyup_min_len').value, document.getElementById('mod11_vhfc_keyup_max_len').value]
            },
            mod11_vhfc_keydn: {
                required: true,
                range: [document.getElementById('mod11_vhfc_keydn_min_len').value, document.getElementById('mod11_vhfc_keydn_max_len').value]
            },
            mod11_switch_offset: {
                required: true,
                range: [document.getElementById('mod11_ulcp_swt_min_len').value, document.getElementById('mod11_ulcp_swt_max_len').value]
            },
            mod11_led_offset: {
                required: true,
                range: [document.getElementById('mod11_ulcp_led_min_len').value, document.getElementById('mod11_ulcp_led_max_len').value]
            },
            mod11_io_size: {
                required: true,
                range: [document.getElementById('mod11_io_size_min_len').value, document.getElementById('mod11_io_size_max_len').value]
            },
            mod11_io_offset: {
                required: true,
                range: [document.getElementById('mod11_io_offset_min_len').value, document.getElementById('mod11_io_offset_max_len').value]
            },
            mod11_io_outputoffset: {
                required: true,
                range: [document.getElementById('mod11_io_otoffset_min_len').value, document.getElementById('mod11_io_otoffset_max_len').value]
            },
            module11atcsaddress: {
                required: true
            },
            module12name: {
                required: true,
                rangelength: [document.getElementById('mod12name_min_len').value, document.getElementById('mod12name_max_len').value]
            
            },
            mod12_vhfc_stx: {
                required: true
            },
            mod12_vhfc_etx: {
                required: true
            },
            mod12_vhfc_chl: {
                required: true,
                range: [document.getElementById('mod12_vhfc_data_min_len').value, document.getElementById('mod12_vhfc_data_max_len').value]
            },
            mod12_vhfc_voice: {
                required: true,
                range: [document.getElementById('mod12_vhfc_voice_min_len').value, document.getElementById('mod12_vhfc_voice_max_len').value]
            },
            mod12_vhfc_tonelg: {
                required: true,
                range: [document.getElementById('mod12_vhfc_tonelg_min_len').value, document.getElementById('mod12_vhfc_tonelg_max_len').value]
            },
            mod12_vhfc_tonesp: {
                required: true,
                range: [document.getElementById('mod12_vhfc_tonesp_min_len').value, document.getElementById('mod12_vhfc_tonesp_max_len').value]
            },
            mod12_vhfc_keyup: {
                required: true,
                range: [document.getElementById('mod12_vhfc_keyup_min_len').value, document.getElementById('mod12_vhfc_keyup_max_len').value]
            },
            mod12_vhfc_keydn: {
                required: true,
                range: [document.getElementById('mod12_vhfc_keydn_min_len').value, document.getElementById('mod12_vhfc_keydn_max_len').value]
            },
            mod12_switch_offset: {
                required: true,
                range: [document.getElementById('mod12_ulcp_swt_min_len').value, document.getElementById('mod12_ulcp_swt_max_len').value]
            },
            mod12_led_offset: {
                required: true,
                range: [document.getElementById('mod12_ulcp_led_min_len').value, document.getElementById('mod12_ulcp_led_max_len').value]
            },
            mod12_io_size: {
                required: true,
                range: [document.getElementById('mod12_io_size_min_len').value, document.getElementById('mod12_io_size_max_len').value]
            },
            mod12_io_offset: {
                required: true,
                range: [document.getElementById('mod12_io_offset_min_len').value, document.getElementById('mod12_io_offset_max_len').value]
            },
            mod12_io_outputoffset: {
                required: true,
                range: [document.getElementById('mod12_io_otoffset_min_len').value, document.getElementById('mod12_io_otoffset_max_len').value]
            },
            module12atcsaddress: {
                required: true
            },
            module13name: {
                required: true,
                rangelength: [document.getElementById('mod13name_min_len').value, document.getElementById('mod13name_max_len').value]
            
            },
            mod13_vhfc_stx: {
                required: true
            },
            mod13_vhfc_etx: {
                required: true
            },
            mod13_vhfc_chl: {
                required: true,
                range: [document.getElementById('mod13_vhfc_data_min_len').value, document.getElementById('mod13_vhfc_data_max_len').value]
            },
            mod13_vhfc_voice: {
                required: true,
                range: [document.getElementById('mod13_vhfc_voice_min_len').value, document.getElementById('mod13_vhfc_voice_max_len').value]
            },
            mod13_vhfc_tonelg: {
                required: true,
                range: [document.getElementById('mod13_vhfc_tonelg_min_len').value, document.getElementById('mod13_vhfc_tonelg_max_len').value]
            },
            mod13_vhfc_tonesp: {
                required: true,
                range: [document.getElementById('mod13_vhfc_tonesp_min_len').value, document.getElementById('mod13_vhfc_tonesp_max_len').value]
            },
            mod13_vhfc_keyup: {
                required: true,
                range: [document.getElementById('mod13_vhfc_keyup_min_len').value, document.getElementById('mod13_vhfc_keyup_max_len').value]
            },
            mod13_vhfc_keydn: {
                required: true,
                range: [document.getElementById('mod13_vhfc_keydn_min_len').value, document.getElementById('mod13_vhfc_keydn_max_len').value]
            },
            mod13_switch_offset: {
                required: true,
                range: [document.getElementById('mod13_ulcp_swt_min_len').value, document.getElementById('mod13_ulcp_swt_max_len').value]
            },
            mod13_led_offset: {
                required: true,
                range: [document.getElementById('mod13_ulcp_led_min_len').value, document.getElementById('mod13_ulcp_led_max_len').value]
            },
            mod13_io_size: {
                required: true,
                range: [document.getElementById('mod13_io_size_min_len').value, document.getElementById('mod13_io_size_max_len').value]
            },
            mod13_io_offset: {
                required: true,
                range: [document.getElementById('mod13_io_offset_min_len').value, document.getElementById('mod13_io_offset_max_len').value]
            },
            mod13_io_outputoffset: {
                required: true,
                range: [document.getElementById('mod13_io_otoffset_min_len').value, document.getElementById('mod13_io_otoffset_max_len').value]
            },
            module13atcsaddress: {
                required: true
            },
            module14name: {
                required: true,
                rangelength: [document.getElementById('mod14name_min_len').value, document.getElementById('mod14name_max_len').value]
            
            },
            mod14_vhfc_stx: {
                required: true
            },
            mod14_vhfc_etx: {
                required: true
            },
            mod14_vhfc_chl: {
                required: true,
                range: [document.getElementById('mod14_vhfc_data_min_len').value, document.getElementById('mod14_vhfc_data_max_len').value]
            },
            mod14_vhfc_voice: {
                required: true,
                range: [document.getElementById('mod14_vhfc_voice_min_len').value, document.getElementById('mod14_vhfc_voice_max_len').value]
            },
            mod14_vhfc_tonelg: {
                required: true,
                range: [document.getElementById('mod14_vhfc_tonelg_min_len').value, document.getElementById('mod14_vhfc_tonelg_max_len').value]
            },
            mod14_vhfc_tonesp: {
                required: true,
                range: [document.getElementById('mod14_vhfc_tonesp_min_len').value, document.getElementById('mod14_vhfc_tonesp_max_len').value]
            },
            mod14_vhfc_keyup: {
                required: true,
                range: [document.getElementById('mod14_vhfc_keyup_min_len').value, document.getElementById('mod14_vhfc_keyup_max_len').value]
            },
            mod14_vhfc_keydn: {
                required: true,
                range: [document.getElementById('mod14_vhfc_keydn_min_len').value, document.getElementById('mod14_vhfc_keydn_max_len').value]
            },
            mod14_switch_offset: {
                required: true,
                range: [document.getElementById('mod14_ulcp_swt_min_len').value, document.getElementById('mod14_ulcp_swt_max_len').value]
            },
            mod14_led_offset: {
                required: true,
                range: [document.getElementById('mod14_ulcp_led_min_len').value, document.getElementById('mod14_ulcp_led_max_len').value]
            },
            mod14_io_size: {
                required: true,
                range: [document.getElementById('mod14_io_size_min_len').value, document.getElementById('mod14_io_size_max_len').value]
            },
            mod14_io_offset: {
                required: true,
                range: [document.getElementById('mod14_io_offset_min_len').value, document.getElementById('mod14_io_offset_max_len').value]
            },
            mod14_io_outputoffset: {
                required: true,
                range: [document.getElementById('mod14_io_otoffset_min_len').value, document.getElementById('mod14_io_otoffset_max_len').value]
            },
            module14atcsaddress: {
                required: true
            },
            module15name: {
                required: true,
                rangelength: [document.getElementById('mod15name_min_len').value, document.getElementById('mod15name_max_len').value]
            
            },
            mod15_vhfc_stx: {
                required: true
            },
            mod15_vhfc_etx: {
                required: true
            },
            mod15_vhfc_chl: {
                required: true,
                range: [document.getElementById('mod15_vhfc_data_min_len').value, document.getElementById('mod15_vhfc_data_max_len').value]
            },
            mod15_vhfc_voice: {
                required: true,
                range: [document.getElementById('mod15_vhfc_voice_min_len').value, document.getElementById('mod15_vhfc_voice_max_len').value]
            },
            mod15_vhfc_tonelg: {
                required: true,
                range: [document.getElementById('mod15_vhfc_tonelg_min_len').value, document.getElementById('mod15_vhfc_tonelg_max_len').value]
            },
            mod15_vhfc_tonesp: {
                required: true,
                range: [document.getElementById('mod15_vhfc_tonesp_min_len').value, document.getElementById('mod15_vhfc_tonesp_max_len').value]
            },
            mod15_vhfc_keyup: {
                required: true,
                range: [document.getElementById('mod15_vhfc_keyup_min_len').value, document.getElementById('mod15_vhfc_keyup_max_len').value]
            },
            mod15_vhfc_keydn: {
                required: true,
                range: [document.getElementById('mod15_vhfc_keydn_min_len').value, document.getElementById('mod15_vhfc_keydn_max_len').value]
            },
            mod15_switch_offset: {
                required: true,
                range: [document.getElementById('mod15_ulcp_swt_min_len').value, document.getElementById('mod15_ulcp_swt_max_len').value]
            },
            mod15_led_offset: {
                required: true,
                range: [document.getElementById('mod15_ulcp_led_min_len').value, document.getElementById('mod15_ulcp_led_max_len').value]
            },
            mod15_io_size: {
                required: true,
                range: [document.getElementById('mod15_io_size_min_len').value, document.getElementById('mod15_io_size_max_len').value]
            },
            mod15_io_offset: {
                required: true,
                range: [document.getElementById('mod15_io_offset_min_len').value, document.getElementById('mod15_io_offset_max_len').value]
            },
            mod15_io_outputoffset: {
                required: true,
                range: [document.getElementById('mod15_io_otoffset_min_len').value, document.getElementById('mod15_io_otoffset_max_len').value]
            },
            module15atcsaddress: {
                required: true
            },
            module16name: {
                required: true,
                rangelength: [document.getElementById('mod16name_min_len').value, document.getElementById('mod16name_max_len').value]
            
            },
            mod16_vhfc_stx: {
                required: true
            },
            mod16_vhfc_etx: {
                required: true
            },
            mod16_vhfc_chl: {
                required: true,
                range: [document.getElementById('mod16_vhfc_data_min_len').value, document.getElementById('mod16_vhfc_data_max_len').value]
            },
            mod16_vhfc_voice: {
                required: true,
                range: [document.getElementById('mod16_vhfc_voice_min_len').value, document.getElementById('mod16_vhfc_voice_max_len').value]
            },
            mod16_vhfc_tonelg: {
                required: true,
                range: [document.getElementById('mod16_vhfc_tonelg_min_len').value, document.getElementById('mod16_vhfc_tonelg_max_len').value]
            },
            mod16_vhfc_tonesp: {
                required: true,
                range: [document.getElementById('mod16_vhfc_tonesp_min_len').value, document.getElementById('mod16_vhfc_tonesp_max_len').value]
            },
            mod16_vhfc_keyup: {
                required: true,
                range: [document.getElementById('mod16_vhfc_keyup_min_len').value, document.getElementById('mod16_vhfc_keyup_max_len').value]
            },
            mod16_vhfc_keydn: {
                required: true,
                range: [document.getElementById('mod16_vhfc_keydn_min_len').value, document.getElementById('mod16_vhfc_keydn_max_len').value]
            },
            mod16_switch_offset: {
                required: true,
                range: [document.getElementById('mod16_ulcp_swt_min_len').value, document.getElementById('mod16_ulcp_swt_max_len').value]
            },
            mod16_led_offset: {
                required: true,
                range: [document.getElementById('mod16_ulcp_led_min_len').value, document.getElementById('mod16_ulcp_led_max_len').value]
            },
            mod16_io_size: {
                required: true,
                range: [document.getElementById('mod16_io_size_min_len').value, document.getElementById('mod16_io_size_max_len').value]
            },
            mod16_io_offset: {
                required: true,
                range: [document.getElementById('mod16_io_offset_min_len').value, document.getElementById('mod16_io_offset_max_len').value]
            },
            mod16_io_outputoffset: {
                required: true,
                range: [document.getElementById('mod16_io_otoffset_min_len').value, document.getElementById('mod16_io_otoffset_max_len').value]
            },
            module16atcsaddress: {
                required: true
            }
        
        
        },
        "onfocusout": function(e){
            $(e).valid();
        },
        "onkeyup": function(e){
            $(e).valid();
        },
        showErrors: function(errorMap, errorList){
            var formSelector = '#' + this.currentForm.id;
            var formObject = $(formSelector);
            var validateObject = formObject.validate();
            var numberOfInvalids = validateObject.numberOfInvalids();
            document.getElementById('savedcontent').value = numberOfInvalids;
            //document.getElementById('savedcontent').style.display = 'none';
            this.defaultShowErrors();
        }
    });
    
    $(function(){
        $.validator.addMethod("module1name", function(value, element){
            return this.optional(element) || /^[a-z0-9\_]+$/i.test(value);
        }, "Module Name must contain only letters, numbers");
    });
    $(function(){
        $.validator.addMethod("module2name", function(value, element){
            return this.optional(element) || /^[a-z0-9\_]+$/i.test(value);
        }, "Module Name must contain only letters, numbers");
    });
    $(function(){
        $.validator.addMethod("module3name", function(value, element){
            return this.optional(element) || /^[a-z0-9\_]+$/i.test(value);
        }, "Module Name must contain only letters, numbers");
    });
    $(function(){
        $.validator.addMethod("module4name", function(value, element){
            return this.optional(element) || /^[a-z0-9\_]+$/i.test(value);
        }, "Module Name must contain only letters, numbers");
    });
    $(function(){
        $.validator.addMethod("module5name", function(value, element){
            return this.optional(element) || /^[a-z0-9\_]+$/i.test(value);
        }, "Module Name must contain only letters, numbers");
    });
    $(function(){
        $.validator.addMethod("module6name", function(value, element){
            return this.optional(element) || /^[a-z0-9\_]+$/i.test(value);
        }, "Module Name must contain only letters, numbers");
    });
    $(function(){
        $.validator.addMethod("module7name", function(value, element){
            return this.optional(element) || /^[a-z0-9\_]+$/i.test(value);
        }, "Module Name must contain only letters, numbers");
    });
    $(function(){
        $.validator.addMethod("module8name", function(value, element){
            return this.optional(element) || /^[a-z0-9\_]+$/i.test(value);
        }, "Module Name must contain only letters, numbers");
    });
    $(function(){
        $.validator.addMethod("module9name", function(value, element){
            return this.optional(element) || /^[a-z0-9\_]+$/i.test(value);
        }, "Module Name must contain only letters, numbers");
    });
    $(function(){
        $.validator.addMethod("module10name", function(value, element){
            return this.optional(element) || /^[a-z0-9\_]+$/i.test(value);
        }, "Module Name must contain only letters, numbers");
    });
    $(function(){
        $.validator.addMethod("module11name", function(value, element){
            return this.optional(element) || /^[a-z0-9\_]+$/i.test(value);
        }, "Module Name must contain only letters, numbers");
    });
    $(function(){
        $.validator.addMethod("module12name", function(value, element){
            return this.optional(element) || /^[a-z0-9\_]+$/i.test(value);
        }, "Module Name must contain only letters, numbers");
    });
    $(function(){
        $.validator.addMethod("module13name", function(value, element){
            return this.optional(element) || /^[a-z0-9\_]+$/i.test(value);
        }, "Module Name must contain only letters, numbers");
    });
    $(function(){
        $.validator.addMethod("module14name", function(value, element){
            return this.optional(element) || /^[a-z0-9\_]+$/i.test(value);
        }, "Module Name must contain only letters, numbers");
    });
    $(function(){
        $.validator.addMethod("module15name", function(value, element){
            return this.optional(element) || /^[a-z0-9\_]+$/i.test(value);
        }, "Module Name must contain only letters, numbers");
    });
    $(function(){
        $.validator.addMethod("module16name", function(value, element){
            return this.optional(element) || /^[a-z0-9\_]+$/i.test(value);
        }, "Module Name must contain only letters, numbers");
    });
    
}

function enablefield(){

    document.getElementById('webui_cnf_pwd').disabled = false;
}

function enablefield_local(){

    document.getElementById('localui_cnf_pwd').disabled = false;
}

function setConfirmUnload(on){
    // alert(on);
    //window.onbeforeunload = (on) ? unloadMessage : null;
}

function matchpwd(){
    $('#myformsc').validate({
        rules: {
            webui_pwd: {
                required: true,
                rangelength: [document.getElementById('webuipwd_minval').value, document.getElementById('webuipwd_maxval').value]
            
            },
            webui_cnf_pwd: {
                required: true,
                equalTo: "#webui_pwd"
            },
            localui_pwd: {
                required: true,
                rangelength: [document.getElementById('localuipwd_minval').value, document.getElementById('localuipwd_maxval').value]
            },
            localui_cnf_pwd: {
                required: true,
                equalTo: "#localui_pwd"
            },
            session_time: {
                required: true,
                range: [document.getElementById('sessiontmout_minval').value, document.getElementById('sessiontmout_maxval').value]
            }
        },
        messages: {
            webui_cnf_pwd: {
                equalTo: "Please enter the same password as above"
            },
            localui_cnf_pwd: {
                equalTo: "Please enter the same password as above"
            }
        }
    });
    setConfirmUnload(false);
}

function gtwy_validation(){

    $('#myformech').validate({
        debug: true,
        rules: {
            string_parameters: {
                required: true,
                range: [document.getElementById('gateway_minval').value, document.getElementById('gateway_maxval').value]
            }
        },
        "onfocusout": function(e){
            $(e).valid();
        },
        "onkeyup": function(e){
            $(e).valid();
        },
        showErrors: function(errorMap, errorList){
            var formSelector = '#' + this.currentForm.id;
            var formObject = $(formSelector);
            var validateObject = formObject.validate();
            var numberOfInvalids = validateObject.numberOfInvalids();
            document.getElementById('savedcontent4').value = numberOfInvalids;
            // document.getElementById('savedcontent1').style.display = 'block';
            this.defaultShowErrors();
        }
    });
}

$(function(){
	$("#datepicker").datepicker({
    	showOn: 'button',
    	buttonImage: 'images/calendar.gif',
    	buttonImageOnly: true,
        changeYear:true
    }).attr('readonly', true);
});

$(function(){
    $("#datepicker2").datepicker({
        showOn: 'button',
        buttonImage: '../images/calendar.gif',
        buttonImageOnly: true,
        changeYear:true
    }).attr('readonly', true);
});


function unloadMessage(){

    return 'Changes are not saved. Are you sure you want to navigate away?';
    
}

$(function(){
    // a workaround for a flaw in the demo system (http://dev.jqueryui.com/ticket/4375), ignore!
    //select all the a tag with name equal to modal
    
    //$j("#formID").FormNavigate("Leaving the page will lost in unsaved data!");
    
    $(':input', document.formID).bind("change", function(){
        if(ptc_page == undefined || ptc_page == null)
		setConfirmUnload(true);
	});
});
//var $j = jQuery.noConflict();
        $(function(){
 //alert('hi');
 $("#slider-vertical").slider({
 orientation: "vertical",
 range: "min",
 min: 0,
 max: 255,
 value: 30,
 slide: function(event, ui){
 $("#amount").val(ui.value);
 }
 });
 $("#amount").val($("#slider-vertical").slider("value"));
 
 });
 function newfunctions()
 {
 
 var values = document.getElementById('amount').value;
 //alert(values);
 showPopWin2('../process?id='+document.getElementById('amount').value+'&atcs_addr='+document.getElementById('atcs_addr').value);
 }
//showPopWin2('../process?id="+document.getElementById('amount').value+"')				

function validate_hex(val)
{
 	var vals = "#"+val;
  	$(vals).keyfilter(/[0-9a-f]/i)
}
function check_condition(){
    var c = document.getElementById("check").innerHTML;
    if (c != "") {
        if (c == 0 || c == 1) {
            document.getElementById('show_status').style.display = "block";
            return true;
        }
    }
    document.getElementById('show_status').style.display = "none";
    return false;
}

function start_request(s){
    document.getElementById("check").innerHTML = "0";
}

/*Validations for UCN*/

function ucn_validation(){
    $('#ucn').validate({
        debug: true,
        rules: {
            ucn: {
                required: true,
                rangelength: [8, 8]
            },
        },
        "onfocusout": function(e){
            $(e).valid();
        },
        "onkeyup": function(e){
            $(e).valid();
        },
        showErrors: function(errorMap, errorList){
            var formSelector = '#' + this.currentForm.id;
            var formObject = $(formSelector);
            var validateObject = formObject.validate();
            var numberOfInvalids = validateObject.numberOfInvalids();
            document.getElementById('savedcontent').value = numberOfInvalids;
            this.defaultShowErrors();
        }
    });
}

$(function(){
    $.validator.addMethod("ucn", function(value, element){
        return this.optional(element) || /^[0-9A-Fa-f]+$/i.test(value);
    }, "Enter valid HEX value.");
});
function checkerror(){
    var chkinvalid = $('#ucn').val();
    if (chkinvalid > 0) {
        setConfirmUnload(true);
        return false;
    }
    else 
        return true;
}
/*Validations for Log Verbosity*/
function log_verbo_validation(){
    $('#log_verbo').validate({
        debug: true,
        rules: {
            log_verbo_level: {
                required: true,
                rangelength: [1, 1]
            },
        },
        "onfocusout": function(e){
            $(e).valid();
        },
        "onkeyup": function(e){
            $(e).valid();
        },
        showErrors: function(errorMap, errorList){
            var formSelector = '#' + this.currentForm.id;
            var formObject = $(formSelector);
            var validateObject = formObject.validate();
            var numberOfInvalids = validateObject.numberOfInvalids();
            document.getElementById('savedcontent').value = numberOfInvalids;
            this.defaultShowErrors();
        }
    });
}

$(function(){
    $.validator.addMethod("log_verbo_level", function(value, element){
        return this.optional(element) || /^[1-2]{0,1}$/i.test(value);
    }, "Enter Log Verbosity Level as 1 or 2.");
});
function checkerror(){
    var chkinvalid = $('#log_verbo_level').val();
    if ($.trim(chkinvalid).length > 0) {
        setConfirmUnload(true);
        return true;
    }
    else 
        return false;
}
/*End for Log Verbosity validations*/

/*Validations for Location Settings*/
function siteconfig_validation(){

	$('#loc_id').validate({
	    debug: true,
	    rules: {
	        site_name: {
	            required: false,
	            rangelength: [1, 25]
	        },
	        dot_number1: {
	            required: false,
	            rangelength: [1, 6]
	        },
	        dot_number2: {
	            required: false,
	            rangelength: [1, 1]
	        },
					mile_post:{
						required: false,
            rangelength: [1, 11]
					},					
	    },
		messages: {
			dot_number1: {
				rangelength: $.validator.format("Enter a value in {0} and {1}."),
			},
			dot_number2: {
				rangelength: $.validator.format("Enter a value in {0} and {1}."),
			}
		},
      "onfocusout": function(e){
          $(e).valid();
      },
      "onkeyup": function(e){
          $(e).valid();
      },
      showErrors: function(errorMap, errorList){
          var formSelector = '#' + this.currentForm.id;
          var formObject = $(formSelector);
          var validateObject = formObject.validate();
          var numberOfInvalids = validateObject.numberOfInvalids();
          document.getElementById('savedcontent').value = numberOfInvalids;
          this.defaultShowErrors();
      }
  });
}

$(function(){
    
    $.validator.addMethod("dot_number1", function(value, element){
        return this.optional(element) || /^[0-9]+$/i.test(value);
    }, "Must contain only numbers.");
	$.validator.addMethod("dot_number2", function(value, element){
        return this.optional(element) || /^[0-9A-Za-z]$/i.test(value);
    }, "Must contain only letters, numbers.");		
		$.validator.addMethod("mile_post", function(value, element){
        return this.optional(element) || /^[0-9A-Za-z._@ -]{0,11}$/i.test(value);
    }, "Cannot contain special characters.");
});

function checkerror(){
    var chkinvalid = document.getElementById('savedcontent').value;
    if (chkinvalid > 0) {
        setConfirmUnload(true);
        return false;
    }
    else 
        return true;
}
/*end of location settings validations*/

$(function(){
   /*Validations for SIN*/
	$.fn.sin_validation = function(sin_value) { 
		 if(sin_value.length > 16){
		 	$("#sin_erro_msg").html("SIN should not be morethan 16 characters");
			return false;
		 }
		 if(!(/^7/i.test(sin_value))){
		 	$("#sin_erro_msg").html("SIN should start with 7.");
			return false;
		 }
		 if(!(/^[0-9\ .]{0,16}$/i.test(sin_value))){
		 	$("#sin_erro_msg").html("SIN should contain only numbers and '.'");
			return false;
		 }
		 if(!/^7\.(\d{3})\.(\d{3})\.(\d{3})\.(\d{2})$/i.test(sin_value)){
		 	$("#sin_erro_msg").html("SIN should be in 7.XXX.XXX.XXX.XX format containing only numbers");
			return false;
		 }
		 $("#sin_erro_msg").html("");
		 return true;
	}
	/*End of SIN validations*/
});
function checkerror(){
    var chkinvalid = document.getElementById('savedcontent').value;
    if (chkinvalid > 0) {
        setConfirmUnload(true);
        return false;
    }
    else 
        return true;
}

function check_request_condition(){
    var c = document.getElementById("check").innerHTML;
    if (c != "") {
        if (c == 0 || c == 1) {
            document.getElementById('show_status').style.display = "block";
            return true;
        }
		else{
			document.getElementById('show_status').style.display = "none";
    		return false;
		}
    }    
}


function changewindow()
{
        document.getElementById("parent").style.display="none";
	document.getElementById("showcalc").style.display="block";
}

function previouswindow()
{
        document.getElementById("showcalc").style.display="none";
        document.getElementById("parent").style.display="block";

}

function calcnewvalue(newvalue)
{
        document.getElementById("showcalc").style.display="none";
        document.getElementById("parent").style.display="block";
        document.getElementById("value").innerHTML=newvalue;
}


function gcpservice()
      {

        if(document.f1.GCP.value=="0")
        {
             if(confirm("Are you sure you want to take GCP Out Of Service?"))
             {
                document.f1.gcpout.value="Put GCP Back in Service";
                document.f1.islout.disabled= false;
                document.f1.oostimeout.disabled = false;
                document.f1.oostimeouthrs.disabled = false;
                document.f1.GCP.value =1;
                window.location = "../get_tracks_info/1?cur_val=1";
             }
             check_btn_status();
        }

        else
        {
             if(confirm("Are you sure you want to put GCP Back in Service?"))
             {
                document.f1.gcpout.value="Take GCP Out Of Service";
                document.f1.islout.value="Take ISL Back in Service";
                document.f1.islout.disabled= true;
                document.f1.oostimeout.disabled = false;
                document.f1.oostimeouthrs.disabled = false;
                document.f1.GCP.value =0;
                window.location = "../get_tracks_info/1?cur_val=0";
             }
             check_btn_status();
        }
        document.f1.GCPClick.value="Yes";

        

        return true;
      }
function check_btn_status()
{
   // alert(document.f1.timeout_yesno.value);
    if (document.f1.timeout_yesno.value==0)
        {
            document.f1.timeout_value.disabled = true;
            document.f1.oostimeouthrs.disabled = true;
        }else
            {
                document.f1.timeout_value.disabled = false;
                document.f1.oostimeouthrs.disabled = false;
            }
}

function islservice()
      {
       if(document.f1.ISL.value=="0")
        {
             if(confirm("Are you sure you want to take ISL Out Of Service?"))
             {
                document.f1.islout.value="Put ISL Back in Service";
                document.f1.gcpout.disabled= true;
                document.f1.oostimeout.disabled = false;
                document.f1.oostimeouthrs.disabled = false;
                document.f1.ISL.value=1;
             }
             check_btn_status();
        }

        else
        {
             if(confirm("Are you sure you want to put ISL Back in Service?"))
             {
                document.f1.islout.value="Take ISL Out Of Service";
                document.f1.gcpout.disabled= true;
                document.f1.oostimeout.disabled = false;
                document.f1.oostimeouthrs.disabled = false;
                document.f1.ISL.value=0;
             }
             check_btn_status();
        }
        document.f1.GCPClick.value="No";
        return true;
     }

function enable_yesno()
{
    document.f1.timeout_yesno.disabled = false;
    document.f1.submit.disabled = false;
    check_btn_status();
}
function enable_value()
{
    document.f1.timeout_value.disabled = false;
    document.f1.submit.disabled = false;
}