/**
 * @author Jeyavel Natesan
 */

add_to_destroy(function(){
	$(document).unbind("ready");
	
	//kills all wrapper events
	$(".btn_save_template").w_die('click');
	$(".cancel_button").w_die('click');
	
	//clear functions 
	delete window.valudate_templatename;
});
		
$(document).ready(function(){
	$(".btn_save_template").w_click( function(){
		document.getElementById("buildcheck12").innerHTML = "";
		$(".template_loader").show();
		if (($("#template_name").val() != null) && ($("#template_name").val() != "")) {
			var name = document.getElementById("template_name").value;
			var site_location = document.getElementById("hd_site_location").value;
			var template_check = document.getElementById("template_checkbox").checked;
			if (valudate_templatename()){
				$.post("/selectsite/create_template_file", {
					templatename  : name,
					site_location : site_location,
					template_check :template_check
				}, function(data){
				   if (typeof data.message != 'undefined' && data.message != null) {
				  	 $(".template_loader").hide();
				  	 if(data.message){
				  	 	alert(data.message);	
				  	 }else{
				  	 	alert("Template updated successfully");
				  	 	$.fn.colorbox.close();
						remove_v_preload_page();
						reload_page();
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
});

function valudate_templatename(){
	var objPattern = /^[0-9A-Za-z_-]+$/i;
	if (($("#template_name").val() != null) && ($("#template_name").val() != "")) {
		if (!objPattern.test($("#template_name").val())) {
			alert('Please enter valid template name.');
			document.getElementById("template_name").focus();
			return false;
		}else{
			return true;
		}
	}
}