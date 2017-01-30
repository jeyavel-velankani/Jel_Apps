/**
 * @author Jeyavel Natesan
*/

$(document).ready(function(){
	add_to_destroy(function(){
		$(document).bind("ready",function(){});
		$('#contentcontents').css({'min-height':'485px' , 'min-width':'910px'});
		
		//kills all wrapper events
		$("#selinstallationname").w_die('change');
		$("#selatcsconfig").w_die('change');
		$("#seldevicename").w_die('change');
		$("#txtaspectid1").w_die('change');
		$("#txtaspectid2").w_die('change');
		$("#txtaspectid3").w_die('change');
		$("#txtdevicename").w_die('change');
		$("txttracknumber").w_die('change');
		$("#discard_icon").w_die('click');
		$("#save_device").w_die('click');

		//clear functions 
		delete window.get_installation_atcs;
		delete window.get_installation;
		delete window.get_installation_atcs_device;
		delete window.validatelogicstatenumber;
		delete window.num_only;
		delete window.validatebitposition;
		delete window.disable_signal_fields;
		delete window.enable_disable_all_elements;
		delete window.hidelogicstatesvalues;
		delete window.addlogicstates_signal;
		delete window.addlogicstates_switch;
		delete window.addlogicstates_hd;
		delete window.cleardevicedetails;
		delete window.clearlogicstatevalues;
		delete window.remove_device;
		delete window.add_new_device;
		delete window.change_device_type;
		delete window.aspectid_validate;
		delete window.validate;
		delete window.logicstatevalue_nooflogicstate_matched;
		delete window.add_logicstate_button_status;
		delete window.delete_logicstate;
		delete window.altaspect_validate;
		delete window.validate_tootal_nooflogicstate;
		delete window.setTitleToSelectedText;
		delete window.devicename_validate;
		delete window.tracknumber_validate;
	});
	
	$('#contentcontents').css({'min-height':'485px' , 'min-width':'910px'});
	document.getElementById('addlogicstatebuttonstatus').value = "added" ;
	var nooflogicstate = document.getElementById('txtnooflogicstatetotal').value ;	
	if ((nooflogicstate.length != 0) || (nooflogicstate.length != null)) {
		$("#deviceeditor_logicstates").hide();
	}
	$("#deviceeditor_switch").hide();
	$("#deviceeditor_signal").hide();
	$("#deviceeditor_hd").hide();
	$("#spn_device_details").append("Device details :");
	$("#span_approvedinstallationcrc").hide();
	document.getElementById("span_approvedinstallationcrc").innerHTML = "";
	
	var selecteddevicename = document.getElementById('seldevicename').options[document.getElementById('seldevicename').selectedIndex].text;
	
	if(selecteddevicename != "Device"){
		get_installation_atcs_device();
		$("#message_deviceeditor").html("Successfully updated device values.");
	}else{
		$("#outerdevicedetails").hide();
		$("#message_deviceeditor").html("");
	}
	
	$("#selinstallationname").w_change(function(){ 
		get_installation();
	});
	
	$("#selatcsconfig").w_change(function(){ 
		get_installation_atcs();
	});
	
	$("#seldevicename").w_change(function(){
		get_installation_atcs_device();
	});
	
	$("#txtaspectid1").w_change(function(){
		aspectid_validate(this);
	});
	
	$("#txtaspectid2").w_change(function(){
		aspectid_validate(this);
	});
	
	$("#txtaspectid3").w_change(function(){
		aspectid_validate(this);
	});
	
	$("#txtdevicename").w_change(function(){
		devicename_validate('change');
	});
	
	$("#txttracknumber").w_change(function(){
		tracknumber_validate('change');
	});
		
	$("#discard_icon").w_click(function(){
		var approvedcrc = document.getElementById('approvedinstallationcrcvalue').value;
		if (approvedcrc != '') {
			alert('Sorry , you need to unapprove selected installation and try again.');
		}else {
			if(confirm("Confirm discard changes?")){
				load_page("Device Editor","/deviceeditor/index");
			}
		} 
	});
	
	$("#save_device").w_click(function(){
		if (!validate()) {
			return false;
		}else {
			$("#contentcontents").mask("Processing request, please wait...");
			var update_val = 'save_type='+document.getElementById('savemode').value
						+',atcs_subnode='+document.getElementById('selatcsconfig').options[document.getElementById('selatcsconfig').selectedIndex].text
						+',installation_name='+document.getElementById('selinstallationname').options[document.getElementById('selinstallationname').selectedIndex].text
						+',device_name='+document.getElementById('txtdevicename').value
						+',track_number='+document.getElementById('txttracknumber').value
						+',adddevice_type='+document.getElementById('seldevicetype').options[document.getElementById('seldevicetype').selectedIndex].text
						+',device_type='+document.getElementById('txtdevicetype').value
						+',sig_conds='+document.getElementById('txtconditions').value
						+',stop_aspect='+document.getElementById('txtstopaspect').value
						+',heada='+document.getElementById('txtheada').value
						+',headb='+document.getElementById('txtheadb').value
						+',headc='+document.getElementById('txtheadc').value
						+',nooflogic_sig='+document.getElementById('txtnooflogicstatessignal').value
						+',switch_type='+document.getElementById('txtswitchtype').value
						+',nooflogic_swi='+document.getElementById('txtnooflogicstatesswitch').value
						+',nooflogic_hd='+document.getElementById('txtnooflogicstateshd').value+',logic_state1='+document.getElementById('txtlogicstate1').value
						+',logic_state1_bitpos='+document.getElementById('txtlogicstate1bitpos').value
						+',logic_state1_contcount='+document.getElementById('txtlogicstate1contcount').value
						+',logic_state2='+document.getElementById('txtlogicstate2').value
						+',logic_state2_bitpos='+document.getElementById('txtlogicstate2bitpos').value
						+',logic_state2_contcount='+document.getElementById('txtlogicstate2contcount').value
						+',logic_state3='+document.getElementById('txtlogicstate3').value
						+',logic_state3_bitpos='+document.getElementById('txtlogicstate3bitpos').value
						+',logic_state3_contcount='+document.getElementById('txtlogicstate3contcount').value
						+',logic_state4='+document.getElementById('txtlogicstate4').value
						+',logic_state4_bitpos='+document.getElementById('txtlogicstate4bitpos').value
						+',logic_state4_contcount='+document.getElementById('txtlogicstate4contcount').value
						+',device_id='+document.getElementById('seldevicename').value
						+',aspectid1='+document.getElementById('txtaspectid1').value
						+',altaspect1='+document.getElementById('txtaltaspect1').value
						+',aspectid2='+document.getElementById('txtaspectid2').value
						+',altaspect2='+document.getElementById('txtaltaspect2').value
						+',aspectid3='+document.getElementById('txtaspectid3').value
						+',altaspect3='+document.getElementById('txtaltaspect3').value
						+',existing_nooflogicstate_edit='+document.getElementById('txtnooflogicstatetotal').value
						+',logic_state5='+document.getElementById('txtlogicstate5').value
						+',logic_state5_bitpos='+document.getElementById('txtlogicstate5bitpos').value
						+',logic_state5_contcount='+document.getElementById('txtlogicstate5contcount').value
						+',logic_state6='+document.getElementById('txtlogicstate6').value
						+',logic_state6_bitpos='+document.getElementById('txtlogicstate6bitpos').value
						+',logic_state6_contcount='+document.getElementById('txtlogicstate6contcount').value;
			$.post("/deviceeditor/update_device_details", {
				result: update_val
			}, function(data){
				$("#contentcontents").unmask("Processing request, please wait...");
				load_page("Device Editor","/deviceeditor/index");
			});
		}
	});
});

