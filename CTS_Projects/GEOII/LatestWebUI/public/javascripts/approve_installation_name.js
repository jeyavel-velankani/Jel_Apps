/**
 * @author Jeyavel Natesan
 */

add_to_destroy(function(){
	$(document).unbind("ready");
	
	//kills all wrapper events
	$(".approve_installation").w_die('click');
	$(".cancel_approve").w_die('click');
	
	//clear functions 
	delete window.valudate_approvalcrc;
	delete window.valudate_approvar;
});

$(document).ready(function(){
	$(".approve_installation").w_click( function(){
			var valid = document.getElementById("dig_in_crc").innerHTML;
			var installationapprovarname = document.getElementById("dig_installation_approver_name").value;
			if ((valudate_approvar()==true) && (valudate_approvalcrc()==true)) {
				var installationname = document.getElementById("validinstallationname").value;
				var installationapprovalcrc = document.getElementById("dig_installation_approval_crc").value;
				var installationapprover = document.getElementById("dig_installation_approver_name").value;
				var installationapprovalstatus = "Approved";
				$(".approve_loader").show();
				document.getElementById("approve_installation").disabled = true;
				document.getElementById("approve_installation_cancel").disabled = true;
				$.post("/mcfextractor/approvalcrc", {
					installationname: installationname,
					installationapprover: installationapprover,
					installationapprovalcrc: installationapprovalcrc,
					installationapprovalstatus: installationapprovalstatus
				}, function(data){
					$(".approve_loader").hide();
					$.fn.colorbox.close();
					$.post("/site/select_installationname_approve", {
				}, function(data){
					$(".loader").hide();
					$.fn.colorbox.close();
					if (data !=null){
						show_approve();
						clearapprovalpage();
						var splitdata = data.split('|');
						if (splitdata.length > 1) {
							if (splitdata[5] == "Approved") {
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
						}
						else
						{
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
			});
			return true;
		}else{
			alert("Please enter valid Approver name/CRC")
			return false;
		}
	});
	
	$(".cancel_approve").w_click(function(){
		$.fn.colorbox.close();
	});
});
	
function valudate_approvalcrc(){
  	var installationapprovalcrc = document.getElementById("dig_installation_approval_crc").value;
	var objPattern = /^[0-9A-Fa-f]+$/i;
	document.getElementById("dig_in_crc").innerHTML = "";
	if (!(objPattern.test(installationapprovalcrc))) {
		document.getElementById("dig_in_crc").innerHTML = "* Invalid hexadecimal";
		return false;
	}
	else {
		if (installationapprovalcrc.length > 8) {
			document.getElementById("dig_in_crc").innerHTML = "*Max length of CRC is 8";
			return false;
		}
	}
	return true;
}

function valudate_approvar(){
	var installationapprovarname = document.getElementById("dig_installation_approver_name").value;
	var objPattern = /^[0-9A-Za-z_-]+$/i;
	if ((installationapprovarname == "") || (installationapprovarname == null)){
		document.getElementById("dig_in_crc").innerHTML = "Enter Approver name";
		alert("Please enter approver name");
		document.getElementById("dig_installation_approver_name").focus();
		return false;
	}else{
		if (!(objPattern.test(installationapprovarname))) {
			document.getElementById("dig_in_crc").innerHTML = "* Enter valid approver name";
			document.getElementById("dig_installation_approver_name").focus();
			return false;
		}
		document.getElementById("dig_in_crc").innerHTML = "";
		return true;
	}
	return true;
}