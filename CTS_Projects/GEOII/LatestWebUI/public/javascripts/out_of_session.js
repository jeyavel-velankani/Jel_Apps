$(document).ready(function(){
	var tmp_url = current_url; 

	setTimeout(function(){
		if(tmp_url == current_url){
			reload_page();
		}
	},10000);
});