function get_installation_atcs(){
	var instname = document.getElementById('selinstallationname').options[document.getElementById('selinstallationname').selectedIndex].text;
	var selatcsconfig =document.getElementById('selatcsconfig').options[document.getElementById('selatcsconfig').selectedIndex].text; 
	$("#message_deviceeditor").html("");
	if (selatcsconfig !="ATCS"){
		$.post("/deviceeditor/selatcsconfig", {
			atcsconfig: selatcsconfig,
			InstallationName :instname
		}, function(data){
		   if (data != "") {
		   		$("#seldevicename >option").remove();
		   		$('#seldevicename').append($('<option></option>').val(0).html('Device'));
			    var device = ""
			    device = data.split('|');
		    	for (var i = 1; i < device.length ; i++) {
					var id = device[i].split(',');
					$('#seldevicename').append($('<option></option>').val(id[0]).html(id[1]));
				}
			}else{
				
				$("#seldevicename >option").remove();
		   		$('#seldevicename').append($('<option></option>').val(0).html('Device'));
			}
		});
	}else{
	   $("#outerdevicedetails").hide();
	   $("#span_approvedinstallationcrc").hide();
	   $("#seldevicename >option").remove();
	   $('#seldevicename').append($('<option></option>').val(0).html('Device'));
	   cleardevicedetails();
	   clearlogicstatevalues();
	}
}

function get_installation(){
	var instname = $("#selinstallationname").val();
	$("#message_deviceeditor").html("");
	$.post("/deviceeditor/installationnameselect", {
		InstallationName: instname
	}, function(data){
	   $("#selatcsconfig >option").remove();
	   $('#selatcsconfig').append($('<option></option>').val(0).html('ATCS'));
	   if (data != "") {
	   	var atcs = "";
		    atcs = data.split('|');
	    	for (var j = 0; j < atcs.length-3 ; j++) {
				$('#selatcsconfig').append($('<option></option>').val(j).html(atcs[j+1]));
			}
			$("#approvedinstallationcrcvalue").val(atcs[atcs.length-2]);
			$("#installation_goltype").attr('value',atcs[atcs.length-1]);
	   }else{
	   	$("#installation_goltype").attr('value',"");
	   	$("#approvedinstallationcrcvalue").val("");
	   }
	   $("#seldevicename >option").remove();
	   $('#seldevicename').append($('<option></option>').val(0).html('Device'));
	   $("#outerdevicedetails").hide();
	   $("#span_approvedinstallationcrc").hide();
	   cleardevicedetails();
	   clearlogicstatevalues();
	});
}

