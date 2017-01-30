$(document).ready(function(){
	if($("#hd_product_type").val() == "0"){
		if ($('#parameters_missing').length > 0 && $('#parameters_missing').val() != "0") {
			$('.message_container span').html("").removeClass("success_message").removeClass("warning_message").addClass("error_message").html("Parameters are missing in realtime database. To resolve this issue click on fix button.").show();
			$('.message_container div').html("<img src='/images/fix.png' alt='Update parameters'>").show();
			$("#contentcontents").unmask("Loading contents, please wait...");
		}else {
			if ($('#parameter_count').length > 0 && $('#parameter_count').val() != "0") {
				if ($("#hd_product_type").val() == "0" && $(".verify_screen").val() == "true") {
					screen_verification_request();
				}
				else 
					$("#contentcontents").unmask("Loading contents, please wait...");
			}
			else {
				$('.v_refresh, .unlock').addClass("disabled");
				$("#contentcontents").unmask("Loading contents, please wait...");
			}
		}
	}
	
	$('.v_save').addClass("disabled");
	$('.v_force_update').hide();
});