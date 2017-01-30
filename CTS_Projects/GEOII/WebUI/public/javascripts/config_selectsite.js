/**
 * @author Jeyavel Natesan
 */

add_to_destroy(function(){
	$(document).unbind("ready");
	
	//kills all wrapper events
	$("#yourFieldName").w_die('keyup');
	$('#submenu1 ul li a').w_die('click');
	$("#masterGeoptclocation").w_die('change');
	$("#installation").w_die('change');
	$("#mcfCRCValue").w_die('change');
	
	$('.load_config').w_die('click');
	$('#copytousb').w_die('click');
	$('#create_template').w_die('click');
	$('.site_conf_close_remove').w_die('click');
	$('.upload_config').w_die('click');
	$("#export_hd_mcfs").w_die('click');

	//clear functions 
	delete window.select_mcf_file_dialog;
	delete window.load_selected_configuration;
	delete window.create_rc2keyfile_dialog;
	delete window.saveas_site;
	delete window.open_site_config;
	delete window.save_site_config;
	delete window.createsitename;
	delete window.check;
	delete window.masterdb_select;
	delete window.installation_select;
	delete window.hidetheselect;
	delete window.build_site_config;
	delete window.export_enable_and_disable;
	delete window.remove_enable_and_disable;
	delete window.validate;
	delete window.enable_disable_create_rc2key;
	delete window.site_conf_load_page;
	delete window.downloadURL;
	delete window.export_site_config;
	delete window.crc_validate;
	delete window.submenu1;
	delete window.sitesubmenu;
	delete window.create_gcp_template;
	
	$('#submenu1').remove();
	$('#sitesubmenu').remove();
	$('#reportsubmenu').remove();
	$('#createbuildsubmenu').remove();
		
	$('.anylinkshadow').remove();
	$('.anylinkcss').remove();
});

$(document).ready(function() {
	setTimeout(function(){
		$('#create_site').addflexmenu('submenu1');
		$('#manage_site').addflexmenu('sitesubmenu');
		$('#config_report').addflexmenu('reportsubmenu');
		$('#build_site_config').addflexmenu('createbuildsubmenu');
	},500);

	site_conf_load_page();
	$("#yourFieldName").w_keyup(function() {
		var objPattern = /^[0-9A-Za-z_-]+$/i;
		if (($("#yourFieldName").val() != null) && ($("#yourFieldName").val() != "")) {
			if (!objPattern.test($("#yourFieldName").val()))
				$(this).css("border", "1px solid red");
			else {
				$(this).css("border", "1px solid #888");
			}
		} else {
			$(this).css("border", "1px solid #888");
		}
	});

	$('#submenu1 ul li a').w_click(function() {
		window.parent.document.getElementById("mainheader").innerHTML = "";
	});
	
	$("#masterGeoptclocation").w_change(function() {
		masterdb_select(false, "");		
	});

	$("#installation").w_change(function() {
		installation_select();
	});
	
	$("#mcfCRCValue").w_change(function() {
		if(crc_validate("MCF", false)){
			document.getElementById("in_crc1").innerHTML = "";
		}
	});
	
	$('.load_config').w_click(function(event){
		remove_v_preload_page();
	    if (!$(this).hasClass('disable')) {
			$('.ajax-loader').show();
			event.preventDefault();
			var url = $(this).attr('href');
			var title = $(this).attr('title');
			var comment_flag = comments_info();
			if (title == null) {
				title = '';
			}
		    if (comment_flag == true ||comment_flag == 'true') {
				if (url != null) {
					$('#leftnavtree').html('');
					load_page(title, url);
				}
				load_content_flag = false;
				setTimeout('build_vital_config_object("Configuration")', 3000);
			}else{
			   	ConfirmDialog('Comments','Comments are not saved.<br>Would you like to leave?',function(){
	           		if (url != null) {
						$('#leftnavtree').html('');
						load_page(title, url);
					}
				    load_content_flag = false;
				    setTimeout('build_vital_config_object("Configuration")', 3000);
	       		},function(){
	 	    		$('.ajax-loader').hide();
	         		//don't load the next page
	       		});
	    	}
		}
	});
	
	$('.upload_config').w_click(function(event){
	        $('.ajax-loader').show();
	        event.preventDefault();
	        var url = $(this).attr('href');
	        var title = "Aspect Lookup";
	        if(title == null){
	            title = '';
	        }
	        if(url != null){
	           load_page(title,url);
	        }
	    
	});
	
	$('#copytousb').w_click(function(){
	   var comment_flag = comments_info();
	   if (comment_flag == true || comment_flag == 'true') {
	   	export_site_config();
	   }
	   else{
	   	 ConfirmDialog('Comments','Comments are not saved.<br>Would you like to leave?',function(){
           export_site_config();
	       },function(){
	 	    $('.ajax-loader').hide();
	         //don't load the next page
	       });
	    }
	});

	$("#export_hd_mcfs").w_click(function(){
		$.post('/gcp_programming/hd_dl_all_create/',{
			menu_link:'Vital Comms Link 1'
		},function(check_resp){
			if(check_resp == 'false' || !check_resp){
				$('#buildcheck12').html('Error creating zip file');
			}else if(check_resp == 'blank'){
				$('#buildcheck12').html('There are no HD MCFs created');
			}else{
				if(check_resp != ''){
					downloadURL('/gcp_programming/hd_dl_all?name='+check_resp);	
				}else{
					$('#buildcheck12').html('Error creating zip file');
				}
			}
		});
	});
	
	$('.site_conf_close_remove').w_click(function() {
		remove_v_preload_page();
		var site_status = document.getElementById("site_status").value;
		var id = $(this).attr('id'); 
		var refresh_page;
		var comment_flag = comments_info();
		if (site_status == "Available") {
			if(id == 'close_site_config'){
			   refresh_page = 2;
			   if(comment_flag == true || comment_flag == 'true'){
		  			$('#leftnavtree').html('');
					reload_page({'refresh_page':refresh_page});
			   }else{
		   			ConfirmDialog('Comments','Comments are not saved.<br>Would you like to leave?',function(){
						$('#leftnavtree').html(''); 
						reload_page({'refresh_page':refresh_page});
	       			},function(){
	 	    			$('.ajax-loader').hide();
	         			//don't load the next page
	       			});
			   }
			}else if(id == 'remove_site_config'){
			   if (confirm("Do you want to remove current site?")) {
					refresh_page = 3;
					$('#leftnavtree').html('');
					reload_page({'refresh_page':refresh_page});
				}
			}			
		}else{
			refresh_page = 1;
			$('#leftnavtree').html('');
			reload_page({'refresh_page':refresh_page});
		}
	});
	
	//set gcp template
	$('#db_template').w_click(function(){
		var site_status = document.getElementById("site_status").value;
		var type_system = $('#systemtype').val();
		if ((site_status == "Available") && (type_system != "GEO")) {
			if (confirm("Current Non Vital configuration will be set as default template.\nDo you want to continue?")){
				$('.ajax-loader').show();
				$.post('/selectsite/copy_template',{typeOfSystem : type_system },function(resp){
					$('#removemessagesuccess').html(resp);
					$('.ajax-loader').hide();
				});
			}
		}
	});	
	
   $("#comment_text_area").w_keyup(function(){
   	  add_comments_popup();
   	  $('#update_comments').removeClass('disabled');
	  document.getElementById('update_comments').setAttribute('onclick', 'update_comments()');
   	});
});

