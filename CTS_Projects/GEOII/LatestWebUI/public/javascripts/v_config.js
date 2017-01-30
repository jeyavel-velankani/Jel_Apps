/****************************************************************************************************************************************
 Company: Siemens 
 Author: Ashwin Dubey
 File: v_config.js
 Requirements: JQuery 1.9.1, jquery_wrapper.js
 Description: Generic vital config javascript file
****************************************************************************************************************************************/

/**********************************************************************
 saving
**********************************************************************/
$('.v_save').click(function(){
	$('.ajax-loader').show();
	
	$('.v_error').html('');	//clears the errors

	var save_obj = {};	//creates json object

	var inputs = $(this).closest('#contentcontents').find('input,select');

	//indexs through all inputs
	inputs.each(function(){
		var key = $(this).attr('id');
		var val = $(this).val();

		//stores the key and val in the array
		save_obj[key] = val;
	});

	// ajax off to save vital config parameters
	$.post('/programming/save',save_obj,function(nv_save_resp){
		if(nv_save_resp.split(',').length  > 1 || nv_save_resp.split('=>').length > 1){
			$('.message').html('');
			var messages = nv_save_resp.split(',');
			for(var i = 0; i < messages.length; i++){
				var id = messages[i].split('=>')[0];
				var message = messages[i].split('=>')[1];

				$('#'+id).closest('.v_row').find('.v_error').html(message);
			}
		}else{
			$('.message').html('Saved Successfully...');
		}

		//checks if there is a table to update
		if($('.v_config_channels_wrapper').length > 0){
			var current_page = parseInt($('.pagination .current').html()); 

			if(!isNaN(current_page)){
				$.post('/programming/rebuild_channels_table',{
					group_ID: nv_group_id,
					page_number: current_page,
					number_per_page: nv_number_per_page,
					current_channel: nv_group_channel
				},function(table_resp){
					$('.channels_selection_table_wrapper').html(table_resp);
				});
			}
		}
		$('.ajax-loader').hide();
	});
});


/**********************************************************************
 validation
**********************************************************************/
//allows number only
$('input').w_keydown(function(event){
	var object = $(this);

	var charCode = event.which;


	if(object.hasClass('numeric_only')){
		if (charCode > 31 && (charCode < 48 || charCode > 57)){
			event.preventDefault(); 
		}
	}

});

$('input').w_keyup(function(event){
	var object = $(this);

	object.closest('.v_row').find('.v_error').html('');	//clear the error for this input

	var type = object.attr('id').split('_')[0]
	var id = object.attr('id').split('_')[1]
	var val = object.val();
	var error = '';
	
	
	if(type == 'string'){
		var min = parseInt(object.attr('min'));
		var max = parseInt(object.attr('max'));
		var mask = object.attr('mask');

		if(min <= val.length && val.length <= max){
			if(mask.length > 0){
				if(mask.split(':').length > 0){
					var mask_type = mask.split(':')[0];
					mask = mask.split(':')[1];

					if(mask_type == 'M' || mask_type == 'N'){
						if(object.closest('.v_row').find('.v_title').html().indexOf('IP Addr') != -1){
							error = ip_validate(mask,val)
						}else{
							error = m_n_validate(mask,val)
						}
					}else if(mask_type != 'S' && object.closest('.v_row').find('.v_title').html().indexOf('IP Addr') != -1){
						error = m_n_validate(mask,val)
					}
					
					object.closest('.v_row').find('.v_error').html(error);

				}else{
					object.closest('.v_row').find('.v_error').html('');
				}
			}else{
				object.closest('.v_row').find('.v_error').html('');
			}
		}else{
			object.closest('.v_row').find('.v_error').html(' Should be in the numeric Range of ('+min+' to '+max+')');
		}
	}else if(type == 'int'){
		var min = parseInt(object.attr('min'));
		var max = parseInt(object.attr('max'));
		var mask = object.attr('mask');
		var base = 10; 

		//checks if there is a mask
		if(mask.split(':').length > 1){
			var mask_type = mask.split(':')[0];
			mask = mask.split(':')[1];

			if(mask_type == 'H'){	//hex
				min = min.toString(16);
				max = max.toString(16);

				base = 16;

				//checks if the number is a hex
				if(val.toString().match(/^[0-9A-Fa-f]+$/g) == null){
					error = 'Should be in Hexadecimal format';
				}
			}else{
				//checks if the number is a hex
				if(val.toString().match(/^[0-9]+$/g) == null){
					error = 'Should be in the numeric Range of ('+min +' to '+ max+' )';
				}
			}
			
		}else{
			
			//checks if the number is a hex
			if(val.toString().match(/^[0-9]+$/g) == null){
				error = 'Should be in the numeric Range of ('+min +' to '+ max+' )';
			}
		}

		if(error == '' && (parseInt(min,base) > parseInt(val,base) ) || (parseInt(max,base) < parseInt(val,base))){
			error = 'Should be in the numeric Range of ('+min+' to '+max+')';
		}

		object.closest('.v_row').find('.v_error').html(error);
	}
});

