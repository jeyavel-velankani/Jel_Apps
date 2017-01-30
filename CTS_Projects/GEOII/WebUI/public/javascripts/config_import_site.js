/**
 * @author Jeyavel Natesan
 */

 add_to_destroy(function(){
	$(document).unbind("ready");
	
	//kills all wrapper events
	$("#site_config_import_form").w_die('submit');
	$("#upload_siteconfig_zip").w_die('change');
	$(".cancel_import_selected_site_config").w_die('click');
	$(".import_selected_site_config").w_die('click');
});

$(document).ready(function() {
	$("#upload_siteconfig_zip").w_change(function() {
		$('.loader').show();
		document.getElementById('import_selected_site_config').disabled = true;
		$("#gcp_site_name").css("border", "1px solid #888");
		$("#gcp_site_name").val("");
		$("#div_gcp_site_name").hide();		
		document.getElementById("error_message").innerHTML = "";
		var select_zip_path = $(this).val();
		$("#selected_imported_file").val(select_zip_path);
		$('#hd_gcp_site_name').attr('value',"");
		var validname;
		if (navigator.appName == "Microsoft Internet Explorer") {
			 validname = select_zip_path.split("\\");
		}else{
			validname = select_zip_path.split('/');
			if (validname.length == 1){
				validname = validname[0].split("\\");
			}
		}
		select_zip_path = validname[validname.length-1];
		var valid = select_zip_path.split('.');
		var validzip = valid[valid.length - 1];
		var site_name = "";
		$('#site_config_import_form').attr('action', '/selectsite/select_import_files');
		if (select_zip_path != null && select_zip_path != '') {
			if ((validzip == "zip") || (validzip == "ZIP")) {
				$('#site_config_import_form').attr('action', '/selectsite/check_import_zip_content');
				$('#site_config_import_form').submit();
			}else if ((validzip == "pac") || (validzip == "PAC") || (validzip == "tpl") || (validzip == "TPL")) {
				$('#hd_gcp_site_name').attr('value',"GCP");
				$("#div_gcp_site_name").show();
				document.getElementById('import_selected_site_config').disabled = false;
				$.post('/selectsite/update_sitename/',{
					filename : select_zip_path,
					site_type : "GCP"
		        },function(resp){
					$("#gcp_site_name").attr('value',resp.sitename);
					$('.loader').hide();	
				});			    
			}else {
				$('.loader').hide();
				document.getElementById("error_message").innerHTML = "Please select zip, PAC or TPL file only";
			}
		}else{
			$('.loader').hide();
			document.getElementById("error_message").innerHTML = "Invalid file path";
		}
	});
	
	$('#site_config_import_form').submit(function() {
		remove_v_preload_page();
	 	var options = {
          success: function(resp_importmsg){
          	var importmsg = resp_importmsg.split('|');
			if(importmsg[0] == "NotValidGCP"){
				$('#hd_gcp_site_name').attr('value',"");
				$('#site_config_import_form').attr('action', '/selectsite/select_import_files');
			 	var select_zip_path = $("#selected_imported_file").val();
				var validname;
				if (navigator.appName == "Microsoft Internet Explorer") {
					 validname = select_zip_path.split("\\");
				}else{
					validname = select_zip_path.split('/');
					if (validname.length == 1){
						validname = validname[0].split("\\");
					}
				}
				select_zip_path = validname[validname.length-1];
				var valid = select_zip_path.split('.');
				var validzip = valid[valid.length - 1];
				var site_name = "";
			 	if ((validzip == "zip") || (validzip == "ZIP")) {
					var split_by_config = select_zip_path.split('Config-');
					if(split_by_config.length >1){
						var spilt_name = split_by_config[1].split('-');
						if(spilt_name.length >= 3 ){
							for (var ind = 0; ind <=(spilt_name.length-3); ind++){
								if (site_name == ""){
									site_name = spilt_name[ind];
								}else{
									site_name = site_name + "-" + spilt_name[ind];
								}
							}						
						}
					}else{
						site_name = select_zip_path.slice(0, select_zip_path.lastIndexOf(validzip)-1);
					}
					if(site_name.length > 20){
						site_name = site_name.slice(0,20);
					}
					var objPattern = /^[0-9A-Za-z_-]+$/i;
					if ((!objPattern.test(site_name)) || (site_name == "")){
						document.getElementById("error_message").innerHTML = "Configuration file name contains invalid characters in site name.";
					}else{
						document.getElementById('import_selected_site_config').disabled = false;
						$.post("/selectsite/check_importsitename", {
							sitename: site_name
						}, function(data){
							$('.loader').hide();
							if (data == "override") {
								document.getElementById("error_message").innerHTML = "Already have '" + site_name + "' site configuration.Do you want to override? ";
							}else {
								document.getElementById("error_message").innerHTML = "";
							}
						});
					}
				}
			}else if(importmsg[0] == "ValidGCP"){
				document.getElementById('import_selected_site_config').disabled = false;
				$('#hd_gcp_site_name').attr('value',"GCP");
				$('#site_config_import_form').attr('action', '/selectsite/select_import_files');
		  		$("#div_gcp_site_name").show();
		  		var select_zip_path = $("#selected_imported_file").val();
		  		var validname;
				if (navigator.appName == "Microsoft Internet Explorer") {
					 validname = select_zip_path.split("\\");
				}else{
					validname = select_zip_path.split('/');
					if (validname.length == 1){
						validname = validname[0].split("\\");
					}
				}
				select_zip_path = validname[validname.length-1];
				$.post('/selectsite/update_sitename/',{
					filename : select_zip_path,
					site_type : "GCP"
		        },function(resp){
					$("#gcp_site_name").attr('value',resp.sitename);
					$('.loader').hide();	
				});		
		  	}else{
		  		$.fn.colorbox.close();
		  		$('.loader').hide();
			  	if (importmsg[0] == "error") {
				 if (importmsg[2] != "") {
				 	alert(importmsg[2]);
				 	$("#maincontent").mask("Removing back-up files, please wait...");
					$.post('/selectsite/removesite',{selected_folder: "true"},function(resp){
						$('#leftnavtree').html('');
						$('#configurationeditorcontent').hide();
						//$('#removemessagesuccess').html(resp);
						$("#maincontent").unmask("Removing back-up files, please wait...");
						remove_v_preload_page();
				    	reload_page();
					});
				 }
				}else if(importmsg[0]=="success"){
			  		if (typeof importmsg[1] != 'undefined' && importmsg[1] != null) {
			  			$('#maincontent').mask('Loading contents, please wait...');
			  			load_selected_configuration(importmsg[1], "");
			  		}else {
			  			load_page("Configuration Editor", "/selectsite/index?importmsg=" + resp_importmsg);
			  		}
			  	}else {
			  			load_page("Configuration Editor", "/selectsite/index?importmsg=" + resp_importmsg);
			  	}
		  	}
		  }
     	};
     	$(this).ajaxSubmit(options);
     	return false; 
  	});
	
	$(".import_selected_site_config").w_click(function(){
		document.getElementById('import_selected_site_config').disabled = false;			
		var select_path = $("#selected_imported_file").val();
		if (select_path == null || select_path == "") {
			document.getElementById("error_message").innerHTML = "Please browse file and try again";
		}else {
			var gcp_site_name  = $("#gcp_site_name").val();
			var gcp_site_name_validate_flag = $('#hd_gcp_site_name').val();
			if(gcp_site_name_validate_flag == null || gcp_site_name_validate_flag == ""){
				document.getElementById('import_selected_site_config').disabled = true;
				$('.loader').show();
	            $("#gcp_site_name").css("border", "1px solid #888");
	            $("#site_config_import_form").submit();
			}else{  
				var objPattern = /^[0-9A-Za-z \w{(),\]\[&~`!@#$%^_-}+;=-]+$/i;
				if ((gcp_site_name != null) && (gcp_site_name != "")) {
		            if (!objPattern.test($("#gcp_site_name").val())) {
		                $("#gcp_site_name").css("border", "1px solid red");
		                document.getElementById("error_message").innerHTML = "Configuration file name contains invalid characters in site name.";
		            }else if(($("#gcp_site_name").val().indexOf('|')!= -1)) {
					    $("#gcp_site_name").css("border", "1px solid red");
		                document.getElementById("error_message").innerHTML = "Configuration file name contains invalid characters in site name.";	
					}else{
						document.getElementById("error_message").innerHTML = "";
						document.getElementById('import_selected_site_config').disabled = true;
						$("#gcp_site_name").css("border", "1px solid #888");
						$('.loader').show();
		                $("#site_config_import_form").submit();
		            }
		        }else{
		        	document.getElementById("error_message").innerHTML = "Please enter site name and try again.";
		        }
	        }
		}
	});
	
	$(".cancel_import_selected_site_config").w_click(function(){
		$.fn.colorbox.close();
	});	
	
    $("#gcp_site_name").w_keyup(function(){
        document.getElementById("error_message").innerHTML = "";
        var objPattern = /^[0-9A-Za-z \w{(),\]\[&~`!@#$%^_-}+;=-]+$/i;
        if (($("#gcp_site_name").val() != null) && ($("#gcp_site_name").val() != "")) {
            if (!objPattern.test($("#gcp_site_name").val())) {
                $(this).css("border", "1px solid red");
                document.getElementById("error_message").innerHTML = "Configuration file name contains invalid characters in site name.";
            }
            else if(($("#gcp_site_name").val().indexOf('|')!= -1)) {
			    $(this).css("border", "1px solid red");
                document.getElementById("error_message").innerHTML = "Configuration file name contains invalid characters in site name.";	
			}else{
                $(this).css("border", "1px solid #888");
                document.getElementById("error_message").innerHTML = "";
            }
        }
    });			
});