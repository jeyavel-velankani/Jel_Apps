var operation_post = null;

$(document).ready(function() {
	add_to_destroy(function(){
		$(document).unbind("ready");
	
		if(typeof operation_post !== 'undefined' && operation_post != null){
	        operation_post.abort();  //cancels previous request if it is still going
		}
	
		//kills all wrapper events
		$('.operation_input').w_die('change');
		$('#cdl_operational').w_die('change');
		$('.operational_save').w_die('click');
		$('.operational_refresh').w_die('click');
	
		//clear functions 
		delete window.cdl_parameter_validation;
	
		//clears global variables
		delete window.operation_post
	});

	
	$('.operation_input').w_change(function(){
		var min = parseInt($(this).attr('min'));
		var max = parseInt($(this).attr('max'));
		var cur_value = parseInt($(this).val());
		var param_name = $(this);
		
		if((min <= cur_value ) && ( cur_value <= max)){
			$(this).closest('.serialright').find('.error_message').html('');
		}else{
			var msg = "Parameter should be of "+min+" to "+max;
			$(this).closest('.serialright').find('.error_message').html(msg);
		}
	
		var operation_error = false;
		$('.operation_input').each(function(){
			if(parseInt($(this).val()) < parseInt($(this).attr('min')) || parseInt($(this).val()) >  parseInt($(this).attr('max'))){
				operation_error = true;
	
			}
		});
	
		if(operation_error){
			$('.operational_save').addClass('disable');
		}else{
			$('.operational_save').removeClass('disable');
		}
	});
	
	//allows number only
	$('.operation_input').w_keydown(function(event){
		//makes sure the user is not coping,pasting,cutting, undo, and redo
	    if(!event.ctrlKey || (event.ctrlKey && (event.which != 67 &&  event.which != 88 && event.which != 86 && event.which != 90 && event.which != 89))){
	       var object = $(this);
			
				validate_integer(event, false);
	
				if(event.keyCode == 189 && object.val().split('-').length > 1){
					event.preventDefault();
				}
			
	    }
	});
	
	$('#cdl_operational').w_change(function(){
		preload_page = function(current_obj){
			ConfirmDialog('CDL','You did not save all parameters.<br>Would you like to leave page?',function(){
				if(typeof item_clicked == 'object'){
					preload_page_finished();		
				}
				preload_page = '';
			},function(){
				//don't load the next page
			});
		};
	});
	
	$('.operational_save').w_click(function(){
		if(!$(this).hasClass('disable')){
			var save_this = $(this);
			save_this.addClass('disable');
			var params = {};
			$('#cdl_operational').find('input[type=text],select').each(function(){
			  params[$(this).attr('name')] = $(this).val();
			})
			
			operation_post = $.post('/cdlsitesetup/update_operational_parameter/',
				params,
			function(good_resp){
				$('.ajax-loader').hide();
				save_this.removeClass('disable');
				if(good_resp.split(',').length  > 1 || good_resp.split('=>').length > 1){
					$('#cdl_message').html('');
					var messages = good_resp.split(',');
					for(var i = 0; i < messages.length; i++){
						var id = messages[i].split('=>')[0];
						var message = messages[i].split('=>')[1];
						$('#'+id).closest('.serialright').find('.error_message').html(message);
					}
				}else{
					$('#cdl_message').html('<div class="success_message">Parameters saved.</div>').find('.success_message').show().delay(6000).fadeOut("slow");
					val_change = false;
					preload_page = '';
				}
			});
		}
	});
	
	$('.operational_refresh').w_click(function(){
		if(!$(this).hasClass('disable')){
			reload_page();
		}
	});
});

function cdl_parameter_validation(){
	var cdl_value = document.getElementById('cdl_value').value ;
	if (cdl_value == "1") {
		var cdl_error = document.getElementById('cdl_error_message').innerHTML;
		if (cdl_error) {
			alert("Please correct the errors and try again.")
			return false;
		}
	}else{
		return false;
	}
    return true;
}