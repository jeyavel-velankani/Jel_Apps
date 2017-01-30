/**
 * @author 248996
 */
$(document).ready(function(){
	//changes the width for io assignments onley so error messages can fit next to them
	$('.serialleft_io').css({'width':'160px'});
	$('.serialright_io').css({'width':'370px'});
	$('.contentCSPsel').css({'float': 'left'});



	$("input, select").die('change').live('change',function(){
		window.parent.myValue = true;
	});

    $(".io_assignment_form_save").live("click", function(){
        var page_type = $('#selected_page_type').attr('value');
		var channel_id = $('#channel_number').val();
		var algorithm_option = $('#algorithm_option').val();
		var first_field_id	= $('#first_field_id').attr('name');
		var connections = {}; //declare object
		var inputs  = $('#io_assignment_form').find('input[type="text"],select');

		$('input[type="text"],select').each(function(){
			connections[$(this).attr('name')] = $(this).val();
		});

		if(typeof algorithm_option ==="undefined" && algorithm_option != ''){
			algorithm_option = '';
		}else{
			algorithm_option = "&algorithm_option="+algorithm_option;
		}
		
		if(typeof first_field_id ==="undefined" && first_field_id != ''){
			first_field_id = '';
		}else{
			first_field_id = "&first_field_id="+first_field_id
		}

		var tbl_row = $("#hdtablerow").val();
		var fld_name = $("#hdname").val();
		var fld_tag = $("#hdtag").val();
		
		if ($("#hd_error_field").val().length > 0){
			return false;
		}
		
		$('#error_explanation').html('Saving...').show();
		disable_buttsons()

        $("#channel_number").val(channel_id);

        window.parent.myValue = false;

        $.post("/programming/io_assignment_update?channel_id=" + channel_id+algorithm_option+first_field_id+'&page_type='+page_type, connections, function(response){
            if(response == "Parameters updated successfully..."){
            	$("#" + tbl_row).children().each(function(ind, tbname){        	
		        	if(ind == 1){
		        		$(tbname).html($("#"+fld_name).val());
		        	}
	        	});
            }
            $("#error_explanation").show();
            $("#error_explanation").html("");          

			enable_all_buttsons();
		});
        
    });
	$('#algorithm_option').live('change',function(){
		disable_buttsons()
 		$("#error_explanation").html('Loading...');

		var algorithm_option = $('#algorithm_option').val();
		$.post("/programming/get_io_input_channel", {
			channel_id: $('#channel_number').val(),
			page_type: $('#selected_page_type').attr('value'),
			Algorithm: algorithm_option
			}, function(req){
				$('#input_content').html(req.io_input_content);
				$('#algorithm_option').val(algorithm_option)
				
				enable_all_buttsons();
				$("#error_explanation").html('');				
		}, "json");
	});
    
    /*$.validator.addMethod('IP4Checker', function(value){
     var ip = /^(25[0-5]|2[0-4][0-9]|[0-1][0-9]{2}|[0-9]{2}|[0-9])(\.(25[0-5]|2[0-4][0-9]|[0-1][0-9]{2}|[0-9]{2}|[0-9])){3}$/;
     return ip.test(value);
     });
     $(".high_availability_form").validate();*/
	
	// Allow only integers
    $(".integer_only").keydown(function(event){
        // Allow: backspace, delete, tab, escape, and enter
        if (event.keyCode == 46 || event.keyCode == 8 || event.keyCode == 9 || event.keyCode == 27 || event.keyCode == 13 ||
        // Allow: Ctrl+A
        (event.keyCode == 65 && event.ctrlKey === true) ||
        // Allow: home, end, left, right
        (event.keyCode >= 35 && event.keyCode <= 39)) {
            // let it happen, don't do anything
            return;
        }
        else {
            // Ensure that it is a number and stop the keypress
            if (event.shiftKey || (event.keyCode < 48 || event.keyCode > 57) && (event.keyCode < 96 || event.keyCode > 105)) {
                event.preventDefault();
            }
        }
    });
    
    $(".integer_only").live('keyup', function(){
        int_validation(this);
     });
    
    function int_validation(ele){
    	var intRegex = /^[0-9]+$/;
    	//var intRegex = /^[-+]?[0-9]+$/;
		var min = $(ele).attr('min');
		var max = $(ele).attr('max');
		var val = $(ele).attr('value');
		
		if (intRegex.test(val)) {
			if ((parseInt(val,10) < parseInt(min,10)) || (parseInt(val,10) > parseInt(max,10))) {
				if($(ele).parent().find('.error').length == 0 ){
					$(ele).parent().append('<div class="error" style="color: #FFF380;width: 161px;float: left;margin-left: 10px;">Value must be with in the range of ' + min + ' and ' + max+'<div>')
				}else{
					$(ele).parent().find('.error').html("Value must be with in the range of " + min + " and " + max);
				}
			}else{
				$(ele).parent().find('.error').remove();
			}
		}
		else {
			if($(ele).parent().find('.error').length == 0 ){
				$(ele).parent().append('<div class="error" style="color: #FFF380;width: 161px;float: left;margin-left: 10px;">Invalid format!! number only allowed<div>')
			}else{
				$(ele).parent().find('.error').html("Invalid format!! number only allowed");
			}
		}
    }
    
    $(".io_assignment_form_discard").live('click', function(){
        if (confirm("Confirm discard changes?")) {
			var page_type = $('#selected_page_type').attr('value');
			var channel_id = $('#channel_number').attr('value');
			var algorithm_option = $('#algorithm_option').attr('value');		
        	
        	disable_buttsons()
			$("#error_explanation").html('Loading...');

        	$("#channel_number").val(channel_id);
			$.post("/programming/get_io_input_channel", {
				channel_id: channel_id,
				page_type: page_type
				}, function(req){
					$('#input_content').html(req.io_input_content);
					enable_all_buttsons()
					$("#error_explanation").html('');
			
			}, "json");
        }
    });
    
    $(".io_assignment_form_refresh").live('click', function(){
		var page_type = $('#selected_page_type').attr('value');
		var channel_id = $('#channel_number').attr('value');
		var algorithm_option = $('#algorithm_option').attr('value');	
        
        disable_buttsons()
		$("#error_explanation").html('Loading...');

		$("#channel_number").val(channel_id);
		$.post("/programming/get_io_input_channel", {
			channel_id: channel_id,
			page_type: page_type
			}, function(req){
				$('#input_content').html(req.io_input_content);
				
				enable_all_buttsons();
				$("#error_explanation").html('');
			
		}, "json");
	        
    });
    
    $(".io_assignment_form_default").live('click', function(){
		var page_type = $('#selected_page_type').attr('value');
		var channel_id = $('#channel_number').attr('value');
		var algorithm_option = $('#algorithm_option').attr('value');		
        
        disable_buttsons()
		$("#error_explanation").html('Loading...');

		$("#channel_number").val(channel_id);
        $.post("/programming/get_io_input_channel", {
			channel_id: channel_id,
			page_type: page_type,
			selected_value: 'default'
			}, function(req){
				$('#input_content').html(req.io_input_content);
				
				enable_all_buttsons();
				$("#error_explanation").html('');
			
		}, "json");
    });
    
    $(".ptc_connection_item").click(function(event){
        $(".ptc_connection_item").removeClass('menu_selected');
        $(this).addClass('menu_selected')
        var index = $(this).attr('id')
        
        $.post('/high_availabilities/switch_connection', {
            index: index
        }, function(response){
            $("#connection_header").html('Connection ' + index);
            $(".connection_information").html(response);
        });
    });
});

