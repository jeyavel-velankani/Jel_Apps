/**
 * @author Jeyavel Natesan
 */

add_to_destroy(function(){
	$(document).unbind("ready");
	
	//kills all wrapper events
	$(".select_installation").w_die('click');
	$(".cancel").w_die('click');
	$(".select_installation_approve").w_die('click');
	$(".cancel_approve").w_die('click');
	$("#txtrename_installation_name").w_die('keyup');
	$(".rename_cancel").w_die('click');
	$(".rename_installation").w_die('click');
});

$(document).ready(function(){
	$(".select_installation").w_click( function(){
		var selected_file = document.getElementById('selected_installation_name').options[document.getElementById('selected_installation_name').selectedIndex].text;
		if(selected_file != ""){
			$(".loader").show();
			$(".loader").hide();
			$.fn.colorbox.close();				
			if(navigator.appName == "Microsoft Internet Explorer"){
				myWindow = window.open("http://"+window.location.host+"/reports/"+selected_file+"/generate_csv",'','status=0,toolbar=no,menubar=1,scrollbars=yes,resizable=yes,HEIGHT=700,WIDTH=800');
			    	myWindow.focus();	
			}else{
				window.location.href = "/reports/"+selected_file+"/generate_csv";	
			}
		}
	});
	
	$(".cancel").w_click(function(){
		$.fn.colorbox.close();
	});
	
	$(".select_installation_approve").w_click( function(){
		var selected_file = document.getElementById('selected_installation_name_approve').options[document.getElementById('selected_installation_name_approve').selectedIndex].text;
		if(selected_file != ""){
			$(".loader").show();
			$.post("/site/select_installationname_approve", {
				id: selected_file
			}, function(data){
				$(".loader").hide();
				$.fn.colorbox.close();
				if (data !=null){
					show_approve();
					clearapprovalpage();
					var splitdata = data.split('|');
					if (splitdata.length > 1){
						if (splitdata[5] == "Approved"){
							document.getElementById('crc_unapproved_utility').style.display = 'none'
							document.getElementById('crc_approved_utility').style.display = 'block'
							document.getElementById("installation_names").value = splitdata[0];
							document.getElementById("installation_approver").value = splitdata[1];
							document.getElementById("site_date").value = splitdata[2] + '  ' + splitdata[3]
							document.getElementById("installation_approval_crc").value = splitdata[4];
							document.getElementById("installation_approval_status").value = splitdata[5];
						}else{
							document.getElementById('crc_approved_utility').style.display = 'none'
							document.getElementById('crc_unapproved_utility').style.display = 'block'
							document.getElementById("installation_names1").value = splitdata[0];
							document.getElementById("installation_approval_status1").value = splitdata[5];
						}
					}else{
						    document.getElementById('crc_approved_utility').style.display = 'none'
						    document.getElementById('crc_unapproved_utility').style.display = 'block'
							document.getElementById("installation_names1").value = data;
							document.getElementById("installation_approver").value = "";
							document.getElementById("installation_approval_crc").value = "";
							document.getElementById("installation_approval_status1").value ="Not Approved";
					}
				}else{
					show_approve();
					document.getElementById('crc_approved_utility').style.display = 'none'
					document.getElementById('crc_unapproved_utility').style.display = 'block'
				}
			});
		}
	});
	
	$(".cancel_approve").w_click(function(){
		$.fn.colorbox.close();
	});
	
	$("#txtrename_installation_name").w_keyup(function(){  
		var objPattern = /^[0-9A-Za-z_-]+$/i;
			if (($("#txtrename_installation_name").val() != null) && ($("#txtrename_installation_name").val() != "")) {
				if (!objPattern.test($("#txtrename_installation_name").val()))
					$(this).css("border", "1px solid red");
				else {
					$(this).css("border", "1px solid #888");
				}
			}else{
				$(this).css("border", "1px solid #888");
			}
    });
	
	$(".rename_installation").w_click(function(){
		var existing_name = $("#txtexisting_installation_name").val(); 
		var modified_name = $("#txtrename_installation_name").val();
		if(modified_name != "" && existing_name != ""){
			if (trim(existing_name) != trim(modified_name)) {
				var objPattern = /^[0-9A-Za-z_-]+$/i;
				if (!objPattern.test(modified_name)) {
					alert("Please enter valid installation name[only alpha numeric, _ , -] ");
					document.getElementById("txtrename_installation_name").focus();
					return false;
				}else {
					document.getElementById("rename_installation").disabled = true;
					document.getElementById("rename_cancel").disabled = true;
					$(".loader").show();
					$.post("/mcfextractor/rename_exist_inatallationname", {
						existinstallationname: trim(existing_name),
						newinstallationname: trim(modified_name)
					}, function(data){
						var returnvalue = data.split('|');
						if (returnvalue.length >1){
							alert(returnvalue[0]);
							$(".loader").hide();
							document.getElementById("txtrename_installation_name").focus();
							document.getElementById("rename_installation").disabled = false;
							document.getElementById("rename_cancel").disabled = false;
							return false;
						}else{
							alert(returnvalue[0]);
							$.fn.colorbox.close();
							load_page("MCF Extractor","/mcfextractor/mcfextractor");
						}
					});
				}
			}else{
				alert("Both installation names should not be match,please change and try again.");
				document.getElementById("txtrename_installation_name").focus();
				return false;
			}
		}else{
			alert("Please enter new installation name.");
			document.getElementById("txtrename_installation_name").focus();
			return false;
		}
	});
	
	$(".rename_cancel").w_click(function(){
		$.fn.colorbox.close();
	});
});