function select_mcf_file_dialog() {
	var sitename = $("#yourFieldName").val();
	var typeofsystem = $("#hd_typeOfSystem").val();
	var nv_version = $("#hd_nv_version").val();
	
	if (sitename) {
		var validsitename = document.getElementById("sitemsginfo").value;
		if (validsitename != "Success") {
			alert("Please correct site name error and try again.");
			return false;
		} else {
			$.fn.colorbox({
				href : "selectsite/select_mcf_file?typeofsystem=" + encodeURIComponent(typeofsystem) + "&nv_ver=" + encodeURIComponent(nv_version)
			});
		}
	} else {
		alert("Please enter site name and try again.");
		return false;
	}
}


function load_selected_configuration(selected_folder, saveasflag){
	$(".loader").show();
	var filename = selected_folder.split("/").pop();
	$.post("/site/selectsiteconfig", {
		open_path_name: selected_folder,
		saveasflag : saveasflag
	}, function(response_data){
		if(response_data.valid_site != 'valid'){
			$('#cboxClose').click();
			remove_v_preload_page();
			if (confirm(filename + ' - ' + response_data.valid_site + ' Do you want to delete it?')){
				$("#maincontent").mask("Deleting site configuration, please wait...");
				$.post('/selectsite/removesite',{selected_folder: selected_folder},function(resp){
					$('#leftnavtree').html('');
					$('#configurationeditorcontent').hide();
					$('#removemessagesuccess').html(resp);
					$("#maincontent").unmask("Deleting site configuration, please wait...");
				});
			}
		}else{
			remove_v_preload_page();
			enable_disable_create_rc2key("disable");
			$('#configurationeditorcontent').show();
			$('#check').html('');
			$('#checkMasterdb').html('');
			document.getElementById("buildcheck").innerHTML = "";
			document.getElementById("yourFieldName").disabled = true;
			document.getElementById("masterGeoptclocation").disabled = false;
			document.getElementById("installation").disabled = false;
			document.getElementById("mcfCRCValue").disabled = false;
			document.getElementById("in_crc1").innerHTML = "";
			$('#config_report').hide();
			$('#site_config_report').hide();
			$('#geoptc_site_config_report').hide();
			export_enable_and_disable("disable");
			var btnreport = '';
			var btnenable = '';
			var enablereport = '';
			var exportflag = '';
			$('#masterdb').show();
			$('#divinstallationname').show();
			$('#commenttext').hide();
			$('#template_checkbox').hide();
			$('#template_name').hide();
			product = response_data.typeOfSystem;
			$(".display_information").html("<input type='hidden' id='hd_aspect_available_flag' value='true'/>").hide();
			if (response_data.typeOfSystem == 'iVIU PTC GEO') {
				if(response_data.aspect_file_error){
					var error_message = response_data.aspect_file_error; 
					error_message += "<input type='hidden' id='hd_aspect_available_flag' value='false'/><a href='/aspectlookup/index' class = 'upload_config'><img src='/images/upload.png'/></a>";
					$(".display_information").html(error_message).show();
				}
				cpu_3_menu_system_flag = false;
				ptc_enabled_flag = true;
				$('#masterdb').show();
				$('#divinstallationname').show();
				$('#systemtype').attr('value', response_data.typeOfSystem);
				$('#hd_typeOfSystem').attr('value', response_data.typeOfSystem);
				$('#yourFieldName').attr('value', response_data.cfgLocationconpath);
				var found_db = false;
				$('#masterGeoptclocation option').each(function(){
	            	if(this.text == response_data.selmasterdb){
	                	this.selected = true;
						found_db = true;
						return true;
	            	}    
				});
				
				if (!found_db) {
					$('#masterGeoptclocation').val("Select Master DB");
				}
					
				if (response_data.selMasterdbInfo.length > 0){
					$("#checkMasterdb").html(response_data.selMasterdbInfo).css({"color":"#FF0000"});
				}
				masterdb_select(true, response_data.selectedinstallationname);					
				
				document.getElementById('lblmcfname').innerHTML = 'iVIU MCF';
				$('#mcfname').attr('value', response_data.mcfnamefromselected);
				$('#mcfCRCValue').attr('value', response_data.mcfCRCValue);
				btnenable = response_data.save;
				btnreport = response_data.reportflag;
				exportflag = response_data.exportflag;
				enablereport = response_data.geoptcreportflag;
				if (response_data.siteptc_upgrade_msg) {
					var strmessage = response_data.siteptc_upgrade_msg;
					if (strmessage.search("Error:")== 0) {
						document.getElementById("buildcheck").innerHTML ="";
						document.getElementById("buildcheckerror").innerHTML = strmessage;
					}else if(strmessage.search("Warning:")== 0)  {
						document.getElementById("buildcheckerror").innerHTML = "";
						document.getElementById("buildcheck").style.color = "#CFD638";
						document.getElementById("buildcheck").innerHTML = strmessage;
					}
				}
				window.parent.document.getElementById("mainheader").innerHTML = "";
				window.parent.document.getElementById("mainheader").innerHTML = "Site Name: " + response_data.s_name + "| ATCS Address: " + response_data.atcs_address + "| Mile Post: " + response_data.m_post + "| DOT Number: " + response_data.dot_num;
			} else {
				ptc_enabled_flag = false;
				cpu_3_menu_system_flag = false;
				$('#masterdb').hide();
				$('#divinstallationname').hide();
				$('#systemtype').attr('value', response_data.typeOfSystem);
				$('#hd_typeOfSystem').attr('value', response_data.typeOfSystem);
				$('#yourFieldName').attr('value', response_data.cfgLocationconpath);
				$('#mcfname').attr('value', response_data.mcfnamefromselected);
				$('#mcfCRCValue').attr('value', response_data.mcfCRCValue);
				if (response_data.typeOfSystem == 'iVIU') {
					document.getElementById('lblmcfname').innerHTML = 'iVIU MCF';
				}else if (response_data.typeOfSystem == 'VIU'){
					document.getElementById('lblmcfname').innerHTML = 'VIU MCF';
				}else if (response_data.typeOfSystem == 'GEO') {
					document.getElementById('lblmcfname').innerHTML = 'GEO MCF';
				}else if (response_data.typeOfSystem == 'GCP') {
					 $('#commenttext').show();
			        $('#update_comments').addClass('disabled');
			        document.getElementById('update_comments').removeAttribute('onclick');
					 $('#update_comments').addClass('disabled');
			         document.getElementById('update_comments').removeAttribute('onclick');
					document.getElementById('lblmcfname').innerHTML = 'GCP MCF';
					 $('#comment_text_area').attr('value', response_data.gcp_comments);				   
				}else if (response_data.typeOfSystem == 'CPU-III') {
					cpu_3_menu_system_flag = true;
					document.getElementById('lblmcfname').innerHTML = 'CPU-III MCF';
				}
				btnenable = response_data.save;
				btnreport = response_data.reportflag;
				exportflag = response_data.exportflag;
				enablereport = response_data.geoptcreportflag;
				if (response_data.siteptc_upgrade_msg) {
					var strmessage = response_data.siteptc_upgrade_msg;
					if (strmessage.search("Error:")== 0) {
						document.getElementById("buildcheck").innerHTML ="";
						document.getElementById("buildcheckerror").innerHTML = strmessage;
					}else if(strmessage.search("Warning:")== 0)  {
						document.getElementById("buildcheckerror").innerHTML = "";
						document.getElementById("buildcheck").style.color = "#CFD638";
						document.getElementById("buildcheck").innerHTML = strmessage;
					}
				}
				window.parent.document.getElementById("mainheader").innerHTML = "";
				window.parent.document.getElementById("mainheader").innerHTML = "Site Name: " + response_data.s_name + "| ATCS Address: " + response_data.atcs_address + "| Mile Post: " + response_data.m_post + "| DOT Number: " + response_data.dot_num;
			}
			//remove_enable_and_disable("enable");
			if (exportflag == true){
				export_enable_and_disable("enable");
				$("#hd_export_flag").val('true');
			}else if (exportflag == false){
				export_enable_and_disable("disable");
				$("#hd_export_flag").val('false');
			}
			if (btnreport == true || btnreport == 'true') {
				$('#config_report').show();
				$('#site_config_report').show();
				$('#geoptc_site_config_report').show();
				if (enablereport == false || enablereport == 'false') {
					document.getElementById('geoptc_site_config_report').removeAttribute('href');
					document.getElementById('geoptc_site_config_report').style.color = "gray";
				}else{
					document.getElementById('geoptc_site_config_report').setAttribute('href', '/selectsite/sendgeoptclistiningreport');
					document.getElementById('geoptc_site_config_report').style.color = "white";
				}
			}else {
				$('#config_report').hide();
				$('#site_config_report').hide();
				$('#geoptc_site_config_report').hide();
			}
			if (btnenable == "save") {
				$('#btnsavecontent').show();
				$('#btnremovesite').hide();
				$('#build_site_config').hide();
		        $('#update_comments').hide();			
				$('#btselectmcffile').show();
			}
			else {
				$('#btnsavecontent').hide();
				$('#btnremovesite').hide();
				$('#build_site_config').show();
				if (response_data.typeOfSystem == 'GCP') {
					$('#update_comments').show();
				}	
				document.getElementById("mcfCRCValue").disabled = true;
				document.getElementById("yourFieldName").disabled = true;
				document.getElementById("masterGeoptclocation").disabled = true;
				document.getElementById("installation").disabled = true;
				$('#btselectmcffile').hide();
			}
			if(response_data.validate_nvconfig != 'valid'){
				if (confirm(response_data.validate_nvconfig + '\nDo you want to migrate to the latest?')){
					$.post('/selectsite/nvconfig_migration',{typeOfSystem: response_data.typeOfSystem},function(resp){
						$('#removemessagesuccess').html(resp);
					});
				}
			}
			$('#hd_current_site_type').attr('value', $('#systemtype').val());
			remove_enable_and_disable("enable");
			$.fn.colorbox.close();
			$('.ajax-loader').show();
			$('#leftnavtree').html('');
			$("#maincontent").mask("Loading contents, please wait...");
			$.when(ptc_enable(), usb_enable(), cpu_3_menu_system(), update_gcp5k_flag()).done(function (){
				build_nav_object();
				load_content_flag = true;
				build_vital_config_object("Configuration");			
				$('.ajax-loader').hide();
			});
		}
	});
}

