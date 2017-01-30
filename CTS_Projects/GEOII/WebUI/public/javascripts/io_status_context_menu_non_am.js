var active_slots = $(".active");
var inactive_slots = $(".inactive");
var cp_slot = $(".cp_slot");

var operatingPrametersWindow;
var configurationPrametersWindow;
 
jQuery.each(inactive_slots, function(i, val){
    $(this).contextMenu('context-menu-1', get_inactive_options(this));
});

jQuery.each(active_slots, function(i, val){
   $(this).contextMenu('context-menu-1', get_options(this));
});

function get_inactive_options(dom_obj){
	var atcs_addr = $(dom_obj).attr('atcs_addr');
    var mcfcrc = $(dom_obj).attr('mcfcrc');	
    var card_index = $(dom_obj).attr('name');
	var cp_card_index = $(".cp_slot").attr("id")
    var card_type = $(dom_obj).attr('card_type');
    var slot_number = $(dom_obj).attr('slot_number');
	var card_name = $("#slot_"+card_type).text();
	
	if(slot_number == 1 && card_type == 9){
		return {
	        'Module Information - VLP': {
	            click: function(element){ // element is the jquery obj clicked on when context menu launched
	                return false;
	            },
	            klass: "inactive_card" // a custom css class for this inactive menu item (usable for styling)
	        },
	        'Module Reset - VLP': {
	            click: function(element){
	                post_module_reset(atcs_addr, slot_number);
	            },
	            klass: "second-menu-item"
	        },
			'Module Information - CP': {
	           click: function(element){ // element is the jquery obj clicked on when context menu launched
	                module_information_links(1, atcs_addr, cp_card_index, card_type, "CP");
	            },
	            klass: "menu-item-1" // a custom css class for this menu item (usable for styling)
	        },
	        'Module Reset - CP': {
	           click: function(element){
	                post_module_reset(atcs_addr, -1);
	            },
	            klass: "second-menu-item"
	        }
	    }
	}else{
		return {
	       'Module Information': {
	            click: function(element){
					return false;
	            },
	            klass: "inactive_card" // a custom css class for this menu item (usable for styling)
	        },
	        'Module Reset': {
	            click: function(element){
	               post_module_reset(atcs_addr, slot_number);
	            },
	            klass: "second-menu-item"
	        }
	    }
	}
}

function get_options(dom_obj){
	var atcs_addr = $(dom_obj).attr('atcs_addr');
    var mcfcrc = $(dom_obj).attr('mcfcrc');	
    var card_index = $(dom_obj).attr('name');
	var cp_card_index = $(".cp_slot").attr("id")
    var card_type = $(dom_obj).attr('card_type');
    var slot_number = $(dom_obj).attr('slot_number');
	var card_name = $("#slot_"+card_type).text();
	
	if(slot_number == 1 && card_type == 9){
		return {
			'Module Information - VLP': {
				click: function(element){ // element is the jquery obj clicked on when context menu launched
				    module_information_links(0, atcs_addr, card_index, card_type, card_name);				
	            },
	            klass: "menu-item-1" // a custom css class for this menu item (usable for styling)
			},
			'Module Information - CP': {
				click: function(element){ // element is the jquery obj clicked on when context menu launched
				    module_information_links(1, atcs_addr, cp_card_index, 10, "CP");				
	            },
	            klass: "menu-item-1" // a custom css class for this menu item (usable for styling)
			},
			'Module Reset - VLP': {
	            click: function(element){
	                post_module_reset(atcs_addr, slot_number);
	            },
	            klass: "second-menu-item"
	        },
			'Module Reset - CP': {
	            click: function(element){
	                post_module_reset(atcs_addr, -1);
	            },
	            klass: "second-menu-item"
	        }
		}
	}else{
		return {
	        'Module Information': {
	            click: function(element){ // element is the jquery obj clicked on when context menu launched
				    module_information_links(0, atcs_addr, card_index, card_type, card_name);				
	            },
	            klass: "menu-item-1" // a custom css class for this menu item (usable for styling)
	        },
	        'Module Reset': {
	            click: function(element){
	                post_module_reset(atcs_addr,slot_number);
	            },
	            klass: "second-menu-item"
	        }
	    }	
	}
}

function post_module_reset(atcs_addr, slot_atcs_devnumber){
    $('.io_spinner').show();	
	$.post("/io_status_view/module_reset", {
        slot_number: slot_atcs_devnumber,
        atcs_addr: atcs_addr
    }, function(data){
		alert(data);
        $('.io_spinner').hide();
    });
}

function module_reset(){
    $('#io_spinner').show();
    var atcs_addr = $(this).attr('atcs_address');
    var slot_atcs_devnumber = $("#slot_atcs_devnumber").val();
    post_module_reset(atcs_addr, slot_atcs_devnumber);
}

function cp_module_reset(slot_atcs_devnumber){
	$('#io_spinner').show();
    var atcs_addr = $(this).attr('atcs_address');
	post_module_reset(atcs_addr, slot_atcs_devnumber);
}
