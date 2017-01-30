$(document).ready(function(){
    //chrome, firefox: a tag is added to the left menu for config so it stacking the click events
    //ie needs it to be recalled everytime the left nav is changed in the DOM so I had to write an exception. 
    if (!$.browser.msie && !$.browser.mozilla) {
        if($("#programming_menu", window.parent.document).attr('delegate') == "true"){
            return
        }
    }

    var hitarea = $(".hitarea", window.parent.document);
    var programming_menu = $("#programming_menu", window.parent.document);
    var site_content = $("#site_content", window.parent.document)
    var iframe = $('#iframe', window.parent.document);
    var children = $(programming_menu).children();

    $(hitarea).toggle(function(){
        if (!$(this).hasClass('disable')) {
            $(this).removeClass('expandable-hitarea').addClass('collapsable-hitarea')
            $(this).next().show();
        }
    }, function(){
        if (!$(this).hasClass('disable')) {
            $(this).removeClass('collapsable-hitarea').addClass('expandable-hitarea')
            $(this).next().hide();
        }
    });
    
    var programming_click_finished = true;
    $(programming_menu).attr('delegate','true');
    $(programming_menu).undelegate('li', 'mouseover mouseout click').delegate('li', 'mouseover mouseout click', function(event){

        if (event.type == 'mouseover') {
            $(this).removeClass('leftnavtext_U').addClass('leftnavtext_H');
        }
        else 
            if (event.type == 'mouseout') {
                $(this).removeClass('leftnavtext_H').addClass('leftnavtext_U');
            }
            else 
                if (event.type == 'click') {
                    event.stopPropagation();
                    
                    if(programming_click_finished){
                        programming_click_finished = false;
    					if(window.parent.myValue){
    						var msg1 = "Changes are not saved.";
    					    var msg2 = "Are you sure you want to navigate away?";
    					    //var msg3 = "Press OK to continue, or Cancel to stay on the current page."; 
    				    
    						if(confirm(msg1 + "\n\n" + msg2 + "\n\n") == false) {
                                programming_click_finished = true;
    							return false;
    						}else{
    						  window.parent.myValue = false;
    						}
    					}					
    					
                        if (!$(this).hasClass('disable') && !$(this).hasClass('expandable-child')) {
                           // $(site_content).mask("Loading parameters, please wait...");
                            $(".contenttabs", window.parent.document).html('')
                            $("#site_content").html('')
                            
                            children.each(function(i, ele){
                                $(ele).removeClass('leftnavtext_D');
                            });
                            
                            $(this).addClass('leftnavtext_D');
                            var page_name = $(this).attr('pagename');
                            var page_url = $(this).attr('pageurl');
                            
                            if (page_url != '' && page_url != undefined) {
                                var breadcrumb = $.trim($(this).attr('breadcrumb'));
                                $(".contentareahdr", window.parent.document).html(breadcrumb);
                                if(page_url != "/dummy.htm"){
    								$("#loading", window.parent.document).show();
    	                            //alert(page_url);
    	                            iframe.attr('src', page_url);
    							} else {
    								$("#ite_content").html("");
    							}
                                programming_click_finished = true;
                                return false;
                            }
                            else 
                                if (page_name != '' && page_name != undefined) {
                                    var breadcrumb = $.trim(page_name).replace(/^[0-9]*/, '');
                                    var menu_link = $(this).attr('menulink');
                                    $(".contentareahdr", window.parent.document).html(breadcrumb);
                                    
                                    if (page_name == 'Set to Default') {
                                        $("#loading", window.parent.document).show();
                                        iframe.attr('src', '/programming/set_to_default_index');
                                    }
                                    else 
                                        if (!$(this).hasClass('parent_expandable')) {
                                            $("#loading", window.parent.document).show();
                                            iframe.attr('src', '/programming/page_parameters?page_name=' + page_name + '&menu_link=' + menu_link);
                                        }
                                        else {
                                            var menu_child = $(this).children();
                                            
                                            if ($(menu_child).first().hasClass('expandable-hitarea')) {
                                                $(menu_child).first().removeClass('expandable-hitarea').addClass('collapsable-hitarea')
                                                $(menu_child).last().show();
                                            }
                                            else 
                                                if ($(menu_child).first().hasClass('collapsable-hitarea')) {
                                                    $(menu_child).first().removeClass('collapsable-hitarea').addClass('expandable-hitarea')
                                                    $(menu_child).last().hide();
                                                }
                                                programming_click_finished = true;
                                            return false
                                        }
                                }
                        }
                    }
                    programming_click_finished = true;
                    return false;
                }
    });
});
