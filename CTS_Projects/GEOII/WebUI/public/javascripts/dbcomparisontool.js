/**
 * @author Jeyavel Natesan
 */

add_to_destroy(function(){
	$(document).unbind("ready");
	
	//kills all wrapper events
	$("#database1path").w_die('change');
	$("#database2path").w_die('change');
	$(".start_merge").w_die('click');
	$(".save_comparison_report").w_die('click');
			
	//clear functions 
	delete window.merge_database;
	delete window.save_dbcomparison_report;
	delete window.compare_database;
});

 $(document).ready(function(){
 	var db_avail_flag = $("#hd_file_available_flag").val();
	if (db_avail_flag == 'false') {
		$(".start_merge").addClass('disable');
		$(".save_comparison_report").addClass('disable');
	}

 	$("#database1path").w_change(function(){
		$('#mycontent').html("");
		var selectdatabase1 = document.getElementById('database1path').options[document.getElementById('database1path').selectedIndex].text;
		$.post("/dbcomparisontool/selected_database1", {
			selecteddatabase1 : selectdatabase1
		}, function(data){});
	});
	
	$("#database2path").w_change(function(){
		$('#mycontent').html("");
		var selectdatabase2 = document.getElementById('database2path').options[document.getElementById('database2path').selectedIndex].text;
		$.post("/dbcomparisontool/selected_database2", {
			selecteddatabase2 : selectdatabase2
		}, function(data){});
	});
	
	$(".start_merge").w_click(function(){
		if (!$(this).hasClass('disable')) {
			merge_database();
		}
	});
	
	$(".save_comparison_report").w_click(function(){
		if (!$(this).hasClass('disable')) {
			save_dbcomparison_report();
		}
	});
});
	
function merge_database(){
	document.getElementById('comparisonerrormessage').innerHTML = "";
	var dbname1 = document.getElementById('database1path').options[document.getElementById('database1path').selectedIndex].text;
	var dbname2 = document.getElementById('database2path').options[document.getElementById('database2path').selectedIndex].text;
	if (trim(dbname1) != trim(dbname2)){
		var db1 = document.getElementById('database1path').options[document.getElementById('database1path').selectedIndex].value;
		var db2 = document.getElementById('database2path').options[document.getElementById('database2path').selectedIndex].value;
		$('#mycontent').html("");
		$("#contentcontents").mask("Processing request, please wait...");
		$.post("/dbcomparisontool/merge_data", {
			database1 : db1 ,
			database2 : db2
		}, function(data){
		 	$("#contentcontents").unmask("Processing request, please wait...");
			if (data) {
				document.getElementById('comparisonerrormessage').innerHTML = data;
				return false;
			}else{
				document.getElementById('comparisonerrormessage').innerHTML = "";
				compare_database();
			}
		});
	}else{
		alert("Please select two different databases and try again");
		return false;
	}
}

function save_dbcomparison_report(){
	document.getElementById('comparisonerrormessage').innerHTML = "";
	$("#contentcontents").mask("Processing request, please wait...");
	$.post("/dbcomparisontool/downloadcomparison_report", {
	}, function(data){
		if (data) {
			$("#contentcontents").unmask("Processing request, please wait...");
			var myWindow = window.open('', '', 'status=0,toolbar=no,menubar=1,scrollbars=yes,resizable=yes,HEIGHT=700,WIDTH=800');
			myWindow.document.write(data);
			myWindow.focus();
		}else{
			$("#contentcontents").unmask("Processing request, please wait...");
			alert("Comparison report not available");
			return false;
		}
	});
}

function compare_database(){
	$('#mycontent').html("");
	var database1 = document.getElementById('database1path').options[document.getElementById('database1path').selectedIndex].text;
	var database2 = document.getElementById('database2path').options[document.getElementById('database2path').selectedIndex].text;
	$("#contentcontents").mask("Processing request, please wait...");
	$.post("/dbcomparisontool/database_comparison_tool_1", {
		db1 : database1,
		db2 : database2
	}, function(data){
		$('#mycontent').html(data);
		$("#contentcontents").unmask("Processing request, please wait...");
	});
}