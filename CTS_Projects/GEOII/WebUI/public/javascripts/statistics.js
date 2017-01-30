/*
-----------------------------------------------------------------------------------------------------
History:
*    Rev 1.0   Jul 05 2013 17:00:00   Gopu
* Initial revision.
-----------------------------------------------------------------------------------------------------
 */
var CheckReqDelay = 5000;
var TimeoutDelay  = 300000;
var TimersStarted = false;
var ReqTimeoutID;
var check_request_status_timer;
var statistics_status_xhr = null;
var statistics_database_cleanup_xhr = null;
var clear_ech_int; 
var process_clear_ech = false;

$(document).ready(function(){
	add_to_destroy(function(){
		$(document).bind("ready",function(){});
	
		//kills all wrapper events
		$('#stats_type').w_die('change');
        $('.stat_ech_clear').w_die('click');
	
		//clear intervals
		clearInterval(check_request_status_timer);
		
		if(typeof statistics_status_xhr !== 'undefined' && statistics_status_xhr != null){
		        statistics_status_xhr.abort();  //cancels previous request if it is still going
		}
		if(typeof statistics_database_cleanup_xhr !== 'undefined' && statistics_database_cleanup_xhr != null){
		        statistics_database_cleanup_xhr.abort();  //cancels previous request if it is still going
		}		

		//clear functions
		delete window.create_request;
		delete window.get_request_status;
		delete window.get_stats_info;
		delete window.request_timeout_occured;
		delete window.cleanup_databases;
		delete window.start_request_timers;
		delete window.stop_request_timers;
        delete window.stats_type_change;
		
		//clears global variables
		delete window.CheckReqDelay;
		delete window.TimeoutDelay;
		delete window.TimersStarted;
		delete window.ReqTimeoutID;
		delete window.check_request_status_timer;
		delete window.statistics_status_xhr;
		delete window.statistics_database_cleanup_xhr;	
        delete window.clear_ech_int;	
        delete window.process_clear_ech;
	});
	
    $("#contentcontents").css({'height': '500px', 'min-height':'0px', 'width': '930px', 'min-width':'633px'});
    create_request();
	$("#stats_type").w_change(function(){
        stats_type_change($(this))
    });
});

function stats_type_change(t){
    clearInterval(clear_ech_int);

    if(typeof echelon_status_interval !== 'undefined'){
        clearInterval(echelon_status_interval);
    }

    process_clear_ech = false;

    if(t.val() == '7'){
        $('.toolbar_button[title="Clear Current Statistics"]').hide();
         $('.toolbar_button[title="Refresh Current Statistics"]').hide();
         $('.stat_ech_clear').show();
    }else{
        $('.toolbar_button[title="Clear Current Statistics"]').show();
        $('.toolbar_button[title="Refresh Current Statistics"]').show();
        $('.stat_ech_clear').hide();
    }

    if(TimersStarted){
        stop_request_timers();
    }
     create_request(t.val());
}

function create_request(stat_cmd)
{

    if(parseInt($("#stats_type").val()) == 7){
        //LAN

        $.post('/status_monitor/echelon_status/',{

        },function(ech_resp){
            $('#status_info').html('');
            $('#stats_table').html(ech_resp).show();
        });
    }else{
        $('#stats_table').hide();
        $('#status_info').html('<div width="90%" align=center><img src="/images/large-loading.gif" border=0/><p>Loading Please wait....</p></div>');
        $.ajax({
            type:      'POST',
            url:       '/statistics/create_request',
            data:{ atcs_add:        $('#atcs_address').val(),
                   statistics_type: $('#stats_type').val(),
                   statistics_cmd:  stat_cmd
            },success: function(resultJSON)
                    {
                        try{
                            $('#current_request_id').val(resultJSON.req_id);
                            start_request_timers();
                        }
                        catch(e)
                        {
                            $('#status_info').html(resultJSON);
                            cleanup_databases();
                        }

                    }
        });
    }
}

function get_request_status()
{
    var previous_events_cnt = 0;
    statistics_status_xhr =	$.ajax({
        type:       'POST',
        url:        '/statistics/check_request_status',
        data:       { requestid: $('#current_request_id').val() },
        success: function(resultJSON)
                {
                    try
                    {
                        if(TimersStarted == true)
                        {
                            if(resultJSON.req_state == 2)
                            {
                                stop_request_timers();
                                $('#status_info').html('');
                                get_stats_info();
                            }
                        }
                    }
                    catch(e)
                    {
                        stop_request_timers();
                        $('#status_info').html(resultJSON);
                        cleanup_databases();
                    }
                }
    });
}

function get_stats_info()
{
	var req_id = $('#current_request_id').val();
    $('#stats_table').hide();
    $('#status_info').html('<div width="90%" align=center><img src="/images/large-loading.gif" border=0/><p>Loading Please wait....</p></div>');
    $.ajax({
        type:      'POST',
        url:       '/statistics/get_stats_info',
        data:      { requestid: req_id   },
        success:    function(response)
                    {
                        $('#status_info').html('');
                        $('#stats_table').show();
                        $('#stats_table').html(response);
                        cleanup_databases();
                    }
    });
}

function request_timeout_occured()
{
    stop_request_timers();
    $('#status_info').html('<p><H1>Request Timeout... </H1></p>');
    cleanup_databases();
}

function cleanup_databases(){
    statistics_database_cleanup_xhr = jQuery.ajax({
        url:        '/statistics/database_cleanup',
        type:       'POST',
        data:       { requestid:  $('#current_request_id').val() },
        beforeSend: function(){},
        success:    function() {}
    });

}

function start_request_timers()
{
    if(TimersStarted == false)
    {
        check_request_status_timer   = setInterval(function(){ get_request_status() }, CheckReqDelay);
        ReqTimeoutID = setTimeout(function(){ request_timeout_occured() }, TimeoutDelay);
        TimersStarted = true;
    }
}

function stop_request_timers()
{
    clearInterval(check_request_status_timer);
    clearTimeout(ReqTimeoutID);
    TimersStarted = false;

    if(typeof statistics_status_xhr !== 'undefined' && statistics_status_xhr != null){
            statistics_status_xhr.abort();  //cancels previous request if it is still going
    }
    if(typeof statistics_database_cleanup_xhr !== 'undefined' && statistics_database_cleanup_xhr != null){
            statistics_database_cleanup_xhr.abort();  //cancels previous request if it is still going
    }       
}


$('.stat_ech_clear').w_click(function(){
    if(!process_clear_ech){
        process_clear_ech = true;
        $(".ajax-loader").show();
        $.post('/status_monitor/echelon_clear',{
            //no params
        },function(requst_resp){
            clear_ech_int = setInterval(function(){
                 $.post('/status_monitor/check_echelon_clear',{
                    request_id:requst_resp
                },function(reply_resp){
                    if(reply_resp.error){
                        clearInterval(clear_ech_int);
                        process_clear_ech = false;
                        $(".ajax-loader").hide();
                    }else{
                        if(reply_resp.request_state == 2){
                            stats_type_change($('#stats_type'));

                            clearInterval(clear_ech_int);
                            process_clear_ech = false;
                            $(".ajax-loader").hide();
                        }
                    }   
                });
            },2000);
            
        },"json");
    }
});