function get_installation_atcs_device(){
	$("#contentcontents").mask("Processing request, please wait...");
	$("#outerdevicedetails").show();
	$("#devicetypefornew").hide();
	$("#message_deviceeditor").html("");
	$("#savemode").val("edit");
	var selecteddevicename = document.getElementById('seldevicename').options[document.getElementById('seldevicename').selectedIndex].text;
	var getdevicedetails = $("#seldevicename").val();
	if (selecteddevicename == "Device") {
		$("#outerdevicedetails").hide();
		$("#span_approvedinstallationcrc").hide();
		cleardevicedetails();
		clearlogicstatevalues();
		$("#contentcontents").unmask("Processing request, please wait...");
	}else {
		cleardevicedetails();
		clearlogicstatevalues();
		$.post("/deviceeditor/getdevicedetails", {
			Id: getdevicedetails
		}, function(data){
			var devicedetails = data.split('|');
			var approvedcrc = document.getElementById("approvedinstallationcrcvalue").value;
			if (approvedcrc != "" ){
					document.getElementById("span_approvedinstallationcrc").innerHTML = "";
					$("#span_approvedinstallationcrc").show();
					document.getElementById("span_approvedinstallationcrc").innerHTML = "Approved CRC : "+approvedcrc;
					enable_disable_all_elements(false);
			}else{
					document.getElementById("span_approvedinstallationcrc").innerHTML = "";
					$("#span_approvedinstallationcrc").hide();
					enable_disable_all_elements(true);
			}
			$("#deviceeditor_switch").hide();
			$("#deviceeditor_signal").hide();
			$("#deviceeditor_hd").hide();
			$("#devicetypeforexisting").hide();
			$("#devicetypefornew").hide();
			hidelogicstatesvalues();
			$('#contentcontents').css({'min-height':'485px' , 'min-width':'910px'})
			if (devicedetails[1] == "Signal") {
				$('#contentcontents').css({'min-height':'580px' , 'min-width':'910px'})
				$("#deviceeditor_signal").show();
				$("#devicetypeforexisting").show();
				document.getElementById("txtdevicetype").value = trim(devicedetails[1]);
				document.getElementById("txtdevicename").value = trim(devicedetails[2]);
				document.getElementById("txttracknumber").value = trim(devicedetails[3]);
				document.getElementById("txtconditions").value = trim(devicedetails[4]);
				document.getElementById("txtstopaspect").value = trim(devicedetails[5]);
				document.getElementById("txtheada").value = trim(devicedetails[6]);
				document.getElementById("txtheadb").value = trim(devicedetails[7]);
				document.getElementById("txtheadc").value = trim(devicedetails[8]);
				document.getElementById("txtnooflogicstatetotal").value = trim(devicedetails[9]);
				if (trim(devicedetails[9])>= 6){
					$("#addlogicstates_sig").hide();
					document.getElementById('txtnooflogicstatessignal').disabled = true;
				}else{
					if (approvedcrc != "") {
						$("#addlogicstates_sig").hide();
						document.getElementById('txtnooflogicstatessignal').disabled = true;
					}
					else {
						$("#addlogicstates_sig").show();
						document.getElementById('txtnooflogicstatessignal').disabled = false;
					}
				}
				document.getElementById("txtaspectid1").value = trim(devicedetails[10]);	
				document.getElementById("txtaltaspect1").value = trim(devicedetails[11]);
				document.getElementById("txtaspectid2").value = trim(devicedetails[12]);
				document.getElementById("txtaltaspect2").value = trim(devicedetails[13]);
				document.getElementById("txtaspectid3").value = trim(devicedetails[14]);
				document.getElementById("txtaltaspect3").value = trim(devicedetails[15]);
				// Check the AM & NONAM to disable the signals fields 
				disable_signal_fields();
				var Id = document.getElementById('seldevicename').options[document.getElementById('seldevicename').selectedIndex].value;
				$.post("/deviceeditor/logicstates", {
					DeviceId: Id
				}, function(data){
					$("#deviceeditor_logicstates").show();
					
					$("#contentcontents").unmask("Processing request, please wait...");
					var logicstatevalues = data.split('|');
					var count = 0;
					for (var i = 0; i < logicstatevalues.length - 1; i++) {
						var logicstate = logicstatevalues[i].split(',');
						count = count + 1
						var label1 = '#lbllogicstate' + count
						$(label1).show();
						var txt1col = '#txtlogicstate' + count
						$(txt1col).show();
						nameof = txt1col.split('#');
						document.getElementById(nameof[1]).value = logicstate[0];
						
						var label2 = '#lbllogicstate' + count + 'bitpos'
						$(label2).show();
						var txt1col1 = '#txtlogicstate' + count + 'bitpos'
						$(txt1col1).show();
						nameof1 = txt1col1.split('#');
						document.getElementById(nameof1[1]).value = logicstate[1];
						
						var label3 = '#lbllogicstate' + count + 'contcount'
						$(label3).show();
						var txt1col2 = '#txtlogicstate' + count + 'contcount'
						$(txt1col2).show();
						nameof2 = txt1col2.split('#');
						document.getElementById(nameof2[1]).value = logicstate[2];
						
						var delete_button = '#delete_logicstate_'+count
						$(delete_button).show();
						
					}
					var nooflogicstate = document.getElementById("txtnooflogicstatetotal").value;
					var logicstatevalsig = 0;
						if (logicstatevalues.length > 0){
							logicstatevalsig = logicstatevalues;
						}
						else{
							logicstatevalsig =0;
						}
					if (nooflogicstate > (logicstatevalsig.length - 1)) {
						var emptylogicstate = nooflogicstate - (logicstatevalsig.length - 1);
						for (var j = 0; j < emptylogicstate; j++) {
							count = count + 1
							
							var label1 = '#lbllogicstate' + count
							$(label1).show();
							var txt1col = '#txtlogicstate' + count
							$(txt1col).show();
							nameof = txt1col.split('#');
							document.getElementById(nameof[1]).value = "";
							
							var label2 = '#lbllogicstate' + count + 'bitpos'
							$(label2).show();
							var txt1col1 = '#txtlogicstate' + count + 'bitpos'
							$(txt1col1).show();
							nameof1 = txt1col1.split('#');
							document.getElementById(nameof1[1]).value = "";
							
							var label3 = '#lbllogicstate' + count + 'contcount'
							$(label3).show();
							var txt1col2 = '#txtlogicstate' + count + 'contcount'
							$(txt1col2).show();
							nameof2 = txt1col2.split('#');
							document.getElementById(nameof2[1]).value = "";
							
							var delete_button = '#delete_logicstate_'+count
							$(delete_button).show();
						}
					}
				});
			} else if (devicedetails[1] == "Switch") {
					$("#deviceeditor_switch").show();
					$("#devicetypeforexisting").show();
					document.getElementById("txtdevicetype").value = trim(devicedetails[1]);
					document.getElementById("txtdevicename").value = trim(devicedetails[2]);
					document.getElementById("txttracknumber").value = trim(devicedetails[3]);
					document.getElementById("txtswitchtype").value = trim(devicedetails[4]);
					document.getElementById("txtnooflogicstatetotal").value = trim(devicedetails[5]);
					if (trim(devicedetails[5]) >= 2){
						$("#addlogicstates_sw").hide();
						document.getElementById('txtnooflogicstatesswitch').disabled = true;
					} else {
						if (approvedcrc != "") {
							$("#addlogicstates_sw").hide();
							document.getElementById('txtnooflogicstatesswitch').disabled = true;
						} else {
							$("#addlogicstates_sw").show();
							document.getElementById('txtnooflogicstatesswitch').disabled = false;
						}
					}
					var Id = document.getElementById('seldevicename').options[document.getElementById('seldevicename').selectedIndex].value;
					$.post("/deviceeditor/logicstates", {
						DeviceId: Id
					}, function(data){
						$("#deviceeditor_logicstates").show();
						$("#contentcontents").unmask("Processing request, please wait...");
						var logicstatevalues = data.split('|');
						var count1 = 0;
						for (var i = 0; i < logicstatevalues.length - 1; i++) {
							var logicstate = logicstatevalues[i].split(',');
							count1 = count1 + 1
							var label1 = '#lbllogicstate' + count1
							$(label1).show();
							var txt1col = '#txtlogicstate' + count1
							$(txt1col).show();
							nameof = txt1col.split('#');
							document.getElementById(nameof[1]).value = logicstate[0];
							
							var label2 = '#lbllogicstate' + count1 + 'bitpos'
							$(label2).show();
							var txt1col1 = '#txtlogicstate' + count1 + 'bitpos'
							$(txt1col1).show();
							nameof1 = txt1col1.split('#');
							document.getElementById(nameof1[1]).value = logicstate[1];
							
							var label3 = '#lbllogicstate' + count1 + 'contcount'
							$(label3).show();
							var txt1col2 = '#txtlogicstate' + count1 + 'contcount'
							$(txt1col2).show();
							nameof2 = txt1col2.split('#');
							document.getElementById(nameof2[1]).value = logicstate[2];
							
							var delete_button = '#delete_logicstate_'+count1
							$(delete_button).show();
						}
						var nooflogicstate = document.getElementById("txtnooflogicstatetotal").value;
						var logicstateval = 0;
						if (logicstatevalues.length > 0){
							logicstateval = logicstatevalues;
						}
						else{
							logicstateval =0;
						}
						if (nooflogicstate > (logicstateval.length - 1)) {
							var emptylogicstate = nooflogicstate - (logicstateval.length - 1);
							for (var j = 0; j < emptylogicstate; j++) {
								count1 = count1 + 1
								var label1 = '#lbllogicstate' + count1
								$(label1).show();
								var txt1col = '#txtlogicstate' + count1
								$(txt1col).show();
								nameof = txt1col.split('#');
								document.getElementById(nameof[1]).value = "";
								
								var label2 = '#lbllogicstate' + count1 + 'bitpos'
								$(label2).show();
								var txt1col1 = '#txtlogicstate' + count1 + 'bitpos'
								$(txt1col1).show();
								nameof1 = txt1col1.split('#');
								document.getElementById(nameof1[1]).value = "";
								
								var label3 = '#lbllogicstate' + count1 + 'contcount'
								$(label3).show();
								var txt1col2 = '#txtlogicstate' + count1 + 'contcount'
								$(txt1col2).show();
								nameof2 = txt1col2.split('#');
								document.getElementById(nameof2[1]).value = "";
								
								var delete_button = '#delete_logicstate_'+count1
								$(delete_button).show();
							}
						}
					});
				}
				else 
					if (devicedetails[1] == "Hazard Detector") {
						//$("#addlogicstates_hd").hide();	
						$("#deviceeditor_hd").show();
						$("#devicetypeforexisting").show();
						document.getElementById("txtdevicetype").value = trim(devicedetails[1]);
						document.getElementById("txtdevicename").value = trim(devicedetails[2]);
						document.getElementById("txttracknumber").value = trim(devicedetails[3]);
						document.getElementById("txtnooflogicstatetotal").value = trim(devicedetails[4]);
						if (trim(devicedetails[4]) >= 1){
							$("#addlogicstates_hd").hide();
							document.getElementById('txtnooflogicstateshd').disabled = true;
						}else{
							if (approvedcrc != "") {
								$("#addlogicstates_hd").hide();
								document.getElementById('txtnooflogicstateshd').disabled = true;
							} else {
								$("#addlogicstates_hd").show();
								document.getElementById('txtnooflogicstateshd').disabled = false;
							}
						}
						var Id = document.getElementById('seldevicename').options[document.getElementById('seldevicename').selectedIndex].value;
						$.post("/deviceeditor/logicstates", {
							DeviceId: Id
						}, function(data){
							$("#deviceeditor_logicstates").show();
							$("#contentcontents").unmask("Processing request, please wait...");
							var logicstatevalues = data.split('|');
							var count1 = 0;
							for (var i = 0; i < logicstatevalues.length - 1; i++) {
								var logicstate = logicstatevalues[i].split(',');
								count1 = count1 + 1
								var label1 = '#lbllogicstate' + count1
								$(label1).show();
								var txt1col = '#txtlogicstate' + count1
								$(txt1col).show();
								nameof = txt1col.split('#');
								document.getElementById(nameof[1]).value = logicstate[0];
								
								var label2 = '#lbllogicstate' + count1 + 'bitpos'
								$(label2).show();
								var txt1col1 = '#txtlogicstate' + count1 + 'bitpos'
								$(txt1col1).show();
								nameof1 = txt1col1.split('#');
								document.getElementById(nameof1[1]).value = logicstate[1];
								
								var label3 = '#lbllogicstate' + count1 + 'contcount'
								$(label3).show();
								var txt1col2 = '#txtlogicstate' + count1 + 'contcount'
								$(txt1col2).show();
								nameof2 = txt1col2.split('#');
								document.getElementById(nameof2[1]).value = logicstate[2];
								
								var delete_button = '#delete_logicstate_'+count1
								$(delete_button).show();
							}
							var nooflogicstate = document.getElementById("txtnooflogicstatetotal").value;
							if (nooflogicstate > (logicstatevalues.length - 1)) {
								var emptylogicstate = nooflogicstate - (logicstatevalues.length - 1);
								for (var j = 0; j < emptylogicstate; j++) {
									count1 = count1 + 1
									var label1 = '#lbllogicstate' + count1
									$(label1).show();
									var txt1col = '#txtlogicstate' + count1
									$(txt1col).show();
									nameof = txt1col.split('#');
									document.getElementById(nameof[1]).value = "";
									
									var label2 = '#lbllogicstate' + count1 + 'bitpos'
									$(label2).show();
									var txt1col1 = '#txtlogicstate' + count1 + 'bitpos'
									$(txt1col1).show();
									nameof1 = txt1col1.split('#');
									document.getElementById(nameof1[1]).value = "";
									
									var label3 = '#lbllogicstate' + count1 + 'contcount'
									$(label3).show();
									var txt1col2 = '#txtlogicstate' + count1 + 'contcount'
									$(txt1col2).show();
									nameof2 = txt1col2.split('#');
									document.getElementById(nameof2[1]).value = "";
									
									var delete_button = '#delete_logicstate_'+count1
									$(delete_button).show();
								}
							}
						});
					}
		});
	}
}		

