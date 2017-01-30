/**
 * @author 269407
 */

 
$(document).ready(function(){
	$(".detail_logic").w_click(function(){
		var header = $("#contentareahdr", window.parent.document);
		var spinner = $("#loading", window.parent.document);
		
		$(header).html('Logic Detail View');
		$("#contentdata").html("");
		$(spinner).show();
		
		var parameter_name = $(this).attr('parameter_name');
		var card_index = $(this).attr('card_index');
		var parameter_type = $(this).attr('parameter_type');
		
		window.location = '/logic_view/detail_logic_view?parameter_name='+parameter_name+'&card_index='+card_index+'&parameter_type='+parameter_type + '&logic_type=param';
	});
	
	$(".link_sub_equation").w_click(function(){	
		var header = $("#contentareahdr", window.parent.document);
		var spinner = $("#loading", window.parent.document);
		var page_header = $(".page_header").html();
		var page_history = document.getElementById("hd_history").value;
		$(header).html('Logic Detail View');
		$("#contentdata").html("");
		$(spinner).show();
		var term_name = $(this).attr('term_name');
		var card_index = $(this).attr('card_index');
		window.location = "/logic_view/detail_logic_view?term_name=" + term_name + "&card_index=" + card_index + "&logic_type=term" + "&page_header=" + page_header + "&page_history=" + page_history;
	});
	
});

function open_prev_page()
	{
		var page_history = document.getElementById("hd_history").value;
		//alert(page_history);
		var arr_history = page_history.split("^^");
		var prev_history = "";
		var prev_page = "";
		if (arr_history.length > 1){
			for (var i = 0; i < (arr_history.length - 1); i++){
				if (prev_history.length == 0){
					prev_history = arr_history[i];
				}
				else{
					prev_history = prev_history + "^^" + arr_history[i];
				}
			}
			prev_page = arr_history[arr_history.length - 2];
		}		
		//params[:logic_type].to_s + "|" + str_name + "|" + params[:card_index].to_s + "|" + page_header
		var page_params = prev_page.split('|');
		var logic_type = page_params[0];
		var strname = page_params[1];
		var card_index = page_params[2];
		var page_header = page_params[3];
		var str_link = "";
		
		if (logic_type ==  "param"){
			var parameter_type = 2;
			str_link = "parameter_name=" + strname + "&card_index=" + card_index + "&parameter_type=" + parameter_type + "&logic_type=param";
		}
		else{
			str_link = "term_name=" + strname + "&card_index=" + card_index + "&logic_type=term" + "&page_header=" + page_header + "&page_history=" + prev_history + "&history_flag=true";
		}
		//alert(str_link);
		
		var header = $("#contentareahdr", window.parent.document);
		var spinner = $("#loading", window.parent.document);
		$(header).html('Logic Detail View');
		$("#contentdata").html("");
		$(spinner).show();		
		window.location = "/logic_view/detail_logic_view?" + str_link;
		
	}
	
function reload_relay_logic(){
	var page_history = document.getElementById("hd_history").value;
	var arr_history = page_history.split("^^");
	var current_page = "";
	if (arr_history.length > 0){
		current_page = arr_history[arr_history.length - 1];
	}
	var page_params = current_page.split('|');
	var logic_type = page_params[0];
	var strname = page_params[1];
	var card_index = page_params[2];
	var page_header = page_params[3];
	var str_link = "";
	
	if (logic_type ==  "param"){
		var parameter_type = 2;
		str_link = "parameter_name=" + strname + "&card_index=" + card_index + "&parameter_type=" + parameter_type + "&logic_type=param";
	}
	else{
		str_link = "term_name=" + strname + "&card_index=" + card_index + "&logic_type=term" + "&page_header=" + page_header + "&page_history=" + page_history + "&history_flag=true";
	}
	//alert(str_link);
	
	var header = $("#contentareahdr", window.parent.document);
	var spinner = $("#loading", window.parent.document);
	$(header).html('Logic Detail View');
	$("#contentdata").html("");
	$(spinner).show();		
	window.location = "/logic_view/detail_logic_view?" + str_link;
	
}
	

