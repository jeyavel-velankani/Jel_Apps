/**
 * @author Jeyavel Natesan
*/
add_to_destroy(function(){
	$(document).unbind("ready");
	
	//kills all wrapper events
	$("#userinstallationname").w_die('keyup');
	$('.upload_config').w_die('click');
	//clear functions 
	delete window.save_mcf;
	delete window.create_database_report;
	delete window.create_new_masterdb;
	delete window.open_masterdb;
	delete window.select_installation_name;
	delete window.select_installation_name_approve;
	delete window.ptcgeodb_approve;
	delete window.ptcgeodb_unapprove;
	delete window.select_nonappliance_model_mcf;
	delete window.select_mcf_file;
	delete window.check_mcf;
	delete window.remove_mcf;
	delete window.clearapprovalpage;
	delete window.get_history;
	delete window.extract_mcffiles;
	delete window.show_approve;
	delete window.open_approve_window;
	delete window.hide_approve;
});

$(document).ready(function(){
	var user_id = $('#hd_user_id').attr('value') ;
	if (user_id == "admin") {
		disable_left_nav_items(["/deviceeditor/index", "/mcfextractor/mcfextractor" , "/mcfextractor/ptcgeolog" , "/dbcomparisontool/database_comparison_tool" ]);
	}else {
		var selecteddatabase = $('#hd_mastersatabase_location').attr('value') ;
		if (!selecteddatabase) {
			disable_left_nav_items(["/deviceeditor/index"]);
		}
	}
	
	$('#btnback').hide();
	$("#navigation1").treeview1({
		persist: "location",
		collapsed: true,
		unique: true
	});
	
	$("#userinstallationname").w_keyup(function(){  
		var objPattern = /^[0-9A-Za-z_-]+$/i;
		if (($("#userinstallationname").val() != null) && ($("#userinstallationname").val() != "")) {
			if (!objPattern.test($("#userinstallationname").val())){
				$(this).css("border", "1px solid red");
			}else {
				$(this).css("border", "1px solid #888");
			}
		}else{
			$(this).css("border", "1px solid #888");
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
	
	$('#navigation1 li').mousedown(function(event) {
		var selectedelementid = this.id;
		if (selectedelementid)  {				
		    switch (event.which) {
				case 1:
					//alert('Left mouse button pressed');
					$('#navigation1 li').removeClass('selected');
					$(this).addClass('selected');
					$.post("/mcfextractor/page_node", {
						installation_name_delete: selectedelementid
					});
					break;
				case 2:
					//alert('You have clicked middle mouse button.');
					var message ="<div style="+"padding-top:30px;padding-left:5px;color:red;padding-right:5px;padding-bottom:10px;font-size:small;"+">You have clicked middle mouse button</div>";
					$.colorbox({html:message ,transition:"none" ,width:"300px" ,height:"150px"});
					break;
				case 3:
					//alert('Right mouse button pressed');
					document.getElementById("hdselectedinstname").value = selectedelementid;
					$('#navigation1 li').removeClass('selected');
					$(this).addClass('selected');
					$.post("/mcfextractor/page_node", {
						installation_name_delete: selectedelementid
					});
					break;
				default: break;
			}
	    }
	});
});	

function save_mcf(){
    var installation_name = prompt('Please provide installation name (should not contain special characters)');
    if (installation_name != null && installation_name != '') {
        $("#contentcontents").mask("Extracting the mcfs, Please Wait...");
        $.post("/mcfextractor/addmcf", {
            installation_name: installation_name
        }, function(data){
			$("#contentcontents").unmask("Extracting the mcfs, Please Wait...");
			load_page("MCF Extractor","/mcfextractor?installation_name=" + installation_name );
        });
    }
    return false;
}
	
function create_database_report(){
	var dbpath = document.getElementById("maintMasterDBPath").value;
	var x = dbpath.split('/');
	var databasename = x[1].split('.');
	if (navigator.appName == "Microsoft Internet Explorer") {
		myWindow = window.open("http://"+window.location.host+"/reports/db|"+databasename[0]+"/generate_csv",'','status=0,toolbar=no,menubar=1,scrollbars=yes,resizable=yes,HEIGHT=700,WIDTH=800');
		myWindow.focus();
	}else{
		window.location.href = "/reports/db|"+databasename[0]+"/generate_csv";
	}		
}

function create_new_masterdb(){
	$.fn.colorbox({href : "/mcfextractor/create_new_masterdatabase"})
}

function open_masterdb(){
	$.fn.colorbox({href:"/mcfextractor/open_masterdatabase"})
}

function select_installation_name(){
	$.fn.colorbox({href:"/mcfextractor/select_installation_name_report"})
}

function select_installation_name_approve(){
	$.fn.colorbox({href:"/mcfextractor/select_installation_name_approve"})
}

function ptcgeodb_approve(){
	$.fn.colorbox({href:"/mcfextractor/approve_installation_name"})
}

function ptcgeodb_unapprove(){
	$.fn.colorbox({href:"/mcfextractor/unapprove_installation_name"})
}

function select_nonappliance_model_mcf(){
	$.fn.colorbox({href:"/mcfextractor/upload_am_non_am_mcf",width:"500px" , height :"250px" })
}

function select_mcf_file(){
	var select_mcf_path = document.getElementById("upload_input").value;
	var valid = select_mcf_path.split('.');
	if (valid[1]=="mcf"){
		setConfirmUnload(false);
		if (select_mcf_path != null && select_mcf_path != '') {
            $("form.mcf_extractor").submit();
        }
	}else{
		alert("Please select mcf file only");
	}	
	return false;
}

function check_mcf(){
	var len = document.getElementById('mcffiless_mcffile').options.length;
	if (len > 0){
		return true;
	}else{
		return false;	
	}
}

function remove_mcf(removestring){
	var len = document.getElementById('mcffiless_mcffile').options.length;
	var selected_mcf_path = "";		
	var Count = 0;
	if (len > 0) {				
		if(removestring =="Selected"){
			var arrayval = []
			for (var i = 0; i < len; i++) {
				if (document.getElementById('mcffiless_mcffile').options[i].selected)
				{
					arrayval[Count] = document.getElementById('mcffiless_mcffile').options[i].value;
					Count++;
				}
			}
			if(Count > 0){
				for(var j = 0; j< arrayval.length;j++){
					selected_mcf_path =  arrayval[j]+'|'+selected_mcf_path
				}
				$('.mcfspinner').show();
				$.post("/mcfextractor/remove_mcf", {
					removestring: selected_mcf_path
				}, function(data){
					$('.mcfspinner').hide();
					$("#mcffiless_mcffile >option").remove();
					var splitvalue = data.split('|')
					for (var i = 0; i < splitvalue.length - 1; i++) {
						$('#mcffiless_mcffile').append($('<option></option>').val(splitvalue[i]).html(splitvalue[i]));
					}
					if (splitvalue.length >1){
						$("#extract_mcffile").show();
						$("#userinstallationname").show();
						$("#lbluserinstallationname").show();
					}else{
						$("#extract_mcffile").hide();
						$("#userinstallationname").hide();
						$("#lbluserinstallationname").hide();
					}
				});
			}else{
				alert("Please select mcf file from the list");
				return false;
			}
		} else if (removestring == "All"){
			$('.mcfspinner').show();
			if ($("#congif_top_icons").length > 0){
				document.getElementById("congif_top_icons").innerHTML = "";	
			}
			$.post("/mcfextractor/remove_mcf", {
				removestring: removestring
			}, function(data){
				$('.mcfspinner').hide();
				$("#mcffiless_mcffile >option").remove();
				var splitvalue = data.split('|')
				for (var i = 0; i < splitvalue.length - 1; i++) {
					$('#mcffiless_mcffile').append($('<option></option>').val(splitvalue[i]).html(splitvalue[i]));
				}
				if (splitvalue.length >1){
					$("#extract_mcffile").show();
					$("#userinstallationname").show();
					$("#lbluserinstallationname").show();	
				}else{
					$("#extract_mcffile").hide();
					$("#userinstallationname").hide();
					$("#lbluserinstallationname").hide();
				}
			});
		}else{
			alert("Please select mcf file from the list");
		}
	}else{
		alert("There is no files to delete");
	}
}

function clearapprovalpage(){
	document.getElementById("installation_names").value = "";
	document.getElementById("installation_approver").value ="";
	document.getElementById("installation_approval_crc").value ="";
	document.getElementById("site_date").value ="";
	document.getElementById("installation_approval_status").value ="Not Approved";
	$('#btnback').hide();
}

function get_history(status){
	var installationname;
	if (status =="Approved"){
		installationname = document.getElementById("installation_names").value	
	}else{
		installationname = document.getElementById("installation_names1").value
	}
    $.post("/mcfextractor/gethistory", {
        installationname : installationname
    }, function(data){
		document.getElementById('mcf_extract_utility').style.display = 'none'
		document.getElementById('crc_approved_utility').style.display = 'none'
		document.getElementById('crc_unapproved_utility').style.display = 'none'
		document.getElementById('approval_history').style.display = 'block'
		$('#btnback').show();
		$('#approval_history').html(data);
    });
}
function extract_mcffiles(){
    var userinstallationname = document.getElementById("userinstallationname").value;
	var objPattern = /^[0-9A-Za-z_-]+$/i;
	if ((userinstallationname != null) && (userinstallationname != "")){
		if (objPattern.test(userinstallationname)) {
			$("#contentcontents").mask("Extracting the mcfs, Please Wait...");
            $.post("/mcfextractor/extractmcf", {
				userinstallationname : userinstallationname
            }, function(data){
				$("#contentcontents").unmask("Extracting the mcfs, Please Wait...");
                load_page("MCF Extractor","/mcfextractor/mcfextractor");
            });	
		}else{
				alert("Please enter valid installation name[only alpha numeric, _ , -] ");
				document.getElementById("userinstallationname").focus();
				return false;
		}
	}else{
		alert("Please enter installation name and try again");
		document.getElementById("userinstallationname").focus();
		return false;
	}  
}

function show_approve() {
	$('#btnback').hide();
	document.getElementById('mcf_extract_utility').style.display = 'none'
	document.getElementById('approval_history').style.display = 'none'
}

function open_approve_window(){
	$.post("/site/get_installation_approve_back", {
		// no params
	}, function(data){
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
}

function hide_approve() {
	document.getElementById('mcf_extract_utility').style.display = 'block'
	document.getElementById('crc_approved_utility').style.display = 'none'
	document.getElementById('crc_unapproved_utility').style.display = 'none'
	document.getElementById('approval_history').style.display = 'none'
	$('#btnback').hide();
}
 