function validatelogicstatenumber(){
	var arr = [];
	arr[0] = document.getElementById('txtlogicstate1').value;
	arr[1] = document.getElementById('txtlogicstate2').value;
	arr[2] = document.getElementById('txtlogicstate3').value;
	arr[3] = document.getElementById('txtlogicstate4').value;
	arr[4] = document.getElementById('txtlogicstate5').value;
	arr[5] = document.getElementById('txtlogicstate6').value;
	var savemode = document.getElementById("savemode").value;
	var devicetype;
	var existtotalnooflogic ;
	var noofstate;
	if (savemode =="edit"){
		devicetype = document.getElementById('txtdevicetype').value;
		existtotalnooflogic = parseInt(document.getElementById("txtnooflogicstatetotal").value);
	}else if(savemode == "new"){
		devicetype = document.getElementById('seldevicetype').options[document.getElementById('seldevicetype').selectedIndex].text;
		existtotalnooflogic = parseInt(document.getElementById("txtnooflogicstatetotal_new").value);
	}
	if(isNaN(existtotalnooflogic)){
			existtotalnooflogic = 0;
	}
	if (devicetype == "Signal"){
			noofstate = parseInt(document.getElementById('txtnooflogicstatessignal').value);	
	} else if(devicetype == "Switch"){
			noofstate = parseInt(document.getElementById('txtnooflogicstatesswitch').value);
	} else if(devicetype == "Hazard Detector"){
			noofstate = parseInt(document.getElementById('txtnooflogicstateshd').value);
	}
	if(isNaN(noofstate)){
			noofstate = 0;
	}
	noofstate = noofstate + existtotalnooflogic ;
	var takeresults = [];
	for (var n=0 ; n < noofstate ; n++){
		if (arr[n]){
		takeresults.push(arr[n]);	
		}
	}
	var results = [];
	for (var i = 0; i < takeresults.length ; i++) {
	        for (var j = i+1; j < takeresults.length ; j++) {
				if (takeresults[i] == takeresults[j]) {
					alert("Logic state number ("+takeresults[j]+") should not be duplicate");
					return false;
				}
			}
	}
	return true;
}
		
function num_only(event)
{
	var keyASCII;
	if (window.event) {
		event = window.event;
		keyASCII = event.keyCode;
	} else {
		keyASCII = event.charCode;
	}
	var keyValue = String.fromCharCode(keyASCII);
	if(keyASCII == '0')	{
		return true;
	}
	if (!(keyValue >= '0' && keyValue <= '9')) {
		return false;
	} else	{
		return true;
	}
}

function validatebitposition(){
	var arr = [];
	arr[0] = document.getElementById('txtlogicstate1bitpos').value;
	arr[1] = document.getElementById('txtlogicstate2bitpos').value;
	arr[2] = document.getElementById('txtlogicstate3bitpos').value;
	arr[3] = document.getElementById('txtlogicstate4bitpos').value;
	arr[4] = document.getElementById('txtlogicstate5bitpos').value;
	arr[5] = document.getElementById('txtlogicstate6bitpos').value;
	var savemode = document.getElementById("savemode").value;
	var devicetype;
	var existtotalnooflogic ;
	var noofstate;
	if (savemode == "edit"){
		devicetype = document.getElementById('txtdevicetype').value;
		existtotalnooflogic = parseInt(document.getElementById("txtnooflogicstatetotal").value);
	}else if (savemode == "new"){
		devicetype = document.getElementById('seldevicetype').options[document.getElementById('seldevicetype').selectedIndex].text;
		existtotalnooflogic = parseInt(document.getElementById("txtnooflogicstatetotal_new").value);
	}
	if(isNaN(existtotalnooflogic)){
			existtotalnooflogic = 0;
	}
	if (devicetype =="Signal"){
			noofstate = document.getElementById('txtnooflogicstatessignal').value;	
	}else if (devicetype =="Switch"){
			noofstate = document.getElementById('txtnooflogicstatesswitch').value;
	}else if (devicetype =="Hazard Detector"){
			noofstate = document.getElementById('txtnooflogicstateshd').value;
	}
	if(isNaN(noofstate)){
			noofstate = 0;
	}
	noofstate = noofstate + existtotalnooflogic ;
	var takeresults = [];
	for (var n=0 ; n < noofstate ; n++){
		if (arr[n]){
		takeresults.push(arr[n]);	
		}
	}
	var results = [];
	for (var i = 0; i < takeresults.length ; i++) {
        for (var j = i+1; j < takeresults.length ; j++) {
			if (takeresults[i] == takeresults[j]) {
				alert("Bit Position ("+takeresults[j]+") should not be duplicate");
				return false;
			}
		}
	}
	return true;
}

function disable_signal_fields(){
	// Check the AM & NONAM to disable the signals fields
	var gol_type = $("#installation_goltype").attr('value');
	if(gol_type == "AM"){
		$("#txtheada").attr('disabled','disabled');
		$("#txtheadb").attr('disabled','disabled');
		$("#txtheadc").attr('disabled','disabled');
	}else if(gol_type == "NONAM"){
		$("#txtconditions").attr('disabled','disabled');
		$("#txtstopaspect").attr('disabled','disabled');
	}
}

function enable_disable_all_elements(enableflag){
	if ((enableflag == 'true') ||(enableflag == true)){
		for(var i=1 ; i <= 6 ; i++){
			document.getElementById('txtlogicstate'+i).disabled = false;
			document.getElementById('txtlogicstate'+i+'bitpos').disabled = false;
			document.getElementById('txtlogicstate'+i+'contcount').disabled = false;	
		}
		document.getElementById('txtdevicename').disabled = false;
		document.getElementById('txttracknumber').disabled = false;
		document.getElementById('txtconditions').disabled = false;
		document.getElementById('txtstopaspect').disabled = false;
		document.getElementById('txtheada').disabled = false;
		document.getElementById('txtheadb').disabled = false;
		document.getElementById('txtheadc').disabled = false;
		document.getElementById('txtnooflogicstatetotal').disabled = true;
		document.getElementById('txtnooflogicstatetotal_new').disabled = true;
		document.getElementById('txtnooflogicstatessignal').disabled = false;
		document.getElementById('txtswitchtype').disabled = false;
		document.getElementById('txtnooflogicstatesswitch').disabled = false;
		document.getElementById('txtnooflogicstateshd').disabled = false;
		document.getElementById('txtaspectid1').disabled = false;
		document.getElementById('txtaltaspect1').disabled = false;
		document.getElementById('txtaspectid2').disabled = false;
		document.getElementById('txtaltaspect2').disabled = false;
		document.getElementById('txtaspectid3').disabled = false;
		document.getElementById('txtaltaspect3').disabled = false;
		$("#addlogicstates_sig").show();		
		$("#addlogicstates_sw").show();
		$("#addlogicstates_hd").show();
	}else{
		
 		for(var j=1 ; j <= 6 ; j++){
			document.getElementById('txtlogicstate'+j).disabled = true;
			document.getElementById('txtlogicstate'+j+'bitpos').disabled = true;
			document.getElementById('txtlogicstate'+j+'contcount').disabled = true;	
		}
		document.getElementById('txtdevicename').disabled = true;
		document.getElementById('txttracknumber').disabled = true;
		document.getElementById('txtconditions').disabled = true;
		document.getElementById('txtstopaspect').disabled = true;
		document.getElementById('txtheada').disabled = true;
		document.getElementById('txtheadb').disabled = true;
		document.getElementById('txtheadc').disabled = true;
		document.getElementById('txtnooflogicstatetotal').disabled = true;
		document.getElementById('txtnooflogicstatetotal_new').disabled = true;
		document.getElementById('txtnooflogicstatessignal').disabled = true;
		document.getElementById('txtswitchtype').disabled = true;
		document.getElementById('txtnooflogicstatesswitch').disabled = true;
		document.getElementById('txtnooflogicstateshd').disabled = true;
		document.getElementById('txtaspectid1').disabled = true;
		document.getElementById('txtaltaspect1').disabled = true;
		document.getElementById('txtaspectid2').disabled = true;
		document.getElementById('txtaltaspect2').disabled = true;
		document.getElementById('txtaspectid3').disabled = true;
		document.getElementById('txtaltaspect3').disabled = true;
		$("#addlogicstates_sig").hide();		
		$("#addlogicstates_sw").hide();
		$("#addlogicstates_hd").hide();	
	}
}

