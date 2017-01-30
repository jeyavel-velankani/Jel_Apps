/**
 * @author Jeyavel Natesan
 */

add_to_destroy(function(){
	$(document).unbind("ready");
	
	//kills all wrapper events
	$(".unapprove_installation").w_die('click');
	$(".cancel_unapprove").w_die('click');
	
	//clear functions 
	delete window.valudate_unapprovar;
});

$(document).ready(function(){
	$(".unapprove_installation").w_click( function(){
			valid = document.getElementById("dig_in_crc_unapprove").innerHTML;
			var installationunapprovarname = document.getElementById("dig_installation_unapprover_name").value;
			if (valudate_unapprovar() == true) {
				var installationname = document.getElementById("validinstallationname").value;
				var installationapprover = document.getElementById("dig_installation_unapprover_name").value;
				var installationunapprovalstatus = "Not Approved";
				$(".unapprove_loader").show();
				document.getElementById("unapprove_installation").disabled = true;
				document.getElementById("unapprove_installation_cancel").disabled = true;
				$.post("/mcfextractor/approvalcrc", {
					installationname: installationname,
					installationapprover: installationunapprovarname,
					installationapprovalstatus: installationunapprovalstatus
				}, function(data){
					$(".unapprove_loader").hide();
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
			});
			return true;
		}else{
			alert("Please enter valid unapprover name");
			document.getElementById("dig_installation_unapprover_name").focus();
			return false;
		}
	});
	
	$(".cancel_unapprove").w_click(function(){
		$.fn.colorbox.close();
	});
});
	
function valudate_unapprovar(){
	var installationunapprovarname = document.getElementById("dig_installation_unapprover_name").value;
	var objPattern = /^[0-9A-Za-z_-]+$/i;
	if ((installationunapprovarname == "") || (installationunapprovarname == null)){
		document.getElementById("dig_in_crc_unapprove").innerHTML = "*Enter unapprover name";
		document.getElementById("dig_installation_unapprover_name").focus();
		return false;
	}else{
		if (!(objPattern.test(installationunapprovarname))) {
			document.getElementById("dig_in_crc_unapprove").innerHTML = "* Enter valid approver name";
			document.getElementById("dig_installation_unapprover_name").focus();
			return false;
		}
		document.getElementById("dig_in_crc_unapprove").innerHTML = "";
		return true;
	}
	return true;
}