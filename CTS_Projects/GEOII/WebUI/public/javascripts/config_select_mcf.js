/**
 * @author Jeyavel Natesan
 */

add_to_destroy(function(){
	$(document).unbind("ready");
	
	//kills all wrapper events
	$(".upload_selected_mcf").w_die('click');
	$("#mcffileUpload").w_die('change');
	$("#form_upload_site_mcf_file").w_die('submit');
	$("#selected_site_mcf").w_die('change');
	$("#selected_mcfCRCValue").w_die('change');
	$(".cancel_uplaod_selected_mcf").w_die('click');
	$('#selected_template').w_die('change');
	$('#selected_pac').w_die('change');
	$("input[type=radio]").w_die('click');
	$("#uploadTemplateFile").w_die('change');
	$("#uploadPacFile").w_die('change');
	
	//clear functions 
	delete window.check_selected_mcf;
	delete window.get_mcfcrc_value;
	delete window.validate_crc_value;
	delete window.check_selected_pac;
	delete window.check_selected_template;
});

$(document).ready(function(){
	var site_type = $("#hd_site_type").val();
	$("#selected_mcfCRCValue").attr("disabled", true);
	
	$('#selected_template').w_change(function(){
		var selected_template = document.getElementById('selected_template').options[document.getElementById('selected_template').selectedIndex].text;
		$("#selected_mcfCRCValue").val("");
		$('#selected_site_mcf').val("Select MCF");
		$("#selected_mcfcrc_validation").html("");
				
		if (selected_template != "Not Used"){
			$(".loader").show();
			$('#selected_site_mcf').attr("disabled", true);
			$("#mcffileUpload").attr("disabled", true);
			$("#selected_mcfCRCValue").attr("disabled", true);
			var selected_template_value = document.getElementById('selected_template').options[document.getElementById('selected_template').selectedIndex].value;
			$.post('/selectsite/get_template_details', {
				template_path : selected_template_value
			}, function(response){
				$("#template_mcfname_mcfcrc").attr('mcf_name',response.mcf_name);
				$("#template_mcfname_mcfcrc").attr('mcfcrc',response.mcfcrc);
				$("#template_mcfname_mcfcrc").attr('mcf_location',response.mcf_location);
				var mcfname_and_mcfcrc_tooltip = "MCF Name: "+response.mcf_name+" ; MCFCRC: "+response.mcfcrc;
				$("#selected_template").attr('title', mcfname_and_mcfcrc_tooltip);
		        
		        var all_gcp_mcf_name_and_mcfcrc = $("#all_gcp_mcf_name_and_mcfcrc").val();
				var array_mcfname_and_mcfcrc = all_gcp_mcf_name_and_mcfcrc.split('||');
				var found_db = false;
				for(var i=0;i< array_mcfname_and_mcfcrc.length-1;i++){
					var crc = array_mcfname_and_mcfcrc[i].split('|');
					if (crc[1].toUpperCase() == response.mcfcrc.toUpperCase()){
						$('#selected_site_mcf option').each(function(){
			            	if(this.text.toUpperCase() == crc[0].toUpperCase()){
			                	this.selected = true;
								found_db = true;
								return true;
			            	}    
						});		
					}
				}
				$("#selected_mcfCRCValue").val(response.mcfcrc);
				$('#upload_selected_mcf').removeAttr("disabled");
				$("#cancel_uplaod_selected_mcf").removeAttr("disabled");
				if (!found_db) {
					$('#selected_site_mcf').val("Select MCF");
					$("#selected_mcfCRCValue").val("");
					$('#selected_site_mcf').removeAttr("disabled");
					$("#mcffileUpload").removeAttr("disabled");
					$("#selected_mcfCRCValue").removeAttr("disabled");
					$('#upload_selected_mcf').attr("disabled", true);
					$("#cancel_uplaod_selected_mcf").attr("disabled", true);
					$("#selected_mcfcrc_validation").html("MCF is not available in repository. Please select MCF");
				}				
				$(".loader").hide();
			});
		}else{
			$("#template_mcfname_mcfcrc").attr('mcf_name',"");
			$("#template_mcfname_mcfcrc").attr('mcfcrc',"");
			$("#template_mcfname_mcfcrc").attr('mcf_location',"");
			$('#selected_site_mcf').removeAttr("disabled");
			$("#mcffileUpload").removeAttr("disabled");
			$("#selected_mcfCRCValue").removeAttr("disabled");
		}
	});
	
	$('#selected_pac').w_change(function(){
		var selected_pac = document.getElementById('selected_pac').options[document.getElementById('selected_pac').selectedIndex].text;
		$("#selected_mcfCRCValue").val("");
		$('#selected_site_mcf').val("Select MCF");
		$("#selected_mcfcrc_validation").html("");
		
		// Remove the already browsed PAC file from the dropdown box
		var select=document.getElementById('selected_pac');
		for (i=0;i<select.length;  i++) {
			var tpl_name = select.options[i].value.split('.')
			tpl_name = tpl_name[tpl_name.length-1];
		}
		
		if (selected_pac != "Select PAC/TPL File"){
			$(".loader").show();
			// $('#selected_site_mcf').attr("disabled", true);
			// $("#mcffileUpload").attr("disabled", true);
			// $("#selected_mcfCRCValue").attr("disabled", true);
		
			var selected_template_value = document.getElementById('selected_pac').options[document.getElementById('selected_pac').selectedIndex].value;
			$.post('/selectsite/get_pac_details', {
				pac_path : selected_template_value
			}, function(response){
				if(response.error == true || response.error == 'true'){
					alert(response.error_message);
					$('#upload_selected_mcf').attr("disabled", true);
				}else{
				  $("#template_mcfname_mcfcrc").attr('mcf_name',response.mcf_name);
				  $("#template_mcfname_mcfcrc").attr('mcfcrc',response.mcfcrc);
				  $("#template_mcfname_mcfcrc").attr('mcf_location',response.mcf_location);
				
				  var mcfname_and_mcfcrc_tooltip = "MCF Name: "+response.mcf_name +" ; MCFCRC: "+response.mcfcrc;
				  $("#selected_pac").attr('title', mcfname_and_mcfcrc_tooltip);	
				
				  var all_gcp_mcf_name_and_mcfcrc = $("#all_gcp_mcf_name_and_mcfcrc").val();
				  var array_mcfname_and_mcfcrc = all_gcp_mcf_name_and_mcfcrc.split('||');
				  var found_db = false;
				  for(var i=0;i< array_mcfname_and_mcfcrc.length-1;i++){
					var crc = array_mcfname_and_mcfcrc[i].split('|');
					if (crc[1].toUpperCase() == response.mcfcrc.toUpperCase()){
						$('#selected_site_mcf option').each(function(){
			            	if(this.text.toUpperCase() == crc[0].toUpperCase()){
			                	this.selected = true;
								found_db = true;
								$("#selected_mcfCRCValue").attr('mcf_location', response.mcf_location);
								return true;
			            	}    
						});		
					}
				}
				$("#selected_mcfCRCValue").val(response.mcfcrc);
				$('#upload_selected_mcf').removeAttr("disabled");
				$("#cancel_uplaod_selected_mcf").removeAttr("disabled");
				if (!found_db) {
					$('#selected_site_mcf').val("Select MCF");
					$("#selected_mcfCRCValue").val("");
					$('#selected_site_mcf').removeAttr("disabled");
					$("#mcffileUpload").removeAttr("disabled");
					$("#selected_mcfCRCValue").removeAttr("disabled");
					$('#upload_selected_mcf').attr("disabled", true);
					$("#cancel_uplaod_selected_mcf").attr("disabled", true);
				}			
			}
			$(".loader").hide();
		  });
		}else{
			$("#template_mcfname_mcfcrc").attr('mcf_name',"");
			$("#template_mcfname_mcfcrc").attr('mcfcrc',"");
			$("#template_mcfname_mcfcrc").attr('mcf_location',"");
			$('#selected_site_mcf').removeAttr("disabled");
			$("#mcffileUpload").removeAttr("disabled");
			$("#selected_mcfCRCValue").removeAttr("disabled");
		}
	});
	
	 $("input[type=radio]").w_click(function(){
	 	$(".loader").show();
	 	$('#selected_site_mcf').val("Select MCF");
		$("#selected_mcfCRCValue").val("");
		$("#template_mcfname_mcfcrc").attr('mcf_name',"");
		$("#template_mcfname_mcfcrc").attr('mcfcrc',"");
		$("#template_mcfname_mcfcrc").attr('mcf_location',"");
		$("#selected_mcfcrc_validation").html("");
		$("#selected_template").attr('title', "Not Used");
		$("#selected_pac").attr('title', "Select PAC/TPL File");
		$('#upload_selected_mcf').removeAttr("disabled");
	 	var selected_site_type = $('input[name="new_site_type"]:checked', '#form_upload_site_mcf_file').val();
	 	if (selected_site_type == "create_new_site"){
	 		$(".div_select_template").show();
	 		$(".div_select_pac").hide();
	 		document.getElementById("selected_template").disabled = true;
	 		$('#selected_site_mcf').attr("disabled", true);
			$("#mcffileUpload").attr("disabled", true);
			$("#selected_mcfCRCValue").attr("disabled", true);
	 		$.post('/selectsite/get_template_list', {
				// no params
			}, function(response){
				$("#selected_template >option").remove();
				$('#selected_template').append($('<option></option>').val('Not Used').html('Not Used'));
				var arrayoftemplates = response.split('||');
				for (var i = 0; i < arrayoftemplates.length - 1; i++) {
					var value_and_name = arrayoftemplates[i].split('|');
					$('#selected_template').append($('<option></option>').val(value_and_name[0]).html(value_and_name[1]));
				}
				$(".loader").hide();
				document.getElementById("selected_template").disabled = false;
				$('#selected_site_mcf').removeAttr("disabled");
				$("#mcffileUpload").removeAttr("disabled");
				$("#selected_mcfCRCValue").removeAttr("disabled");
			});
	 	}else if (selected_site_type == "create_new_site_from_pac"){
	 		$(".div_select_template").hide();
	 		$(".div_select_pac").show();
	 		document.getElementById("selected_pac").disabled = true;
	 		$('#selected_site_mcf').removeAttr("disabled");
			$("#mcffileUpload").removeAttr("disabled");
			$("#selected_mcfCRCValue").removeAttr("disabled");
	 		$.post('/selectsite/get_pac_file_list', {
				// no params
			}, function(response){
		 		$("#selected_pac >option").remove();
				$('#selected_pac').append($('<option></option>').val('Select PAC/TPL File').html('Select PAC/TPL File'));
				var arrayofpacnames = response.split('||');
				for (var i = 0; i < arrayofpacnames.length - 1; i++) {
					var value_and_name = arrayofpacnames[i].split('|');
					$('#selected_pac').append($('<option></option>').val(value_and_name[0]).html(value_and_name[1]));
				}
				$(".loader").hide();
				document.getElementById("selected_pac").disabled = false;
			});	
	 	}
	});

	$(".upload_selected_mcf").w_click(function(){
	    var site_type = $("#hd_site_type").val();
		product = site_type;
	    if (site_type == "GCP") {
	    	document.getElementById("selected_mcfcrc_validation").innerHTML = "";
			var selected_template = document.getElementById('selected_template').options[document.getElementById('selected_template').selectedIndex].text;
			var mcfcrc_entered  = $("#selected_mcfCRCValue").val();
			var template_mcfcrc = $("#template_mcfname_mcfcrc").attr('mcfcrc');
			var selected_site_type = $('input[name="new_site_type"]:checked', '#form_upload_site_mcf_file').val();
			var crc_value = 0; 
			var hexavalue = new Array();
			hexavalue = mcfcrc_entered.toLowerCase().split('x');
			if ((hexavalue.length >1) && (hexavalue.length <3)){
				crc_value = hexavalue[1];
			}else if (hexavalue.length == 1){
				crc_value = hexavalue[0];
			}
			if (selected_site_type == "create_new_site_from_pac"){
				var selected_pac = document.getElementById('selected_pac').options[document.getElementById('selected_pac').selectedIndex].text;
				if(selected_pac != "Select PAC/TPL File"){
					if (($("#selected_mcfCRCValue").attr('mcf_location').length > 0) && $("#selected_mcfCRCValue").attr('mcf_location') != $("#template_mcfname_mcfcrc").attr('mcf_location'))
					{
						document.getElementById("selected_mcfcrc_validation").innerHTML = "Upgrade/Downgrade to/from GCP 5000/4000 is not supported.";
						return false;
					}
//					if(crc_value.toUpperCase() != template_mcfcrc.toUpperCase()){
//						document.getElementById("selected_mcfcrc_validation").innerHTML = "Mcf not matching with PAC,Please select valid MCF file";
//						return false;
//					}
				}else{
					document.getElementById("selected_mcfcrc_validation").innerHTML = "Please select PAC/TPL file";
					$('#upload_selected_mcf').removeAttr("disabled");
					$('#upload_selected_mcf').removeAttr("disabled");
					return false;	 							
				}
			}else if((selected_site_type == "create_new_site")&&(selected_template != "Not Used")&&(crc_value.toUpperCase() != template_mcfcrc.toUpperCase())){
				document.getElementById("selected_mcfcrc_validation").innerHTML = "Mcf not matching with template,Please select valid MCF file";
				$('#upload_selected_mcf').removeAttr("disabled");
				$('#upload_selected_mcf').removeAttr("disabled");
				return false;
			}
			$('#selected_site_mcf').removeAttr("disabled");
			$("#selected_mcfCRCValue").removeAttr("disabled");
			//$('#upload_selected_mcf').attr("disabled", true);
			//$("#cancel_uplaod_selected_mcf").attr("disabled", true);
		}
		var selected_mcf = document.getElementById('selected_site_mcf').selectedIndex;
		if ((selected_mcf != -1) && (selected_mcf != 0)) {
			$('#form_upload_site_mcf_file').attr('action', '/selectsite/select_mcf?type='+site_type);
			if (validate_crc_value("MCF")) {
				$(".loader").show();
				document.getElementById("selected_mcfcrc_validation").innerHTML = "";
				$('#upload_selected_mcf').attr("disabled", true);
				$("#cancel_uplaod_selected_mcf").attr("disabled", true);
				$("#form_upload_site_mcf_file").submit();
			}
		}else {
			document.getElementById("selected_mcfcrc_validation").innerHTML = "Please select MCF file";
			$('#upload_selected_mcf').removeAttr("disabled");
			$("#cancel_uplaod_selected_mcf").removeAttr("disabled");
			return false;
		}
	});
	
	$("#mcffileUpload").w_change(function(){
		check_selected_mcf();
	});
	
	$("#uploadTemplateFile").w_change(function(){
		check_selected_template();
	});
	
	$("#uploadPacFile").w_change(function(){
		check_selected_pac();
	});
	
	$("#form_upload_site_mcf_file").submit(function(){
		var form_submit = {
		    success:    function(resp) {
				var strarray = resp.split('|');               
		    	if(strarray[0] == "newsite"){
					//$.fn.colorbox.close();
					$("#divselectcontent").unmask("Processing request, please wait...");				
					//////////////////////////////////////////////////////////////////////////////////////////
					var cont = "";
					var error_message = strarray[1];
					var warning_message = strarray[2];
			        var ptc_enable = strarray[4];
					var crc_valid_flag = strarray[5];
					var valid_mcf_pac = strarray[6];
					if (typeof error_message !== 'undefined' && error_message !== null && error_message != "") {
						//$('#maincontent').unmask('Processing request, please wait...');
					    //alert(error_message);
					    document.getElementById("selected_mcfcrc_validation").innerHTML = error_message;
						if (crc_valid_flag == "false" || valid_mcf_pac == "false") {
						   $(".loader").hide();
						   $("#selected_mcfCRCValue").val("");
						   $('#upload_selected_mcf').attr("disabled", false);
						   $("#cancel_uplaod_selected_mcf").attr("disabled", false);
					     }
						 else{
						 	$.fn.colorbox.close();
							$("#maincontent").mask("Removing back-up files, please wait...");
							$.post('/selectsite/removesite', {
								selected_folder: "true"
							}, function(resp){
								$('#leftnavtree').html('');
								$('#configurationeditorcontent').hide();
								//$('#removemessagesuccess').html(resp);
								$("#maincontent").unmask("Removing back-up files, please wait...");
								remove_v_preload_page();
								reload_page();
							});
							}
						}
					else {
						$.fn.colorbox.close();
						if (typeof warning_message !== 'undefined' && warning_message !== null) {
							cont = trim(warning_message);
							intIndexOfMatch = 0;
							while (intIndexOfMatch != -1) {
								cont = cont.replace("<BR>", "\n");
								intIndexOfMatch = cont.indexOf("<BR>");
							}
						}
						if (ptc_enable == 'true' || ptc_enable == true) {
							ptc_enabled_flag = true;
						}else {
							ptc_enabled_flag = false;
						}
						if (cont != "") {
							if (!alert(cont)) {
								//$('#maincontent').unmask('Processing request, please wait...');
								if ((cont.indexOf("Error") == -1) && (cont.indexOf("error") == -1)) {
									$.when(usb_enable(), build_nav_object(),update_gcp5k_flag()).done(function(){
										remove_v_preload_page();
										reload_page();
									});
								}
							}
						}else {
						    if($('.message_container span').addClass("success_message").html("Successfully created site.").show().fadeOut(6000)){
								$('#maincontent').mask('Processing request, please wait...');
								$.when(usb_enable(), build_nav_object(),update_gcp5k_flag()).done(function(){
									remove_v_preload_page();
									reload_page();
									$('.message_container span').addClass("success_message").html("Successfully created site.").show().fadeOut(6000);
								});
							}
						}
					}
					//////////////////////////////////////////////////////////////////////////////////////////
					//load_page("","/selectsite/index");
				}else{
					var selected_site_type = $('input[name="new_site_type"]:checked', '#').val();
					var mcfname_and_mcfcrc = resp.split('|');
					var mcfname_and_mcfcrc_tooltip = "MCF Name: "+mcfname_and_mcfcrc[0]+" ; MCFCRC: "+mcfname_and_mcfcrc[1];
					$("#template_mcfname_mcfcrc").attr('mcf_name',mcfname_and_mcfcrc[0]);
					$("#template_mcfname_mcfcrc").attr('mcfcrc',mcfname_and_mcfcrc[1]);
					$("#template_mcfname_mcfcrc").attr('mcf_location',mcfname_and_mcfcrc[2]);
					if(selected_site_type == "create_new_site"){
						$("#selected_template").attr('title', mcfname_and_mcfcrc_tooltip);
					}else{
						$("#selected_pac").attr('title', mcfname_and_mcfcrc_tooltip);	
					}					
					var all_gcp_mcf_name_and_mcfcrc = $("#all_gcp_mcf_name_and_mcfcrc").val();
					var array_mcfname_and_mcfcrc = all_gcp_mcf_name_and_mcfcrc.split('||');
					var found_db = false;
					for(var i=0;i< array_mcfname_and_mcfcrc.length-1;i++){
						var crc = array_mcfname_and_mcfcrc[i].split('|');
						if (crc[1].toUpperCase() == mcfname_and_mcfcrc[1]){
							$('#selected_site_mcf option').each(function(){
				            	if(this.text == crc[0]){
				            		this.selected = true;
									found_db = true;
									$("#selected_mcfCRCValue").attr('mcf_location', mcfname_and_mcfcrc[2]);
									return true;
				            	}    
							});		
						}
					}
					$("#selected_mcfCRCValue").val(mcfname_and_mcfcrc[1]);
					$('#upload_selected_mcf').removeAttr("disabled");
					$("#selected_mcfCRCValue").removeAttr("disabled");
					$("#cancel_uplaod_selected_mcf").removeAttr("disabled");
					$("#selected_mcfcrc_validation").html("");
					if (!found_db) {
						$('#selected_site_mcf').val("Select MCF");
						$("#selected_mcfCRCValue").val("");
						$('#selected_site_mcf').removeAttr("disabled");
						$("#mcffileUpload").removeAttr("disabled");
						$("#selected_mcfCRCValue").removeAttr("disabled");
						$('#upload_selected_mcf').attr("disabled", true);
						$("#cancel_uplaod_selected_mcf").attr("disabled", true);
						if($('#create_new_site:checked').length == 1){
							$("#selected_mcfcrc_validation").html("MCF is not available in repository. Please select MCF");
						}
					}
					$(".loader").hide();

					//is cleared so if the user selects the same file it will be detected on change
					//$("#uploadPacFile").val('');
					//$("#uploadTemplateFile").val('');
					//todo: this needs changes in the controller to work because right now it needs the file to be uploaded again on create
				}
		    }
		};
        $(this).ajaxSubmit(form_submit);
		return false; 
	});
	
	$("#selected_site_mcf").w_change(function(){
		var selected_mcf = document.getElementById('selected_site_mcf').selectedIndex;
		document.getElementById('selected_mcfCRCValue').value = "";
		if (selected_mcf != -1) {
			get_mcfcrc_value();
		}else {
			document.getElementById("selected_mcfcrc_validation").innerHTML = "Please select MCF file";
			return false;
		}
	});
	

	$(".cancel_uplaod_selected_mcf").w_click(function(){
		$.fn.colorbox.close();
		$("#maincontent").mask("Removing back-up files, please wait...");
        $.post('/selectsite/removesite', {
            selected_folder: "true"
        }, function(resp){
            $('#leftnavtree').html('');
            $('#configurationeditorcontent').hide();
            //$('#removemessagesuccess').html(resp);
            $("#maincontent").unmask("Removing back-up files, please wait...");
            remove_v_preload_page();
            reload_page();
        });
	});
});

