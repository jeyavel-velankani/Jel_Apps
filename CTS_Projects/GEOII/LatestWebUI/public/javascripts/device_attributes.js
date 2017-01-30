var device_last_id_val = 0;
$(document).ready(function(){
	$('.elements_content').custom_scroll(430);
	device_last_id_val = $("#device_last_id_val").val();
	if($("#devicecount").val() == 'false'){
		$('.save_device_attr').addClass('disable');
		$('.device_attr_refresh').addClass('disable');
	}
	add_to_destroy(function(){
		$(document).unbind("ready");
	    
		//kills all wrapper events
		$('.device_attr_refresh').w_die('click');
		$('.ptc_wiu').w_die('click');
		$('#rearrange_device_order').w_die('click');
		$('.switch_ptc').w_die('click');
		$(".hazarddetector_ptc").w_die('click');
		$('.save_device_attr').w_die('click');
		$('.device_attr_form').w_die('submit');
		$(".inputbox_ptcdevice2").w_die('change');
		
		//clear functions 
		delete window.format_ptc_data_style;
		delete window.format_ptc_switch_style;
		delete window.format_ptc_hd_style;
		delete window.includeorexclude_device;
		delete window.add_new_device;
		delete window.add_txtbox_to_tblrow;
		delete window.enable_disable_row_device_fields;
		delete window.validate_device_attribute_values;
		delete window.validate_device_remove;
	});
	
	
	$(".inputbox_ptcdevice2").w_change(function(){
		$("#error_container").html("");
		$(".errormesg").html("");
		add_nv_preload_page();
		if (!validate_device_attribute_values()) {
			return false;
		}
	});
	$("#add_sig_attributes").w_click(function(){
		add_new_device('signal');
	 $('.save_device_attr').removeClass('disable');
	 $('.device_attr_refresh').removeClass('disable');
		var sig_count = parseInt($("#hd_newsignal_count").val());
		$("#hd_newsignal_count").attr('value', sig_count+1);
		add_nv_preload_page();
	});
	
	$("#add_switch_attributes").w_click(function(){
		add_new_device('switch');
		$('.save_device_attr').removeClass('disable');
	  $('.device_attr_refresh').removeClass('disable');
		var sw_count = parseInt($("#hd_newswitch_count").val());
		$("#hd_newswitch_count").attr('value', sw_count+1);
		add_nv_preload_page();
	});
	
	$("#add_hazarddetector_attributes").w_click(function(){
		add_new_device('hazarddetector');
		$('.save_device_attr').removeClass('disable');
	 $('.device_attr_refresh').removeClass('disable');
		var hz_count = parseInt($("#hd_newhzdetector_count").val());
		$("#hd_newhzdetector_count").attr('value', hz_count+1);
		add_nv_preload_page();
	});
	
	$(".remove_device_attr").w_click(function(){
		$(".errormesg").html("");
		var rem_dev = $("#remove_devices_list").val();	
		
		if (rem_dev.indexOf($(this).attr('id')) > 0){
			rem_dev = rem_dev.replace("|" + $(this).attr('id'), "");
			$("#remove_devices_list").attr('value', rem_dev);
			$(this).attr('title', "Remove");
			document.getElementById($(this).attr('id')).innerHTML = '<img alt="Add_edit_delete_delete" src="/images/add_edit_delete_delete.png">';
		}else{
			rem_dev = rem_dev + "|" + $(this).attr('id');
			$("#remove_devices_list").attr('value', rem_dev);
			$(this).attr('title', "Add");
			document.getElementById($(this).attr('id')).innerHTML = '<img alt="Add_edit_delete_delete" src="/images/add_edit_delete_add.png">';
			$(this).closest('tr').hide();
		   // $('.save_device_attr').removeClass('disable');
	      //  $('.device_attr_refresh').removeClass('disable');
		}
		var tittle = $(this).attr('title');
		if (tittle == "Add") {
			enable_disable_row_device_fields(false ,$(this).attr('row_id'));
		}else if ($(this).attr('title') == "Remove") {
			enable_disable_row_device_fields(true ,$(this).attr('row_id'));
		}
		
		validate_device_attribute_values();
		add_nv_preload_page();
	});
	
	$(".save_device_attr").w_click(function(){
		if(!$(this).hasClass('disable')){
		$(".errormesg").html("");
		var type_of_system = $("#typeOfSyetem").val();
		$("#error_container").html("");
		if(validate_device_attribute_values() == true){
			$(".device_attr_form").trigger("submit");
		}	
	}
	});
		
	$(".device_attr_form").submit(function(){
		$("#contentcontents").mask("Processing request, please wait...");
		var params =  $(".device_attr_form").serialize();
		var page_url = $(this).attr('action');
		remove_preload_page();
		$.post(page_url, params , function(response){
			$("#contentcontents").unmask("Processing request, please wait...");

			reload_page({'message':response.message});
		});		
        return false;
    });
	
	$(".device_attr_refresh").w_click(function(){
	if(!$(this).hasClass('disable')){
		reload_page();
		}
    });
	
	$("#rearrange_device_order").w_click(function(){
		$("#contentcontents").mask("Re-Ordering elements position, please wait...");
		var installation_name = $("#installation_name").attr('value');
		$.post("/ptc/reorder_elements",{
			installation_name: installation_name,
			reoder_refresh_flag: true
		},function(response){
			$("#contentcontents").html(response);
			$("#contentcontents").unmask("Re-Ordering elements position, please wait...");
	   });
	});
		
	$('.ptc_wiu').w_click(function(){
		var next_element = prev_element = current_element = null;
        $('.ptc_wiu').removeClass('selected_ptc_element');
        $(this).addClass('selected_ptc_element');
        next_element = $(this).next().attr('id');
        prev_element = $(this).prev().attr('id');
        current_element = $(this).attr('id');
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
        format_ptc_data_style(prev_element, next_element);
	});
	
	$('.switch_ptc').w_click(function(){
        var next_element = prev_element = current_element = null;
        $('.switch_ptc').removeClass('selected_switch_ptc_element');
        $(this).addClass('selected_switch_ptc_element');
        next_element = $(this).next().attr('id');
        prev_element = $(this).prev().attr('id');
        current_element = $(this).attr('id');
        $('.uparrow_switch').css({
            "opacity": "1",
			"filter": "alpha(opacity=100)",
            "cursor": "pointer"
        });
        $('.downarrow_switch').css({
            "opacity": "1",
			"filter": "alpha(opacity=100)",
            "cursor": "pointer"
        });
        $('.switch_ptc td').css({
            "background-color": "#949494",
            "color": "#000"
        });
        $(this).children().css({
            "background-color": "#CFD638",
            "color": "#000"
        });
        format_ptc_switch_style(prev_element, next_element);
    });
	
	$('.hazarddetector_ptc').w_click(function(){
        var next_element = prev_element = current_element = null;
        $('.hazarddetector_ptc').removeClass('selected_hazarddetector_ptc_element');
        $(this).addClass('selected_hazarddetector_ptc_element');
        next_element = $(this).next().attr('id');
        prev_element = $(this).prev().attr('id');
        current_element = $(this).attr('id');
        
        $('.uparrow_hd').css({
            "opacity": "1",
			"filter": "alpha(opacity=100)",
            "cursor": "pointer"
        });
        $('.downarrow_hd').css({
            "opacity": "1",
			"filter": "alpha(opacity=100)",
            "cursor": "pointer"
        });
        $('.hazarddetector_ptc td').css({
            "background-color": "#949494",
            "color": "#000"
        });
        $(this).children().css({
            "background-color": "#CFD638",
            "color": "#000"
        });
        format_ptc_hd_style(prev_element, next_element);
    });
});

