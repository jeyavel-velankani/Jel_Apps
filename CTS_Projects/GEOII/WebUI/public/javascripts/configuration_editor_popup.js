/**
 * @author Jeyavel Natesan
 */
add_to_destroy(function(){
	$(document).unbind("ready");
	
	//kills all wrapper events
	$("#saveas_site_name").w_die('keyup');
	$(".btn_ok_saveas_site").w_die('click');
	$(".cancel_button").w_die('click');
	$(".open_configuration").w_die('click');
	
	//clear functions 
	delete window.valudate_saveassitename;
});
		
$(document).ready(function(){
	$("#saveas_site_name").w_keyup(function(){
		var objPattern = /^[0-9A-Za-z_-]+$/i;
			if (($("#saveas_site_name").val() != null) && ($("#saveas_site_name").val() != "")) {
				if (!objPattern.test($("#saveas_site_name").val()))
					$(this).css("border", "1px solid red");
				else {
					$(this).css("border", "1px solid #888");
				}
			}else{
				$(this).css("border", "1px solid #888");
			}
     });
     
	$(".btn_ok_saveas_site").w_click( function(){
		document.getElementById("buildcheck12").innerHTML = "";
		$(".saveas_open_loader").show();
		if (($("#saveas_site_name").val() != null) && ($("#saveas_site_name").val() != "")) {
			var name = document.getElementById("saveas_site_name").value;
			if (valudate_saveassitename){
				$.post("/selectsite/saveassiteconfigfiles", {
					saveassitename: name
				}, function(data){
				  if (typeof data.message != 'undefined' && data.message != null) {
				  	$(".saveas_open_loader").hide();
				  	alert(data.message);
				  }
				  else {
				  	if ((data.length > 0) && (data != "Site name already exist")) {
				  		load_selected_configuration(data, "saveas");
				  	}
				  	else {
				  		$(".saveas_open_loader").hide();
				  		alert("Site Name already exist");
				  	}
				  }
				});
			}
		}
		else{
			$(".saveas_open_loader").hide();
			alert("Please enter site name");
		}
	});
	
	$(".cancel_button").w_click(function(){
		$.fn.colorbox.close();
	});
	
	$(".open_configuration").w_click(function(){
		document.getElementById("buildcheck12").innerHTML = "";
		$("#selected_folder").css({"border":"1px solid #000"});
		var selected_folder = $("#selected_folder").val();
		if(selected_folder != "" && selected_folder != "Select"){
			load_selected_configuration(selected_folder, "");
		}else{
			$("#selected_folder").css({"border":"1px solid red"});
		}
	});
});

function valudate_saveassitename(){
	var objPattern = /^[0-9A-Za-z_-]+$/i;
	if (($("#saveas_site_name").val() != null) && ($("#saveas_site_name").val() != "")) {
		if (!objPattern.test($("#saveas_site_name").val())) {
			alert('Please enter valid site name.');
			document.getElementById("saveas_site_name").focus();
			return false;
		}
		else
		{
			return true;
		}
	}
}


function change_product_type() {
	var product_type = document.getElementById('selected_product').options[document.getElementById('selected_product').selectedIndex].text;
	var iviu_ptc_geo = $('#hd_iviu_ptc_geo').val().split('||');
	var iviu = $('#hd_iviu').val().split('||');
	var viu = $('#hd_viu').val().split('||');
	var geo = $('#hd_geo').val().split('||');
	var gcp = $('#hd_gcp').val().split('||');
	var geo_cpu3 = $('#hd_geo_cpu3').val().split('||');
	var root_path = $('#hd_root_directory').val();
	var valarray = "";
	var valarray_path = "";
	var site_name = "";

	if (product_type == "IVIU PTC GEO") {
		valarray = iviu_ptc_geo;
	} else if (product_type == "IVIU") {
		valarray = iviu;
	} else if (product_type == "VIU") {
		valarray = viu;
	} else if (product_type == "GEO") {
		valarray = geo;
	} else if (product_type == "GCP") {
		valarray = gcp;
	} else if (product_type == "GEO CPU3") {
		valarray = geo_cpu3;
	} else if (product_type.toUpperCase() == "SELECT") {
		valarray = "";
		$("#selected_folder >option").remove();
		$('#selected_folder').append($('<option></option>').val("").html('Select'));
	}
	if (valarray != "") {
		$("#selected_folder >option").remove();
		for (var i = 1; i < (valarray.length); i++) {
			site_name = valarray[i];
			valarray_path = root_path + "/" + valarray[i];
			$('#selected_folder').append($('<option></option>').val(valarray_path).html(site_name));
		}
	}
	else{
		valarray = "";
		$("#selected_folder >option").remove();
		$('#selected_folder').append($('<option></option>').val("").html('Select'));
	}
}
