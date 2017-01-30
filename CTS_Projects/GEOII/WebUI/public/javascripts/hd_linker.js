$(document).ready(function(){
	add_to_destroy(function(){
		$('.hd_linker').w_die('click');
		$('.hd_update').w_die('click');
		$('.hd_discard').w_die('click');
		$('.hd_close').w_die('click');
		$('.hd_atcs').w_die('keyup');
		$('.hd_create').w_die('click');
		$('.hd_view_report').w_die('click');   
        $('.hd_download').w_die('hover');
        $('.hd_dl_item').w_die('click'); 
        $('.hd_mcf_template_name').w_die('change');  

		delete window.hd_create_mcf;
        delete window.get_report;
        delete window.hd_atcs_key_up;
        delete window.get_menu_link;
        delete window.update_hd_linker_button;
        delete window.add_dl_buttons;
        delete window.downloadURL;
	});

	update_hd_linker_button();
});

$('.hd_linker').w_click(function(){

    var hd_linker_this = $(this);
    if(!hd_linker_this.hasClass('disabled')){
        hd_linker_this.addClass('disabled');
        $('.ajax-loader').show();

        var menu_link = get_menu_link();

        $.post('/gcp_programming/hd_linker/',{
            page_name:menu_link
        },function(resp){
            
            if($('.site_content_wrapper').length == 0){
            	if($( ".site_content" ).length > 0){
	                $( ".site_content" ).after("<div class='hd_linker_outer_wrapper'>"+resp+"</div>");
	                $( ".site_content" ).wrap( "<div class='site_content_wrapper'></div>");
	            }else{
	            	$( ".content_wrapper" ).after("<div class='hd_linker_outer_wrapper'>"+resp+"</div>");
                	$( ".content_wrapper" ).wrapInner( "<div class='site_content_wrapper'></div>");
                }
            }else{
                $( ".hd_linker_outer_wrapper").html(resp);
            }
            
            add_dl_buttons();

            var remote_sin = $('#remote_sin').clone();
            remote_sin.appendTo('.remote_sin_wrapper')
            $('.remote_sin_wrapper #remote_sin').attr('id','').addClass('hd_atcs');

            var remote_sin_attr = $('#remote_sin').closest('#serial_outer').find('.save_mcf_parameter a');

            $('.hd_atcs').attr('modified_field',$('.hd_atcs').attr('modified_field')+'_new');

            $('.hd_atcs').attr('discard_value',$('.hd_atcs').val());

            $('.site_content_wrapper').hide();
            hd_linker_this.removeClass('disabled');

            hd_atcs_key_up();

            $('.ajax-loader').hide();
        });
    }
});

$('.hd_update').w_click(function(){
    var update_this = $(this);
    if(!update_this.hasClass('disabled')){
        if($('.hd_atcs').val() != $('.hd_atcs').attr('current_value')){
            $('.hd_atcs').attr('discard_value',$('.hd_atcs').val());
            if($('.parameters_save').length > 0){
	           $('.parameters_save').click();
            }else if($('.v_save').length > 0){
                $('.v_save').click();
            }
		}else{
			$('.hd_linker_message').html("Parameters updated successfully...");
            $('.hd_linker_wrapper .toolbar_button').removeClass('disabled');
            $('.ajax-loader').hide();
            remove_v_preload_page();
		}

        //enables buttons
        $('.hd_create').removeClass('disabled'); 
        $('.hd_view_report').removeClass('disabled'); 
    }
});

$('.hd_discard').w_click(function(){
    var discard_this = $(this);
    if(!discard_this.hasClass('disabled')){
        $('.hd_linker_wrapper .toolbar_button').addClass('disabled');
        $('.ajax-loader').show();


        $('#remote_sin').val($('.hd_atcs').attr('discard_value'));

        $('.hd_linker').click();

        //enables buttons
        $('.hd_create').removeClass('disabled'); 
        $('.hd_view_report').removeClass('disabled'); 
    }
});

$('.hd_close').w_click(function(){
    //this button does not have a disable feature 
    //because if you can something and dont save 
    //you get a pop up and if you stay on the page the button is not enabled

    reload_page();
});


$('.hd_mcf_template_name').w_change(function(){
    var file = $(this).val();
    var ext = file.substr(file.lastIndexOf('.')+1).toLowerCase();

    if(ext != 'mcf'){
        $(this).val(file+'.mcf');
    }
});

$('.hd_create').w_click(function(){
    if(!$(this).hasClass('disabled')){
        var create_this = $(this);
        $('.hd_linker_wrapper .toolbar_button').addClass('disabled');
        $('.ajax-loader').show();

        var hd_mcf_template_name = $('.hd_mcf_template_name').val();

        $.post('/gcp_programming/hd_check_mcf_exsist/',{
            hd_mcf_template_name:hd_mcf_template_name,
            menu_link:get_menu_link()
        },function(resp){
            if(resp == "false"){
                hd_create_mcf(create_this,hd_mcf_template_name,'');
            }else{
                //already exsist
                ConfirmDialog("Warning",hd_mcf_template_name+" already exsist.<br><br>Would you like to override it?",function(){
                    hd_create_mcf(create_this,hd_mcf_template_name,'');
                },function(){
                    $('.hd_linker_wrapper .toolbar_button').removeClass('disabled');
                    $('.ajax-loader').hide();
                });
            }
        });
    }
});

function hd_create_mcf(create_this,hd_mcf_template_name,callback){
    $.post('/gcp_programming/hd_create_mcf/',{
        hd_mcf_template_name:hd_mcf_template_name,
        hd_atcs:$('.hd_atcs').val(),
        menu_link:get_menu_link()
    },function(resp){
        $('.hd_linker_message').success_message('MCF created successfully.')
        $('.hd_ucn').val(resp);
        $('.ajax-loader').hide();

        if(typeof callback === 'function'){
            callback();
        }
        
        $('.hd_linker_wrapper .toolbar_button').removeClass('disabled');
    })
}

