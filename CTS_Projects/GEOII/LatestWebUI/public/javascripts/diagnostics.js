/**
* @author 248869
*/

var auto_refresh_interval;
var request_in_process = false;
var alarms_refresh_xhr = null;

$(document).ready(function(){
	add_to_destroy(function(){
		$(document).bind("ready",function(){});
	
		//kills all wrapper events
		$('#select_slot').w_die('change');
		$('.row_sel_style').w_die('click');

		//clear intervals
		clearInterval(auto_refresh_interval);
		
		if(typeof alarms_refresh_xhr !== 'undefined' && alarms_refresh_xhr != null){
		        alarms_refresh_xhr.abort();  //cancels previous request if it is still going
		}
		
		//clear functions
		delete window.auto_refresh_alarms;

		//clears global variables
		delete window.auto_refresh_interval;
		delete window.request_in_process;
		delete window.alarms_refresh_xhr;
	});
	
	$("#contentcontents").css({'height': '400px', 'min-height':'350px'});
	var track_menu = '<%= params[:system_view] %>';
	if(track_menu != null && track_menu != undefined && track_menu != ""){
		jQuery("#contentareahdr").html('<%= params[:page_heading] %>');
	}
	
	auto_refresh_alarms();
	
	$(document).on("change", "#select_slot",function () {
		$("#current_slot").val($('#select_slot').val());
		$('#alarm_cause').html("");
		$('#alarm_remedy').html("");
		clearInterval(auto_refresh_interval);
		$(".ajax-loader").hide();
		auto_refresh_alarms(); 
	});

	$(document).on("click", ".row_sel_style",function () {
	    $('.row_sel_style').each(function(index, ele){
	    	if(index%2 == 0){
	    		$(ele).children().css({        			
	            	"background-color": "#515151",
	            	"color": "#FFF"
	        	});         		
	    	}else{
	    		$(ele).children().css({        			
	            	"background-color": "#424242",
	            	"color": "#FFF"
	        	}); 
	    	}
	    });
	    $(this).children().css({
	        "background-color": "#CFD638",
	        "color": "#000"
	    });
	           
	    sel_id = $(this).attr('id');
	    if ($("#hd_" + sel_id).val().length > 0){
	    	cause_remedy = $("#hd_" + sel_id).val().split('Remedy:');        
	        $("#alarm_cause").html(cause_remedy[0].replace("Cause:","").replace("<BR>","").replace(/^\s+|\s+$/g,""));
	        if(cause_remedy[1] != undefined){
	        	$("#alarm_remedy").html(cause_remedy[1].replace("<BR>","").replace(/^\s+|\s+$/g,""));
	        }
	        else{
	        	$("#alarm_remedy").html("");
	        }
	    }
	    else
	    {
	    	$("#alarm_cause").html("");
	        $("#alarm_remedy").html("");
	    }        
	    
	    var div_height = $("#div_cause_remedy").height();
	    var frm_height = 400 + div_height - 29;
		$("#contentcontents").css({'height': frm_height + 'px', 'min-height':'350px'});		
	});	
});

function auto_refresh_alarms(){
	request_in_process = false;
	auto_refresh_interval = setInterval(function(){
	var slotnum = $("#current_slot").val();
	var page_no = $("#hd_page").val();
		if (!request_in_process) {
			request_in_process = true;
			$(".ajax-loader").show();
			alarms_refresh_xhr = $.post('/application/alarms_refresh', {
				slot_num: slotnum,
				page: page_no
			}, function(req){
				request_in_process = false;
				$('#system_alarm').html(req.alarms_content);
				$(".ajax-loader").hide();
			}, "json");
		}	
	}, 3000);
}
