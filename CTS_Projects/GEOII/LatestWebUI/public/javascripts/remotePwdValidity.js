var t=''
$(document).ready(function() {

 if(document.getElementById('text1_t1')!=null && document.getElementById('text1_t1').value!='' && document.getElementById('text2_t1')!=null && document.getElementById('text2_t1').value!=''){
      var temp = document.getElementById('hidnpwdExpTime').value
      temp = temp.substring(0,temp.indexOf('sec'))
      if(temp!=0){
        doSomething()
      }else if(temp == 0 ){
        document.getElementById('text1_t1').value=''
        document.getElementById('text2_t1').value=''
      }
 }
});
function doSomething(){
      var temp = document.getElementById('hidnpwdExpTime').value
      temp = temp.substring(0,temp.indexOf('sec'))
      if(temp!=0){
        t = setTimeout("timer_fn()", 1000);
      }else if(temp == 0 ){
        document.getElementById('text2_t1').value=''
        document.getElementById('text1_t1').value=''
        window.location.href="remoteSetup?removepwd=1";
      }      
}
function timer_fn(){
     var temp = document.getElementById('hidnpwdExpTime').value
     temp = temp.substring(0,temp.indexOf('sec'))
     temp = temp -1
     document.getElementById('hidnpwdExpTime').value = temp+" sec"
     doSomething()
  }