/**
 * @author Jeyavel Natesan
 */

add_to_destroy(function(){
	$(document).unbind("ready");
	
	//kills all wrapper events
	$(".open_geoptcdb").w_die('click');
	$(".cancel").w_die('click');
	$(".installation_folder").w_die('click');
});

$(document).ready(function(){
	$(".open_geoptcdb").w_click( function(){
		var selected_file = document.getElementById('selected_file').options[document.getElementById('selected_file').selectedIndex].text;
		if(selected_file != "" && selected_file != "Selected File"){
			$(".loader").show();
			$.post("/site/ptcgeodb_opengeoptcmasterdb", {
				open_masterdbfile_path_name: selected_file
			}, function(data){
				$(".loader").hide();
				$.fn.colorbox.close();
				load_page("MCF Extractor","/mcfextractor/mcfextractor");
				enable_left_nav_items(["/deviceeditor/index"]);
			});
		}else{
			$("#selected_file").css({"border":"1px solid red"});
		}
	});
	
	$(".cancel").w_click(function(){
		$.fn.colorbox.close();
	});
	
	$(".installation_folder").w_click(function(){
		$("#installation_folder").css({"border":"1px solid #000"});
		var installation_folder = $("#installation_folder").val();
		var filename = $("#file_name").val();
		var objPattern = /^[0-9A-Za-z_-]+$/i;
		if (filename != "" && filename != "File name") {
			if ((filename != "Masterdb") && (filename != "masterdb")) {
				if (!(objPattern.test(filename))) {
					alert('Please enter valid database file name');
					$("#file_name").css({
						"border": "1px solid red"
					});
					document.getElementById("file_name").focus();
					return false;
				}
				$(".loader").show();
				$.post("/site/ptcgeodb_create_new_geoptcdb", {						
					file_name: filename
				}, function(data){
					$(".loader").hide();
					$.fn.colorbox.close();
					load_page("MCF Extractor","/mcfextractor/mcfextractor");
					enable_left_nav_items(["/deviceeditor/index"]);
				});
			}else {
				alert('Please enter different db name, \nThe name Masterdb not accepted by the application.');
				$("#file_name").css({
					"border": "1px solid red"
				});
			}
		}else {
			alert('Please enter database file name');
			$("#file_name").css({
				"border": "1px solid red"
			});
		}
	});	
});