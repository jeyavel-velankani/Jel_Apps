/**
 * @author 248869
 */

var routes_interval;
var route_table_xhr =  null;

$(document).ready(function(){
	add_to_destroy(function(){
		$(document).bind("ready",function(){});
	
		//kills all wrapper events
		$('#atcs_routes').w_die('click');
	
		//clear intervals
		clearInterval(routes_interval);

		if(typeof route_table_xhr !== 'undefined' && route_table_xhr != null){
		        route_table_xhr.abort();  //cancels previous request if it is still going
		}
		
		//clears global variables
		delete window.routes_interval;
		delete window.route_table_xhr;
	});
	
	var request_in_process = false;
	routes_interval= setInterval(function(){
		if (!request_in_process) {
			request_in_process = true;
			route_table_xhr = $.post('/route_table', {
				auto_refresh: true
			}, function(response){
				$("#atcs_routes").html(response);
				request_in_process = false;
			});
		}	
	}, 3000);
});
