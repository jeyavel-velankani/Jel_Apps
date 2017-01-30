/**
 * @author Jeyavel Natesan
 */

add_to_destroy(function(){
	$(document).unbind("ready");
	
	//kills all wrapper events
	$('#geoaspect_table').w_die('submit');
	$('#ptcaspect_table').w_die('submit');
	$(".save_aspect_file_config").w_die('click');
	$('.download_aspecttextfiles').w_die('click');
	$('#arrow1').w_die('click');
			
	//clear functions 
	delete window.addfield;
	delete window.deletefield;
	delete window.editfield;
	delete window.save_aspect_file_config;
	delete window.select_ptcaspect_file;
	delete window.select_lookuptable_file;
	delete window.format_ptc_data_style;
});
	
$(document).ready(function(){
	var msg= '<%= flash[:aspectlookupsuccess] %>';
	if(msg){
		$('#success_message').fadeOut(10000,function(){
			$('#success_message').html("");
		});
	}
	
	$('#geoaspect_table').submit(function(e) {
     	var options = {
          success: function(response) { 
		  	$("#contentcontents").unmask("Uploading the aspect files, Please wait...");
		  	reload_page();
          } 
     	};
     	$(this).ajaxSubmit(options);
     	return false; 
  	});
	
	$('#ptcaspect_table').submit(function(e) {
	 	var options = {
          success: function(response) { 
		  	$("#contentcontents").unmask("Uploading the aspect files, Please wait...");
		  	reload_page();
          } 
     	};
     	$(this).ajaxSubmit(options);
     	return false; 
  	});
	
	$(".save_aspect_file_config").w_click(function(){
		save_aspect_file_config();
	});
});	

$('.download_aspecttextfiles').w_click(function(){
	$("#contentcontents").mask("Downloading the aspect files, Please wait...");
	$.post("/aspectlookup/check_downloadfile_exists", {
		// no params
	}, function(data){
		$("#contentcontents").unmask("Downloading the aspect files, Please wait...");
		if(data.errorflag){
			reload_page({'errorflag':data.errorflag});
		}else{
			window.location.href = "/aspectlookup/download_aspecttextfiles";
		}
	});
});

$('#arrow1').w_click(function(event){
    event.preventDefault();
	var link_title = $(this).attr('title');
	var alternate_element = null;
    var selected_element = $('.selected_aspect_element').attr('id');			
	var next_element = $('.selected_aspect_element').next().attr('id');
    var prev_element = $('.selected_aspect_element').prev().attr('id'); 
	var prevSelected = selected_element;
    if (link_title == 'next') {
		alternate_element = next_element;
	}else if (link_title == 'prev') {
		alternate_element = prev_element;
	}					
	if ( (alternate_element != null) && (alternate_element != "") && (alternate_element != undefined)) {
        var page_url = $(this).attr('href');
        $('#position_spinner').show();
		$.post(page_url, {current_ele: selected_element, alternate_ele: alternate_element}, function(data){
			$('#position_spinner').hide();
			$('.aspect_value_table').html(data);
			selected_element = $('.selected_aspect_element').attr('id');			
			next_element = $('.selected_aspect_element').next().attr('id');
    		prev_element = $('.selected_aspect_element').prev().attr('id');
			format_ptc_data_style(prev_element,selected_element, next_element, prevSelected);
		});
	 }	
});

function format_ptc_data_style(prev_element,selected_element, next_element, prevSelected){
	if (prev_element == "" || prev_element == undefined || prev_element == null) {
		prev_element = null;
		$('.uparrow').css({
			"opacity": "0.2",
			"cursor": "default"
		});
	} else {
		$('.uparrow').css({
			"opacity": "1",
			"cursor": "pointer"
		});
	}
	if (next_element == "" || next_element == undefined || next_element == null) {
		next_element = null;
		$('.downarrow').css({
			"opacity": "0.2",
			"cursor": "default"
		});
	} else {
		$('.downarrow').css({
			"opacity": "1",
			"cursor": "pointer"
		});
	}
	document.getElementById("aspectvalGEO"+selected_element).style.background = "#CFD638";
    document.getElementById("aspectvalGEO"+selected_element).style.color = "#000";
	document.getElementById("aspectvalPTC"+selected_element).style.background = "#CFD638";
	document.getElementById("aspectvalPTC"+selected_element).style.color = "#000";
	if (selected_element != prevSelected) {
		document.getElementById("hdgeoaspval").value = document.getElementById("aspectvalGEO" + selected_element).value;
		document.getElementById("hdptcaspval").value = document.getElementById("aspectvalPTC" + selected_element).value;
	}
}

