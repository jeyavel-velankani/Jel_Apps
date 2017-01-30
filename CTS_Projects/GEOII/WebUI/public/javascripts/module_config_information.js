/**
 * @author Kalyan
 */
function module_information_links(mcf_type){
    var card_index = $('#card_index').val();
    var atcs_addr = $('#atcs_address').val();
    var card_type = $('.slot_header').attr('title');
	if(mcf_type == 1){
		card_type = 10
	}
	var card_name = $("#slot_"+card_type).text();
	
    var slot_url = "/diagnostic_terminal/fetch_module_information";
    $('#io_spinner').show();
    
    $.post("/diagnostic_terminal/get_online", {
        atcs_addr: atcs_addr,
        type: card_index,
        information_type: 10,
        mcf_type: mcf_type
    }, function(response_data){
        var periodic_update = setInterval(function(){
            $.post(slot_url, {
                id: response_data,
                card_type: card_name
            }, function(data){
                if (data != "0" && data != "1") {
                    clearInterval(periodic_update);
                    $('#io_spinner').hide();
                    $('#callback_content').html(data).show();
                }
            });
        }, 3000);
    });
}

function configuration_parameters(){
    var url = "/diagnostic_terminal/configuration_parameters";
    $.post(url, {}, function(data){
        $('#callback_content').html(data).show();
		$('#callback_content').fadeOut(3000);
    });
}

function module_reset(){
    $('#io_spinner').show();
    var atcs_addr = $('#atcs_address').val();
    var slot_atcs_devnumber = $("#slot_atcs_devnumber").val();
    
    $.post("/diagnostic_terminal/module_reset", {
        slot_number: slot_atcs_devnumber,
        atcs_addr: atcs_addr
    }, function(data){
		$('#callback_content').html(data).show().fadeOut(3000);
        $('#io_spinner').hide();
    });
}

function operating_parameters(){
    $('#io_spinner').show();
    var card_index = $('#card_index').val();
    var atcs_addr = $('#atcs_address').val();
    var mcfcrc = $('#card_mcfcrc').val();
    var card_type = $('#card_type').val();
    
    $.post("/diagnostic_terminal/get_online", {
        type: card_index,
        atcs_addr: atcs_addr,
        information_type: 2
    }, function(request_id){
        var periodic_information = setInterval(function(){
            $.post("/diagnostic_terminal/get_operating_parameters", {
                id: request_id,
                card_type: card_type,
                card_index: card_index,
                mcfcrc: mcfcrc
            }, function(data){
                if (data != "0" && data != "1") {
                    clearInterval(periodic_information);
                    $('#io_spinner').hide();
                    $('#callback_content').html(data).show();
                }
            });
        }, 2000);
    });
}


$(document).ready(function(){

    
    //$("#slot_content").contextMenu({menu: 'myMenu'}, {});
    $(".content_close").w_click(function(){
		$("#callback_content").fadeOut('slow');	
	});
	
    $('#card_data').contextMenu('context-menu-1', {
        'Module Information': {
            click: function(element){ // element is the jquery obj clicked on when context menu launched
                module_information_links(0);
            },
            klass: "menu-item-1" // a custom css class for this menu item (usable for styling)
        },
        'Module Reset': {
            click: function(element){
                module_reset();
            },
            klass: "second-menu-item"
        },
        'Configuration Parameters': {
            click: function(element){
                configuration_parameters();
            },
            klass: "third-menu-item"
        },
        'Operating Parameters': {
            click: function(element){
                operating_parameters();
            },
            klass: "fourth-menu-item"
        }
    });
    
    $('#inactive_card_data').contextMenu('context-menu-1', {
        'Module Information': {
            click: function(element){
                return false;
            },
            klass: "inactive_card" // a custom css class for this menu item (usable for styling)
        },
        'Module Reset': {
            click: function(element){
                return false;
            },
            klass: "inactive_card"
        },
        'Configuration Parameters': {
            click: function(element){
                return false;
            },
            klass: "inactive_card"
        },
        'Operating Parameters': {
            click: function(element){
                return false;
            },
            klass: "inactive_card"
        }
    });
    
    
    $('#cp_slot_inactive').contextMenu('context-menu-1', {
        'Module Information': {
            click: function(element){
                return false;
            },
            klass: "inactive_card"
        },
        'Module Reset': {
            click: function(element){
                return false;
            },
            klass: "inactive_card"
        },
        'Configuration Parameters': {
            click: function(element){
                return false;
            },
            klass: "inactive_card"
        },
        'Operating Parameters': {
            click: function(element){
                return false;
            },
            klass: "inactive_card"
        }
    });
    
    
    $('#cp_slot_active').contextMenu('context-menu-1', {
        'Module Information': {
            click: function(element){
                module_information_links(1);
            },
            klass: "first-menu-item"
        },
        'Module Reset': {
            click: function(element){
                module_reset();
            },
            klass: "second-menu-item"
        },
        'Configuration Parameters': {
            click: function(element){
                configuration_parameters();
            },
            klass: "third-menu-item"
        },
        'Operating Parameters': {
            click: function(element){
                operating_parameters();
            },
            klass: "fourth-menu-item"
        }
    });
    
});