function hidelogicstatesvalues(){
	for(var i=1 ; i<=6 ; i++){
		var label1 ="#lbllogicstate"+i;
		$(label1).hide();	
		var textbox1 = "#txtlogicstate"+i;
		$(textbox1).hide();	
		var label2 ='#lbllogicstate'+i+'bitpos';
		$(label2).hide();	
		var textbox2 = '#txtlogicstate'+i+'bitpos';
		$(textbox2).hide();	
		var label3 ='#lbllogicstate'+i+'contcount';
		$(label3).hide();	
		var textbox3 = '#txtlogicstate'+i+'contcount';
		$(textbox3).hide();	
		var deletebutton = '#delete_logicstate_'+i;
		$(deletebutton).hide();
	}
}

function addlogicstates_signal(){
	document.getElementById('addlogicstatebuttonstatus').value = "added" ;
	var savemode = document.getElementById("savemode").value;
	var existtotalnooflogic ;
	if (savemode == "edit"){
		existtotalnooflogic = parseInt(document.getElementById("txtnooflogicstatetotal").value);
	}else if(savemode == "new"){
		existtotalnooflogic = parseInt(document.getElementById("txtnooflogicstatetotal_new").value);
	}
	if(isNaN(existtotalnooflogic)){
			existtotalnooflogic = 0;
	}
	var nooflogicstateadd = parseInt(document.getElementById("txtnooflogicstatessignal").value);
	if(isNaN(nooflogicstateadd)){
		nooflogicstateadd = 0;
	}
	var validnoof = existtotalnooflogic + nooflogicstateadd
	if (validnoof > existtotalnooflogic ) {
		if ((validnoof > 0) && (validnoof < 7)) {
			$("#deviceeditor_logicstates").show();
			hidelogicstatesvalues();
			var count1 = 0
			for (var j = 0; j < validnoof; j++) {
				count1 = count1 + 1
				var label1 = '#lbllogicstate' + count1
				$(label1).show();
				var txt1col = '#txtlogicstate' + count1
				$(txt1col).show();
				nameof = txt1col.split('#');
				document.getElementById(nameof[1]).value = "";
				
				var label2 = '#lbllogicstate' + count1 + 'bitpos'
				$(label2).show();
				var txt1col1 = '#txtlogicstate' + count1 + 'bitpos'
				$(txt1col1).show();
				nameof1 = txt1col1.split('#');
				document.getElementById(nameof1[1]).value = "";
				
				var label3 = '#lbllogicstate' + count1 + 'contcount'
				$(label3).show();
				var txt1col2 = '#txtlogicstate' + count1 + 'contcount'
				$(txt1col2).show();
				nameof2 = txt1col2.split('#');
				document.getElementById(nameof2[1]).value = "";
			}
			if (savemode == "edit") {
				var Id = document.getElementById('seldevicename').options[document.getElementById('seldevicename').selectedIndex].value;
				$.post("/deviceeditor/logicstates", {
					DeviceId: Id
				}, function(data){
					$("#deviceeditor_logicstates").show();
					var logicstatevalues = data.split('|');
					var nooflogictotal = parseInt(document.getElementById("txtnooflogicstatetotal").value);
					var addedlogic_sig = parseInt(document.getElementById("txtnooflogicstatessignal").value);
					var logicstatetotal = nooflogictotal + addedlogic_sig
					var count = 0;
					var nvalue;
					var countlogicavl = logicstatevalues.length - 1;
					if (countlogicavl < logicstatetotal) {
						nvalue = countlogicavl;
					}
					else {
						nvalue = logicstatetotal;
					}
					for (var i = 0; i < nvalue; i++) {
						var logicstate = logicstatevalues[i].split(',');
						count = count + 1
						var label1 = '#lbllogicstate' + count
						$(label1).show();
						var txt1col = '#txtlogicstate' + count
						$(txt1col).show();
						nameof = txt1col.split('#');
						document.getElementById(nameof[1]).value = logicstate[0];
						
						var label2 = '#lbllogicstate' + count + 'bitpos'
						$(label2).show();
						var txt1col1 = '#txtlogicstate' + count + 'bitpos'
						$(txt1col1).show();
						nameof1 = txt1col1.split('#');
						document.getElementById(nameof1[1]).value = logicstate[1];
						
						var label3 = '#lbllogicstate' + count + 'contcount'
						$(label3).show();
						var txt1col2 = '#txtlogicstate' + count + 'contcount'
						$(txt1col2).show();
						nameof2 = txt1col2.split('#');
						document.getElementById(nameof2[1]).value = logicstate[2];
						
						var delete_button = '#delete_logicstate_' + count
						$(delete_button).show();
					}
				});
			}
			return true;
		}
		else {
			alert("Please enter No.logic states within the limits and try again.")
			document.getElementById("txtnooflogicstatessignal").value = "";
			return false;
		}
	}
}

function addlogicstates_switch(){
	document.getElementById('addlogicstatebuttonstatus').value = "added" ;
	var savemode = document.getElementById("savemode").value;
	var existtotalnooflogic ;
	if (savemode == "edit"){
		existtotalnooflogic = parseInt(document.getElementById("txtnooflogicstatetotal").value);
	}else if(savemode == "new"){
		existtotalnooflogic = parseInt(document.getElementById("txtnooflogicstatetotal_new").value);
	}
	if(isNaN(existtotalnooflogic)){
		existtotalnooflogic = 0;
	}
	var nooflogicstateadd = parseInt(document.getElementById("txtnooflogicstatesswitch").value);
	if(isNaN(nooflogicstateadd)){
			nooflogicstateadd = 0;
	}
	var validnoof = existtotalnooflogic + nooflogicstateadd
	if (validnoof > existtotalnooflogic) {
		if ((validnoof > 0) && (validnoof < 3)) {
			$("#deviceeditor_logicstates").show();
			hidelogicstatesvalues();
			var count1 = 0
			for (var j = 0; j < validnoof; j++) {
				count1 = count1 + 1
				var label1 = '#lbllogicstate' + count1
				$(label1).show();
				var txt1col = '#txtlogicstate' + count1
				$(txt1col).show();
				nameof = txt1col.split('#');
				document.getElementById(nameof[1]).value = "";
				var label2 = '#lbllogicstate' + count1 + 'bitpos'
				$(label2).show();
				var txt1col1 = '#txtlogicstate' + count1 + 'bitpos'
				$(txt1col1).show();
				nameof1 = txt1col1.split('#');
				document.getElementById(nameof1[1]).value = "";
				
				var label3 = '#lbllogicstate' + count1 + 'contcount'
				$(label3).show();
				var txt1col2 = '#txtlogicstate' + count1 + 'contcount'
				$(txt1col2).show();
				nameof2 = txt1col2.split('#');
				document.getElementById(nameof2[1]).value = "";
			}
			if (savemode == "edit") {
				var Id = document.getElementById('seldevicename').options[document.getElementById('seldevicename').selectedIndex].value;
				$.post("/deviceeditor/logicstates", {
					DeviceId: Id
				}, function(data){
					$("#deviceeditor_logicstates").show();
					var logicstatevalues = data.split('|');
					var nooflogictotal = parseInt(document.getElementById("txtnooflogicstatetotal").value);
					var addedlogic_sw = parseInt(document.getElementById("txtnooflogicstatesswitch").value);
					var logicstatetotal = nooflogictotal + addedlogic_sw
					var count = 0;
					var nvalue;
					var countlogicavl = logicstatevalues.length - 1;
					if (countlogicavl < logicstatetotal) {
						nvalue = countlogicavl;
					}
					else {
						nvalue = logicstatetotal;
					}
					for (var i = 0; i < nvalue; i++) {
						var logicstate = logicstatevalues[i].split(',');
						count = count + 1
						var label1 = '#lbllogicstate' + count
						$(label1).show();
						var txt1col = '#txtlogicstate' + count
						$(txt1col).show();
						nameof = txt1col.split('#');
						document.getElementById(nameof[1]).value = logicstate[0];
						
						var label2 = '#lbllogicstate' + count + 'bitpos'
						$(label2).show();
						var txt1col1 = '#txtlogicstate' + count + 'bitpos'
						$(txt1col1).show();
						nameof1 = txt1col1.split('#');
						document.getElementById(nameof1[1]).value = logicstate[1];
						
						var label3 = '#lbllogicstate' + count + 'contcount'
						$(label3).show();
						var txt1col2 = '#txtlogicstate' + count + 'contcount'
						$(txt1col2).show();
						nameof2 = txt1col2.split('#');
						document.getElementById(nameof2[1]).value = logicstate[2];
						
						var delete_button = '#delete_logicstate_' + count
						$(delete_button).show();
					}
				});
			}
			return true;
		}
		else {
			alert("Please enter No.logic states within the limits and try again.")
			document.getElementById("txtnooflogicstatesswitch").value = "";
			return false;
		}
	}
}

