/**
 * @author Jeyavel Natesan
 */
add_to_destroy(function(){
	$(document).unbind("ready");
	
	//kills all wrapper events
	$("#fileUploadPac1").w_die('change');
	$("#fileUploadPac2").w_die('change');
	$("#gcp_site_config_import_form").w_die('submit');
	$(".start_merge").w_die('click');
	$(".save_comparison_report").w_die('click');
			
	//clear functions 
	delete window.merge_pacfiles;
	delete window.save_paccomparison_report;
	delete window.check_selected_pac1;
	delete window.check_selected_pac2;
	delete window.downloadURL;
});

$(document).ready(function(){
    set_content_deminsions(950,500);
    $("#mycontent").custom_scroll(350);
 	$("#fileUploadPac1").w_change(function(){
		add_v_compare_popup();
		check_selected_pac1();
 	});
	
	$("#fileUploadPac2").w_change(function(){
		add_v_compare_popup();
		check_selected_pac2();
 	});
	
	$("#selected_pac1_path").w_change(function(){
		add_v_compare_popup();
 	});
	
	$("#selected_pac2_path").w_change(function(){
		add_v_compare_popup();
 	});
			
	$(".start_merge").w_click(function(){
		if (!$(this).hasClass('disable')) {
			merge_pacfiles();
		}
	});
	
	$(".save_comparison_report").w_click(function(){
		if (!$(this).hasClass('disable')) {
			save_paccomparison_report();
		}
	});
	
});

function check_selected_pac1(){	
    $(".loader").show();
	var select_pac_path = document.getElementById("fileUploadPac1").value;
	var valid = select_pac_path.split('.');
	var validname;
	if (navigator.appName == "Microsoft Internet Explorer") {
		 validname = select_pac_path.split("\\");
	}else{
		validname = select_pac_path.split('/');
		if (validname.length == 1){
			validname = validname[0].split("\\");
		}
	}
	var filename = validname[validname.length-1];
	var validpac = valid[valid.length-1];
	if ((validpac == "pac")|| (validpac == "PAC")) {
		if (select_pac_path != null && select_pac_path != '') {
			$.post('/paccomparisontool/get_pac', {
				//no params
			}, function(response){
				$("#selected_pac1_path >option").remove();
				$("#selected_pac1_path").append($('<option></option>').val('Select PAC1').html('Select PAC1'));
				document.getElementById("uploaded_pac1_path").value = select_pac_path;
				$("#selected_pac1_path").append($('<option></option>').val(select_pac_path).html(filename));
				if (response.length > 0) {
					 var valarray = response.split('|');
					for (var i = 1; i < (valarray.length); i++) {
						var pac_file_name ;
						if (navigator.appName == "Microsoft Internet Explorer") {
							 pac_file_name = valarray[i].split("\\");
							 if (pac_file_name.length == 1) {
							 	pac_file_name = valarray[i].split('/');
							 }
						}else{
							pac_file_name = valarray[i].split('/');
							if (pac_file_name.length == 1){
								pac_file_name = pac_file_name[0].split("\\");
							}
						}
						$('#selected_pac1_path').append($('<option></option>').val(valarray[i]).html(pac_file_name[pac_file_name.length - 1]));
					}
				}
				$(".loader").hide();	
				document.getElementById("selected_pac1_path").focus();					
				document.getElementById('selected_pac1_path').selectedIndex = 1;
	        });
		}
	}else{
		$(".loader").hide();
		alert("Please select PAC file only");
	}
}