var hd_report_template_name;
$('.hd_view_report').w_click(function(){
    if(!$(this).hasClass('disabled')){
        var report_this = $(this);
        $('.hd_linker_wrapper .toolbar_button').addClass('disabled');
        $('.ajax-loader').show();

        var hd_mcf_template_name = $('.hd_mcf_template_name').val();
        hd_report_template_name = hd_mcf_template_name.replace('.mcf','.html')

        $.post('/gcp_programming/hd_check_report_exsist/',{
            hd_report_template_name:hd_report_template_name,
            menu_link:get_menu_link()
        },function(resp){
            if(resp == "true"){
                get_report();
            }else{
                //already exsist
                ConfirmDialog("Warning",hd_report_template_name+" does not exsist.<br><br>Would you like to create it?",function(){
                    hd_create_mcf(report_this,hd_mcf_template_name,get_report);
                },function(){
                    $('.hd_linker_wrapper .toolbar_button').removeClass('disabled');
                    $('.ajax-loader').hide();
                });
            }
        });
    }
});

function get_report(){
    $('.hd_linker_wrapper .toolbar_button').removeClass('disabled');
    $('.ajax-loader').hide();
    window.open('/gcp_programming/hd_view_report/?hd_report_template_name='+hd_report_template_name,'_blank');
}

function hd_atcs_key_up(){
    $('.hd_atcs').w_keyup(function(){
        if(!$(this).attr('disabled') && !$(this).attr('readonly') && !$(this).hasClass('disabled')){
            var validate_sin = '';
            var remote_sin = $(this).val();
            var actual_sin = $("#hd_actual_sin").val();
            var element_id = $(this).attr('modified_field');
            //buttons_remote_sin_16
            var mcf_4000_version = $(".mcf_version").html();
            if (mcf_4000_version != '' && mcf_4000_version != undefined) {
                $(".contentCSPsel").attr('disabled', 'disabled');
                $(".integer_only").attr('disabled', 'disabled');
                $(this).removeAttr('disabled');
            }
            validate_sin = sin_validation(remote_sin);
            $(".remote_sin_error").html(validate_sin).css('color', 'red');
	        $(".remote_sin_error").show();
            if (validate_sin.length == 0){
                if(update_offset_values(remote_sin, actual_sin, ".remote_sin_error", ".integer_only")){

                }
            } else{
                $(this).focus();
                return validate_sin;
            }

            var cur_sin = $(this).val();
            $('#remote_sin').val(cur_sin);
            cur_sin = cur_sin.split('.');
            var mcf_name = '';

            for(var sin_i = 2; sin_i < cur_sin.length; sin_i++){
                mcf_name += cur_sin[sin_i];
            }

            mcf_name += '.mcf';

            $('.hd_mcf_template_name').val(mcf_name)
            $('.hd_ucn').val(''); //clears ucn
             
            //disables until saved or discarded
            $('.hd_create').addClass('disabled'); 
            $('.hd_view_report').addClass('disabled'); 
        }
    });
}

function get_menu_link(){
    if($("#gcp_4k").val()){
        var menu_link = $('#page_header').html();
    }else{
        var menu_link = '';

        var uri_info_ar = current_url.split('?')[1].split('&');

        for(var uri_i = 0; uri_i < uri_info_ar.length; uri_i++){
            var uri_var = uri_info_ar[uri_i].split('=');
            var uri_val = uri_var[1];
            uri_var = uri_var[0];

            if(uri_var == "menu_link"){
               menu_link =  uri_val.replace(/\+/g," ");
            }
        }
    }

    return menu_link;
}

function update_hd_linker_button(){
    if($('.hd_linker').length > 0){
        if($('select').val()==1){
            $('.hd_linker').addClass('disabled');
        }else{
            $('.hd_linker').removeClass('disabled');
        }
    }
}


function add_dl_buttons(){
    $('.hd_download').append('<div class="dl_drop_down_wrapper"><div class="hd_dl_item">MCF</div><div class="hd_dl_item">Report</div></div>')
}

$('.hd_download').w_hover(function(){
    if(!$(this).hasClass('disabled')){
        $(this).find('.dl_drop_down_wrapper').show();
    }
},function(){
    $(this).find('.dl_drop_down_wrapper').hide();
});

$('.hd_dl_item').w_click(function(){    
    var selected = $(this).html();
    var name = $('.hd_mcf_template_name').val();

    if(selected == 'Report'){
        name = name.substr(0,name.lastIndexOf('.'))+'.html'
    }
    
    $('.ajax-loader').show();
    $(this).closest('.dl_drop_down_wrapper').hide();

    $.post('/gcp_programming/hd_check_dl',{
        name:name
    },function(file_check){
        if(file_check == true || file_check == 'true'){
            downloadURL('/gcp_programming/hd_dl?name='+name);
        }else{
            $('.hd_linker_message').html("File not found: "+name);
            $('.ajax-loader').hide();
        }
    });
});

function downloadURL(dl_url) {
    var iframe;
    var hiddenIFrameID = 'hiddenDownloader';
    iframe = document.getElementById(hiddenIFrameID);
    if (iframe === null) {
        iframe = document.createElement('iframe');  
        iframe.id = hiddenIFrameID;
        iframe.style.display = 'none';
        document.body.appendChild(iframe);
    }
    setTimeout("$('.ajax-loader').hide();",2000);
    iframe.src = dl_url;   
}