function addlogicstates_hd(){
		document.getElementById('addlogicstatebuttonstatus').value = "added" ;
		var savemode = document.getElementById("savemode").value;
		var existtotalnooflogic ;
		if (savemode == "edit"){
			existtotalnooflogic = parseInt(document.getElementById("txtnooflogicstatetotal").value);
		}else if (savemode == "new"){
			existtotalnooflogic = parseInt(document.getElementById("txtnooflogicstatetotal_new").value);
		}
		if(isNaN(existtotalnooflogic)){
			existtotalnooflogic = 0;
		}
		var nooflogicstateadd = parseInt(document.getElementById("txtnooflogicstateshd").value);
		if(isNaN(nooflogicstateadd)){
			nooflogicstateadd = 0;
		}
		var validnoof = existtotalnooflogic + nooflogicstateadd ;
		if (validnoof > existtotalnooflogic) {
			if ((validnoof > 0) && (validnoof < 2)) {
				$("#deviceeditor_logicstates").show();
				hidelogicstatesvalues();
				var count1 = 0
				for (var j = 0; j < validnoof; j++) {
					count1 = count1 + 1
					var label1 = '#lbllogicstate' + count1
					$(label1).show();
					var txt1col = '#txtlogicstate' + count1
					$(txt1col).show();
					nameof = txt1col.split('#');
					document.getElementById(nameof[1]).value = "";
					var label2 = '#lbllogicstate' + count1 + 'bitpos'
					$(label2).show();
					var txt1col1 = '#txtlogicstate' + count1 + 'bitpos'
					$(txt1col1).show();
					nameof1 = txt1col1.split('#');
					document.getElementById(nameof1[1]).value = "";
					
					var label3 = '#lbllogicstate' + count1 + 'contcount'
					$(label3).show();
					var txt1col2 = '#txtlogicstate' + count1 + 'contcount'
					$(txt1col2).show();
					nameof2 = txt1col2.split('#');
					document.getElementById(nameof2[1]).value = "";
				}
				if (savemode == "edit") {
					var Id = document.getElementById('seldevicename').options[document.getElementById('seldevicename').selectedIndex].value;
					$.post("/deviceeditor/logicstates", {
						DeviceId: Id
					}, function(data){
						$("#deviceeditor_logicstates").show();
						var logicstatevalues = data.split('|');
						var nooflogictotal = parseInt(document.getElementById("txtnooflogicstatetotal").value);
						var addedlogic_hd = parseInt(document.getElementById("txtnooflogicstateshd").value);
						var logicstatetotal = nooflogictotal + addedlogic_hd
						var count = 0;
						var nvalue;
						var countlogicavl = logicstatevalues.length - 1;
						if (countlogicavl < logicstatetotal) {
							nvalue = countlogicavl;
						}else {
							nvalue = logicstatetotal;
						}
						for (var i = 0; i < nvalue; i++) {
							var logicstate = logicstatevalues[i].split(',');
							count = count + 1
							var label1 = '#lbllogicstate' + count
							$(label1).show();
							var txt1col = '#txtlogicstate' + count
							$(txt1col).show();
							nameof = txt1col.split('#');
							document.getElementById(nameof[1]).value = logicstate[0];
							
							var label2 = '#lbllogicstate' + count + 'bitpos'
							$(label2).show();
							var txt1col1 = '#txtlogicstate' + count + 'bitpos'
							$(txt1col1).show();
							nameof1 = txt1col1.split('#');
							document.getElementById(nameof1[1]).value = logicstate[1];
							
							var label3 = '#lbllogicstate' + count + 'contcount'
							$(label3).show();
							var txt1col2 = '#txtlogicstate' + count + 'contcount'
							$(txt1col2).show();
							nameof2 = txt1col2.split('#');
							document.getElementById(nameof2[1]).value = logicstate[2];
							
							var delete_button = '#delete_logicstate_' + count
							$(delete_button).show();
						}
					});
				}
				return true;
			}else {
				alert("Please enter No.logic states within the limits and try again.")
				document.getElementById("txtnooflogicstateshd").value = "";
				return false;
			}
		}
}

function cleardevicedetails(){
	document.getElementById("txtdevicetype").value ="";
	document.getElementById("txtdevicename").value ="";
	document.getElementById("txttracknumber").value ="";
	document.getElementById("txtconditions").value ="";
	document.getElementById("txtstopaspect").value ="";
	document.getElementById("txtheada").value ="";
	document.getElementById("txtheadb").value ="";
	document.getElementById("txtheadc").value ="";
	document.getElementById("txtaspectid1").value ="";
	document.getElementById("txtaltaspect1").value ="";
	document.getElementById("txtaspectid2").value ="";
	document.getElementById("txtaltaspect2").value ="";
	document.getElementById("txtaspectid3").value ="";
	document.getElementById("txtaltaspect3").value ="";
	document.getElementById("txtnooflogicstatessignal").value ="";
	document.getElementById("txtswitchtype").value ="";
	document.getElementById("txtnooflogicstatesswitch").value ="";
	document.getElementById("txtnooflogicstateshd").value ="";
	document.getElementById("txtnooflogicstatetotal").value ="";
	document.getElementById("txtnooflogicstatetotal_new").value ="";
}

function clearlogicstatevalues(){
	document.getElementById("txtlogicstate1").value = "";
	document.getElementById("txtlogicstate2").value = "";
	document.getElementById("txtlogicstate3").value = "";
	document.getElementById("txtlogicstate4").value = "";
	document.getElementById("txtlogicstate5").value = "";
	document.getElementById("txtlogicstate6").value = "";
	document.getElementById("txtlogicstate1bitpos").value = "";
	document.getElementById("txtlogicstate2bitpos").value = "";
	document.getElementById("txtlogicstate3bitpos").value = "";
	document.getElementById("txtlogicstate4bitpos").value = "";
	document.getElementById("txtlogicstate5bitpos").value = "";
	document.getElementById("txtlogicstate6bitpos").value = "";
	document.getElementById("txtlogicstate1contcount").value = "";
	document.getElementById("txtlogicstate2contcount").value = "";
	document.getElementById("txtlogicstate3contcount").value = "";
	document.getElementById("txtlogicstate4contcount").value = "";
	document.getElementById("txtlogicstate5contcount").value = "";
	document.getElementById("txtlogicstate6contcount").value = "";
}

function remove_device(){
	var approvedcrc = document.getElementById("approvedinstallationcrcvalue").value;
	if (approvedcrc != "") {
		alert("Sorry , you need to unapprove selected installation and try again.")
	}
	else {
		
		var installation = document.getElementById('selinstallationname').options[document.getElementById('selinstallationname').selectedIndex].text;
		var atcssubnode = document.getElementById('selatcsconfig').options[document.getElementById('selatcsconfig').selectedIndex].text;
		var devicename = document.getElementById('seldevicename').options[document.getElementById('seldevicename').selectedIndex].text
		if ((installation != "Installation") && (atcssubnode != "ATCS") && (devicename != "Device")) {
			if (confirm("Do you want to delete '" + devicename + "' device?")) {
				var getdevicedetails = $("#seldevicename").val();
				$("#contentcontents").mask("Processing request, please wait...");
				$.post("/deviceeditor/removedevice", {
					selecteddeviceid: getdevicedetails
				}, function(data){
					get_installation_atcs();
					$("#outerdevicedetails").hide();
					$("#message_deviceeditor").html("");
					$("#message_deviceeditor").html(data);
					$("#contentcontents").unmask("Processing request, please wait...");
				});
			}
		}
		else {
			alert("Select device and try again.");
		}
	}
}

