var check_state_interval;
var check_status_interval;
var fetch_view_interval;
var fetch_module_interval;
var request_progress = false;
var request_in_progress_auto = false;
var color_status = false;
var io_view_xhr = null;
var fetch_view_xhr = null;
var scale_factor_values = null;

$(document).ready(function(){
	add_to_destroy(function(){
		$(document).bind("ready",function(){});
	
		//kills all events
		$('#io_status').w_die('click');
		
		//clear intervals
		clearInterval(check_state_interval);
		clearInterval(check_status_interval);
		clearInterval(fetch_module_interval);
		clearInterval(fetch_view_interval);
		
		if(typeof io_view_xhr !== 'undefined' && io_view_xhr != null){
	        io_view_xhr.abort();  //cancels previous request if it is still going
	    }		
		if(typeof fetch_view_xhr !== 'undefined' && fetch_view_xhr != null){
	        fetch_view_xhr.abort();  //cancels previous request if it is still going
	    }
		
		//clears global variables
		delete window.check_state_interval;
		delete window.check_status_interval;
		delete window.fetch_module_interval;
		delete window.fetch_view_interval;
		delete window.io_view_xhr;
		delete window.fetch_view_xhr;
	});

	var selected_atcs_address = $('#atcs_address').val();
	if(selected_atcs_address != "" && selected_atcs_address != null && selected_atcs_address != undefined){
		//update_timestamp(selected_atcs_address);
		$("#card_content").html("");
		var io_request_progress = false;	
		var view_type = $("#view_type").text();
		var card_index = "";
		render_io_view(selected_atcs_address, false, view_type, true);	
	}else{
		$("#card_content").html("<p style'color:#FFF'>Display is not in session!!</p>");
		$(".ajax-loader").hide();
	}
	
	$(".slot_header").w_click(function (event) {
		var card_ind = $(this).attr('card_index');
		var selected_atcs_address = $(this).parent().attr('atcs_addr');
		var view_type = $("#view_type").text();
		if ($(this).attr('card_status') == 'active'){
			initiate_io_card_req(selected_atcs_address, view_type, card_ind);
		}
	});	
});

$("#io_status").change(function(event){
	clearTimeout(fetch_view_interval);	
			
	var selected_atcs_address = $(this).val();
	if(selected_atcs_address != ""){
		$("#card_content").html("");
		var io_request_progress = false;	
		var view_type = $("#view_type").text();
		var card_index = "";
		render_io_view(selected_atcs_address, false, view_type, true);	
	}else{
		clearTimeout(fetch_view_interval);
		$("#card_content").html("");
		$(".ajax-loader").hide();
	}
});

function check_status(request_id, atcs_address, view_type, render_io){
	check_state_interval = setTimeout(function(){
		$.post("/io_status_view/check_state", {id: request_id}, function(request_state){
			if (request_state == 2 || request_state == -1){
				clearInterval(check_state_interval);
				if (render_io){
					render_io_view(atcs_address, false, view_type, true);
				}
				else{					
					$(".ajax-loader").hide();
					$("#contentcontents").unmask("Module refreshing, please wait...");
					if ($("#current_pagename").text() == "module"){
						render_io_view(atcs_address, false, view_type, true);
					}					
				}
			}else {
				check_status(request_id, atcs_address, view_type, render_io);
			}
		});
	}, 3000);
}

function check_view_status(atcs_address, view_type, mcfcrc){
	$(".ajax-loader").show();
	$("#io_status").attr("disabled", "disabled");
	$.post("/io_status_view/check_view_status", {atcs_address: atcs_address, mcfcrc: mcfcrc, view_type: view_type}, function(response){
		if(response == "1" || response == "-1"){
			clearTimeout(check_status_interval);
			render_io_view(atcs_address, false, view_type, true);
		}else{
			check_status_interval = setTimeout(function(){
				check_view_status(atcs_address, view_type, mcfcrc);
			}, 3000);
		}
	});
}

function module_view_auto_refresh(selected_atcs_address, mcfcrc, request_progress, view_type, first_request){
	if (!request_progress) {
		request_progress = true;
		request_in_progress_auto = true;
		$(".ajax-loader").show();		
		$("#io_status").attr("disabled", "disabled");
		var cards_counter = {};
		$(".atcs_card_table").each(function(index, ele){	
			cards_counter[$(ele).attr('counter_id')] = $(ele).attr('counter');
		});	
		//var cards_counter = { card_10_4: 0, card_7_4: 6, card_7_3: 2, card_8_3: 0}
		$(".atcs_button").addClass('disable');	
		fetch_view_xhr = $.post("/io_status_view/fetch_view", {view_type: view_type, atcs_address: selected_atcs_address, get_scale_value: false, scale_factor_values: scale_factor_values, cards_counter: cards_counter}, function(response){
			if (response.vlp_unconfigured != undefined) {
				if (response.request_id) {
					clearInterval(fetch_view_interval);
					check_status(response.request_id,selected_atcs_address, view_type, true);
				}
				else {
					if (response.view == "") {
						$(".ajax-loader").hide();
						$("#io_status").removeAttr("disabled");
						set_width_content(view_type);
					}
					else {
						if (!response.geo_exists && response.view != "") {
							$("#io_status").empty().append('<option value="">Select</option>');
							jQuery("#card_content").html(response.view);
							$(".ajax-loader").hide();
							$("#io_status").removeAttr("disabled");
							set_width_content(view_type);
						}
						else {
							$(".ajax-loader").hide();
							$("#io_status").removeAttr("disabled");
							// Iterating over the JSON response
							$.each(response.view, function(index, data){
								$.each(data, function(map_index, value){
									$(".io_card_" + map_index).html(value);
								});
							});
							
							if (view_type == "io") {
								var active_slots = $(".active");
								var inactive_slots = $(".inactive");
								
								jQuery.each(inactive_slots, function(i, val){
									$(this).contextMenu('context-menu-1', get_inactive_options(this));
								});
								
								jQuery.each(active_slots, function(i, val){
									$(this).contextMenu('context-menu-1', get_options(this));
								});
							}
							set_width_content(view_type);
						}
					}
				}
			}
			else {
				$("#card_content").html("<span id='progress_message'>" + response + "</span>");
				$(".ajax-loader").hide();
				$("#io_status").removeAttr("disabled");
			}
			request_in_progress_auto = false;
		});
	}
}