function select_lookuptable_file(){
	var select_lookuptable_path = document.getElementById("upload_input").value;
	var onchng = document.getElementById("upload_input").onchange ;
	document.getElementById("upload_input").onchange = "";	
	var valid = select_lookuptable_path.split('.');	
	var validtxt = valid[valid.length-1];
	var filename ;

	if (select_lookuptable_path.indexOf('\\') != -1) {
	    filename = select_lookuptable_path.split("\\");
	}else{
		filename = select_lookuptable_path.split('/');
	}
	var validfile_name = filename[filename.length-1];
	if ((validtxt == "txt") || (validtxt == "TXT")) {
		var split_filename = validfile_name.split('.');

		if ((split_filename[0].toLowerCase() == "aspectlookuptable") && (split_filename[split_filename.length-1].toLowerCase() == "txt") && (split_filename.length == 4)) {
			$("#contentcontents").mask("Uploading the aspect files, Please wait...");
			$.post("/aspectlookup/check_uploadfile_exists", {
				upload_filename : validfile_name,
				typeoffile : "geo_aspects"
			}, function(data){
				if (data == "overwrite") {
					$("#contentcontents").unmask("Uploading the aspect files, Please wait...");
					var confirmval = confirm("Already have '" + validfile_name + "' geo aspect text file, Do you want to override? ");
					if (confirmval) {
						document.getElementById("upload_input").onchange = onchng;
						if (select_lookuptable_path != null && select_lookuptable_path != '') {
							$("#contentcontents").mask("Uploading the aspect files, Please wait...");
							$("form.geoaspect_table").submit();
						}
					}else{
						document.getElementById("upload_input").onchange = onchng;
						if (navigator.appName == "Microsoft Internet Explorer"){
							reload_page();
						}
					}
				}else{
					document.getElementById("upload_input").onchange = onchng;
					if (select_lookuptable_path != null && select_lookuptable_path != '') {
						$("form.geoaspect_table").submit();
					}
				}
			});
		}else{
			alert("Selected geo aspect file name format should be 'aspectlookuptable.{RR}.{V}.txt'");
			document.getElementById("upload_input").onchange = onchng;
		}
	} else {
		alert("Please select text file only");
		document.getElementById("upload_input").onchange = onchng;
	}
}
   
function select_ptcaspect_file(){
    var select_ptcaspectfile_path = document.getElementById("upload_input1").value;	
	var onchng = document.getElementById("upload_input1").onchange ;
	document.getElementById("upload_input1").onchange = "";	
	var valid = select_ptcaspectfile_path.split('.');	
	var validtxt = valid[valid.length-1];
	var filename ;
	if (select_ptcaspectfile_path.indexOf('\\')!=-1) {
	    filename = select_ptcaspectfile_path.split("\\");
	}else{
		filename = select_ptcaspectfile_path.split('/');
	}
	var validfile_name = filename[filename.length-1];
	if ((validtxt == "txt") || (validtxt == "TXT")) {
		var split_filename = validfile_name.split('.');
		if ((split_filename[0].toLowerCase()=="ptcaspectvalues") && (split_filename[split_filename.length-1].toLowerCase() == "txt") && (split_filename.length == 4)) {
			$("#contentcontents").mask("Uploading the aspect files, Please wait...");
			$.post("/aspectlookup/check_uploadfile_exists", {
				upload_filename : validfile_name,
				typeoffile : "ptc_aspects"
			}, function(data){
				if (data == "overwrite") {
					$("#contentcontents").unmask("Uploading the aspect files, Please wait...");
					var confirmval = confirm("Already have '" + validfile_name + "' ptc aspect text file, Do you want to override? ");
					if (confirmval) {
						document.getElementById("upload_input1").onchange = onchng;
						if (select_ptcaspectfile_path != null && select_ptcaspectfile_path != '') {
							$("#contentcontents").mask("Uploading the aspect files, Please wait...");
							$("form.ptcaspect_table").submit();
						}
					}else{
						document.getElementById("upload_input1").onchange = onchng;
						if (navigator.appName == "Microsoft Internet Explorer"){
							reload_page();
						}
					}
				}else{
					document.getElementById("upload_input1").onchange = onchng;
					if (select_ptcaspectfile_path != null && select_ptcaspectfile_path != '') {
						$("form.ptcaspect_table").submit();
					}
				}
			});
		}else{
			alert("Selected ptc aspect file name format should be 'PTCAspectValues.{RR}.{V}.txt'");
			document.getElementById("upload_input1").onchange = onchng;
		}
	}else{
		alert("Please select text file only");
		document.getElementById("upload_input1").onchange = onchng;
	}
}
   