function create_rc2keyfile_dialog() {
	$.fn.colorbox({ href : "selectsite/create_rc2keyfile"})
}

function saveas_site() {
	var comment_flag = comments_info();
	if (comment_flag == true || comment_flag == 'true') {
		$.fn.colorbox({href: "/saveas_site"});
	}
	else{
	   ConfirmDialog('Comments','Comments are not saved.<br>Would you like to leave?',function(){
         $.fn.colorbox({ href : "/saveas_site" });
	    },function(){
	 	  $('.ajax-loader').hide();
	      //don't load the next page
	    });	
	 }  	  
}

function create_gcp_template(){
	$("#maincontent").unmask("Processing request, please wait...");
	$.fn.colorbox({ href : "/create_gcp_template"});
}

function open_site_config() {
	var comment_flag = comments_info();
	if(comment_flag == true || comment_flag == 'true'){
	  $('#removemessagesuccess').html('');
	  $("#buildcheck").html('');
	  $("#buildcheckerror").html('');
	  $('#btselectmcffile').show();
	  $('#template_message').html('');
	  $.fn.colorbox({ href : "/open_site_config" });	
	}
	else{
	  ConfirmDialog('Comments','Comments are not saved.<br>Would you like to leave?',function(){
        $.fn.colorbox({ href : "/open_site_config" });
	  },function(){
	 	$('.ajax-loader').hide();
	  //don't load the next page
	 });
	}
}