function check_selected_template(){
	$(".loader").show();
	var selected_template_path = document.getElementById("uploadTemplateFile").value;
	var valid = selected_template_path.split('.');
	var validname;
	if (navigator.appName == "Microsoft Internet Explorer") {
		 validname = selected_template_path.split("\\");
	}else{
		validname = selected_template_path.split('/');
		if (validname.length == 1){
			validname = validname[0].split("\\");
		}
	}
	var filename = validname[validname.length-1];
	var validmcf = valid[valid.length-1];
	if ((validmcf == "tpl")|| (validmcf == "TPL")) {
		if (selected_template_path != null && selected_template_path != '') {
			$.post('/selectsite/get_template_list', {
				// no params
			}, function(response){
				$("#selected_template >option").remove();
				$("#selected_template").append($('<option></option>').val('Not Used').html('Not Used'));
				document.getElementById("uploaded_template_path").value = selected_template_path;
				$("#selected_template").append($('<option></option>').val(selected_template_path).html(filename));
				if (response.length > 0) {
					var arrayoftemplates = response.split('||');
					for (var i = 0; i < arrayoftemplates.length - 1; i++) {
						var value_and_name = arrayoftemplates[i].split('|');
						$('#selected_template').append($('<option></option>').val(value_and_name[0]).html(value_and_name[1]));
					}
				}
				document.getElementById("selected_template").focus();					
				document.getElementById('selected_template').selectedIndex = 1;
				$('#form_upload_site_mcf_file').attr('action', '/selectsite/template_readmcfcrc');
				$('#form_upload_site_mcf_file').submit();
	        });
		}
	}else{
		$(".loader").hide();
		alert("Please select Template file only");
	}
}