function save_aspect_file_config(){
	var val_aspect = document.getElementById('select_aspectlookup_file').value;
	var val_ptcaspect = document.getElementById('select_ptcaspect_file').value;
	if ((val_aspect) && (val_ptcaspect)) {
			$("#contentcontents").mask("Updating the changes, Please wait...");
		   	var select_lookuptable_path = document.getElementById('select_aspectlookup_file').options[document.getElementById('select_aspectlookup_file').selectedIndex].text;
			var select_ptcaspect_path = document.getElementById('select_ptcaspect_file').options[document.getElementById('select_ptcaspect_file').selectedIndex].text;
			var filename1 = select_lookuptable_path.split('/');
			var filename2 = select_ptcaspect_path.split('/');
		   	$.post("/aspectlookup/save", {
				selectedfilename1 : filename1[filename1.length-1],
				selectedfilename2 : filename2[filename2.length-1]
			 }, function(data){
			 	$("#contentcontents").unmask("Updating the changes, Please wait...");
			 	reload_page();
			 });
	 }else{
	 	if ((!val_aspect) && (!val_ptcaspect)) {
				alert("GEO Aspect lookup and PTC Aspect text files are not available, please load and try again");
		} else if (!val_aspect) {
				alert("GEO Aspect lookup text file is not available, please load and try again");
		} else if (!val_ptcaspect) {
				alert("PTC Aspect text file is not available, please load and try again");
		}
	}
}
   
function editfield(val){
	var txtfldgeo = "aspectvalGEO" + val;
	var txtfldptc = "aspectvalPTC" + val;
	var edtfld = "edit" + val;
	var delfld = "delete" + val;
	var geovalue = trim(document.getElementById(txtfldgeo).value);
	var ptcvalue = trim(document.getElementById(txtfldptc).value);		
	var actiontype = 'edit';
	if (document.getElementById(txtfldgeo).readOnly) {
			document.getElementById(txtfldgeo).readOnly = false;
			document.getElementById(txtfldptc).readOnly = false;
			document.getElementById(txtfldgeo).focus();
			document.getElementById(edtfld).innerHTML = "<img src='/images/check_small.png'>";
			document.getElementById(delfld).innerHTML = "<img src='/images/cross.png'>"; 
			document.getElementById(edtfld).title = "Save";
			document.getElementById(delfld).title = "Cancel";
			document.getElementById(txtfldgeo).className = "contentCSPselEdit";
			document.getElementById(txtfldptc).className = "contentCSPselEdit";
			document.getElementById(txtfldgeo).size = 30;
			document.getElementById(txtfldptc).size = 30;
	} else {
			if((trim(geovalue) == '') || (trim(ptcvalue) == '')){
				alert("Please enter GEO aspect and PTC aspect values");
				document.getElementById(txtfldgeo).focus();
				return false;
			}
			document.getElementById(txtfldgeo).readOnly = true;
			document.getElementById(txtfldptc).readOnly = true;
			document.getElementById(edtfld).innerHTML = "<img src='/images/add_edit_delete_edit.png'>";
			document.getElementById(delfld).innerHTML = "<img src='/images/add_edit_delete_delete.png'>";
			document.getElementById(edtfld).title = "Edit";
			document.getElementById(delfld).title = "Delete";
			document.getElementById(txtfldgeo).className = "contentCSPsel";
			document.getElementById(txtfldptc).className = "contentCSPsel";
			document.getElementById("hdgeoaspval").value = "";
			document.getElementById("hdptcaspval").value = "";
			$("#asplookup").mask("Processing request, please wait...");
			$.post("/aspectlookup/update", {
				aspectvalGEO_val : geovalue,
				aspectvalPTC_val : ptcvalue,
				lineno_val : val,
				actiontype : actiontype
			 }, function(data){
			 	$("#asplookup").unmask("Processing request, please wait...");	
				alert("Aspect details updated successfully");					
			 });
	}				
}
   