function import_site_config(){
	var comment_flag = comments_info();
	if (comment_flag == true || comment_flag == 'true') {
		$('#removemessagesuccess').html('');
		$("#buildcheck").html('');
		$("#buildcheckerror").html('');
		$("#buildcheck12").html('');
		$.fn.colorbox({
			href: "/select_import_site"
		});
	}
	else {
		ConfirmDialog('Comments', 'Comments are not saved.<br>Would you like to leave?', function(){
			$.fn.colorbox({
				href: "/select_import_site"
			});
		}, function(){
			$('.ajax-loader').hide();
			//don't load the next page
		});
	}
}

function save_site_config() {
	if ($("#hd_aspect_available_flag").val() == 'true') {
		if (!validate()) {
			return false;
		}else {
			$('#maincontent').mask('Processing request, please wait...');
			//$('#contentcontents').mask('Processing request, please wait...');
			var sys_type = $("#hd_typeOfSystem").val();
			var mcfcrc = document.getElementById('mcfCRCValue').value;
			var comments = "";
			product = sys_type;
			if (sys_type == "GCP"){
				comments = document.getElementById('comment_text_area').value;
			}
			$.post("/selectsite/updateconfiguration", {
				typeofsystem: sys_type,
				mcfcrc: mcfcrc,
				comments : comments
			}, function(resp_data){
				var cont = "";
				if (typeof resp_data.error_message !== 'undefined' && resp_data.error_message !== null) {
					//$('#contentcontents').unmask('Processing request, please wait...');
					$('#maincontent').unmask('Processing request, please wait...');
				    alert(resp_data.error_message);
				}else {
					if (typeof resp_data.warning_message !== 'undefined' && resp_data.warning_message !== null) {
						cont = trim(resp_data.warning_message);
						intIndexOfMatch = 0;
						while (intIndexOfMatch != -1) {
							cont = cont.replace("<BR>", "\n");
							intIndexOfMatch = cont.indexOf("<BR>");
						}
					}
					if (resp_data.ptc_enable == 'true' || resp_data.ptc_enable == true) {
						ptc_enabled_flag = true;
					}else {
						ptc_enabled_flag = false;
					}
					if (cont != "") {
						if (!alert(cont)) {
							//$('#contentcontents').unmask('Processing request, please wait...');
							$('#maincontent').unmask('Processing request, please wait...');
							if ((cont.indexOf("Error") == -1) && (cont.indexOf("error") == -1)) {
								$.when(usb_enable(), build_nav_object(),update_gcp5k_flag()).done(function(){
									reload_page();
								});
							}
						}
					}else {
						if($('.message_container span').addClass("success_message").html("Successfully created site.").show().fadeOut(6000)){
							//$('#contentcontents').unmask('Processing request, please wait...');
							$('#maincontent').unmask('Processing request, please wait...');
							$.when(usb_enable(), build_nav_object(),update_gcp5k_flag()).done(function(){
								reload_page();
							});
						}
					}
				}
			});
		}
	}
}

