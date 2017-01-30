/*
 * Module used to produce a dropdown menu effect when pointer is placed over
 * a button or similar
 */

/*
* Download hover, This function should be loaded when page is rendered.
*/
function dropdown_hover(){
    $('#dropdownsubmenu').hide();
    $(".download_icon").mouseover(function() {
        $('#dropdownsubmenu').show();
    }).mouseout(function(){
        $('#dropdownsubmenu').hide();
    });
}