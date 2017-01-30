/**
 * @author Jeyavel Natesan
 */

add_to_destroy(function(){
	$(document).unbind("ready");
	
	//kills all wrapper events
	$(".btnok_createrc2key").w_die('click');
	$(".btndownloadrc2key").w_die('click');
	
	//clear functions 
	delete window.valudate_rc2keyvalue;
	delete window.valudate_rc2keyvalue_feild;
});

 $(document).ready(function(){
	$(".btnok_createrc2key").w_click( function(){
		document.getElementById("rc2key_success").innerHTML = "";
		document.getElementById("rc2key_error").innerHTML = "";
		if (!valudate_rc2keyvalue_feild()) {
			$(".rc2key_loader").hide();
			return false;
		}else {
			var rc2key_value = document.getElementById('txtrc2key_value').value;
			$.post("/selectsite/generate_rc2keyfile", {
				txtrc2key_value: rc2key_value
			}, function(response){
				if (response) {
					$(".rc2key_loader").hide();
					document.getElementById("rc2key_success").innerHTML = "Successfully created rc2key.bin";
					document.getElementById('txtrc2key_file_name').value = response.rc2key_filename;
					var append = "<div style='padding-left:25px;''><label>RC2 key file crc: </label></div>"
					append += "<div style='padding-left:25px;'><input type='text' id='mcfcrc_uploadtext' value=" + response.rc2keyvale_crc + " class='contentCSPsel_rc2key' disabled='disabled'/></div>"
					$(".append_content").html(append);
					document.getElementById('download_and_recreate_content').style.display = 'block';
					$("#btnok_createrc2key").hide();
				}else {
					$(".rc2key_loader").hide();
					document.getElementById("rc2key_error").innerHTML = "RC2Key file not generated please try again";
				}
			});
		}
	});
	
	$(".btndownloadrc2key").w_click( function(){
		var created_rc2key_filename =  document.getElementById('txtrc2key_file_name').value ;
		var download_path = "/selectsite/download_rc2keyfile?rc2key_filename=" + created_rc2key_filename;
		window.location.href = download_path
		$.fn.colorbox.close();
	});
});

function valudate_rc2keyvalue(obj, txt){		
	if ((obj.value == null) || (obj.value == "")) {			
		document.getElementById("rc2key_error").innerHTML = "Please enter " + txt + "RC2Key value and try again.";
		return false;		
	}
	return true;
}

function valudate_rc2keyvalue_feild(){		
	if($("#txtrc2key_value").val() != $("#txtconfirmrc2key_value").val()){
		document.getElementById("rc2key_error").innerHTML = "Confirm RC2Key value is not matching with RC2Key value.";
		$("#txtconfirmrc2key_value").focus();
		return false;
	}else{
		document.getElementById("rc2key_error").innerHTML = "";
	}
	
	if (($("#txtrc2key_value").val() != null) && ($("#txtrc2key_value").val() != "")) {
		$(".rc2key_loader").show();
		return true;
	}else{
		document.getElementById("rc2key_error").innerHTML = "Please enter RC2Key value and try again.";
		return false;
	}	
}