function format_ptc_data_style(prev_element, next_element){
    if (prev_element == "" || prev_element == undefined || prev_element == null) {
        prev_element = null;
        $('.uparrow').css({
            "opacity": "0.2",
            "filter": "alpha(opacity=20)",
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
            "opacity": "0.2",
            "filter": "alpha(opacity=20)",
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
	
function format_ptc_switch_style(prev_element, next_element){
    if (prev_element == "" || prev_element == undefined || prev_element == null) {
        prev_element = null;
        $('.uparrow_switch').css({
            "opacity": "0.2",
			"filter": "alpha(opacity=20)",
            "cursor": "default"
        });
    }else {
        $('.uparrow_switch').css({
            "opacity": "1",
			"filter": "alpha(opacity=100)",
            "cursor": "pointer"
        });
    }
    if (next_element == "" || next_element == undefined || next_element == null) {
        next_element = null;
        $('.downarrow_switch').css({
            "opacity": "0.2",
			"filter": "alpha(opacity=20)",
            "cursor": "default"
        });
    }else {
        $('.downarrow_switch').css({
            "opacity": "1",
			"filter": "alpha(opacity=100)",
            "cursor": "pointer"
        });
    }
}
	
function format_ptc_hd_style(prev_element, next_element){
	if (prev_element == "" || prev_element == undefined || prev_element == null) {
	    prev_element = null;
	    $('.uparrow_hd').css({
	        "opacity": "0.2",
			"filter": "alpha(opacity=20)",
	        "cursor": "default"
	    });
	}else {
	    $('.uparrow_hd').css({
	        "opacity": "1",
			"filter": "alpha(opacity=100)",
	        "cursor": "pointer"
	    });
	}
	if (next_element == "" || next_element == undefined || next_element == null) {
	    next_element = null;
	    $('.downarrow_hd').css({
	        "opacity": "0.2",
			"filter": "alpha(opacity=20)",
	        "cursor": "default"
	    });
	}else {
	    $('.downarrow_hd').css({
	        "opacity": "1",
			"filter": "alpha(opacity=100)",
	        "cursor": "pointer"
	    });
	}
}

function includeorexclude_device(object , device_class){
	if (object.checked == true){			
		$("."+device_class).children().each(function(index, table_data){
			$(table_data).children("div").each(function(index, value){
				$(value).find("input[type=text]").removeAttr("disabled");
				$(value).find("select").removeAttr("disabled");		
				$(value).find("input:checkbox").attr('checked', 'checked');				
			});
		});
	}else if (object.checked == false){
		$("."+device_class).children().each(function(index, table_data){
			$(table_data).children("div").each(function(index, value){
				$(value).find("input[type=text]").attr("disabled",true);
				$(value).find("select").attr("disabled",true);	
				$(value).find("input:checkbox").attr('checked',false);				
			});
		});
	}
}

function enable_disable_row_device_fields(enable_disable_flag , device_class){
	if (enable_disable_flag == true) {
		$("." + device_class).children().each(function(index, table_data){
			$(table_data).children("div").each(function(index, value){
				$(value).find("input[type=text]").removeAttr("disabled");
				$(value).find("select").removeAttr("disabled");
				$(value).find("input:checkbox").removeAttr("disabled");
			});
		});
	}else if(enable_disable_flag == false){
		$("."+device_class).children().each(function(index, table_data){
			$(table_data).children("div").each(function(index, value){
				$(value).find("input[type=text]").attr("disabled",true);
				$(value).find("select").attr("disabled",true);	
				$(value).find("input:checkbox").attr('disabled',true);				
			});
		});
	}
}

function add_new_device(device_type){
	//if(confirm("Do you want to add new" + device_type + " device ?")){
		$(".errormesg").html("");	
		var tbldevice = document.getElementById("mytable_" + device_type);
		var rowCount = tbldevice.rows.length;
        var row = tbldevice.insertRow(rowCount);
		if (parseInt(device_last_id_val) > 0){
			device_last_id_val = parseInt(device_last_id_val) + 1;
		}
		var row_id = device_type + "_" + parseInt(device_last_id_val);
		$(row).attr('id', row_id);
		$(row).addClass('ptc_wiu signal');
		$(row).addClass(row_id);
		
		var column_i = 0;
		var field_name = device_type + "_sitedeviceid";
		add_txtbox_to_tblrow(column_i, rowCount, row, field_name , "Site Device Id");
		column_i++;

		field_name = device_type + "_device_name";
		add_txtbox_to_tblrow(column_i, rowCount, row, field_name , "Device Name");
		column_i++;
		
		if($('#typeOfSyetem').val() != 'VIU'){
			field_name = device_type + "_subnode";
			add_txtbox_to_tblrow(column_i, rowCount, row, field_name , "Geo Sub Node");
			column_i++;
		}
		field_name = device_type + "_trackname";
		//field_name = device_type + ($('#typeOfSyetem').val() != 'VIU' ? "_tracknumber" : "_trackname");
		add_txtbox_to_tblrow(column_i, rowCount, row, field_name , "Track Name");
		var track_name_id = field_name+'_'+rowCount;
		$("#"+track_name_id).attr('value', "Not Set");
		column_i++;

		field_name = device_type + "_direction_" + rowCount;
		
		
		var cell4 = row.insertCell(column_i);
		var divfield = document.createElement("div");
		divfield.align = "left" ;
		divfield.className = "text_font" ;
		var select = document.createElement("select");
   		select.setAttribute("name", field_name);
   		select.setAttribute("id", field_name);
   		select.setAttribute("class", "selectbox_ptcdevice");
   		column_i++;
   		   		
   		var option = document.createElement("option");
  		if (device_type == 'switch'){
  			option.setAttribute("value", "LF");
	  		option.innerHTML = "LF";
	  		select.appendChild(option);
	  		option = document.createElement("option");
	  		option.setAttribute("value", "LR");
	  		option.innerHTML = "LR";
	  		select.appendChild(option);	  		
	  		option.setAttribute("value", "RF");
	  		option.innerHTML = "RF";
	  		select.appendChild(option);
	  		option = document.createElement("option");
	  		option.setAttribute("value", "RR");
	  		option.innerHTML = "RR";
	  		select.appendChild(option);	
  		}else{
   			option.setAttribute("value", "Increasing");
	  		option.innerHTML = "Increasing";
	  		select.appendChild(option);
	  		option = document.createElement("option");
	  		option.setAttribute("value", "Decreasing");
	  		option.innerHTML = "Decreasing";
	  		select.appendChild(option);
   		}
		cell4.appendChild(divfield);
		divfield.appendChild(select);
		
		field_name = device_type + "_milepost";
		add_txtbox_to_tblrow(column_i, rowCount, row, field_name , "Mile Post");
		var default_mile_post_val = $("#default_milepost").val(); 
		var mile_post_id = field_name+'_'+rowCount;
		$("#"+mile_post_id).attr('value', default_mile_post_val);
		column_i++;
		
		field_name = device_type + "_subdivisionnumber";
		add_txtbox_to_tblrow(column_i, rowCount, row, field_name ,"Sub Division Number");
		var default_sub_div_no_val = $("#default_subdivision_no").val(); 
		var sub_div_no_id = field_name+'_'+rowCount;
		$("#"+sub_div_no_id).attr('value', (default_sub_div_no_val == "") ? "Not Set" : default_sub_div_no_val);
		column_i++;
		
		field_name = device_type + "_sitename";
		add_txtbox_to_tblrow(column_i, rowCount, row, field_name , "Site Name");
		var default_site_name_val = $("#default_sitename").val(); 
		var site_name_id = field_name+'_'+rowCount;
		$("#"+site_name_id).attr('value', default_site_name_val);
		column_i++;
		
		field_name = device_type + "_description";
		add_txtbox_to_tblrow(column_i, rowCount, row, field_name , "Description");
		column_i++;
			
		if($('#typeOfSyetem').val() != 'VIU'){	
			var cell8 = row.insertCell(column_i);
	        var chkbox = document.createElement("input");
	        chkbox.type = "checkbox";
			chkbox.id = device_type + "_include_" + rowCount;
			chkbox.name = device_type + "_device_" + rowCount;
			chkbox.value = "Include";
			chkbox.checked = true;
			chkbox.disabled = true;
	        cell8.appendChild(chkbox);
	        column_i++;
	    }
		
		var cell9 = row.insertCell(column_i);
		cell9.innerHTML = '<div align="center"><a id="'+ device_type+'_remove_new_' + rowCount + '" class="remove_device_attr" title="Remove" row_id="'+row_id+'" href="javascript: void(0)"> <img src="/images/add_edit_delete_delete.png?1389045313" alt="Add_edit_delete_delete"></a>' +
		 		'</div>';
		column_i++;
		$('.elements_content').custom_scroll(430);  
}


function add_txtbox_to_tblrow(cellid, rowCount, tblrow, field_name , name){
	var cell = tblrow.insertCell(cellid);
	var divfield = document.createElement("div");
	divfield.align = "left" ;
	divfield.className = "text_font" ;
    var txtfield = document.createElement("input");
    txtfield.type = "text";
	txtfield.id = field_name + "_" + rowCount;
	txtfield.name = field_name + "_" + rowCount;
	txtfield.size = 30;
	txtfield.className = "inputbox_ptcdevice2";
	cell.appendChild(divfield);
	divfield.appendChild(txtfield);
    $("#"+field_name + "_" + rowCount).attr('name_text', name);
}

function validate_device_attribute_values(){
	var stringObjPattern = /^[0-9A-Za-z_-]+$/i;
	var numberObjPattern = /^[0-9]+$/i;
	var milePostObjPattern = /^[0-9A-Za-z.]+$/i;
	var siteDeviceObjPattern = /^[0-9A-Za-z ]+$/i;
	var tracknamepattern = /^[0-9A-Za-z \w{.\\(),\]\[~`!@#$%^*_|-}+;:?ой-]+$/i;
	var warning_message_queue = [];
	var flag = true;
	var rem_dev = $("#remove_devices_list").val();
	var all_dev = rem_dev.split('|');
	var signal_remove_ids = [];
	var switch_remove_ids = [];
	var hd_remove_ids = [];
	for(var k = 0; k < all_dev.length; k++){
	  	var sig_remove_id = all_dev[k].split('signal_remove_');
		if(sig_remove_id.length > 1){
			signal_remove_ids.push(all_dev[k]);	
		}
		var sw_remove_id = all_dev[k].split('switch_remove_');
		if(sw_remove_id.length > 1){
			switch_remove_ids.push(all_dev[k]);	
		}
		var hd_remove_id = all_dev[k].split('hazarddetector_remove_');
		if(hd_remove_id.length > 1){
			hd_remove_ids.push(all_dev[k]);	
		}
	}
	$("#mytable_signal").children().each(function(index, table_data){
		$(table_data).children("tr").each(function(index, value){
			if (index > 0) {
				if (validate_device_remove(signal_remove_ids, $(value).find("a[class=remove_device_attr]").attr('id')) == true) {
					warning_message_queue.push("");
					$(value).find("input[type=text]").each(function(i, ele){
						var name_text = $("#" + ele.id).attr('name_text');
						var name_id = ele.id;
						var warning_message = "";

						if($(value).closest('tr').css('display') != 'none'){
							if (name_text == "Site Device Id" || name_text == "Device Name" || name_text == "Site Name") {
								if (!stringObjPattern.test(ele.value)) {
									$("#"+name_id).css("border", "1px solid red");
									warning_message = "Signal - Row " + index + " Please enter valid " + name_text + "[only alpha numeric,_,-]";
								}else{
									$("#"+name_id).css("border", "1px solid #888");
								}
							}else if (name_text == "Geo Sub Node") {
								if (!numberObjPattern.test(ele.value)) {
									$("#" + name_id).css("border", "1px solid red");
									warning_message = "Signal - Row " + index + " Please enter valid " + name_text + "[only numeric values 0-9 ]";
								}
								else {
									$("#" + name_id).css("border", "1px solid #888");
								}
							}else if (name_text == "Track Name") {
								if ((tracknamepattern.test(ele.value)) || (ele.value.toLowerCase() == 'not set')) {
									$("#" + name_id).css("border", "1px solid #888");
								}
								else {
									$("#" + name_id).css("border", "1px solid red");
									warning_message = "Signal - Row " + index + " Please enter valid " + name_text + "[only alpha numeric and spcial characters(Excluding /,',\",=,<,>,&)]";									
								}
							}else if (name_text == "Mile Post") {
								if (!milePostObjPattern.test(ele.value)) {
									$("#" + name_id).css("border", "1px solid red");
									warning_message = "Signal - Row " + index + " Please enter valid " + name_text + "[only alpha numeric,.]";
								}
								else {
									$("#" + name_id).css("border", "1px solid #888");
								}
							}else if (name_text == "Sub Division Number") {
								if (!siteDeviceObjPattern.test(ele.value)) {
									$("#" + name_id).css("border", "1px solid red");
									warning_message = "Signal - Row " + index + " Please enter valid " + name_text + "[only alpha numeric and space]";
								}
								else {
									$("#" + name_id).css("border", "1px solid #888");
								}
							}
							if (warning_message != "") {
								warning_message_queue.push(warning_message);
							}
						}
					});
					
				}else{
					$(value).find("input[type=text]").each(function(i, ele){
						$("#"+ele.id).css("border", "1px solid #888");
					});
				}
			}
		});
	});
	
	$("#mytable_switch").children().each(function(index, table_data){
		$(table_data).children("tr").each(function(index, value){
			if (index > 0) {
				if (validate_device_remove(switch_remove_ids, $(value).find("a[class=remove_device_attr]").attr('id')) == true) {
					warning_message_queue.push("");
					$(value).find("input[type=text]").each(function(i, ele){
						var name_text = $("#" + ele.id).attr('name_text');
						var name_id = ele.id;
						var warning_message = "";

						if($(value).closest('tr').css('display') != 'none'){
							if (name_text == "Site Device Id" || name_text == "Device Name" || name_text == "Site Name") {
								if (!stringObjPattern.test(ele.value)) {
									$("#"+name_id).css("border", "1px solid red");
									warning_message = "Switch - Row " + index + " Please enter valid " + name_text + "[only alpha numeric,_,-]";
								}else{
									$("#"+name_id).css("border", "1px solid #888");
								}
							}else if (name_text == "Geo Sub Node") {
								if (!numberObjPattern.test(ele.value)) {
									$("#"+name_id).css("border", "1px solid red");
									warning_message = "Switch - Row " + index + " Please enter valid " + name_text + "[only numeric values 0-9 ]";
								}else{
									$("#"+name_id).css("border", "1px solid #888");
								}
							}else if (name_text == "Track Name") {
								if ((tracknamepattern.test(ele.value)) || (ele.value.toLowerCase() == 'not set')) {
									$("#" + name_id).css("border", "1px solid #888");
								}
								else {
									$("#" + name_id).css("border", "1px solid red");
									warning_message = "Switch - Row " + index + " Please enter valid " + name_text + "[only alpha numeric and spcial characters(Excluding /,',\",=,<,>,&)]";									
								}
                            }else if (name_text == "Mile Post") {
								if (!milePostObjPattern.test(ele.value)) {
									$("#"+name_id).css("border", "1px solid red");
									warning_message = "Switch - Row " + index + " Please enter valid " + name_text + "[only alpha numeric,.]";
								}else{
									$("#"+name_id).css("border", "1px solid #888");
								}
							}else if (name_text == "Sub Division Number") {
								if (!siteDeviceObjPattern.test(ele.value)) {
									$("#"+name_id).css("border", "1px solid red");
									warning_message = "Switch - Row " + index + " Please enter valid " + name_text + "[only alpha numeric and space]";
								}else{
									$("#"+name_id).css("border", "1px solid #888");
								}
							}
							if (warning_message != "") {
								warning_message_queue.push(warning_message);
							}
						}
					});
				}else{
					$(value).find("input[type=text]").each(function(i, ele){
						$("#"+ele.id).css("border", "1px solid #888");
					});
				}
			}
		});
	});
	
	$("#mytable_hazarddetector").children().each(function(index, table_data){
		$(table_data).children("tr").each(function(index, value){
			
			if (index > 0) {
				if (validate_device_remove(hd_remove_ids, $(value).find("a[class=remove_device_attr]").attr('id')) == true) {
					warning_message_queue.push("");
					$(value).find("input[type=text]").each(function(i, ele){
						var name_text = $("#" + ele.id).attr('name_text');
						var name_id = ele.id;
						var warning_message = "";

						if($(value).closest('tr').css('display') != 'none'){
							if (name_text == "Site Device Id" || name_text == "Device Name" || name_text == "Site Name") {
								if (!stringObjPattern.test(ele.value)) {
									$("#"+name_id).css("border", "1px solid red");
									warning_message = "Hazard Detector - Row " + index + " Please enter valid " + name_text + "[only alpha numeric,_,-]";
								}else{
									$("#"+name_id).css("border", "1px solid #888");
								}
							}else if (name_text == "Geo Sub Node") {
								if (!numberObjPattern.test(ele.value)) {
									$("#"+name_id).css("border", "1px solid red");
									warning_message = "Hazard Detector - Row " + index + " Please enter valid " + name_text + "[only numeric values 0-9 ]";
								}else{
									$("#"+name_id).css("border", "1px solid #888");
								}
							}else if (name_text == "Track Name") {
								if ((tracknamepattern.test(ele.value)) || (ele.value.toLowerCase() == 'not set')) {
									$("#" + name_id).css("border", "1px solid #888");
								}
								else {
									$("#" + name_id).css("border", "1px solid red");
									warning_message = "Hazard Detector - Row " + index + " Please enter valid " + name_text + "[only alpha numeric and spcial characters(Excluding /,',\",=,<,>,&)]";									
								}
                            }else if (name_text == "Mile Post") {
								if (!milePostObjPattern.test(ele.value)) {
									$("#"+name_id).css("border", "1px solid red");
									warning_message = "Hazard Detector - Row " + index + " Please enter valid " + name_text + "[only alpha numeric,.]";
								}else{
									$("#"+name_id).css("border", "1px solid #888");
								}
							}else if (name_text == "Sub Division Number") {
								if (!siteDeviceObjPattern.test(ele.value)) {
									$("#"+name_id).css("border", "1px solid red");
									warning_message = "Hazard Detector - Row " + index + " Please enter valid " + name_text + "[only alpha numeric and space]";
								}else{
									$("#"+name_id).css("border", "1px solid #888");
								}
							}
							if (warning_message != "") {
								warning_message_queue.push(warning_message);
							}
						}
					});
				}else{
					$(value).find("input[type=text]").each(function(i, ele){
						$("#"+ele.id).css("border", "1px solid #888");
					});
				}
			}
		});
	});
	$("#error_container").html('');
	for (var j = 0; j < warning_message_queue.length; j++) {
		if(warning_message_queue[j] != "" ){
			$("#error_container").append("<li class='warning_message_small' id='error_warning_id_" + j + "'>"+warning_message_queue[j]+"</li> ");	
			flag = false;
		}
	}
	$('.elements_content').custom_scroll(430);
	if(flag){
		return true;	
	}else{
		return false;
	}
}
function validate_device_remove(remove_ids , current_row_id){
	var flag = true;
	for (var y = 0; y < remove_ids.length; y++) {
		if(remove_ids[y] == current_row_id){
			flag=  false;
		}
	}
	return flag;			
}