//validates
function m_n_validate(mask,val){
	error = false;

	var m = mask.split('.');
	var v = val.split('.');

	if(m.length == v.length){
		for(var m_index = 0; m_index < m.length; m_index++){
			if(!isNaN(v[m_index])){
				if(0 > v[m_index] || v[m_index] > parseInt(m[m_index].replace(/#/gi, '9'))){
					error = true; 
				}
			}else{
				error = true; 
			}
		}
	}else{
		error = true; 
	}

	if(error){ 
		return "should be in the range ('"+mask.replace(/M:/gi, "").replace(/N:/gi, "").replace(/#/gi, '0')+"' - '"+mask.replace(/M:/gi, "").replace(/N:/gi, "").replace(/#/gi, '9')+"')";
	}
	
}

function ip_validate(mask,val){
	error = false;

	var m = mask.split('.');
	var v = val.split('.');

	if(m.length == v.length){
		for(var m_index = 0; m_index < m.length; m_index++){
			if(!isNaN(v[m_index])){
				if(0 > v[m_index] || v[m_index] > 255){
					error = true; 
				}
			}else{
				error = true; 
			}
		}
	}else{
		error = true; 
	}

	if(error){ 
		return "should be in the range of (0.0.0.0 - 255.255.255.255)";
	}
	
}


/**********************************************************************
 refresh
**********************************************************************/
$('.v_refresh').w_click(function(){
	$('.ajax-loader').show();

	$.get(current_url,{
		//no params
	},function(v_refresh_resp){
		$('#contentcontents').html(v_refresh_resp);
		$('.ajax-loader').hide();
	});
});

/**********************************************************************
 defaults
**********************************************************************/
$('.nv_default').w_click(function(){
	$('.ajax-loader').show();

	$.get(current_url,{
		default:'true'
	},function(nv_refresh_resp){
		$('#contentcontents').html(nv_refresh_resp);
		$('.ajax-loader').hide();
	});
});


/**********************************************************************
 sub group change
**********************************************************************/
$('.subgroup_anchor').w_change(function(){
	
	var anchor_id = $(this).attr('id').split('_')[1];

	$('.ajax-loader').show();

	$.post('/nv_config/get_subgroup',{
		group_id: nv_group_id,
		group_ch:nv_group_channel,
		selected_id:parseInt($(this).val()),
		enum_id:anchor_id
	},function(subgroup_resp){
		$('.subgroup_parameters_'+anchor_id).html(subgroup_resp);
		$('.ajax-loader').hide();
	});
});

/**********************************************************************
 sub group change
**********************************************************************/
$('.nv_arrow').w_click(function(){
	$('.ajax-loader').show();
	
	$('.selected_row').removeClass('selected_row');
	$(this).closest('tr').find('td').addClass('selected_row');

	nv_group_channel = parseInt($(this).closest('tr').find('.nv_channel').html());

	$.post('/nv_config/get_build',{
		group_id: nv_group_id,
		group_ch:nv_group_channel
	},function(build_resp){
		$('.nv_config_channels_content_wrapper').html(build_resp);
		$('.ajax-loader').hide();
	});
});