function check_selected_pac(){
	$(".loader").show();
	var selected_pac_path = document.getElementById("uploadPacFile").value;
	var valid = selected_pac_path.split('.');
	var validname;
	if (navigator.appName == "Microsoft Internet Explorer") {
		 validname = selected_pac_path.split("\\");
	}else{
		validname = selected_pac_path.split('/');
		if (validname.length == 1){
			validname = validname[0].split("\\");
		}
	}
	var filename = validname[validname.length-1];
	var validmcf = valid[valid.length-1].toLowerCase();
	if ((validmcf == "pac")|| (validmcf == "tpl")) {
		if (selected_pac_path != null && selected_pac_path != '') {
			$.post('/selectsite/get_pac_file_list', {
				// no params
			}, function(response){
				$("#selected_pac >option").remove();
				$("#selected_pac").append($('<option></option>').val('Select PAC/TPL File').html('Select PAC/TPL File'));
				document.getElementById("uploaded_pac_path").value = selected_pac_path;
				//* is used to identify a new file that was uploaded
				$("#selected_pac").append($('<option></option>').val(selected_pac_path+"*").html(filename));
				if (response.length > 0) {
					var arrayoftemplates = response.split('||');
					for (var i = 0; i < arrayoftemplates.length - 1; i++) {
						var value_and_name = arrayoftemplates[i].split('|');
						$('#selected_pac').append($('<option></option>').val(value_and_name[0]).html(value_and_name[1]));
					}
				}
				
				document.getElementById("selected_pac").focus();					
				document.getElementById('selected_pac').selectedIndex = 1;
				$('#form_upload_site_mcf_file').attr('action', '/selectsite/template_readmcfcrc');
				$('#form_upload_site_mcf_file').submit();
	        });
		}
	}else{
		$(".loader").hide();
		alert("Please select PAC/TPL file only");
	}
}
	