function createsitename() {
	if (check()) {
		if (!validate_input()){
			return false;
		}
		var sys_type = $("#hd_typeOfSystem").val();
		var gcp_comment = "";
		var template_checked = "";
		var objPattern = /^[0-9A-Za-z_-]+$/i;
		$('#check').html('');
		$('#sitemsginfo').attr('value', "");
		var name = $("#yourFieldName").val();
		if (sys_type == "GCP"){
		  gcp_comment = $("#comment_text_area").val();
		  template_checked = document.getElementById("template_checkbox").checked;
		}
		if (($("#yourFieldName").val() != null) && ($("#yourFieldName").val() != "")) {
			if (objPattern.test($("#yourFieldName").val())) {
				if (name.length > 0) {
					if (document.getElementById("yourFieldName").disabled == false) {
						$(".sitenamespinner").show();
						$.post("/selectsite/createsitename", {
							sitename 		: name,
							typeofsystem 	: $("#hd_typeOfSystem").val(),
							comments        : gcp_comment,
							template_checked : template_checked
						}, function(data) {
							$(".sitenamespinner").hide();
							if (data.length > 0) {
								$('#sitemsginfo').attr('value', data);
								if (data != "Success") {
									$('#check').html(data);
								} else {
									select_mcf_file_dialog();
								}
							} else {
								$('#sitemsginfo').attr('value', data);
								$('#check').html('');
							}
						});
					} else {
						$('#sitemsginfo').attr('value', "Success");
						select_mcf_file_dialog();
					}
				} else {
					$(".sitenamespinner").hide();
					$('#check').html('Enter site name');
					$('#sitemsginfo').attr('value', 'Enter site name');
				}
			} else {
				$('#check').html('Please enter valid site name[only alpha numeric,_,-]');
				$('#sitemsginfo').attr('value', 'Please enter valid site name[only alpha numeric,_,-]');
				return false;
			}
		} else {
			$('#check').html('Enter site name');
			$('#sitemsginfo').attr('value', 'Enter site name');
			return false;
		}
	}
}

function check() {
	var sitename = document.getElementById("yourFieldName").value;
	if (sitename == '') {
		alert('Please enter the site name.');
		document.getElementById("yourFieldName").focus();
		return false;
	} else {
		var mcfname = document.getElementById("mcfname").value;
		if (mcfname.length > 0) {
			var confirmval = confirm("Already have the mcf '" + mcfname + "' Do you want to update with new mcf ?");
			if (confirmval) {
				return true;
			} else {
				return false;
			}
		} else {
			return true;
		}
	}
}

// Master db select: Populate the installation which are there in the selected master db. 
function masterdb_select(flg_inst_select, inst_name){
	var valuedb = $("#masterGeoptclocation").val();
	$("#masterGeoptclocation").attr('title', valuedb);
	if (valuedb == 'Select Master DB') {
		$("#checkinst").html('');
		$("#installation >option").remove();
		$('#installation').append($('<option></option>').val(0).html('Select GEO Installation'));
		return false;
	} else {
		$(".masterdbspinner").show();
		$.post("/selectsite/masterdbselected", {
			Masterdbselected 	: valuedb,
			typeofsystem 		: $("#hd_typeOfSystem").val()
		}, function(data) {
			$(".masterdbspinner").hide();
			$('#checkMasterdb').html('');
			$("#installation >option").remove();
			$('#installation').append($('<option></option>').val(0).html('Select GEO Installation'));
			var arrayinstallation = data.split(',');
			for (var i = 0; i < arrayinstallation.length - 1; i++) {
				$('#installation').append($('<option></option>').val(i + 1).html(arrayinstallation[i]));
			}
			var len = document.getElementById('installation').options.length;
			if (len > 1) {
				$("#checkinst").html('');
				if (flg_inst_select){
					$('#installation option').filter(function () {
				    	return $(this).text() === inst_name;
					}).prop('selected', true);
					installation_select();
				}
				return true;
			} else {
				$("#checkinst").html("GEO Installation Not available").css({"color":"#FF0000"});
				return false;
			}
		});
	}
}
// Validating selected installation
function installation_select() {
	$(".installationspinner").show();
	$("#checkinst").html('');
	var installationname = document.getElementById('installation').options[document.getElementById('installation').selectedIndex].text;
	if (installationname != "Select GEO Installation") {
		$.post("/selectsite/selectinstallationame", {
			installationname 	: installationname,
			typeofsystem 		: $("#hd_typeOfSystem").val(),
			Masterdbselected 	: $("#masterGeoptclocation").val()
		}, function(data) {
			$(".installationspinner").hide();
			var mcftype = data.split('|');
			if (mcftype[0] == "Non-Appliance Model" || mcftype[0] == "Appliance Model") {
				$("#checkinst").html(mcftype[0]).css({"color":"#339900"});
			} else {
				if (mcftype[0] == "Incomplete Installation") {
					$("#checkinst").html(mcftype[0]).css({"color":"#FF0000"});
				}
			}
		});
	} else {
		$(".installationspinner").hide();
	}
}

