/****************************************************************************************************************************************
Authoer: Kevin Ponce
Requirements: JQuery 1.9.1
Description: Library used to easily update jQuery when function are deprecated.

****************************************************************************************************************************************/

/****************************************************************************************************************************************
 reg functions
****************************************************************************************************************************************/
function w_console (string){
	if (typeof console !== 'undefined'){
		console.log(string);
	}		
}

function w_alter(string){
	alert(string);
}

function w_confrim(string){
	return k_confirm(string);
}

/****************************************************************************************************************************************
 plugins to jquery functions
****************************************************************************************************************************************/

(function($){

//click
  $.fn.extend({
  	w_click: function(callback){
       if(typeof callback === 'function'){
        call_off(this,'click');
        call_on(this,'click',callback);
      }else if(typeof callback === 'undefined'){
        $(this).click();
      }
  	}
  });

  //change
  $.fn.extend({
    w_change: function(callback,clear){
      if(typeof callback === 'function'){
        if(typeof clear == 'undefined' ||(typeof clear !== 'undefined' && clear == false)){
          call_off(this,'change');
        }
        call_on(this,'change',callback);
      }else if(typeof callback === 'undefined'){
        $(this).change();
      }
    }
  });

  //focus
  $.fn.extend({
    w_focus: function(callback){
      if(typeof callback === 'function'){
        call_off(this,'focus');
        call_on(this,'focus',callback);
      }else if(typeof callback === 'undefined'){
        $(this).focus();
      }
    }
  });

  //blur
  $.fn.extend({
    w_blur: function(callback){
      if(typeof callback === 'function'){
        call_off(this,'blur');
        call_on(this,'blur',callback);
      }else if(typeof callback === 'undefined'){
        $(this).blur();
      }
    }
  });

  //key up
  $.fn.extend({
    w_keyup: function(callback){
      call_off(this,'keyup');
      call_on(this,'keyup',callback);
    }
  });

  $.fn.extend({
    w_keydown: function(callback){
      call_off(this,'keydown');
      call_on(this,'keydown',callback);
    }
  });

  $.fn.extend({
    w_mouseup: function(callback){
      call_off(this,'mouseup');
      call_on(this,'mouseup',callback);
    }
  });

  $.fn.extend({
    w_mousedown: function(callback){
      call_off(this,'mousedown');
      call_on(this,'mousedown',callback);
    }
  });

  $.fn.extend({
    w_mousemove: function(callback){
      call_off(this,'mousemove');
      call_on(this,'mousemove',callback);
    }
  });  

  $.fn.extend({
    w_submit: function(callback){
      call_off(this,'submit');
      call_on(this,'submit',callback);
    }
  });

  $.extend({
    w_post: function(url,params,success_callback,error_callback,type){

      if(typeof type === 'undefined'){
        $.ajax({
        type: "POST",
        url: url,
        data: params,
        success: success_callback,
        error: error_callback});
      }else{
        $.ajax({
        type: "POST",
        url: url,
        data: params,
        success: success_callback,
        error: error_callback,
        type:type});
      }
      
    }
  });


//hover
  $.fn.extend({
    w_hover: function(callback_enter,callback_leave){

        call_off(this,'mouseenter');
        call_off(this,'mouseleave');

        if (typeof callback_enter == 'function' && typeof callback_leave == 'function') { // make sure the callback is a function
            call_on(this,'mouseenter',callback_enter);
            call_on(this,'mouseleave',callback_leave);
        }

    }
  });

//die
  $.fn.extend({
    w_die: function(type){
        call_off(this,type);
    }
  });


function call_on(element_this,type,callback){
  if(element_this.selector.split(' ').length > 1){
      var selector = element_this.selector.substring(element_this.selector.lastIndexOf(' ')+1);
      var elements = $(element_this.selector.substring(0,element_this.selector.lastIndexOf(' ')+1));
    }else{
      var selector = element_this.selector;
      var elements = $(document);
    }

    elements.each(function(){
      var obj = this;

      if (typeof callback == 'function') { // make sure the callback is a function
          $(obj).on(type, selector, callback);

      }
    });
}

function call_off(element_this,type){
  if(element_this.selector.split(' ').length > 1){
      var selector = element_this.selector.substring(element_this.selector.lastIndexOf(' ')+1);
      var elements = $(element_this.selector.substring(0,element_this.selector.lastIndexOf(' ')+1));
    }else{
      var selector = element_this.selector;
      var elements = $(document);
    }

    elements.each(function(){
      var obj = this;
          
      $(obj).off(type, selector);


    });
}

 

})(jQuery);