function check_selected_mcf(){	
    $(".loader").show();
	var select_mcf_path = document.getElementById("mcffileUpload").value;
	var valid = select_mcf_path.split('.');
	var validname;
	if (navigator.appName == "Microsoft Internet Explorer") {
		 validname = select_mcf_path.split("\\");
	}else{
		validname = select_mcf_path.split('/');
		if (validname.length == 1){
			validname = validname[0].split("\\");
		}
	}
	var filename = validname[validname.length-1];
	var validmcf = valid[valid.length-1];
	document.getElementById('selected_mcfCRCValue').value ="";
	document.getElementById("selected_mcfcrc_validation").innerHTML = "";
	if ((validmcf == "mcf")|| (validmcf == "MCF")) {
		if (select_mcf_path != null && select_mcf_path != '') {
			$.post('/selectsite/get_mcf', {
				typeofsystem 		: $("#hd_site_type").val()
			}, function(response){
				$("#selected_site_mcf >option").remove();
				$("#selected_site_mcf").append($('<option></option>').val('Select MCF').html('Select MCF'));
				document.getElementById("uploaded_mcf_path").value = select_mcf_path;
				$("#selected_site_mcf").append($('<option></option>').val(select_mcf_path).html(filename));
				if (response.length > 0) {
					 var valarray = response.split('|');
					for (var i = 1; i < (valarray.length); i++) {
						var mcf_file_name ;
						if (navigator.appName == "Microsoft Internet Explorer") {
							 mcf_file_name = valarray[i].split("\\");
							 if (mcf_file_name.length == 1) {
							 	mcf_file_name = valarray[i].split('/');
							 }
						}else{
							mcf_file_name = valarray[i].split('/');
							if (mcf_file_name.length == 1){
								mcf_file_name = mcf_file_name[0].split("\\");
							}
						}
						$('#selected_site_mcf').append($('<option></option>').val(valarray[i]).html(mcf_file_name[mcf_file_name.length - 1]));
					}
				}
				$(".loader").hide();	
				document.getElementById("selected_site_mcf").focus();					
				document.getElementById('selected_site_mcf').selectedIndex = 1;
				$("#selected_site_mcf").change();
				document.getElementById('selected_mcfCRCValue').focus();				
	        });
		}
	}else{
		$(".loader").hide();
		alert("Please select mcf file only");
	}
}

