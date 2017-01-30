
var other_request_process = false;
	$(document).ready(function() {
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
	  
		$('.setup_wizard_menu_link').w_click(function(){
			$(".programming_parameters_template").mask("Loading parameters, please wait...");
			var page_name = $(this).attr("page_name");
			$(".setup_wizard_menu_link").each(function(index, ele){
				if ($(ele).attr("page_name") == page_name)
					$(ele).css({'font-weight':'bold'});
				else
					$(ele).css({'font-weight':'normal'});	
			});
	        $.get("/gcp_programming/page_parameters?setup_wizard=true&page_name="+page_name, function(response){
				 $(".programming_parameters_template").unmask("Loading parameters, please wait...");
	            $(".programming_parameters_template").html(response)
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
			$(this).css({'font-weight':'bold'});
	    });
		
		$('.setup_wizard_menu_link').mouseout(function(){
			var page_name = $("#page_name").val();
			if($(this).attr("page_name") != page_name)
				$(this).css({'font-weight':'normal'});
	    });
		
		$('.button_container').w_click(function(){
			if ($(this).hasClass('disable'))
				return;
			if (!other_request_process) {
				 $(".programming_parameters_template").mask("Loading page, please wait...");
				var page_name, page_type;
				if ($(this).attr("data-label") == "Previous") {
					page_name = $("#previous_page_name").val();
					page_type = "prev"
				} else {
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
				$.post('/gcp_programming/page_parameters', {
					page_name: page_name,
					setup_wizard: true,
					page_type: page_type
				}, function(response){
					$(".programming_parameters_template").unmask("Loading page, please wait...");
					$(".programming_parameters_template").html(response);
					other_request_process = false;
				});
			}
		});	
		var iframe = $('#iframe', window.parent.document)
		var content_contents = $("#contentcontents", window.parent.document)
		$(iframe).css({'height': '667px', 'min-height':'317px'});
		$(content_contents).css({'height': '667px', 'min-height':'317px'});
	});