/**
 * @author Jeyavel Natesan
 */

$(document).ready(function() {
	add_to_destroy(function(){
		$(document).unbind("ready");
		
		//kills all wrapper events
		$('.menu_link_item').w_die('click');
		
	    //clear functions 
		delete window.link_change;
		delete window.change;
		
	});
	change();

	$('.menu_link_item').w_click(function(){
		$("#site_content").mask("Loading content, please wait...");
	    $('.menu_link_item').each( function(){
	      $(this).removeClass('menu_selected')
	    });
	    var link = $(this);
	    $.get(link.attr('href'), {}, function(data){
	      $('#module_content').html(data);
		  $('#module_content').custom_scroll(430);
	      link.addClass('menu_selected')
		  $("#site_content").unmask("Loading content, please wait...");
	      link_change();
	    }); 
	    return false;
	 });
});

function change(){
	$("#site_content").mask("Loading content, please wait...");
	$.get("/nv_config/feeder?channel=0", {}, function(data){
	      $('#module_content').html(data);
		  $('#module_content').custom_scroll(430);
		  $("#site_content").unmask("Loading content, please wait...");
	      link_change();
	});
}

function link_change(){
    $('.menu_selected').text($(":text").val());
}		
