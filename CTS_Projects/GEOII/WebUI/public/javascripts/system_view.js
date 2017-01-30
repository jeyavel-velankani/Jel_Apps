/**
 * @author 248869
 */
$(document).ready(function() {
	add_to_destroy(function(){
		$(document).bind("ready",function(){});
	
		//kills all events
		//no events
		
		//clear intervals
		//no intervals
		
		//clear functions 
		delete window.check_integer_bounds;

		//clears global variables
		//no global variables
	});
	
	var content_contents = $("#contentcontents", window.parent.document);
	$(content_contents).css('width', 950);
	var cur_width = 0;
	$(".card_layout").each(function(index, ele){
		cur_width = cur_width + $(ele).width();
	});	
	$("#card_content").width(cur_width + 30);	
});

function check_integer_bounds(lower_bound, upper_bound, current_element){
    //alert((current_element.value > upper_bound) || (current_element.value < lower_bound));
    var flag = true;
    var page_id = current_element.id;
    
    if (!current_element.value.match(/^\d+$/)) {
        $("#" + page_id).css({
            "border": "1px solid red"
        });
        $("#" + page_id).addClass('error');
        $('.operating_update').attr('disabled', 'disabled');
        flag = false;
    }
    else 
        if (current_element.value > upper_bound) {
            $("#" + page_id).css({
                "border": "1px solid red"
            });
            $("#" + page_id).addClass('error');
            $('.operating_update').attr('disabled', 'disabled');
            flag = false;
        }
        else 
            if (current_element.value < lower_bound) {
                $("#" + page_id).css({
                    "border": "1px solid red"
                });
                $("#" + page_id).addClass('error');
                $('.operating_update').attr('disabled', 'disabled');
                flag = false;
            }
            else {
                $("#" + page_id).css({
                    "border": "1px solid #000"
                });
                $("#" + page_id).removeClass('error');
                $('.operating_update').removeAttr('disabled');
            }
    
    $('form.update_operating_parameters').find(":input").each(function(i){
        if ($(this).hasClass('error')) 
            $('.operating_update').attr('disabled', 'disabled');
    });
}
