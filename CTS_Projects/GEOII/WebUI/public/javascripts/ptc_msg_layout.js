$(document).ready(function(){
	$('.ptc_wiu_msg_content').custom_scroll(430);
		   	if($("#ptcdevicecount").val() == 'false'){
		$('.save_message_layout').addClass('disable');
		$('.ptc_wiu_refresh').addClass('disable');
	}
	add_to_destroy(function(){
		$(document).unbind("ready");

		//kills all wrapper events
		$('.ptc_wiu_refresh').w_die('click');
		$('#element_arrow').w_die('click');
		$('.element_ptc').w_die('click');
		$('.ptc_wiu').w_die('click');
		$("#arrow").w_die('click');
		$('.save_message_layout').w_die('click');
		$('.msg_layout_form').w_die('submit');
	});
	
	$(".save_message_layout").w_click(function(){
		if (!$(this).hasClass('disable')) {
			$(".msg_layout_form").trigger("submit");
		}
	});
		
	$(".msg_layout_form").submit(function(){
		$(".errormesg").html("");
		$("#contentcontents").mask("Processing request, please wait...");
		var device_order = new Array();			
		$(".ptc_wiu").each(function(i, element){			
			device_order.push($.trim($(element).children().attr('id')));
		});
		installation_name = $("#installation_name").val();
		var page_url = $(this).attr('action');
		$.post(page_url, {
			devices: device_order,
			installation_name: installation_name
		 }, function(response){
		 	$(".errormesg").html(response.message);
			$("#contentcontents").unmask("Processing request, please wait...");
		});	
        remove_preload_page();	
        return false;
    });
	
	$(".ptc_wiu_refresh").w_click(function(){
		if (!$(this).hasClass('disable')) {
			$("#contentcontents").mask("Loading contents, please wait...");
			$.post("/ptc/message_layout", {}, function(response){
				$("#contentcontents").html(response);
				$("#contentcontents").unmask("Loading contents, please wait...");
			});
		}
    });
	
	//Re-Order elements
	$("#reordernow").w_click(function(){
		$(".errormesg").html("");
		$("#contentcontents").mask("Re-Ordering elements position, please wait...");
		var installation_name = $("#installation_name").attr('value');
		$.post("/ptc/reorder_elements",{
			installation_name: installation_name,
			pagename: 'messagelayout'
		},function(response){
			$("#contentcontents").html(response);
			$("#contentcontents").unmask("Re-Ordering elements position, please wait...");
	   });
	});
	
	
	// Element's row click
	$('.element_ptc').w_click(function(){
        var next_element = prev_element = current_element = null;
        $('.element_ptc').removeClass('selected_element_ptc_element');
        $(this).addClass('selected_element_ptc_element');
        next_element = $(this).next().attr('id');
        prev_element = $(this).prev().attr('id');
        current_element = $(this).attr('id');
		
			
        $('.uparroworder').css({
            "opacity": "1",
			"filter": "alpha(opacity=100)",
            "cursor": "pointer"
        });
        $('.downarroworder').css({
            "opacity": "1",
			"filter": "alpha(opacity=100)",
            "cursor": "pointer"
        });

        $('.element_ptc').children().css({
            "background-color": "#949494",
            "color": "#000"
        });
        
        $(this).children().first().css({
            "background-color": "#CFD638",
            "color": "#000"
        });
        format_ptc_element_style(prev_element, next_element);
    });	
	
	// Device name row click	
	$('.ptc_wiu').w_click(function(){
        var next_element = prev_element = current_element = null;
        $('.ptc_wiu').removeClass('selected_ptc_element');
        $(this).addClass('selected_ptc_element');
        next_element = $(this).next().attr('id');
        prev_element = $(this).prev().attr('id');
        current_element = $(this).attr('id');
        
        $(this).children().last()
        $('.uparrow').css({
            "opacity": "1",
            "filter": "alpha(opacity=100)",
            "cursor": "pointer"
        });
        $('.downarrow').css({
            "opacity": "1",
            "filter": "alpha(opacity=100)",
            "cursor": "pointer"
        });
        
        $('.ptc_wiu td').css({
            "background-color": "#949494",
            "color": "#000"
        });
        
        $(this).children().css({
            "background-color": "#CFD638",
            "color": "#000"
        });
        
        format_ptc_data_style(prev_element, next_element)
    });
    
	// Device name order change with in the element type
    $("#arrow").w_click(function(event){
        event.preventDefault();
        var link_title = $(this).attr('title');
        var alternate_element = alternate_element_id = null;
        var selected_element = $('.selected_ptc_element');
        var next_element = $('.selected_ptc_element').next();
        var prev_element = $('.selected_ptc_element').prev();
        if (link_title == 'next') {
            alternate_element = next_element;
            alternate_element_id = next_element.attr('id');
        }else if (link_title == 'prev') {
            alternate_element = prev_element;
            alternate_element_id = prev_element.attr('id');
        }
        if (selected_element != null && alternate_element_id != null && alternate_element_id != "") {
            var selected_content = selected_element.clone();
            var cloned_content = alternate_element.clone();
            alternate_element.replaceWith(selected_content);
            selected_element.replaceWith(cloned_content);
            						
            selected_element = $('.selected_ptc_element');
            var next_element_id = $('.selected_ptc_element').next().attr('id');
            var prev_element_id = $('.selected_ptc_element').prev().attr('id');
            format_ptc_data_style(prev_element_id, next_element_id);
			window.parent.myValue = true;
            add_nv_preload_page();
        }
    });
});

function format_ptc_data_style(prev_element, next_element){
    if (prev_element == "" || prev_element == undefined || prev_element == null) {
        prev_element = null;
        $('.uparrow').css({
            "opacity": "0.3",
            "filter": "alpha(opacity=30)",
            "cursor": "default"
        });
    }else {
        $('.uparrow').css({
            "opacity": "1",
            "filter": "alpha(opacity=100)",
            "cursor": "pointer"
        });
    }
    if (next_element == "" || next_element == undefined || next_element == null) {
        next_element = null;
        $('.downarrow').css({
            "opacity": "0.3",
            "filter": "alpha(opacity=30)",
            "cursor": "default"
        });
    }else {
        $('.downarrow').css({
            "opacity": "1",
            "filter": "alpha(opacity=100)",
            "cursor": "pointer"
        });
    }
}

function format_ptc_element_style(prev_element, next_element){
    if (prev_element == "" || prev_element == undefined || prev_element == null) {
        prev_element = null;
        $('.uparroworder').css({
            "opacity": "0.3",
			"filter": "alpha(opacity=30)",
            "cursor": "default"
        });
    }else {
        $('.uparroworder').css({
            "opacity": "1",
			"filter": "alpha(opacity=100)",
            "cursor": "pointer"
        });
    }
    if (next_element == "" || next_element == undefined || next_element == null) {
        next_element = null;
        $('.downarroworder').css({
            "opacity": "0.3",
			"filter": "alpha(opacity=30)",
            "cursor": "default"
        });
    }else {
        $('.downarroworder').css({
            "opacity": "1",
			"filter": "alpha(opacity=100)",
            "cursor": "pointer"
        });
    }
}