function hidetheselect() {
	var type = document.getElementById("systemtype").value;
	var saveremovesite = document.getElementById("saveremovesite").value;
	$('#configurationeditorcontent').hide();
	$('#btnsavecontent').hide();
	$('#btselectmcffile').show();
	remove_enable_and_disable("disable");
	$('#build_site_config').hide();
	export_enable_and_disable("disable");
	$('#config_report').hide();
	$('#site_config_report').hide();
	$('#geoptc_site_config_report').hide();
	$('#update_comments').hide();
	var x = $("#hd_report_config").val();
	var expt_flag = $("#hd_export_flag").val();
	var template_expt_flag = $("#hd_export_template_flag").val();
	var geoptcflag = $("#hd_geoptcreportflag").val();
	var site_name = $("#hd_site_name").val();
	if (expt_flag == 'true') {
		export_enable_and_disable("enable");
	} else if (expt_flag == 'false') {
		export_enable_and_disable("disable");
	}
	if (x == 'true') {
		$('#config_report').show();
		$('#site_config_report').show();
		$('#geoptc_site_config_report').show();
		if (geoptcflag == 'false') {
			document.getElementById('geoptc_site_config_report').removeAttribute('href');
			document.getElementById('geoptc_site_config_report').style.color = "gray";
		}
	} else {
		$('#config_report').hide();
		$('#site_config_report').hide();
		$('#geoptc_site_config_report').hide();
	}
	if (saveremovesite == "save") {
		$('#btnsavecontent').show();
		$('#btnremovesite').hide();
		$('#btselectmcffile').show();
		$('#configurationeditorcontent').show();
		if (document.getElementById("yourFieldName").value.length > 0) {
			remove_enable_and_disable("enable");
		}
		else
		{
			remove_enable_and_disable("disable");
		}
		document.getElementById("mcfCRCValue").disabled = false;
	}
	if (saveremovesite == "configure") {
		$('#btnsavecontent').hide();
		$('#btnremovesite').hide();
		$('#btselectmcffile').hide();
		$('#configurationeditorcontent').show();
		remove_enable_and_disable("enable");
		$('#build_site_config').show();
		document.getElementById("mcfCRCValue").disabled = true;
		if (type == "GCP") {
			$('#update_comments').show();
		}	
	}
	if (saveremovesite == "Remove") {
		$('#btnsavecontent').hide();
		$('#btnremovesite').show();
		$('#btselectmcffile').hide();
		$('#configurationeditorcontent').show();
		remove_enable_and_disable("disable");
		$('#build_site_config').hide();
		$('#update_comments').hide();	

	}
	if (saveremovesite.length == 0) {
		$('#btnsavecontent').hide();
		$('#btnremovesite').hide();
		$('#configurationeditorcontent').hide();
		remove_enable_and_disable("disable");
		$('#build_site_config').hide();
		$('#update_comments').hide();	
	}
	$('#masterdb').show();
	$('#divinstallationname').show();
	$('#commenttext').hide();
	$('#template_checkbox').hide();
	$('#template_name').hide();
	
	if (type == "iVIU PTC GEO") {
		$('#masterdb').show();
		$('#divinstallationname').show();
		var mcftypename = $("#lblmcfname").text();
		if (mcftypename == "Non-Appliance Model" || mcftypename == "Appliance Model") {
			$("#checkinst").html(mcftypename).css({"color":"#339900"});
		} else {
			if (mcftypename == "Incomplete Installation") {
				$("#checkinst").html(mcftypename).css({"color":"#FF0000"});
			}
		}
	} else {
		$('#masterdb').hide();
		$('#divinstallationname').hide();
		if (type == "GCP") {
		  $('#template_checkbox').show();
		  $('#template_checkbox').removeClass('disabled');
			$('#template_name').show();
			$('#template_name').removeClass('disabled');
			document.getElementById('template_checkbox').disabled = false;
			document.getElementById('template_checkbox').checked = false;
			var template_check = $('#hd_template_check').val();
			if (template_check == "PAC") {
				document.getElementById('template_checkbox').checked = false;
				$('#template_checkbox').addClass('disabled');
				$('#template_name').addClass('disabled');
				document.getElementById('template_checkbox').disabled = true;
			}
			else if (template_check == "TPL") {
				document.getElementById('template_checkbox').checked = true;
				$('#template_checkbox').addClass('disabled');
				$('#template_name').addClass('disabled');
				document.getElementById('template_checkbox').disabled = true;
			}
			$('#commenttext').show();
			$('#update_comments').addClass('disabled');
			document.getElementById('update_comments').removeAttribute('onclick');
		  }
	   }
	// document.getElementById('licpu').removeAttribute('href');
	// $('#licpu').addClass('disable');
}

function build_site_config_files() {
	var site_type = $("#hd_typeOfSystem").val();
	var comments = "";
	var template_check = "";
	$('#buildcheck').html('');
	document.getElementById("buildcheck").style.color = "#008000";
	$('#buildcheckerror').html('');
	$('#buildcheck12').html('');
	if (site_type == "GCP"){
	  comments = document.getElementById('comment_text_area').value;
	  template_check = document.getElementById('template_checkbox').checked;
	}
	$("#maincontent").mask("Processing request, please wait...");
	//$("#contentcontents").mask("Processing request, please wait...");
	document.getElementById('mcfCRCValue').disabled = true;
	export_enable_and_disable("disable");
	$('#config_report').hide();
	$('#site_config_report').hide();
	$('#geoptc_site_config_report').hide();
		$.post("/selectsite/build", {
			typeofsystem: site_type,
			comments: comments,
			template_check:template_check
		}, function(data){
			//$("#contentcontents").unmask("Processing request, please wait...");
			$("#maincontent").unmask("Processing request, please wait...");
			var splitdata = data.split('|');
			var buildcheck = "";
			if (splitdata.length > 1) {
				buildcheck = splitdata[1];
			}
			document.getElementById('mcfCRCValue').disabled = false;
			if (splitdata[0] == "Build created successfully") {
				export_enable_and_disable("enable");
				$('#config_report').show();
				$('#site_config_report').show();
				$('#geoptc_site_config_report').show();
				if (buildcheck != "") {
					document.getElementById('geoptc_site_config_report').removeAttribute('href');
					document.getElementById('geoptc_site_config_report').style.color = "gray";
				}
				alert(splitdata[0]);
				$('#buildcheck').html("");
				remove_v_preload_page();
				reload_page();
			}
			else {
				export_enable_and_disable("disable");
				$('#config_report').hide();
				$('#site_config_report').hide();
				$('#geoptc_site_config_report').hide();
				$('#buildcheckerror').html("");
				$('#buildcheckerror').html("Build Failed : " + data);
			}
		});
}