function add_new_device()
{
	var approvedcrc = document.getElementById("approvedinstallationcrcvalue").value;
	if (approvedcrc != "") {
		alert("Sorry , you need to unapprove selected installation and try again.")
	}
	else {
		$("#message_deviceeditor").html("");
		var installation = document.getElementById('selinstallationname').options[document.getElementById('selinstallationname').selectedIndex].text;
		var atcssubnode = document.getElementById('selatcsconfig').options[document.getElementById('selatcsconfig').selectedIndex].text;
		$("#outerdevicedetails").hide();
		$("#savemode").val("new");
		if ((installation != "Installation") && (atcssubnode != "ATCS")) {
			$("#outerdevicedetails").show();
			$("#devicetypeforexisting").hide();
			$("#devicetypefornew").show();
			$("#deviceinfo").show();
			$("#deviceeditor_logicstates").hide();
			$("#seldevicetype >option").remove();
			$('#seldevicetype').append($('<option></option>').val(0).html('Signal'));
			$('#seldevicetype').append($('<option></option>').val(1).html('Switch'));
			$('#seldevicetype').append($('<option></option>').val(2).html('Hazard Detector'));
			document.getElementById('seldevicename').options[0].selected = true;
			cleardevicedetails();
			change_device_type();
			document.getElementById("txtnooflogicstatetotal_new").value = 0;
			document.getElementById("span_approvedinstallationcrc").innerHTML = "";
			$("#span_approvedinstallationcrc").hide();
			enable_disable_all_elements(true);
			disable_signal_fields();
		}
		else {
			$("#outerdevicedetails").hide();
			alert("Please select Installation and ATCS Subnode for add new device.")
		}
	}
}

function change_device_type(){
	var device_type = document.getElementById('seldevicetype').options[document.getElementById('seldevicetype').selectedIndex].text;
	cleardevicedetails();
	$("#deviceeditor_logicstates").hide();
	document.getElementById("txtnooflogicstatetotal_new").value = 0;
	if (device_type =="Signal"){
		$("#deviceeditor_switch").hide();
		$("#deviceeditor_hd").hide();
		$("#deviceeditor_signal").show();
		disable_signal_fields();
	}else if(device_type == "Switch"){
		$("#deviceeditor_signal").hide();
		$("#deviceeditor_hd").hide();
		$("#deviceeditor_switch").show();
	}else if(device_type == "Hazard Detector"){
		$("#deviceeditor_signal").hide();
		$("#deviceeditor_switch").hide();
		$("#deviceeditor_hd").show();
	}
}

function aspectid_validate(checkvalue){
	var str = trim(checkvalue.value);
	if (str != "" && (str >=1 && str <=50 )){
		return true;
	}else{
		if (str == ""){
			return true;
		}else{
			alert('Aspect Id Range should be 1 to 50');
			document.getElementById(checkvalue.id).value ="";	
			var x = "document.getElementById('"+checkvalue.id+"').focus();"
			setTimeout(x,0);
			return false;
		} 
	}
}

function validate(){
	$("#message_deviceeditor").html("");
	var approvedcrc = document.getElementById("approvedinstallationcrcvalue").value;
	if (approvedcrc != "") {
		alert("Sorry , you need to unapprove selected installation and try again.")
	}else {
		var installation = document.getElementById('selinstallationname').options[document.getElementById('selinstallationname').selectedIndex].text;
		var atcssubnode = document.getElementById('selatcsconfig').options[document.getElementById('selatcsconfig').selectedIndex].text;
		var devicename = document.getElementById('seldevicename').options[document.getElementById('seldevicename').selectedIndex].text
		var savemode = document.getElementById("savemode").value;
		if (installation != "Installation") {
			if (atcssubnode != "ATCS") {
				if (devicename_validate('validate')) {
				  if (tracknumber_validate('validate')){
						if (add_logicstate_button_status()) {
							if (logicstatevalue_nooflogicstate_matched()) {
								var nooflogicstatesig = parseInt(document.getElementById("txtnooflogicstatessignal").value);
								var nooflogicstateswi = parseInt(document.getElementById("txtnooflogicstatesswitch").value);
								var nooflogicstatehd = parseInt(document.getElementById("txtnooflogicstateshd").value);
								if (isNaN(nooflogicstatesig)) {
									nooflogicstatesig = 0;
								}
								if (isNaN(nooflogicstateswi)) {
									nooflogicstateswi = 0;
								}
								if (isNaN(nooflogicstatehd)) {
									nooflogicstatehd = 0;
								}
								var validnoflogicstatesig;
								var validnoflogicstateswi;
								var validnoflogicstatehd;
								if (savemode == "new") {
									var existing_total_nooflogic_new = parseInt(document.getElementById("txtnooflogicstatetotal_new").value);
									if (isNaN(existing_total_nooflogic_new)) {
										existing_total_nooflogic_new = 0;
									}
									validnoflogicstatesig = existing_total_nooflogic_new + nooflogicstatesig;
									validnoflogicstateswi = existing_total_nooflogic_new + nooflogicstateswi;
									validnoflogicstatehd = existing_total_nooflogic_new + nooflogicstatehd;
								}else if (savemode == "edit") {
									var existing_total_nooflogic = parseInt(document.getElementById("txtnooflogicstatetotal").value);
									if (isNaN(existing_total_nooflogic)) {
										existing_total_nooflogic = 0;
									}
									validnoflogicstatesig = existing_total_nooflogic + nooflogicstatesig;
									validnoflogicstateswi = existing_total_nooflogic + nooflogicstateswi;
									validnoflogicstatehd = existing_total_nooflogic + nooflogicstatehd;
								}
								if ((devicename == "Device") && (savemode == "new")) {
									if (((validnoflogicstatesig > 0) && (validnoflogicstatesig < 7)) || ((validnoflogicstateswi > 0) && (validnoflogicstateswi < 4)) || ((validnoflogicstatehd > 0) && (validnoflogicstatehd < 2))) {
										if (validatelogicstatenumber() && validatebitposition()) {
											var devicetype = document.getElementById('seldevicetype').options[document.getElementById('seldevicetype').selectedIndex].text;
											if (devicetype == "Signal") {
												if (altaspect_validate('1')) {
													if (altaspect_validate('2')) {
														if (altaspect_validate('3')) {
															return true;
														}else {
															alert('Aspect id & Alt aspect both should have a value or both are empty');
															var aspid3 = "document.getElementById('txtaspectid3').focus();"
															setTimeout(aspid3, 0);
															return false;
														}
													}else {
														alert('Aspect id & Alt aspect both should have a value or both are empty');
														var aspid2 = "document.getElementById('txtaspectid2').focus();"
														setTimeout(aspid2, 0);
														return false;
													}
												}else {
													alert('Aspect id & Alt aspect both should have a value or both are empty');
													var aspid1 = "document.getElementById('txtaspectid1').focus();"
													setTimeout(aspid1, 0);
													return false;
												}
											}else {
												return true;
											}
										}else {
											return false;
										}
									}else {
										alert("Please enter No.logic states within the limits and try again.");
										return false;
									}
								}else if ((devicename != "Device") && (savemode == "edit")) {
										if (((validnoflogicstatesig > 0) && (validnoflogicstatesig < 7)) || ((validnoflogicstateswi > 0) && (validnoflogicstateswi < 4)) || ((validnoflogicstatehd > 0) && (validnoflogicstatehd < 2))) {
											if (validatelogicstatenumber() && validatebitposition()) {
												var devicetype = trim(document.getElementById('txtdevicetype').value);
												if (devicetype == "Signal") {
													if (altaspect_validate('1')) {
														if (altaspect_validate('2')) {
															if (altaspect_validate('3')) {
																return true;
															}else {
																alert('Aspect id & Alt aspect both should have a value or both are empty');
																var aspid3 = "document.getElementById('txtaspectid3').focus();"
																setTimeout(aspid3, 0);
																return false;
															}
														}else {
															alert('Aspect id & Alt aspect both should have a value or both are empty');
															var aspid2 = "document.getElementById('txtaspectid2').focus();"
															setTimeout(aspid2, 0);
															return false;
														}
													}else {
														alert('Aspect id & Alt aspect both should have a value or both are empty');
														var aspid1 = "document.getElementById('txtaspectid1').focus();"
														setTimeout(aspid1, 0);
														return false;
													}
												}else {
													return true;
												}
											}else {
												return false;
											}
										}else {
											alert("Please enter No.logic states within the limits and try again.");
											return false;
										}
									}else {
										alert("Please select the Device name");
										return false;
									}
							}else {
								alert("Please enter all logic state values and try again");
								return false;
							}
						}else { //add button status
							alert("Please add logic state and try again");
							var devicetype;
							if (savemode == "new") {
								devicetype = document.getElementById('seldevicetype').options[document.getElementById('seldevicetype').selectedIndex].text;
							}else 
							if (savemode == "edit") {
								devicetype = trim(document.getElementById('txtdevicetype').value);
							}
							if (devicetype == "Signal") {
								document.getElementById('txtnooflogicstatessignal').focus();
							}else if (devicetype == "Switch") {
								document.getElementById('txtnooflogicstatesswitch').focus();
							}else if (devicetype == "Hazard Detector") {
								document.getElementById('txtnooflogicstateshd').focus();
							}
							return false;
						}
					}
				  }
				}else {
					alert("Please select the ATCS Subnode");
					return false;
				}
			}else {
				alert("Please select the Installation Name");
				return false;
			}
		}
	}



