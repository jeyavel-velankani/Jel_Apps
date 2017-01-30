var t;

function check_status(_url){
  t = setTimeout(function(){
  var event_id = $('#event_id').attr('value');
  
  if (check_req()){
      $.ajax({
        type: "POST",
        url: _url,
        data: "event_id="+event_id,
        success: function(){
          $('#signal').attr('value', 2);
          hidePopWin2(false);
        }
      });
    check_status();
    }
  }, 5500);
}

function check_req(){
    var c = document.getElementById('signal').value;
    if (c != "") {
        if (c == 2) {
            return false;
        }
        if (c == 1) {
            return false;
        }
    }
    return true;
}

function reloader(url){
  var _url = url
  $('#div-one').load(_url, {auto_refresh: true}, function(){
    clearTimeout(t);
    t = setTimeout(function(){
      reloader(_url);
    }, 5000);
  });
}