function set_width_content(view_type){
var cur_width = 0;
	if((view_type == "io") ||(view_type == "atcs"))
	{
		$(".card_layout").each(function(index, ele){			
			cur_width = cur_width + $(ele).width();
		});	
		$("#card_content").width(cur_width + 30);
		if(cur_width >= 930){
			$(".content_wrapper").css({
				'overflow-x': 'scroll',
				'overflow-y': 'hidden',
				'width': '930px'
			});
		}
	}
}

function render_io_view(selected_atcs_address, request_progress, view_type, first_request){
	if (!request_progress) {
		request_progress = true;
		$(".ajax-loader").show();
		$("#io_status").attr("disabled", "disabled");
		var auto_refresh_interval = 5000;
		if(view_type == 'io'){
			auto_refresh_interval = 3000;
		}
		$("#maskcontent").mask("Loading contents, please wait...");
		io_view_xhr = $.post("/io_status_view/fetch_view", {view_type: view_type, atcs_address: selected_atcs_address, get_scale_value: true}, function(response){
			$("#maskcontent").unmask("Loading contents, please wait...");
			if (response.vlp_unconfigured){
				jQuery("#card_content").html(response.view);
				$(".ajax-loader").hide();	
				$("#io_status").removeAttr("disabled");
			}
			else if (response.view_exists) {
				var card_content = jQuery("#card_content");
				if (card_content.length > 0) {
					card_content.html(response.view);
					//$(".ajax-loader").hide();
					$("#io_status").removeAttr("disabled");
					if (first_request)
						set_width_content(view_type);
					fetch_view_interval = setInterval(function(){
						if (!request_in_progress_auto) {
							if (jQuery("#card_content").length > 0) {
								scale_factor_values = response.scale_factor;
								module_view_auto_refresh(selected_atcs_address, response.mcfcrc, request_in_progress_auto, view_type, false);
							}
							else 
								clearInterval(fetch_view_interval);
						}
					}, auto_refresh_interval);
				}
			}
			else if (response.poll) {
				/* Poll the request to check the view status */
				var mcfcrc = response.mcfcrc;
				jQuery("#card_content").html("<span id='progress_message'>Request in progress. Please wait ...</span>");
				check_view_status(selected_atcs_address, view_type, mcfcrc);
			}
			else if(response.mcfcrc && response.request_id && response.geo_exists){
				jQuery("#card_content").html("<span id='progress_message'>Initializing. Please wait ...</span>");
				check_status(response.request_id, selected_atcs_address, view_type, true);
			}
			else if(!response.record_exists && response.geo_exists){
				jQuery("#card_content").html(response.view);
				$(".ajax-loader").hide();
				$("#io_status").removeAttr("disabled");
			}			
			else if (!response.geo_exists) {
				clearTimeout(fetch_view_interval);
				$("#io_status").empty().append('<option value="">Select</option>');
				
				jQuery("#card_content").html(response.view);
				$(".ajax-loader").hide();
				$("#io_status").removeAttr("disabled");
			}
		}, "json");
	}
}


function module_information_links(slot_number, atcs_addr, card_index, card_type, card_name){
	var crd_name = $.trim(card_name);
    $.fn.colorbox({
		href : "io_status_view/fetch_module_information?slot_number=" + slot_number + "&card_type=" + encodeURIComponent(card_type) + "&card_name="+ encodeURIComponent(crd_name)
	});
}

function initiate_io_card_req(selected_atcs_address, view_type, card_ind){
	
	$.post("/io_status_view/initiate_io_card_req", {view_type: view_type, atcs_address: selected_atcs_address, card_ind: card_ind}, function(response){
	});
	
}

function module_refresh(view_type){	
	var message = '';
	var selected_atcs_address = $("#io_atcs_address").text();
	
 	$(".ajax-loader").show();
	$("#contentcontents").mask("Module refreshing, please wait...");
	$.post("/io_status_view/initiate_io_card_req", {
		view_type: view_type, 
		atcs_address: selected_atcs_address
		}, function(response){
			check_status(response,selected_atcs_address, view_type, false);
		});
}