function logicstatevalue_nooflogicstate_matched(){
	var savemode = document.getElementById("savemode").value;
	var existing_noof_state;
	var devicetype;
	if (savemode =="edit"){
		existing_noof_state = parseInt(document.getElementById("txtnooflogicstatetotal").value);
		devicetype = document.getElementById('txtdevicetype').value;
	}else if (savemode =="new"){
		existing_noof_state = parseInt(document.getElementById("txtnooflogicstatetotal_new").value);
		devicetype = document.getElementById('seldevicetype').options[document.getElementById('seldevicetype').selectedIndex].text;
	}
	if (isNaN(existing_noof_state)){
		existing_noof_state = 0;
	}
	var noofstate;
	if (devicetype == "Signal"){
			noofstate = parseInt(document.getElementById('txtnooflogicstatessignal').value);	
	}else if (devicetype == "Switch"){
			noofstate = parseInt(document.getElementById('txtnooflogicstatesswitch').value);
	}else if (devicetype == "Hazard Detector"){
			noofstate = parseInt(document.getElementById('txtnooflogicstateshd').value);
	}
	if(isNaN(noofstate)){
		noofstate = 0;
	}
	var total_logic_state ;
	total_logic_state = existing_noof_state + noofstate;
	var arr1 = [];
	var arr2 = [];
	var arr3 = [];
	var a1 = 0;
	for (var i = 1; i <= total_logic_state; i++) {
		var logicstate = parseInt(document.getElementById('txtlogicstate'+i).value);
		if (!isNaN(logicstate)){
			arr1[a1] = logicstate;
			a1 = a1+1; 
		}
	}
	var a2 = 0 ;
	for (var j = 1; j <= total_logic_state; j++) {
		var bitpos = parseInt(document.getElementById('txtlogicstate'+j+'bitpos').value);
		if (!isNaN(bitpos)){
			arr2[a2] = bitpos;	
			a2 = a2+1; 
		}
	}
	var a3 = 0;
	for (var k = 1; k <= total_logic_state; k++) {
		var contcount = parseInt(document.getElementById('txtlogicstate'+k+'contcount').value);
		if (!isNaN(contcount)){
			arr3[a3] = contcount;
			a3 = a3+1; 
		}
	}
	if ((arr1.length == total_logic_state) && (arr2.length == total_logic_state) && (arr3.length == total_logic_state)){
		return true;
	}else{
		return false;
	}
}

function add_logicstate_button_status(){
	var addbuttonstatus = document.getElementById('addlogicstatebuttonstatus').value ;
	if (addbuttonstatus == ""){
		return false;
	}else if (addbuttonstatus == "added") {
		return true;
	}
}

function delete_logicstate(logicstate){
	var approvedcrc = document.getElementById("approvedinstallationcrcvalue").value;
	if (approvedcrc != "") {
		alert("Sorry , you need to unapprove selected installation and try again.")
	} else {
		if (confirm("Do you want to delete '" + logicstate + "' logic state?")) {
			$("#contentcontents").mask("Processing request, please wait...");
			var selected_deviceid = document.getElementById('seldevicename').options[document.getElementById('seldevicename').selectedIndex].value;
			var savemode = document.getElementById("savemode").value;
			var selected_devicetype;
			if (savemode == "edit") {
				selected_devicetype = document.getElementById('txtdevicetype').value;
			}
			else {
				selected_devicetype = document.getElementById('seldevicetype').options[document.getElementById('seldevicetype').selectedIndex].text;
			}
			if (selected_deviceid != 0 && logicstate != "") {
				$.post("/deviceeditor/deletelogicstate", {
					logicstatenumber: logicstate,
					deviceid: selected_deviceid,
					devicetype: selected_devicetype
				}, function(data){
					$("#contentcontents").unmask("Processing request, please wait...");
					if (data == "Success") {
						get_installation_atcs_device();
						$("#message_deviceeditor").html("Successfully removed logic state.");
					}
				});
			}
		}
	}
}

function altaspect_validate(val){
	var aspectidname = "txtaspectid"+val;
	var altaspectname = "txtaltaspect"+val;
	var aspectid = trim(document.getElementById(aspectidname).value);
	var altaspect = trim(document.getElementById(altaspectname).value);
	if ((aspectid != "") && (altaspect != "" )){
			return true;
	}else{
		if ((aspectid == "") && (altaspect == "" )){
			return true;
		}else{
			return false;	
		}
	}
}

function devicename_validate(change_flag){
	var stringObjPattern = /^[0-9A-Za-z_-]+$/i;
	var valdevicename = trim(document.getElementById("txtdevicename").value);
	if (stringObjPattern.test(valdevicename)) {
		$("#txtdevicename").css("border", "1px solid #888");
		return true;
	}else {
		$("#txtdevicename").css("border", "1px solid red");
		if (change_flag == 'validate') {
				alert("Please enter valid device name"+ "[only alpha numeric,_,-]");	
		}	
		return false;
	}
 }
 
 function tracknumber_validate(change_flag){
	var numberObjPattern = /^[0-9]+$/i;
	var valtracknumber = trim(document.getElementById("txttracknumber").value);
	if (numberObjPattern.test(valtracknumber)) {
		$("#txttracknumber").css("border", "1px solid #888");
		return true;
	}else {
		$("#txttracknumber").css("border", "1px solid red");
		if(change_flag == 'validate'){
			alert(" Please enter valid track number"+"[only numeric values 0-9 ]");	
		}
		return false;
	}
 }
 
function validate_tootal_nooflogicstate(type , value){
	var exist_total_logicstate ;
	exist_total_logicstate = parseInt(trim(document.getElementById('txtnooflogicstatetotal').value));
	document.getElementById('addlogicstatebuttonstatus').value = "";
	if(isNaN(exist_total_logicstate)){
			exist_total_logicstate = 0;
	}
	var add_logicstate = 0;
	add_logicstate = parseInt(trim(value));
	if(isNaN(add_logicstate)){
			add_logicstate = 0;
	}
	var validate_noof_lstate = exist_total_logicstate + add_logicstate ;
	if (type == "Signal"){
		if (validate_noof_lstate >= 7){
			alert("Please enter No.logic states within the limits");
			document.getElementById('txtnooflogicstatessignal').value = "";
			document.getElementById('txtnooflogicstatessignal').focus();
			return false;
		} else{
			return true;
		}
	}else if (type == "Switch"){
		if (validate_noof_lstate >= 3){
			alert("Please enter No.logic states within the limits");
			document.getElementById('txtnooflogicstatesswitch').value = "";
			document.getElementById('txtnooflogicstatesswitch').focus();
			return false;
		} else{
			return true;
		}
	}else if(type == "Hazard Detector"){
		if (validate_noof_lstate >= 2){
			alert("Please enter No.logic states within the limits");
			document.getElementById('txtnooflogicstateshd').value = "";
			document.getElementById('txtnooflogicstateshd').focus();
			return false;
		} else{
			return true;
		}
	}
}

function setTitleToSelectedText(select){
	if (select.selectedIndex > -1) {
		select.title = select.options[select.selectedIndex].text;
	}
}
setTitleToSelectedText('document.forms.formName.elements.selinstallationname');
