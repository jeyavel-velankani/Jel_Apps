//intervals
var periodic_updated;

var refresh_post; 
var refesh_finished = true;

add_to_destroy(function(){
	$(document).unbind("ready");

	if(typeof refresh_post !== 'undefined' && refresh_post != null){
        refresh_post.abort();  
    }

	//clear intervals
	clearInterval(periodic_updated);

	
	delete window.periodic_updated;
});
/************************************************************************************************************************
 Navigation
************************************************************************************************************************/
$(document).bind("ready",function(){
	set_content_deminsions(910,270);

	periodic_updated = setInterval(function(){
		if(refesh_finished){
			refesh_finished = false;

			refresh_post = $.post('/leds/refresh',{
				//no params
			},function(refresh_resp){
				refesh_finished = true;
				$.each(refresh_resp,function(i, value){
					if(value != null){
						var name = value['name'];
						var status_text = value['status_text'];
						var status_value = parseInt(value['status_value']);
						var led; 
						var type;

						if(status_value == 0){
							led = 'gray'
						}else if(status_value == 2 || status_value == 3){
							led = 'yellow'
						}else{
							led = 'green'
						}

						var tr = $('#'+i);

						tr.find('.name').html(name);
						tr.find('.status').html(status_text);
						tr.find('.led img').attr('src','/images/led/'+led+'.png');						
					}
				});
				refresh_post = null;
			},'json');
		}
	},5000);


});	