function get_element(channel_id, page_type){
	disable_buttsons()
	$("#error_explanation").html('Loading...');
	
	$("#channel_number").val(channel_id);
	$.post("/programming/get_io_input_channel", {
		channel_id: channel_id,
		page_type: page_type
		}, function(req){
			$('#input_content').html(req.io_input_content);
			enable_all_buttsons()
			$("#error_explanation").html('');	

			//changes the width for io assignments onley so error messages can fit next to them
			$('.serialleft_io').css({'width':'160px'});
			$('.serialright_io').css({'width':'370px'});
			$('.contentCSPsel').css({'float': 'left'});
	}, "json");
}

function disable_buttsons(){
	$('.save_icon ').addClass('disabled_buttons');
	$('.discard_icon').addClass('disabled_buttons');
	$('.refresh_icon ').addClass('disabled_buttons');
	$('.default_icon ').addClass('disabled_buttons');
	$(['.row_sel_style']).addClass('disabled_buttons');
	$('input, select').attr('disabled', true).addClass('disabled_buttons');
}
function enable_all_buttsons(){
	$('.save_icon ').removeClass('disabled_buttons');
	$('.discard_icon').removeClass('disabled_buttons');
	$('.refresh_icon ').removeClass('disabled_buttons');
	$('.default_icon ').removeClass('disabled_buttons');
	$(['.row_sel_style']).removeClass('disabled_buttons');
	$('input, select').attr('disabled', '').removeClass('disabled_buttons');
}