/**
 * @author Jeyavel Natesan
 */
$(document).ready(function(){
	//For OCE - mcfextractor page context menu display
	$('#navigation1').contextMenu('context-menu-1', {
      	'Delete Installation': {
         click: function(element) {  // element is the jquery obj clicked on when context menu launched
			if (confirm("Do you want to delete '" + document.getElementById("hdselectedinstname").value + "' installation?")) {
				$("#mcf1").mask("Deleting the selected installation, please wait...");
				$.post("/mcfextractor/deletemcf", {}, function(data){
					if (data == "Select Installation") {
						$("#mcf1").unmask("Deleting the selected installation, please wait...");
						var message = "<div style=" + "padding-top:30px;padding-left:5px;padding-right:5px;padding-bottom:10px;font-size:small;" + ">Please select installation name and then click 'Delete Installation' option</div>";
						$.colorbox({
							html: message,
							transition: "none",
							width: "300px",
							height: "150px"
						});
					}else {
						$("#mcf1").unmask("Deleting the selected installation, please wait...");
						load_page("MCF Extractor","/mcfextractor/mcfextractor");  
					}
				});
			}			
         },
         klass: "ocemenu-item-1" // a custom css class for this menu item (usable for styling)
       },
       'Create Report': {
         click: function(element){ 
		 $("#mcf1").mask("Processing request, please wait..."); 
		 $.post("/mcfextractor/createreport", {
            }, function(data){
				var instname = data;
				if (data == "Select Installation"){
					$("#mcf1").unmask("Processing request, please wait..."); 
					var message ="<div style="+"padding-top:30px;padding-left:5px;padding-right:5px;padding-bottom:10px;font-size:small;"+">Please select installation name and then click 'Create Report' option</div>";
					$.colorbox({html:message ,transition:"none" ,width:"300px" ,height:"150px"});
				}else{
					if (navigator.appName == "Microsoft Internet Explorer") {
						$.post("/site/select_installationname", {
							id: data
						}, function(data){
							$(".loader").hide();
							$.fn.colorbox.close();
							$("#mcf1").unmask("Processing request, please wait...");
							myWindow = window.open('', '', 'status=0,toolbar=no,menubar=1,scrollbars=yes,resizable=yes,HEIGHT=700,WIDTH=800');
							myWindow.document.write(data);
							myWindow.focus();
						});
					}else{
						$("#mcf1").unmask("Processing request, please wait...");
						window.location.href = "/reports/"+instname+"/generate_csv";
					}					
				}
            });
		 },
         klass: "ocemenu-item-1"
       },
	   'Approve': {
         click: function(element){ 
		 		$(".loader").show();
				$("#mcf1").mask("Processing request, please wait...");
				$.post("/site/select_installationname_approve", {				
					}, function(data){
						$(".loader").hide();
						$.fn.colorbox.close();
						$("#mcf1").unmask("Processing request, please wait...");
						if (data == "Select Installation") {
							var message = "<div style=" + "padding-top:30px;padding-left:5px;padding-right:5px;padding-bottom:10px;font-size:small;" + ">Please select installation name and then click 'Approve' option</div>";
							$.colorbox({
								html: message,
								transition: "none",
								width: "300px",
								height: "150px"
							});
						}else {
							if (data != null) {
								$("#mcf1").unmask("Processing request, please wait...");
								show_approve();
								clearapprovalpage();
								var splitdata = data.split('|');
								if (splitdata.length > 1) {
									if (splitdata[5] == "Approved") {
										document.getElementById('crc_unapproved_utility').style.display = 'none'
										document.getElementById('crc_approved_utility').style.display = 'block'
										document.getElementById("installation_names").value = splitdata[0];
										document.getElementById("installation_approver").value = splitdata[1];
										document.getElementById("site_date").value = splitdata[2] + '  ' + splitdata[3] ;
										document.getElementById("installation_approval_crc").value = splitdata[4];
										document.getElementById("installation_approval_status").value = splitdata[5];
									}else{
										document.getElementById('crc_approved_utility').style.display = 'none'
										document.getElementById('crc_unapproved_utility').style.display = 'block'
										document.getElementById("installation_names1").value = splitdata[0];
										document.getElementById("installation_approval_status1").value = splitdata[5];
									}
								}
								else {
									document.getElementById('crc_approved_utility').style.display = 'none'
									document.getElementById('crc_unapproved_utility').style.display = 'block'
									document.getElementById("installation_names1").value = data;
									document.getElementById("installation_approver").value = "";
									document.getElementById("installation_approval_crc").value = "";
									document.getElementById("installation_approval_status1").value ="Not Approved";
								}
							}else {
								show_approve();
								document.getElementById('crc_approved_utility').style.display = 'none'
								document.getElementById('crc_unapproved_utility').style.display = 'block'
							}
						}
				});		
			
		 },
         klass: "ocemenu-item-1"
       },
	   'Rename Installation': {
         click: function(element){ 
		 		$(".loader").show();
				$.fn.colorbox({href:"/mcfextractor/rename_installationname"})		
		 },
         klass: "ocemenu-item-1"
       }
	});			
});