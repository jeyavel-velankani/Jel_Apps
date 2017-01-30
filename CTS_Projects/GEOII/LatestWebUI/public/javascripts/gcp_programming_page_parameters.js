/**
 * @author 305777
 */

$(document).ready(function(){
	add_to_destroy(function(){
         $(document).bind("ready", function(){
         });
         
         //kills all wrapper events
         $('.parameters_form').w_die('change');
		  $("input select").w_die('change');      
     });

    var ui_state = $('#ui_state').val();
    if (ui_state != '') {
        $("#template_set_to_defaults").addClass("disable");
    }
        
    var gcp_4k = $('#gcp_4k').val();
    var menu_link = $('#menu_link').val();
    if (gcp_4k == true || gcp_4k == 'true' && menu_link && menu_link.match('TEMPLATE:') && menu_link.match('selection')) {
        $("#prev_button").addClass("disable");
    }
    
    
    $("input select").change(function(){
        window.parent.myValue = true;
    });
    
    $(".parameters_form").change(function(){
        window.parent.myValue = true;
    });
    
    if (gcp_4k == true || gcp_4k == 'true') {
        if (menu_link != '') {
            var new_menu_link = $('li[menulink^="<%= params[:menu_link].split(":")[0] %>"]', window.parent.document);
            var existing_menu_link = $('li.leftnavtext_D', window.parent.document);
            if (new_menu_link.length > 0 && new_menu_link.attr("menulink") != existing_menu_link.attr("menulink")) {
                existing_menu_link.removeClass("leftnavtext_D");
                new_menu_link.addClass("leftnavtext_D");
                var new_pagename = new_menu_link.attr("pagename").replace(/\d/g, "");
                $("#contentareahdr", window.parent.document).html(new_pagename);
            }
        }
    }
    var next_link_disable = $('#next_link_disable').val();
    if (next_link_disable != '') {
        $("#next_button").addClass('disable');
    }
    var track_setup = $('#track_setup').val();
    var parameters = $('#parameters').val();
    // if (track_setup == '' && parameters == true || parameters == 'true') {
        // request_screen_verification();
    // }
});
