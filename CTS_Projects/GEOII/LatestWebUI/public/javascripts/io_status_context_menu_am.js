var moduleWindow;
var moduleInfoNonAm;
var moduleResetWindow;

var active_slots = $(".active");
var inactive_slots = $(".inactive");
var cp_slot = $(".cp_slot");

jQuery.each($('.card_layout'), function(){
	$('#context-menu-1').remove();
});

jQuery.each(inactive_slots, function(i, val){
	var card_type = $(this).attr('card_type');
	var card_name = $("#slot_" + card_type).text();
	var actual_card_name = $.trim(card_name);
	if (actual_card_name != '< Empty >') {
		$(this).contextMenu('context-menu-1', get_inactive_options(this));
	}
});

function get_inactive_options(dom_obj){
    var atcs_addr = $(dom_obj).attr('atcs_addr');
    var mcfcrc = $(dom_obj).attr('mcfcrc');
    var card_index = $(dom_obj).attr('name');
    var cp_card_index = $(".cp_slot").attr("id")
    var card_type = $(dom_obj).attr('card_type');
    var slot_number = $(dom_obj).attr('slot_number');
    var card_name = $(dom_obj).attr('card_caption');

    if (slot_number == 1) {
        return {            
            'Module Reset - VLP': {
                click: function(element){                    
                    if (confirm("Are you sure, you want to reset the VLP Module?")) {
                        post_module_reset(atcs_addr, slot_number);
                    }                    
                },
                klass: "second-menu-item"
            },
            // 'Module Information - CP': {
                // click: function(element){ // element is the jquery obj clicked on when context menu launched
                    // module_information_links(slot_number, atcs_addr, cp_card_index, card_type, "CP");
                // },
                // klass: "menu-item-1" // a custom css class for this menu item (usable for styling)
            // },
            'Module Reset - CP': {
                click: function(element){
                    if (confirm("Are you sure, you want to reset the CP Module?")) {
                        post_module_reset(atcs_addr, -1);
                    }
                },
                klass: "second-menu-item"
            }
        }
    }
    else {
        return {            
            'Module Reset': {
                click: function(element){
                    if (confirm("Are you sure, you want to reset the Module?")) {
                        post_module_reset(atcs_addr, slot_number);
                    }
                },
                klass: "second-menu-item"
            },
        }
    }
}

jQuery.each(active_slots, function(i, val){
    $(this).contextMenu('context-menu-1', get_options(this));
});

function get_options(dom_obj){
    var atcs_addr = $(dom_obj).attr('atcs_addr');
    var mcfcrc = $(dom_obj).attr('mcfcrc');
    var card_index = $(dom_obj).attr('name');
    var cp_card_index = $(".cp_slot").attr("id")
    var card_type = $(dom_obj).attr('card_type');
    var slot_number = $(dom_obj).attr('slot_number');
    var card_name = $(dom_obj).attr('card_caption');

    if (slot_number == 1) {
        return {
            'Module Information - VLP': {
                click: function(element){ // element is the jquery obj clicked on when context menu launched
                    module_information_links(slot_number, atcs_addr, card_index, card_type, "VLP");
                },
                klass: "menu-item-1" // a custom css class for this menu item (usable for styling)
            },
            'Module Reset - VLP': {
                click: function(element){
                    if (confirm("Are you sure, you want to reset the VLP Module?")) {
                        post_module_reset(atcs_addr, slot_number);
                    }
                },
                klass: "second-menu-item"
            },
            'Module Information - CP': {
                click: function(element){ // element is the jquery obj clicked on when context menu launched
                    module_information_links(slot_number, atcs_addr, cp_card_index, card_type, "CP");
                },
                klass: "menu-item-1" // a custom css class for this menu item (usable for styling)
            },
            'Module Reset - CP': {
                click: function(element){
                    if (confirm("Are you sure, you want to reset the CP Module?")) {
                        post_module_reset(atcs_addr, -1);
                    }
                },
                klass: "second-menu-item"
            }
        }
    }
    else {
        return {
            'Module Information': {
                click: function(element){ // element is the jquery obj clicked on when context menu launched
                    module_information_links(slot_number, atcs_addr, card_index, card_type, card_name);
                },
                klass: "menu-item-1" // a custom css class for this menu item (usable for styling)
            },
            'Module Reset': {
                click: function(element){
                    if (confirm("Are you sure, you want to reset the Module?")) {
                        post_module_reset(atcs_addr, slot_number);
                    }
                },
                klass: "second-menu-item"
            },
        }
    }
}

function post_module_reset(atcs_address, slot_number){
    $('.io_spinner').show();
    $("#contentcontents").mask("Module is resetting, please wait...");
    $.post("/io_status_view/module_reset", {
        slot_number: slot_number,
        atcs_addr: atcs_address
    }, function(data){
        $('.io_spinner').hide();
        $("#contentcontents").unmask("Module is resetting, please wait...");
    });
}

function cp_module_reset(slot_atcs_devnumber){
    $('#io_spinner').show();
    var atcs_addr = $('#atcs_address').val();
    post_module_reset(atcs_addr, slot_atcs_devnumber);
}