function export_enable_and_disable(eend_option) {
	if (eend_option == "enable") {
		document.getElementById('copytousb').style.color = "white";
	} else if (eend_option == "disable") {
		document.getElementById('copytousb').style.color = "gray";
	}
}

function remove_enable_and_disable(rend_option) {
	if (rend_option == "enable") {
		document.getElementById("site_status").value = "Available";
		document.getElementById('remove_site_config').style.color = "white";
		if ($('#systemtype').val() == "GEO" || $('#systemtype').val() == "GCP"){
			$('#db_template').hide();
		}else{
			$('#db_template').show();
		}
	} else if (rend_option == "disable") {
		document.getElementById('remove_site_config').style.color = "gray";
		$('#db_template').hide();
		document.getElementById("site_status").value = "";
	}
}

function validate() {
	var sitename = document.getElementById("yourFieldName").value;
	var systemtype = document.getElementById("systemtype").value;
	var mcfname = document.getElementById("mcfname").value;
	var installation = document.getElementById('installation').options[document.getElementById('installation').selectedIndex].text;
	var mastergeoptclocation = document.getElementById('masterGeoptclocation').options[document.getElementById('masterGeoptclocation').selectedIndex].text;
	if ((mcfname.length > 0) && (sitename.length > 0)) {
		if (systemtype == "iVIU PTC GEO") {
			var incompleteinst = document.getElementById("checkinst").innerHTML;
			if (trim(incompleteinst) == "Incomplete Installation") {
				alert("Please select valid installation and try again.")
				return false;
			} 
			if ((mastergeoptclocation == "Select Master DB") && (installation == "Select GEO Installation")) {
				alert("Select master db/Installation name and try again.");
				return false;
			}
		}
		if (systemtype == "CPU-III") {
			if (crc_validate("MCF",true)) {
				if (crc_validate("SIGNAL",true)) {
					if (crc_validate("PTC",true)) {
						//if ((confirm("This process will create mcf.db and rt.db \nDo you want to proceed ?"))) {
							return true;
						//}
					}
				}
			}
		}else{
			if (crc_validate("MCF",true)) {
				//if ((confirm("This process will create mcf.db and rt.db \nDo you want to proceed ?"))) {
					return true;
				//}
			}
		}
	} else {
		alert("Please enter sitename & select mcf file and try again.")
		return false;
	}
}

function validate_input() {
	var sitename = document.getElementById("yourFieldName").value;
	var systemtype = document.getElementById("systemtype").value;
	var mcfname = document.getElementById("mcfname").value;
	var installation = document.getElementById('installation').options[document.getElementById('installation').selectedIndex].text;
	var mastergeoptclocation = document.getElementById('masterGeoptclocation').options[document.getElementById('masterGeoptclocation').selectedIndex].text;
	if ((sitename.length > 0)) {
		if (systemtype == "iVIU PTC GEO") {
			var incompleteinst = document.getElementById("checkinst").innerHTML;
			if (trim(incompleteinst) == "Incomplete Installation") {
				alert("Please select valid installation and try again.")
				return false;
			}
			if ((mastergeoptclocation == "Select Master DB") && (installation == "Select GEO Installation")) {
				alert("Select master db/Installation name and try again.");
				return false;
			}
		}		
	} else {
		alert("Please enter sitename & select mcf file and try again.")
		return false;
	}
	return true;
}


function enable_disable_create_rc2key(enable_option) {
	if (enable_option == "enable") {
		$('#create_rc2key_file_disabled').hide();
		$('#create_rc2key_file').show();
	} else if (enable_option == "disable") {
		$('#create_rc2key_file_disabled').show();
		$('#create_rc2key_file').hide();
	}
}

// Export the site configurations
function export_site_config(){
	var expt_flag = $("#hd_export_flag").val();
	var type_sys = $("#hd_typeOfSystem").val();
	if (expt_flag == 'true') {
		$.post("/selectsite/copybuildfiles", {
			typeofsystem: type_sys
		}, function(resp_build_files){
			if(resp_build_files.error == true){
				// display error messane
				if (type_sys != 'GCP'){
					reload_page();	
				}else{
					if(resp_build_files.message){
						alert(resp_build_files.message);	
					}else{
						alert("Build files not available, Please build and try again");
					}
				}
				
			}else{
				downloadURL('/selectsite/download_export_site_config?file_path='+ resp_build_files.file_path);	
			}
		});
	}
}

// Download the passing url path file from the system
function downloadURL(dl_url) {
    var iframe;
    var hiddenIFrameID = 'hiddenDownloader';
    iframe = document.getElementById(hiddenIFrameID);
    if (iframe === null) {
        iframe = document.createElement('iframe');  
        iframe.id = hiddenIFrameID;
        iframe.style.display = 'none';
        document.body.appendChild(iframe);
    }
	iframe.src = dl_url;   
}

function download_config_report(){
	var typeofsystem = $("#hd_typeOfSystem").val();
	downloadURL('/selectsite/sendconfigreport?typeofsystem=' + typeofsystem);	
}

function download_gcp_config_report(report_type){
	downloadURL('/selectsite/send_gcp_configreports?report_type='+report_type);	
}

function download_pac_import_report(){
	downloadURL('/selectsite/download_pac_import_report');	
}

