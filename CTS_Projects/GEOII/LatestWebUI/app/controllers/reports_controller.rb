####################################################################
# Company: Siemens 
# Author: Jeyavel Natesan
# File: reports_controller.rb
# Description: This module will generate MCF installation configuration reports. 
####################################################################
class ReportsController < ApplicationController
  layout 'general'
  include ReportsHelper
  if OCE_MODE ==1
    require 'markaby'
  end
  
  ####################################################################
  # Function:      generate_csv
  # Parameters:    session[:mantmasterdblocation]
  # Retrun:        HTML string
  # Renders:       send_data
  # Description:   This action will generate MCF configuration report in .html format.
  ####################################################################
  def generate_csv
    $mantmasterdblocation = session[:mantmasterdblocation]
    $oceversionreport = session[:webui_version]
    $aspectlookupfile = nil
    $aspectlookupfile = session[:aspectfilepath]
    begin
      filename = nil
      paramvalue = params[:id]
      if (paramvalue[0,3] == "db|")
        databaseid = paramvalue[3..-1]  
      else
        instname = paramvalue
      end
      mab = Markaby::Builder.new
      mab.html do
        head do 
          unless instname.blank?
            title instname
            filename = instname
          else
            title databaseid
            filename = databaseid
          end
          style :type => "text/css" do
            %[body { font: 11px/120% Arial; background-color:black;color:#F2F2F2; }
              div {font: 12px Arial;color:#F2F2F2; }
              th{background-color:#98bf21;color:black;}
              table{font-family: Arial; border-collapse:collapse; }
              table td, table th {font-size:12px; border:1px solid #98bf21; padding:3px 7px 2px 7px; }
              table th { font-size:11px; text-align:left; padding-top:5px; padding-bottom:4px; background-color:#A7C942; color:#000; }
              table tr.alt td {color:#000000; background-color:#EAF2D3; }]
          end
        end
        body do 
          database = $mantmasterdblocation
          dbvalue =database.split('/')
          div "", :style => "clear:both; padding-top:20px;width:auto;"
          div "PTC GEO Database  : "+dbvalue[dbvalue.length-1]
          div "", :style => "clear:both; padding-top:20px;width:auto;"
          x = DateTime.now
          div "Date/Time         : "+x.to_s
          div "", :style => "clear:both; padding-top:20px;width:auto;"
          div "OCE Version : "+ $oceversionreport
          div "", :style => "clear:both; padding-top:20px;width:auto;"
          installation = nil
          unless instname.blank?
            installation = Installationtemplate.find(:all, :conditions => ["InstallationName = ?",instname] ,:order => 'InstallationName COLLATE NOCASE', :include => [:ptcdevices])
          end
          unless databaseid.blank?
            installation = Installationtemplate.find(:all, :order => 'InstallationName COLLATE NOCASE' ,:include => [:ptcdevices])
          end
          installation.each do |installationnameid|
            ptcdevices = installationnameid.ptcdevices
            mcf_names = Mcfphysicallayout.find(:all, :select =>"MCFName", :conditions => {:InstallationName => installationnameid.InstallationName}).map(&:MCFName).uniq #ptcdevices.map(&:mcfname).uniq
            signals = []
            switches = []
            hazarddetectors = []
            goltypevalue = Mcfptc.find_by_MCFName(mcf_names[0].to_s, :select => "GOLType").try(:GOLType)
            unless goltypevalue.blank?
              goltype = goltypevalue.to_s == "1" ? "Non Appliance Model" : "Appliance Model"
              div "GOLType           : "+goltype
              div "", :style => "clear:both; padding-top:20px;width:auto;"
              installationexist = Approval.find(:last,:conditions=>{:InstallationName=>installationnameid.InstallationName},:order=>'ApprovalDate, ApprovalTime ASC')
              appCRC = nil
              unless installationexist.blank?
                if installationexist.ApprovalCRC == "" || installationexist.ApprovalCRC == 0
                  appCRC = '0x0'
                else
                  approvalcrcintvalue = installationexist.ApprovalCRC.to_i
                  appCRC = '0x'+approvalcrcintvalue.to_s(16).upcase
                end
              else
                appCRC = '0x0'
              end
              div "Installation Name/Approval CRC : " + installationnameid.InstallationName + ' / ' + appCRC.to_s
              mcf_names.each do |mcf|
                div "", :style => "clear:both; padding-top:20px;width:auto;"
                mcfcrc = Mcfptc.find_by_MCFName(mcf, :select => "CRC").try(:CRC)
                if mcfcrc
                  intvalue = mcfcrc.to_i
                  mcfhexaCRCvale= '0x'+intvalue.to_s(16).upcase
                  div "MCF Name/CRC      : "+mcf.to_s+' / '+mcfhexaCRCvale.to_s
                else
                  div "MCF Name/CRC       : "+mcf.to_s+' / 0x0'
                end
              end
              ptc_devices = ptcdevices.select{|device| device.InstallationName == installationnameid.InstallationName}
              unless ptc_devices.blank?
                ptc_devices.each do |ptc_device|
                  signals << ptc_device.signal unless ptc_device.signal.blank?
                  switches << ptc_device.switch unless ptc_device.switch.blank?
                  hazarddetectors << ptc_device.hazarddetector unless ptc_device.hazarddetector.blank?
                end         
                unless signals.blank?
                  div "", :style => "clear:both; padding-top:20px;width:auto;"
                  div "SIGNALS" , :style => "font-weight: bold;"
                  div "", :style => "clear:both; padding-top:10px;width:auto;"
                  table do
                    th do "Object Name" end
                    if goltype =="Appliance Model"
                      th do "Conditions" end
                      th do "Stop Aspect" end
                      th do "GEO Subnode" end
                      th do "Aspect LS" end
                      th do "Bit Position" end
                      th do "Contiguous Count" end
                      th do "IsDark LS" end
                      th do "Bit Position" end
                      th do "Contiguous Count" end
                      th do "T1L" end
                      th do "Bit Position" end
                      th do "Contiguous Count" end
                      th do "STASP" end
                      th do "Bit Position" end
                      th do "Contiguous Count" end
                      th do "Aspect Id1" end
                      th do "Alt Aspect1" end
                      th do "Aspect Id2" end
                      th do "Alt Aspect2" end
                      th do "Aspect Id3" end
                      th do "Alt Aspect3" end
                    elsif goltype =="Non Appliance Model"
                      th do "HeadA" end
                      th do "HeadB" end
                      th do "HeadC" end
                      th do "GEO Subnode" end
                      th do "CirOut.Aspect Steady" end
                      th do "Bit Position" end
                      th do "Contiguous Count" end
                      th do "CirOut.Aspect Flashing" end
                      th do "Bit Position" end
                      th do "Contiguous Count" end
                      th do "CirIn.Aspect" end
                      th do "Bit Position" end
                      th do "Contiguous Count" end
                      th do "Aspect Id1" end
                      th do "Alt Aspect1" end
                      th do "Aspect Id2" end
                      th do "Alt Aspect2" end
                      th do "Aspect Id3" end
                      th do "Alt Aspect3" end
                    end
                    signals.each do |signal|
                      logic_states = Logicstate.find(:all, :conditions =>['Id=?',signal.Id], :order => "BitPosn asc") 
                      case goltype
                        when "Appliance Model"
                        tr do 
                          td signal.ptcdevice.PTCDeviceName
                          td signal.Conditions
                          td signal.StopAspect
                          td signal.ptcdevice.Subnode
                          td logic_states[0].try(:LogicStateNumber)
                          td logic_states[0].try(:BitPosn)
                          td logic_states[0].try(:ContiguousCount)
                          td logic_states[1].try(:LogicStateNumber)
                          td logic_states[1].try(:BitPosn)
                          td logic_states[1].try(:ContiguousCount)
                          td logic_states[2].try(:LogicStateNumber)
                          td logic_states[2].try(:BitPosn)
                          td logic_states[2].try(:ContiguousCount)
                          td logic_states[3].try(:LogicStateNumber)
                          td logic_states[3].try(:BitPosn)
                          td logic_states[3].try(:ContiguousCount)
                          td signal.AspectId1
                          td signal.AltAspect1
                          td signal.AspectId2
                          td signal.AltAspect2
                          td signal.AspectId3
                          td signal.AltAspect3
                        end
                        when "Non Appliance Model"
                        cirout = []
                        ciroutflash = []
                        cirin = []
                        logic_states.each do |bitposition|
                          bitpos = bitposition.try(:BitPosn)
                          if bitpos >=0 && bitpos <=9
                            cirout << bitposition
                          elsif bitpos >=10 && bitpos <=19
                            ciroutflash << bitposition
                          elsif bitpos >=20 
                            cirin << bitposition
                          end
                        end
                        maxcount = []
                        maxcount << cirout.length << ciroutflash.length << cirin.length
                        for lop in 0...(maxcount.max.to_i)
                          tr do 
                            td signal.ptcdevice.PTCDeviceName
                            if lop == 0
                              td signal.HeadA
                              td signal.HeadB
                              td signal.HeadC
                              td signal.ptcdevice.Subnode
                            else
                              td ""
                              td ""
                              td ""
                              td ""
                            end
                            td cirout[lop].try(:LogicStateNumber)
                            td cirout[lop].try(:BitPosn)
                            td cirout[lop].try(:ContiguousCount)
                            td ciroutflash[lop].try(:LogicStateNumber)
                            td ciroutflash[lop].try(:BitPosn)
                            td ciroutflash[lop].try(:ContiguousCount)
                            td cirin[lop].try(:LogicStateNumber)
                            td cirin[lop].try(:BitPosn)
                            td cirin[lop].try(:ContiguousCount)
                            if lop == 0
                              td signal.AspectId1
                              td signal.AltAspect1
                              td signal.AspectId2
                              td signal.AltAspect2
                              td signal.AspectId3
                              td signal.AltAspect3
                            else
                              td ""
                              td ""
                              td ""
                              td ""
                              td ""
                              td ""
                            end
                          end
                        end # for loop
                      end #Case END
                    end
                  end
                end
                unless switches.blank?
                  div "", :style => "clear:both; padding-top:20px;width:auto;"
                  div "SWITCHES" , :style => "font-weight: bold;"
                  div "", :style => "clear:both; padding-top:10px;width:auto;"
                  table do 
                    if goltype == "Appliance Model"
                      th do "Object Name" end
                      th do "GEO Subnode" end
                      th do "Switch Type" end
                      th do "Number of LS" end
                      th do "NWP" end
                      th do "Bit Position" end
                      th do "Contiguous Count" end
                      th do "RWP" end
                      th do "Bit Position" end
                      th do "Contiguous Count" end
                    elsif goltype == "Non Appliance Model"
                      th do "Object Name" end
                      th do "GEO Subnode" end
                      th do "Switch Type" end
                      th do "Number of LS" end
                      th do "NWP" end
                      th do "Bit Position" end
                      th do "Contiguous Count" end
                      th do "RWP" end
                      th do "Bit Position" end
                      th do "Contiguous Count" end
                    end
                    switches.each do |switch|
                      logic_states = Logicstate.find(:all, :conditions =>['Id=?',switch.Id], :order => "BitPosn asc")  #switch.logicstates.all(:order => "Id asc")
                      case goltype
                        when "Appliance Model"
                        switch_type = switch.SwitchType.to_i
                        switchtype = case switch_type
                          when 0 then "Switch"
                          when 1 then "Switch with No NK2"
                          when 2 then "DT switch/Electric lock"      
                        end   
                        tr do            
                          td switch.ptcdevice.PTCDeviceName
                          td switch.ptcdevice.Subnode
                          td switchtype
                          td switch.NumberOfLogicStates
                          td logic_states[0].try(:LogicStateNumber)
                          td logic_states[0].try(:BitPosn)
                          td logic_states[0].try(:ContiguousCount)
                          td logic_states[1].try(:LogicStateNumber)
                          td logic_states[1].try(:BitPosn)
                          td logic_states[1].try(:ContiguousCount)
                        end
                        when "Non Appliance Model"
                        logic_states = Logicstate.find(:all, :conditions =>['Id=?',switch.Id], :order => "BitPosn asc")  #switch.logicstates.all(:order => "Id asc")
                        switch_type = switch.SwitchType.to_i
                        switchtype = case switch_type
                          when 0 then "Switch"
                          when 1 then "Switch with No NK2"
                          when 2 then "Electric lock"      
                        end
                        tr do    
                          if (switch.NumberOfLogicStates.to_i == 1)
                            td switch.ptcdevice.PTCDeviceName
                            td switch.ptcdevice.Subnode
                            td switchtype
                            td switch.NumberOfLogicStates
                            td logic_states[0].try(:LogicStateNumber)
                            td logic_states[0].try(:BitPosn)
                            td logic_states[0].try(:ContiguousCount)
                            td ""
                            td ""
                            td ""
                          elsif (switch.NumberOfLogicStates.to_i == 2)
                            td switch.ptcdevice.PTCDeviceName
                            td switch.ptcdevice.Subnode
                            td switchtype
                            td switch.NumberOfLogicStates
                            td logic_states[0].try(:LogicStateNumber)
                            td logic_states[0].try(:BitPosn)
                            td logic_states[0].try(:ContiguousCount)
                            td logic_states[1].try(:LogicStateNumber)
                            td logic_states[1].try(:BitPosn)
                            td logic_states[1].try(:ContiguousCount)
                          else
                            td switch.ptcdevice.PTCDeviceName
                            td switch.ptcdevice.Subnode
                            td switchtype
                            td switch.NumberOfLogicStates
                            td ""
                            td ""
                            td ""
                            td ""
                            td ""
                            td ""
                          end
                        end
                      end
                    end
                  end
                end
                unless hazarddetectors.blank?
                  div "", :style => "clear:both; padding-top:20px;width:auto;"
                  div "HAZARD DETECTORS" , :style => "font-weight: bold;"
                  div "", :style => "clear:both; padding-top:10px;width:auto;"
                  table do
                    th do "ObjectName" end
                    th do "GEO Subnode" end
                    th do "AUX" end
                    th do "Bit Position" end
                    th do "Contiguous Count" end
                    hazarddetectors.each do |hazard|
                      logic_states = Logicstate.find(:all, :conditions =>['Id=?',hazard.Id], :order => "BitPosn asc") 
                      tr do
                        td hazard.ptcdevice.PTCDeviceName
                        td hazard.ptcdevice.Subnode
                        td logic_states[0].try(:LogicStateNumber)
                        td logic_states[0].try(:BitPosn)
                        td logic_states[0].try(:ContiguousCount)
                      end
                    end
                  end
                end
              else
                div "", :style => "clear:both; padding-top:20px;width:auto;"
                div "Note :- No Devices present for this installation." , :style =>"color:#C3CF21;size:12;font-weight: bold;"
                div "", :style => "clear:both; padding-top:10px;width:auto;"
              end
              if goltype == "Appliance Model"
                aspects = Aspect.find(:all, :select=>"[Index],AspectName", :conditions=>['InstallationName=?',installationnameid.InstallationName])
                unless aspects.blank?
                  div "", :style => "clear:both; padding-top:20px;width:auto;"
                  div "Aspect Table" , :style => "font-weight: bold;"
                  div "", :style => "clear:both; padding-top:10px;width:auto;"
                  @txtfilepath = $aspectlookupfile 
                  table do
                    th do "Aspect ID" end
                    th do "GEO Aspect" end
                    th do "PTC Aspect" end
                    th do "PTC Code" end
                    aspects.each do |aspect|
                      tr do
                        td aspect.Index
                        td aspect.AspectName
                        returnvalue = nil
                        begin
                          file = File.new(@txtfilepath, "r")
                          while (line = file.gets)
                            result=[]
                            @data = "#{line}"
                            result = @data.split(", \"")
                            if (result.length == 1)
                              result = @data.split(",\"")
                            end
                            restrim = []
                            restrim1 = result[0].split("\"")
                            restrim = result[1].split("\"")
                            restrimf= restrim[0].split(", \"")
                            if(restrim1[0].rstrip.upcase == aspect.AspectName.upcase)
                              returnvalue = restrimf[0].rstrip
                              break
                            end
                          end
                          file.close
                        end  
                        unless returnvalue.blank?
                          ptcaspects = Ptcaspect.all(:conditions => {:InstallationName => installationnameid.InstallationName },:order => "PTCCode asc")
                          for i in 0...(ptcaspects.length)
                            if (ptcaspects[i].AspectName.upcase == returnvalue.upcase)
                              td  ptcaspects[i].AspectName
                              td  ptcaspects[i].PTCCode
                              break
                            end
                          end
                        else
                          td ""
                          td ""
                        end
                      end
                    end
                  end
                end # end aspects
              end
            else
              div "Installation Name : #{installationnameid.InstallationName}"
              div "", :style => "clear:both; padding-top:20px;width:auto;"
              div "Note :- Incomplete installation." , :style =>"color:#C3CF21;size:12;font-weight: bold;"
            end # goltype loop
            unless databaseid.blank?
              #loop line
              div "", :style => "clear:both; padding-top:10px;width:auto;"
              hr :style =>"width:1400px;color:#C3CF21;size:8;align:center"
              div "", :style => "clear:both; padding-top:10px;width:auto;"
            end
          end
        end # end Body tag
      end # end HTML tag
      send_data(mab.to_s, :type => "text/html", :filename => "#{filename}-report.html")      
    rescue Exception => e         
      puts e
    end  
  end
end
