/**
 * @author Jeyavel Natesan
 */

$(document).ready(function(){
	add_to_destroy(function(){
	$(document).unbind("ready");
	
	//kills all wrapper events
		$('#export_files').w_die('click');
		$('#frmfilemanager').w_die('submit');
		$("#overridecancel").w_die('change');
		$(".template_remove").w_die('click');
		
		//clear functions 
		delete window.upload_zip;
		delete window.validate_check_all;
		delete window.save_selected_file;
		delete window.ok_imported_files;
		delete window.cancel_imported_file;	
		
		$('#templatemenu').remove();
		
		});
		
	$('#frmfilemanager').submit(function(e) {
     	var options = {
          success: function(resp_message) { 
               load_page("File Manager","/filemanager/index?import_flag=true&importmsg="+resp_message);
          } 
     	};
     	$(this).ajaxSubmit(options);
     	return false; 
  	});
		
	$(".remove_gcp_template").w_click( function(){
		var len = document.getElementById('selected_template').options.length;
		cfm_msg = "Selected template will be delete.\nDo you want to continue?";
		if (confirm(cfm_msg)) {
			if (len >= 1) {
				$(".loader").show();
				$("#form_template_file_remove").submit();
			}
			else {
				alert("Please select/browse the template file and try again.");
			}
		}
	});
	
	$(".cancel_template_button").w_click(function(){
		$.fn.colorbox.close();
	});
	
	  		
	$("#overridecancel").w_change(function(){
			var checkbox_array = [];
			var cbs = $("input:checkbox");			
			cbs.each(function(index, ckelement){
				if (ckelement.id != "overridecancel"){
					checkbox_array.push(ckelement.id);	
				}
			});
			if (this.checked == true){
				for (var x = 0; x < checkbox_array.length; x++) {
					$('#'+checkbox_array[x]).attr('checked', 'checked');
				}
			}else if (this.checked == false) {
				for (var x = 0; x < checkbox_array.length; x++) {
					$('#' + checkbox_array[x]).removeAttr('checked');
				}
			}
	});
	
	$('#export_files').w_click(function(){
		$("#template_mess").html("");
		$("#contentcontents").mask("Exporting the files, Please wait...")
		$.post("/filemanager/check_export_exists", {
			// no params
		}, function(data){
			$("#contentcontents").unmask("Exporting the files, Please wait...")
			if(data.errorflag){
				alert("Aspect lookup,PTC Aspect text files,MCF and Master DB are not available for export" );
			}else{
				window.location.href = "/filemanager/export_files";
			}
		});
	});
	
	$(".template_remove").w_click(function(){
		type_id = $(this).attr('id');
		sity_type = trim($("#"+ type_id).html());
		var cfm_msg = ""; 
		if (sity_type == 'GCP') {
			remove_gcp_template();		
		}
		else {
			cfm_msg = "Current " + sity_type + " Non Vital configuration template will be delete.\nDo you want to continue?";
			if (confirm(cfm_msg)) {
				$('.ajax-loader').show();
				$.post('/filemanager/remove_template', {
					type: sity_type
				}, function(resp){
					$('.ajax-loader').hide();
					if (resp.error == true || resp.error == 'true') {
						$('#template_mess').html(resp.mess);
					}
					else {
						$('#template_mess').html(resp.mess);
						load_page("File Manager", "/filemanager/index?remove_msg_template=" + resp.mess);
					}
				});
			}
		  }
	   });
  });
  
  $("#form_template_file_remove").submit(function(){
		var form_submit = {
		    success: function(resp){
				$(".loader").hide();
				if(resp.search("Error:")== 0){
				//if (resp.error == true || resp.error == 'true') {
					document.getElementById("error_message").innerHTML = resp
				}
				else {
					alert(resp);
				    $.fn.colorbox.close();
					remove_v_preload_page();
					reload_page();
				}
			} 
		};
        $(this).ajaxSubmit(form_submit);
		return false; 
	});

function remove_gcp_template(){
	$.fn.colorbox({ href : "/remove_gcp_template"});
    }
		
function upload_zip(){	
    $("#template_mess").html("");
	var onchng = document.getElementById("upload_zip_input").onchange;
	document.getElementById("upload_zip_input").onchange = "";
	$("#contentcontents").mask("Processing request, please wait...");
	var select_zip_path = document.getElementById("upload_zip_input").value;
	var valid = select_zip_path.split('.');
	var validzip = valid[valid.length - 1];
	if ((validzip == "zip") || (validzip == "ZIP")) {
		if (select_zip_path != null && select_zip_path != '') {
			document.getElementById("upload_zip_input").onchange = onchng;
			$("#frmfilemanager").submit();
		}
	}else{	
		alert("Please select only zip file");
		$("#contentcontents").unmask("Processing request, please wait...");
		if(navigator.appName == "Microsoft Internet Explorer"){
			load_page("File Manager","/filemanager/index");
		}
		document.getElementById("upload_zip_input").onchange = onchng;
		return false;
	}	
}

function validate_check_all(){
	var rec_count = document.getElementById("rec_count").value;
	var chk = true;
	for(rec = 1; rec <= rec_count; rec++){
		if (!(document.getElementById("chk_"+rec).checked)){
			chk = false;		
		}
	}		
	if (chk){
		document.getElementById("overridecancel").checked = true;
	}else{
		document.getElementById("overridecancel").checked = false;
	}
}

function save_selected_file(){		
	$("#contentcontents").mask("Processing request, please wait...");
	var rec_count = document.getElementById("rec_count").value;
	var files_list="";
	var display_files_list="";
	for(rec = 1; rec <= rec_count; rec++){
		if (document.getElementById("chk_"+rec).checked){
			files_list = files_list + "|checked*" + document.getElementById("chk_"+rec).value;
			display_files_list = display_files_list + "\n" + document.getElementById("chk_"+rec).value;
		} else {
			files_list = files_list + "|notchecked*" + document.getElementById("chk_"+rec).value
		}	
	}
	if (files_list.length > 0){
		if (confirm("Selected files will be override and un-selected files will keep as original.\n Please confirm.")){			
			$.post("/filemanager/save_selected_files", {
				sel_files: files_list
				}, function(data){
					load_page("File Manager","/filemanager/index?successmsg="+data);
				});	
		}else{
			$("#contentcontents").unmask("Processing request, please wait...");
			return false;
		}		
	}else{
		$("#contentcontents").unmask("Processing request, please wait...");
		return false;
	}
}

function ok_imported_files(){
	var msg = "Successfully imported files.";
	load_page("File Manager","/filemanager/index?successmsg=" + msg);
}

function cancel_imported_file(){
	$("#contentcontents").mask("Processing request, please wait...");
	var hd_obj = document.forms['frmfilemanager'].elements['hd_imp_filename'];
	var hd_len = hd_obj.length;
	var can_files = "";
	if(hd_len == undefined)
	{
		 can_files = hd_obj.value;			
	} else {
		for (var hd_i = 0; hd_i< hd_len; hd_i++) {
			can_files = can_files + "|" + hd_obj[hd_i].value;
		}
	}
	if (can_files.length > 0){
		if (confirm("Current imported files will be revert back, please confirm")){			
			$.post("/filemanager/cancel_import", {
				cancel_files: can_files
				}, function(data){
					load_page("File Manager","/filemanager/index?successmsg="+data);
				});	
		}else{
			$("#contentcontents").unmask("Processing request, please wait...");
			return false;
		}		
	}else{
		$("#contentcontents").unmask("Processing request, please wait...");
		return false;
	}
}
