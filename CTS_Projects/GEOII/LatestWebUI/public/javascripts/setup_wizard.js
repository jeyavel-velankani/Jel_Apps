var other_request_process = false;

$(document).ready(function(){
    var page_name = $("#first_template_name").val();
    if (page_name.match("TEMPLATE:  selection")) {
        $(".button_container").each(function(index, ele){
            if ($(ele).attr("data-label") == "Previous") 
                $(ele).addClass('disable');
        });
    }
    else {
        $(".button_container").each(function(index, ele){
            if ($(ele).attr("data-label") == "Previous") 
                $(ele).removeClass('disable');
        });
    }
    $("#site_content").mask("Loading parameters, please wait...");
    $.get("/programming/page_parameters?setup_wizard=true&page_type=next&page_name=" + page_name, function(response){
        $(".programming_parameters_template").html(response.html_content);
            $('.v_config_wrapper').custom_scroll(450);
    });

	$('.setup_wizard_menu_link').w_click(function() {
        $(".programming_parameters_template").mask("Loading parameters, please wait...");
        var page_name = $(this).attr("page_name");
        $(".setup_wizard_menu_link").each(function(index, ele){
            if ($(ele).attr("page_name") == page_name) 
                $(ele).css({
                    'font-weight': 'bold'
                });
            else 
                $(ele).css({
                    'font-weight': 'normal'
                });
        });
        $.get("/programming/page_parameters?setup_wizard=true&page_name=" + page_name, function(response){
            $(".programming_parameters_template").unmask("Loading parameters, please wait...");
            $(".programming_parameters_template").html(response.html_content);
            $('.v_config_wrapper').custom_scroll(400);
        })
        if (page_name.match("TEMPLATE:  selection")) {
            $(".button_container").each(function(index, ele){
                if ($(ele).attr("data-label") == "Previous") 
                    $(ele).addClass('disable');
            });
        }
        else {
            $(".button_container").each(function(index, ele){
                if ($(ele).attr("data-label") == "Previous") 
                    $(ele).removeClass('disable');
            });
        }
    });
    $('.setup_wizard_menu_link').mouseover(function(){
        $(this).css({
            'font-weight': 'bold'
        });
    });
    $('.setup_wizard_menu_link').mouseout(function(){
        var page_name = $("#page_name").val();
        if ($(this).attr("page_name") != page_name) 
            $(this).css({
                'font-weight': 'normal'
            });
    });
    
	$('.button_container').w_click(function() {
		var other_request_process = false;
        if ($(this).hasClass('disable')) 
            return;
		if (($("#previous_page_name").val() == "LAST PAGE") && ($(this).attr("data-label") == "Previous")) {
		  other_request_process = true;
		}
        if (other_request_process == false) {
			 $(".programming_parameters_template").mask("Loading page, please wait...");
            var page_name, page_type;
            if ($(this).attr("data-label") == "Previous") {
				page_name = $("#previous_page_name").val();
				page_type = "prev"
			}
			else {
				page_name = $("#next_page_name").val();
				page_type = "next"
				
			}
            if (page_name.match("TEMPLATE:  selection")) {
                $(".button_container").each(function(index, ele){
                    if ($(ele).attr("data-label") == "Previous") 
                        $(ele).addClass('disable');
                });
            }
            else {
                $(".button_container").each(function(index, ele){
                    if ($(ele).attr("data-label") == "Previous") 
                        $(ele).removeClass('disable');
                });
            }
            other_request_process = true;
            $.post('/programming/page_parameters', {
                page_name: page_name,
                setup_wizard: true,
                page_type: page_type
            }, function(response){
                $(".programming_parameters_template").unmask("Loading page, please wait...");
                $(".programming_parameters_template").html(response.html_content);
                other_request_process = false;
            });
        }else{
			return false;
		}
    });        
});