function deletefield(val){   
	var txtfldgeo = "aspectvalGEO" + val;
   	var txtfldptc = "aspectvalPTC" + val;
   	var edtfld = "edit" + val;
   	var delfld = "delete" + val;
	window.parent.myValue = false;
	if (document.getElementById(delfld).title == 'Delete') {
		if (confirm("Are you sure, want to delete '" + document.getElementById(txtfldgeo).value + "' aspect")) {
			$("#asplookup").mask("Processing request, please wait...");
			$.post("/aspectlookup/delete", {
				deletelineno_val: val
			}, function(data){
				alert("Aspect details deleted successfully");
				reload_page();
			});
			var tblasp = document.getElementById("mytable");
			tblasp.deleteRow(val);
		}
	} else if (document.getElementById(delfld).title == 'Remove') {	
		if (confirm("Are you sure, want to delete " + document.getElementById(txtfldgeo).value + " aspect")) {
			var tblasp = document.getElementById("mytable");
			tblasp.deleteRow(val);
		}			
	} else {
		document.getElementById(txtfldgeo).readOnly = true;
		document.getElementById(txtfldptc).readOnly = true;
		document.getElementById(edtfld).innerHTML = "<img src='/images/add_edit_delete_edit.png'>";
		document.getElementById(delfld).innerHTML = "<img src='/images/add_edit_delete_delete.png'>";
		document.getElementById(edtfld).title = "Edit";
		document.getElementById(delfld).title = "Delete";
		document.getElementById(txtfldgeo).className = "contentCSPsel";
		document.getElementById(txtfldptc).className = "contentCSPsel";
		document.getElementById(txtfldgeo).value = document.getElementById("hdgeoaspval").value;
		document.getElementById(txtfldptc).value = document.getElementById("hdptcaspval").value;
		document.getElementById("hdgeoaspval").value = "";
		document.getElementById("hdptcaspval").value = "";
	}
}

function addfield(){
	if(confirm("Do you want to add new record?")){
		var tblasp = document.getElementById("mytable");
		var rowCount = tblasp.rows.length;
        var row = tblasp.insertRow(rowCount);
		$(row).attr('id',rowCount);
		$(row).addClass('aspect_table_view');
		var cell0 = row.insertCell(0);
        var txtgeo = document.createElement("input");
        txtgeo.type = "text";
		txtgeo.id = "aspectvalGEO" + rowCount;
		txtgeo.name = "aspectvalGEO" + rowCount;
		txtgeo.size = 30;
        cell0.appendChild(txtgeo);
		
		var cell1 = row.insertCell(1);
        var txtptc = document.createElement("input");
        txtptc.type = "text";
		txtptc.id = "aspectvalPTC" + rowCount;
		txtptc.name = "aspectvalPTC" + rowCount;
		txtptc.size = 30;
        cell1.appendChild(txtptc);
		
		var cell2 = row.insertCell(2);
		cell2.innerHTML = '<a href="javascript: void(0)"><img alt="Add" border="0" id="edit'+ rowCount +'" onclick="editfield('+ rowCount +');" src="/images/check_small.png" title="Add" /></a>';
		
		var cell3 = row.insertCell(3);
		cell3.innerHTML = '<a href="javascript: void(0)"><img alt="Cancel" border="0" id="delete'+ rowCount +'" onclick="deletefield('+ rowCount +');" src="/images/cross.png" title="Remove" /></a>';
		document.getElementById("aspectvalGEO"+ rowCount).focus();
	}	
}

function trim(stringToTrim){
	return stringToTrim.replace(/^\s+|\s+$/g, "");
}