function get_mcfcrc_value(){
	$(".loader").show();
	var site_type = $("#hd_site_type").val();
	document.getElementById("selected_mcfCRCValue").disabled = false;
	document.getElementById('selected_mcfCRCValue').value = "";
	document.getElementById("upload_selected_mcf").disabled = true;
	document.getElementById("cancel_uplaod_selected_mcf").disabled = true;
	document.getElementById("selected_mcfcrc_validation").innerHTML = "";

	var selected_mcf = document.getElementById('selected_site_mcf').options[document.getElementById('selected_site_mcf').selectedIndex].value;
	if (selected_mcf == "Select MCF") {
		$(".loader").hide();
		document.getElementById("selected_mcfCRCValue").disabled = true;
		document.getElementById("upload_selected_mcf").disabled = false;
		document.getElementById("cancel_uplaod_selected_mcf").disabled = false;
	}else{
		$.post('/selectsite/get_mcfcrc', {
			mcf_path: selected_mcf,
			typeofsystem 		: site_type
		}, function(response){
			var mcfcrc = response.mcfcrc;			
			if ((mcfcrc != "") || (mcfcrc != null)) {
				document.getElementById('selected_mcfCRCValue').value = mcfcrc;
			}else {
				document.getElementById('selected_mcfCRCValue').value = "";
			}
			$("#selected_mcfCRCValue").attr('mcf_location',response.mcf_location);
			$(".loader").hide();
			document.getElementById("upload_selected_mcf").disabled = false;
			document.getElementById("cancel_uplaod_selected_mcf").disabled = false;
		});
	}
}

