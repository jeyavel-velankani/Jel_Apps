function remotesetup_getpass_alert(obj){       
       window.location.href="remoteSetup?remotecalib="+obj.id;
 }

function timed_pop(){
    if(document.getElementById('timed_pop').style.display=='none'){
          document.getElementById('timed_pop').style.display='block'

      }
    var t = setTimeout("timer_fn()", 500);
}

 function timer_fn(){     
     window.location.href = document.getElementById("field_getter").value;
     return true;
   }
 function fn_logmsg(){
     document.getElementById('logmsg').style.display='block'
 }
 function submitmsg(){     
     document.getElementById('logmsg').style.display="none";     
     window.location.href = document.getElementById("field_getter").value+"&logmsg="+document.getElementById("log_msg").value;
 }
 function increment_val(obj){
      var value=obj.value;
     if(obj.readOnly == false){
        val=parseInt(value)+1;
        obj.value=val;
      }

}
function decrement_val(obj){
      var value=obj.value;
       if(obj.readOnly == false){
        val=parseInt(value)-1;
            if(val<0){
                val=0;
            }
        obj.value=val;
      }
}
function editclick(textBoxName){
    if(textBoxName == 'new'){
        document.getElementById('val1').readOnly=false
    }else if(textBoxName == 'new1'){
        document.getElementById('val2').readOnly=false
    }
}
function editValue(obj){
        if(obj=="test2_t1")
            document.getElementById('test2_t1').readOnly=false
        else if(obj=="test4_t1")
            document.getElementById('test4_t1').readOnly=false
        else if(obj=="test6_t1")
        document.getElementById('test6_t1').readOnly=false
}
function updateValue(cardid){
       lamp1volt=document.getElementById('val1').value
       lamp2volt=document.getElementById('val2').value      
       if(cardid == null || cardid==''){
            cardid=31;
       }
       window.location.href="sscc_lamps?lamp1volt="+lamp1volt+"&lamp2volt="+lamp2volt+"&cardid="+cardid;
}
function updatetestValue(cardid,test){
      var url;      
        if(document.getElementById('test2_t1')!=null){
            lmptston = document.getElementById('test2_t1').value
            url = "lmptston="+lmptston
        }
    
        if(document.getElementById('test4_t1')!=null){
            lmptstdelay = document.getElementById('test4_t1').value
            if(url!=null)
                url = url+"&lmptstdelay="+lmptstdelay
            else
                url = "lmptstdelay="+lmptstdelay
            
        }
        if(document.getElementById('test6_t1')!=null){
            lmptstcancel = document.getElementById('test6_t1').value
            if(url!=null)
                url = url+"&lmptstcancel="+lmptstcancel
            else
                url = "lmptstcancel="+lmptstcancel
        }      
        if(cardid == null || cardid==''){
            cardid=1;
       }       
       window.location.href="sscc_test?"+url+"&cardid="+cardid+"&test="+test;
}

function editPassword(obj){
        if(obj=="text1_t1"){            
            document.getElementById('text1_t1').readOnly=false
        }
}
function editTime(obj){
        if(obj=="text2_t1")
            document.getElementById('text2_t1').readOnly=false
}
function updateRemoteValue(){
        remotepassword = document.getElementById('text1_t1').value
        remotetimeout = document.getElementById('text2_t1').value        
        
       window.location.href="remoteSetup?remotetimeout="+remotetimeout+"&remotepassword="+remotepassword;
}
function remotesetup_calib(obj){
        var id = obj.id;
        var foundChar;
        var numbers ="0123456789"
        for (counter=0;counter<numbers.length;counter++){
            ch = id.indexOf(numbers.charAt(counter));
            if(ch>-1){
              foundChar = numbers.charAt(counter)
              break;
            }
        }
       if(foundChar=='' || foundChar== undefined)
            foundChar='sscc'
        window.location.href=document.getElementById("remote_getter").value+"&remotecalib="+foundChar+"&checkbox_display="+true+"&idOfCheck="+id+"&secRemain="+document.getElementById('hidnpwdExpTime').value;
          
 }
function enable_textfield(){
      var temp= document.getElementById('field_getter').value
      viewtype = temp.substring(temp.indexOf('view_type')+10,temp.length)

      if (viewtype=="APP"){
          document.getElementById('appspan').style.display=''
      }else if (viewtype=="LIN"){
          document.getElementById('linspan').style.display=''
      }
}
function updateCalibrateValue(){
    var linvalue,appvalue,url;    
    if(document.getElementById('app')!=null){
        appvalue = document.getElementById('app').value      
            url = "&appvalue="+appvalue
    }
    else if(document.getElementById('lin')!=null){
        linvalue = document.getElementById('lin').value        
        url = "&linvalue="+linvalue
    }
     window.location.href=document.getElementById("field_getter").value+url
}
function maintenancenotes(option){
    if(option =="ok"){       
        note=document.getElementById('note').value
    }
    else if(option =="cancel"){
        note=""
    }
    window.location.href="/logs/maintenanceLog?id=notes&note="+note;
}
function logclearalertmsg(text){
    if(window.confirm('Are you sure to clear the '+text+' log')){
        id="clear"        
    }else{
        id=""        
    }
    window.location.href="/logs/"+text+"Log/?id="+id;

}