function site_conf_load_page(){
	//$("#maincontent").unmask("Loading contents, please wait...");
	$('#hd_current_site_type').attr('value', $('#systemtype').val());
	enable_disable_create_rc2key("enable");
	document.getElementById("checkinst").innerHTML = "";
	hidetheselect();
	var str = $("#hd_refresh_page").val();
	var imp_message = $("#hd_importfilemessage").val();
	$('#buildcheck12').html('');
	if (imp_message == "success") {
		document.getElementById("buildcheck12").style.color = "#008000";
		$('#buildcheck12').html('Successfully imported site configuration files');
	} else if (imp_message != "") {
		document.getElementById("buildcheck12").style.color = "#FF0000";
		$('#buildcheck12').html(imp_message);
	}
	var systype = $("#hd_typeOfSystem").val();

	if (str == 2 || str == 3) {
		// Close site OR remove site
		window.parent.document.getElementById("mainheader").innerHTML = "";
		load_content_flag = false;
		build_vital_config_object("Configuration");
	} else {
		var sitename = $("#hd_site_name").val();
		if (sitename != "") {
			$('#leftnavtree').html('');
			enable_disable_create_rc2key("disable");
			// open new site
			if (systype != "" || systype != null) {
				enable_disable_create_rc2key("disable");				
			} else {
				enable_disable_create_rc2key("enable");
			}
			load_content_flag = false;
			build_vital_config_object("Configuration");
			var atcs_addr = $("#hd_atcs_addr").val();
			var mile_post = $("#hd_mile_post").val();
			var dot_number = $("#hd_dot_number").val();
			window.parent.document.getElementById("mainheader").innerHTML = "";
			window.parent.document.getElementById("mainheader").innerHTML = "Site Name: " + sitename + "| ATCS Address: " + atcs_addr + "| Mile Post: " + mile_post + "| DOT Number: " + dot_number;
		} else {
			// create new site
			var systype = document.getElementById("systemtype").value;
			if (systype) {
				enable_disable_create_rc2key("disable");
			}
			window.parent.document.getElementById("mainheader").innerHTML = "";
		}
		
		if(($("#hd_aspect_available_flag").val() == 'false') && (systype != "iVIU PTC GEO")){
			$("#configurationeditorcontent").hide();
		}
	}
}

function crc_validate(type_crc_validate , alert_flag){
	var crc_value_to_validate = "";
	var type_crc_string = "";
	var crc_validation_id = "";
	var message = "";
	if (type_crc_validate == "MCF"){
		crc_value_to_validate = document.getElementById("mcfCRCValue").value;
		type_crc_string = "MCF";	
		crc_validation_id = "in_crc1";
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
		message = "Please enter hexadecimal number only";
		if (alert_flag == true){
			alert(message);	
		}else{
			document.getElementById(crc_validation_id).innerHTML = message;
		}
		return false;
	}else {
		if (crc_value == "" || crc_value_to_validate == "") {
		    if (alert_flag == true){
			  message = "Please enter "+type_crc_string+" CRC value";
			  alert(message);	
		    }else{
				document.getElementById(crc_validation_id).innerHTML = "Please enter CRC value";
		    }
		   return false;
		}else {
			if (crc_value.length > 0) {
				var objPattern = /^[0-9A-Fa-f]+$/i;
				if (!(objPattern.test(crc_value))) {
					if (alert_flag == true) {
						message = type_crc_string + " CRC,Please enter hexadecimal number only";
						alert(message);
					}else {
						document.getElementById(crc_validation_id).innerHTML = "Please enter hexadecimal number only";
					}
					return false;
				}else {
					if (crc_value.length <= 8) {
						return true;
					}else {
						if (alert_flag == true) {
							message = "Maximum length of " + type_crc_string + " CRC is 8";
							alert(message);
						}else {
							document.getElementById(crc_validation_id).innerHTML = "Maximum length of CRC is 8";
						}
						return false;
					}
				}
			}else{
				if (alert_flag == true) {
					message = "Please enter valid " + type_crc_string + " CRC value";
					alert(message);
				}else {
					document.getElementById(crc_validation_id).innerHTML = "Please enter valid CRC value";
				}
				return false;
			}
		}
	}
}

function update_comments(){
   var comments = $('#comment_text_area').val();
   $('#maincontent').mask('Processing request, please wait...');
   $.post("/selectsite/update_comments", {
       comments: comments,
       typeofsystem: $("#hd_typeOfSystem").val(),
   }, function(data){
   	   $('#hd_comments').val(comments);
	   $('#maincontent').unmask('Processing request, please wait...');
	   $('#update_comments').addClass('disabled');
	   document.getElementById('update_comments').removeAttribute('onclick');
	   remove_v_preload_page();
	});
}

function enable_template(){
	var template_checked = document.getElementById("template_checkbox").checked;
	var create_template = false;
	if(template_checked == true){
	  create_template = true;
	}
	else{
		create_template = false;
	}
	return create_template;
}

function build_site_config_files_gcp(){
	var create_temp = enable_template();
    if (create_temp == false || create_temp == 'false') {
		if (confirm("Creating PAC will set hidden parameters to default values\nDo you want to proceed?")) {
			build_site_config_files();
		}
	}
	else if (create_temp == 'true' || create_temp == true) {
			create_gcp_template();
		}
	}
	
function add_comments_popup(){
	preload_page = function(){
	  ConfirmDialog('Comments','Comments are not saved.<br>Would you like to leave?',function(){
       if (typeof item_clicked == 'object') {
	     preload_page_finished();
	   }
	  preload_page = '';
	 },function(){
	 	$('.ajax-loader').hide();
	  //don't load the next page
	 });
   };
}

function comments_info(){
	var comment_prev = $('#hd_comments').val();
	var comment_new = $('#comment_text_area').val();
	var type = $('#hd_typeOfSystem').val();
	if (type == "GCP") {
		if (comment_prev == comment_new) {
			return true;
		}else {
			return false;
		}
	}else{
		return true;
	}
}