function check_selected_pac2(){	
    $(".loader").show();
	var select_pac_path = document.getElementById("fileUploadPac2").value;
	var valid = select_pac_path.split('.');
	var validname;
	if (navigator.appName == "Microsoft Internet Explorer") {
		 validname = select_pac_path.split("\\");
	}else{
		validname = select_pac_path.split('/');
		if (validname.length == 1){
			validname = validname[0].split("\\");
		}
	}
	var filename = validname[validname.length-1];
	var validpac = valid[valid.length-1];
	if ((validpac == "pac")|| (validpac == "PAC")) {
		if (select_pac_path != null && select_pac_path != '') {
			$.post('/paccomparisontool/get_pac', {
				//no params
			}, function(response){
				$("#selected_pac2_path >option").remove();
				$("#selected_pac2_path").append($('<option></option>').val('Select PAC2').html('Select PAC2'));
				document.getElementById("uploaded_pac2_path").value = select_pac_path;
				$("#selected_pac2_path").append($('<option></option>').val(select_pac_path).html(filename));
				if (response.length > 0) {
					 var valarray = response.split('|');
					for (var i = 1; i < (valarray.length); i++) {
						var pac_file_name ;
						if (navigator.appName == "Microsoft Internet Explorer") {
							 pac_file_name = valarray[i].split("\\");
							 if (pac_file_name.length == 1) {
							 	pac_file_name = valarray[i].split('/');
							 }
						}else{
							pac_file_name = valarray[i].split('/');
							if (pac_file_name.length == 1){
								pac_file_name = pac_file_name[0].split("\\");
							}
						}
						$('#selected_pac2_path').append($('<option></option>').val(valarray[i]).html(pac_file_name[pac_file_name.length - 1]));
					}
				}
				$(".loader").hide();	
				document.getElementById("selected_pac2_path").focus();					
				document.getElementById('selected_pac2_path').selectedIndex = 1;
	        });
		}
	}else{
		$(".loader").hide();
		alert("Please select PAC file only");
	}
}

function merge_pacfiles(){
	$('#mycontent').html("");
	$("#mycontent").remove_custom_scroll();
	document.getElementById('comparisonerrormessage').innerHTML = "";
	$("#contentcontents").mask("Processing request, please wait...");
	var pacname1 = document.getElementById('selected_pac1_path').options[document.getElementById('selected_pac1_path').selectedIndex].text;
	var pacname2 = document.getElementById('selected_pac2_path').options[document.getElementById('selected_pac2_path').selectedIndex].text;
	var uploaded_pac1 = document.getElementById("uploaded_pac1_path").value;
	var uploaded_pac2 = document.getElementById("uploaded_pac2_path").value;
	
  	if(pacname1 != "Select PAC1" && pacname2 != "Select PAC2"){
  		if (uploaded_pac1 != "" || uploaded_pac2 != "") {
			$("#gcp_site_config_import_form").submit();
		}else {
			if (trim(pacname1) != trim(pacname2)) {
				$("#gcp_site_config_import_form").submit();
			}else {
				alert("Please select two different pac files and try again");
				$("#contentcontents").unmask("Processing request, please wait...");
				return false;
			}
		}
	}else{
	  	alert("Please select pac files and try again");
		$("#contentcontents").unmask("Processing request, please wait...");
		return false;
	}
}

$("#gcp_site_config_import_form").submit(function(){
	var form_submit = {
	    success:    function(resp) {
		  if (resp.match("error")) {
		  	var error = resp.split('|');
		  	var error_flag = error[0];
		  	if (error_flag == "error") {
		  		$("#contentcontents").unmask("Processing request, please wait...");
		  		if (typeof error[1] !== 'undefined' && error[1] != null && error[1] != "") {
		  			$('#mycontent').html("<span class='error_message'>" + error[1] + "</span>");
		  		}
		  	 }
		  }
		  else {
		  	$("#contentcontents").unmask("Processing request, please wait...");
		  	$('#mycontent').html(resp);
		  	$("#mycontent").custom_scroll(350);
			remove_v_preload_page();
		  }
	    } 
	};
    $(this).ajaxSubmit(form_submit);
	return false; 
});

function save_paccomparison_report(){
	document.getElementById('comparisonerrormessage').innerHTML = "";
	downloadURL('/paccomparisontool/downloadcomparison_report');
	remove_v_preload_page();
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

function add_v_compare_popup(){
  preload_page = function(){
  	ConfirmDialog('Compare PAC', 'You did not Compare files.<br>Would you like to leave page?', function(){
  		if (typeof item_clicked == 'object') {
  			preload_page_finished();
  		}
  		preload_page = '';
  	}, function(){
  		//don't load the next page
	});
  };
}