function validate_crc_value(type_crc_validate){
	var crc_value_to_validate = "";
	var type_crc_string = "";
	if (type_crc_validate == "MCF"){
		crc_value_to_validate = document.getElementById("selected_mcfCRCValue").value;
		type_crc_string = "MCF";	
	}
	var crc_value = 0; 
	var hexavalue = new Array();
	hexavalue = crc_value_to_validate.toLowerCase().split('x');
	if ((hexavalue.length >1) && (hexavalue.length <3)){
		crc_value = hexavalue[1];
	}else if (hexavalue.length == 1){
		crc_value = hexavalue[0];
	}
	if (hexavalue.length > 2) {
		document.getElementById("selected_mcfcrc_validation").innerHTML = "Please enter hexadecimal number only";
		return false;
	}else {
		if (crc_value == "" || crc_value_to_validate == "") {
		   document.getElementById("selected_mcfcrc_validation").innerHTML = "Please enter valid "+type_crc_string+" CRC value";
		   return false;
		}else {
			if (crc_value.length > 0) {
				var objPattern = /^[0-9A-Fa-f]+$/i;
				if (!(objPattern.test(crc_value))) {
					document.getElementById("selected_mcfcrc_validation").innerHTML = type_crc_string + " CRC,Please enter hexadecimal number only";
					return false;
				}else {
					if (crc_value.length <= 8) {
						document.getElementById("selected_mcfcrc_validation").innerHTML = "";
						return true;
					}else {
						document.getElementById("selected_mcfcrc_validation").innerHTML = "Maximum length of " + type_crc_string + " CRC is 8";
						return false;
					}
				}
			}else {
				document.getElementById("selected_mcfcrc_validation").innerHTML = "Please enter valid " + type_crc_string + " CRC value";
				return false;
			}
		}
	}
}