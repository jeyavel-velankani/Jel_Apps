/**
 * @author Jeyavel Natesan
 */

add_to_destroy(function(){
	$(document).unbind("ready");
	
	//kills all wrapper events
	$("#mcf_extractor").w_die('submit')
	$(".upload_apandnonapmcf").w_die('click');
	
	//clear functions 
	delete window.mdbfilecheck;
	delete window.mcffilecheck;
	delete window.mcffilecheck1;
	
	delete window.xmlfilecheck;
	delete window.change;
	delete window.clear;
	delete window.validatefile;
	delete window.filecheck;
});

$(document).ready(function(){		
  $('#mcf_extractor').submit(function(e) {
     var options = {
          success: function(response) { 
		       $(".loader").hide();
			   $.fn.colorbox.close();
               load_page("MCF Extractor","/mcfextractor/mcfextractor");      
          } 
     };
     $(this).ajaxSubmit(options);
     return false; 
  });
  
  $(".upload_apandnonapmcf").w_click(function(){
        if(filecheck()){
			$(".loader").show();
			$("#mcf_extractor").submit();
		}
  });
});

function mdbfilecheck(){
	var onchng = document.getElementById("fileToUpload").onchange ;
	document.getElementById("fileToUpload").onchange = "";
	var mdbfilepath = document.getElementById("fileToUpload").value;
	var valid = mdbfilepath.split('.');
	var validmdb = valid[valid.length-1];
	if ((validmdb == "mdb") || (validmdb == "MDB")) {
		document.getElementById("fileToUpload").onchange = onchng;
		return true;
	}else{
		alert("Please select mdb file only");
		document.getElementById("fileToUpload_path").value ="";
		document.getElementById("fileToUpload").onchange = onchng;
		return false;			
	}
return false;
}

function mcffilecheck() {
	var onchng = document.getElementById("fileToUpload1").onchange ;
	document.getElementById("fileToUpload1").onchange = "";
	var mcffilepath = document.getElementById("fileToUpload1").value;
	var valid = mcffilepath.split('.');
	var validmcf = valid[valid.length-1];
	if ((validmcf == "mcf") || (validmcf == "MCF")) {
		document.getElementById("fileToUpload1").onchange = onchng;
		return true;
	}else{
		alert("Please select mcf file only");
		document.getElementById("fileToUpload1_path").value ="";
		document.getElementById("fileToUpload1").onchange = onchng;
		return false;
	}
return false;
}

function mcffilecheck1(){
	var onchng = document.getElementById("fileToUpload11").onchange ;
	document.getElementById("fileToUpload11").onchange = "";
	var mcffilepath1 = document.getElementById("fileToUpload11").value;
	var valid = mcffilepath1.split('.');
	var validmcf = valid[valid.length-1];
	if ((validmcf == "mcf") || (validmcf == "MCF")) {
		document.getElementById("fileToUpload11").onchange = onchng;
		return true;
	}else{
		alert("Please select mcf file only");
		document.getElementById("fileToUpload11_path").value ="";
		document.getElementById("fileToUpload11").onchange = onchng;
		return false;
	}
	return false;
}

function xmlfilecheck() {
	var onchng = document.getElementById("fileToUpload3").onchange ;
	document.getElementById("fileToUpload3").onchange = "";
	var xmlfilepath = document.getElementById("fileToUpload3").value;
	var valid = xmlfilepath.split('.');
	var validxml = valid[valid.length-1];
	if ((validxml == "xml") || (validxml == "XML")) {
		document.getElementById("fileToUpload3").onchange = onchng;
		return true;
	}else{
		alert("Please select xml file only");
		document.getElementById("fileToUpload2_path").value ="";
		document.getElementById("fileToUpload3").onchange = onchng;
		return false;
	}
	return false;
}

function change(str)  {
   if (str == true || str == 'true') {
		document.getElementById('appliancemodelcontent').style.display = 'none'
		document.getElementById('nonappliancemodelcontent').style.display = 'block'
		clear(str);
	}else {
		document.getElementById('appliancemodelcontent').style.display = 'block'
		document.getElementById('nonappliancemodelcontent').style.display = 'none'
		clear(str);
	}
}
  
function clear(str)  {
	if (str == true || str == 'true') {
		document.getElementById("fileToUpload_path").value = "";
		document.getElementById("fileToUpload").value = '';
		document.getElementById("fileToUpload1_path").value = "";
		document.getElementById("fileToUpload1").value = '';
		document.getElementById("fileToUpload2_path").value = "";
		document.getElementById("fileToUpload3").value = '';
	}else{
		if ($("#mdb_file_name").val()) {
			document.getElementById("fileToUpload_path").value = $("#mdb_file_name").val();
		}		
		document.getElementById("fileToUpload11_path").value = "";
		document.getElementById("fileToUpload11").value = '';
	}
}
  
function validatefile() {
  	var mcffilepath = document.getElementById("fileToUpload1").value;
	var xmlfilepath = document.getElementById("fileToUpload3").value;
	if (((mcffilepath.length > 0) && (xmlfilepath.length == 0)) || ((mcffilepath.length == 0) && (xmlfilepath.length > 0))){
		alert("Please select 'MCF' and 'XML' both at a time.");
		return false;	
	}else {
		return true;	
	}
}
function filecheck(){
  	var file1 = document.getElementById("fileToUpload_path").value;
	var file2 = document.getElementById("fileToUpload1_path").value;
	var file3 = document.getElementById("fileToUpload2_path").value;
	var file22 = document.getElementById("fileToUpload11_path").value;
	if (document.getElementById("appliancemodelmcf").checked == true ) {
		if (file22 == null || file22 == "") {
			alert("Please Select Appliance mcf file.");
			return false;
		}else{
			return true;
		}
	}else{
		if (file1 == null || file1 == "")	{
			alert("Please Select Non-Appliance model mdb file.");
			return false;
		}else if(file2 == null || file2 == "") {
			alert("Please Select Non-Appliance model mcf file.");
			return false;
		}else if(file3 == null || file3 == "") {
			alert("Please Select Non-Appliance model mcf Mnemonic xml file.");
			return false;
		}else{
			return true;
		}
	}
}