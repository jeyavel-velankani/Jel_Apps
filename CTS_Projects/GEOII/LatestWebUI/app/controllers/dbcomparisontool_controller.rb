####################################################################
# Company: Siemens 
# Author: Jeyavel Natesan
# File: dbcomparisontool_controller.rb
# Description: This module will compare the two PTC GEO Database's and display/download comparison log  
####################################################################
#History:
# Log: /wayside/GEOII/Trunk/Software/WebUI/app/controllers/dbcomparisontool_controller.rb
#
# Rev 4769   July 17 2013 17:00:00   Jeyavel Natesan
# Initial version
class DbcomparisontoolController < ApplicationController
  layout "general"
  include DbcomparisontoolHelper
  if OCE_MODE == 1
    require 'markaby'
  end

  ####################################################################
  # Function:      database_comparison_tool
  # Parameters:    None
  # Retrun:        @selected_database1path , @selected_database2path , @database1path , @database2path 
  # Renders:       None
  # Description:   Get the all PTC GEO Databases and display in the page
  ####################################################################
  def database_comparison_tool
    root_directory = File.join(RAILS_ROOT, "/Masterdb")
    @database1path = Dir[root_directory + "/*"].reject{|f| [".", ".."].include? f}
    @database2path = Dir[root_directory + "/*"].reject{|f| [".", ".."].include? f}
    @selected_database1path = nil
    @selected_database2path = nil
    unless session[:selecteddatabase1].blank?
      @selected_database1path = session[:selecteddatabase1]
    else  
      @selected_database1path = @database1path[0]
    end
    unless session[:selecteddatabase2].blank?
      @selected_database2path = session[:selecteddatabase2]
    else  
      @selected_database2path = @database2path[0]
    end
    session[:comp_rep_path] = nil
    path = session[:OCE_ConfigPath] + 'tmp' 
    htmllists = Dir[path+"/*.html"]
    htmllists.each do |htmllist|
      File.delete htmllist
    end
    dbfiles = Dir[path+"/*.db"]
    dbfiles.each do |db_file|
       FileUtils.rm_rf(db_file)
    end
  end

  ####################################################################
  # Function:      selected_database1
  # Parameters:    params[:selecteddatabase1]
  # Retrun:        None
  # Renders:       render :text =>""
  # Description:   Update the selected database 1 path
  ####################################################################
  def selected_database1
    root_directory = File.join(RAILS_ROOT , "/Masterdb")
    session[:selecteddatabase1] = root_directory+'/'+params[:selecteddatabase1]
    render :text =>""
  end
  
  ####################################################################
  # Function:      selected_database2
  # Parameters:    params[:selecteddatabase2]
  # Retrun:        None
  # Renders:       render :text =>""
  # Description:   Update the selected database 2 path
  ####################################################################
  def selected_database2
    root_directory = File.join(RAILS_ROOT , "/Masterdb")
    session[:selecteddatabase2] = root_directory+'/'+params[:selecteddatabase2]
    render :text =>""
  end

  ####################################################################
  # Function:      database_comparison_tool_1
  # Parameters:    session[:comparedatabasepath]
  # Retrun:        None
  # Renders:       None
  # Description:   Create the report from the compared file
  ####################################################################
  def database_comparison_tool_1
    error_flag = false
    begin
     (ActiveRecord::Base.configurations["site_ptc_db"])["database"] = session[:comparedatabasepath]
      database1 = params[:db1]
      database2 = params[:db2]
      mab = Markaby::Builder.new
      mab.html do
        head do 
          title "Database Comparison Tool"
          style :type => "text/css" do
            %[body { font-family: Arial;font-size: 13px; background-color:#000;color:#F2F2F2; }              
              th{background-color:#A7C942;color:#000;}
              table{font-family: Arial;font-size: 13px;border-collapse:collapse; }
              .comparisoncontent table td, table th {font-family: Arial;font-size:13px; border:1px solid #98bf21; padding:3px 7px 2px 7px; }
              table th {font-family: Arial; font-size:13px; text-align:left; padding-top:5px; padding-bottom:4px; background-color:#A7C942; color:#000; }
              table tr.alt td {font-family: Arial; font-size:13px;color:#000; background-color:#A7C942; }]
          end
        end
        body do 
          div.comparisoncontent do
            installation_matched =  Installationtemplate.find_by_sql("Select A.* from Installationtemplate A Join Installationtemplate1 B On A.InstallationName = B.InstallationName")
            div "", :style => "clear:both; padding-top:10px;width:auto;"
            comparisonflag = false
            #       VERSIONS -START 
            if Versions.table_exists?
              left_version  = Versions.find_by_sql(" Select A.* from Versions A Left Outer Join Versions1 B On A.SchemaVersion = B.SchemaVersion And A.ApprovalCRCVersion = B.ApprovalCRCVersion where B.SchemaVersion is null ")
              right_version = Versions.find_by_sql(" Select A.* from Versions1 A Left Outer Join Versions B On A.SchemaVersion = B.SchemaVersion And A.ApprovalCRCVersion = B.ApprovalCRCVersion where B.SchemaVersion is null")
              unless left_version.blank? && right_version.blank?
                comparisonflag = true
                div "", :style => "clear:both; padding-top:20px;width:auto;"
                div "Versions" , :style => "color:#F2F2F2;font-family: Arial; font-size:13px;font-weight:bold;"
                div "", :style => "clear:both; padding-top:10px;width:auto;"
                table do
                  td do 
                    table do
                      th do "SchemaVersion" end
                      th do "ApprovalCRCVersion" end
                      left_version.each do |version |
                        tr do 
                          td version.SchemaVersion
                          td version.ApprovalCRCVersion
                        end
                      end
                    end
                  end
                  td do 
                    table do
                      th do "SchemaVersion" end
                      th do "ApprovalCRCVersion" end
                      right_version.each do |version |
                        tr do 
                          td version.SchemaVersion
                          td version.ApprovalCRCVersion
                        end
                      end
                    end
                  end
                  
                end
              end
            else
              div "Versions table does not exist in #{database1} Database." , :style => "padding-left:0px;color:#CFD638;font-family: Arial; font-size:13px;font-weight:bold;"
            end
            #       VERSIONS -END
            unless installation_matched.blank?
              installation_matched.each do |installationcompare|
                div "InstallationName: #{installationcompare.InstallationName}" , :style => "padding-top:20px;color:#CFD638;font-family: Arial; font-size:13px;font-weight:bold;"
                div "", :style => "clear:both; padding-top:10px;width:auto;"
                comparisonflag = false
                installationname = installationcompare.InstallationName
                left_atcs = Atcsconfig.find_by_sql("Select A.* from ATCSConfig A Left Outer join ATCSConfig1 B On A.Subnode = B.Subnode And ifNull(A.SubnodeName,'') = ifNull(B.SubnodeName,'') and ifNull(A.GCName,'') = ifNull(B.GCName,'') and A.InstallationName = B.InstallationName And ifnull(A.UCN,0) = ifNull(B.UCN,0) Where A.InstallationName Like '#{installationname}' and B.SubnodeName is null")
                right_atcs = Atcsconfig.find_by_sql("Select A.* from ATCSConfig1 A Left Outer join ATCSConfig B On A.Subnode = B.Subnode And ifNull(A.SubnodeName,'') = ifNull(B.SubnodeName,'') and ifNull(A.GCName,'') = ifNull(B.GCName,'') and A.InstallationName = B.InstallationName And ifnull(A.UCN,0) = ifNull(B.UCN,0) Where A.InstallationName Like '#{installationname}' and B.SubnodeName is null")
                unless left_atcs.blank? && right_atcs.blank?
                  comparisonflag = true
                  div "", :style => "clear:both; padding-top:20px;width:auto;"
                  div "Atcsconfig" , :style => "color:#F2F2F2;font-family: Arial; font-size:13px;font-weight:bold;"
                  div "", :style => "clear:both; padding-top:10px;width:auto;"
                  table do
                    td do 
                      table do
                        th do "Subnode" end
                        th do "SubnodeName" end
                        th do "GCName" end
                        th do "Installtion Name" end
                        th do "UCN" end
                        left_atcs.each do |atcsconfig |
                          tr do 
                            td atcsconfig.Subnode
                            td atcsconfig.SubnodeName
                            td atcsconfig.GCName
                            td atcsconfig.InstallationName
                            td atcsconfig.UCN
                          end
                        end
                      end
                    end
                    td do 
                      table do
                        th do "Subnode" end
                        th do "SubnodeName" end
                        th do "GCName" end
                        th do "Installtion Name" end
                        th do "UCN" end
                        right_atcs.each do |atcsconfig |
                          tr do 
                            td atcsconfig.Subnode
                            td atcsconfig.SubnodeName
                            td atcsconfig.GCName
                            td atcsconfig.InstallationName
                            td atcsconfig.UCN
                          end
                        end
                      end
                    end
                    
                  end
                end
                
                left_approval  = Approval.find_by_sql(" Select A.* from Approval A Left Outer Join Approval1 B On A.InstallationName = B.InstallationName And ifNull(A.Approver,'') = ifNull(B.Approver,'') and A.ApprovalDate = B.ApprovalDate and A.ApprovalTime = B.ApprovalTime and A.ApprovalCRC = B.ApprovalCRC and ifNull(A.ApprovalStatus,'') = ifNull(B.ApprovalStatus,'') Where A.InstallationName Like '#{installationname}' and B.InstallationName is null")
                right_approval = Approval.find_by_sql(" Select A.* from Approval1 A Left Outer Join Approval B On A.InstallationName = B.InstallationName And ifNull(A.Approver,'') = ifNull(B.Approver,'') and A.ApprovalDate = B.ApprovalDate and A.ApprovalTime = B.ApprovalTime and A.ApprovalCRC = B.ApprovalCRC and ifNull(A.ApprovalStatus,'') = ifNull(B.ApprovalStatus,'') Where A.InstallationName Like '#{installationname}' and B.InstallationName is null")
                unless left_approval.blank? && right_approval.blank?
                  comparisonflag = true
                  div "", :style => "clear:both; padding-top:20px;width:auto;"
                  div "Approval" , :style => "color:#F2F2F2;font-family: Arial; font-size:13px;font-weight:bold;"
                  div "", :style => "clear:both; padding-top:10px;width:auto;"
                  table do
                    tr do 
                      table do
                        th do "Installtion Name" end
                        th do "Approver" end
                        th do "Approval Date" end
                        th do "Approval CRC" end
                        th do "Approval Status" end
                        left_approval.each do |approval |
                          tr do 
                            td approval.InstallationName
                            td approval.Approver
                            td approval.ApprovalDate
                            td approval.ApprovalCRC
                            td approval.ApprovalStatus
                          end
                        end
                      end
                    end
                    div "", :style => "clear:both; padding-top:10px;width:auto;"
                    tr do 
                      table do
                        th do "Installtion Name" end
                        th do "Approver" end
                        th do "Approval Date" end
                        th do "Approval CRC" end
                        th do "Approval Status" end
                        right_approval.each do |approval |
                          tr do 
                            td approval.InstallationName
                            td approval.Approver
                            td approval.ApprovalDate
                            td approval.ApprovalCRC
                            td approval.ApprovalStatus
                          end
                        end
                      end
                    end
                    
                  end
                end
                left_aspect  = Aspect.find_by_sql(" Select A.* from Aspect A Left Outer Join Aspect1 B On A.InstallationName = B.InstallationName and A.GCName = B.GCName and A.AspectName = B.AspectName and A.[Index] = B.[Index] Where A.InstallationName Like '#{installationname}' and B.InstallationName is null")
                right_aspect = Aspect.find_by_sql(" Select A.* from Aspect1 A Left Outer Join Aspect B On A.InstallationName = B.InstallationName and A.GCName = B.GCName and A.AspectName = B.AspectName and A.[Index] = B.[Index] Where A.InstallationName Like '#{installationname}' and B.InstallationName is null")
                
                unless left_aspect.blank? && right_aspect.blank?
                  comparisonflag = true
                  div "", :style => "clear:both; padding-top:20px;width:auto;"
                  div "Aspect" , :style => "color:#F2F2F2;font-family: Arial; font-size:13px;font-weight:bold;"
                  div "", :style => "clear:both; padding-top:10px;width:auto;"
                  table do
                    td do 
                      table do
                        th do "Index" end
                        th do "AspectName" end
                        th do "GCName" end
                        th do "InstallationName" end
                        left_aspect.each do |aspect |
                          tr do 
                            td aspect.Index
                            td aspect.AspectName
                            td aspect.GCName
                            td aspect.InstallationName
                          end
                        end
                      end
                    end
                    td do 
                      table do
                        th do "Index" end
                        th do "AspectName" end
                        th do "GCName" end
                        th do "InstallationName" end
                        right_aspect.each do |aspect |
                          tr do 
                            td aspect.Index
                            td aspect.AspectName
                            td aspect.GCName
                            td aspect.InstallationName
                          end
                        end
                      end
                    end
                    
                  end
                end
                
                left_gcfile  = Gcfile.find_by_sql(" Select A.* from GCFile A Left Outer Join GCFile1 B On A.GCName = B.GCName and A.InstallationName = B.InstallationName Where A.InstallationName Like '#{installationname}' and B.InstallationName is null")
                right_gcfile = Gcfile.find_by_sql(" Select A.* from GCFile1 A Left Outer Join GCFile B On A.GCName = B.GCName and A.InstallationName = B.InstallationName Where A.InstallationName Like '#{installationname}' and B.InstallationName is null")
                unless left_gcfile.blank? && right_gcfile.blank?
                  comparisonflag = true
                  div "", :style => "clear:both; padding-top:20px;width:auto;"
                  div "Gcfile" , :style => "color:#F2F2F2;font-family: Arial; font-size:13px;font-weight:bold;"
                  div "", :style => "clear:both; padding-top:10px;width:auto;"
                  table do
                    td do 
                      table do
                        th do "GCName" end
                        th do "InstallationName" end
                        left_gcfile.each do |gcfile |
                          tr do 
                            td gcfile.GCName
                            td gcfile.InstallationName
                          end
                        end
                      end
                    end
                    td do 
                      table do
                        th do "GCName" end
                        th do "InstallationName" end
                        right_gcfile.each do |gcfile |
                          tr do 
                            td gcfile.GCName
                            td gcfile.InstallationName
                          end
                        end
                      end
                    end
                    
                  end
                end
                logicstate_leftquery  = "Select A.* from (Select P.PTCDeviceName DeviceName,L.LogicStateNumber LogicStateNumber ,L.BitPosn BitPosn , L.ContiguousCount ContiguousCount from LogicState L Inner Join PTCDevice P ON P.Id = L.Id Where P.InstallationName Like '#{installationname}') A Left Outer Join (Select P1.PTCDeviceName DeviceName,L1.LogicStateNumber LogicStateNumber ,L1.BitPosn BitPosn , L1.ContiguousCount ContiguousCount  from LogicState1 L1 Inner Join PTCDevice1 P1 ON P1.Id = L1.Id Where P1.InstallationName Like '#{installationname}') B On A.DeviceName = B.DeviceName and A.LogicStateNumber = B.LogicStateNumber and A.BitPosn = B.BitPosn and A.ContiguousCount = B.ContiguousCount Where B.DeviceName is null" 
                logicstate_rightquery = "Select A.* from (Select P.PTCDeviceName DeviceName,L.LogicStateNumber LogicStateNumber ,L.BitPosn BitPosn , L.ContiguousCount ContiguousCount from LogicState1 L Inner Join PTCDevice1 P ON P.Id = L.Id Where P.InstallationName Like '#{installationname}') A Left Outer Join (Select P1.PTCDeviceName DeviceName,L1.LogicStateNumber LogicStateNumber ,L1.BitPosn BitPosn , L1.ContiguousCount ContiguousCount  from LogicState L1 Inner Join PTCDevice P1 ON P1.Id = L1.Id Where P1.InstallationName Like '#{installationname}') B On A.DeviceName = B.DeviceName and A.LogicStateNumber = B.LogicStateNumber and A.BitPosn = B.BitPosn and A.ContiguousCount = B.ContiguousCount Where B.DeviceName is null"
                left_logicstate = Logicstate.find_by_sql(logicstate_leftquery)
                right_logicstate = Logicstate.find_by_sql(logicstate_rightquery)
                unless left_logicstate.blank? && right_logicstate.blank?
                  comparisonflag = true
                  div "", :style => "clear:both; padding-top:20px;width:auto;"
                  div "Logicstate" , :style => "color:#F2F2F2;font-family: Arial; font-size:13px;font-weight:bold;"
                  div "", :style => "clear:both; padding-top:10px;width:auto;"
                  table do
                    td do 
                      table do
                        th do "Device Name" end
                        th do "LogicState Number" end
                        th do "BitPosn" end
                        th do "Contiguous Count" end
                        left_logicstate.each do |logicstate |
                          tr do 
                            td logicstate.DeviceName
                            td logicstate.LogicStateNumber
                            td logicstate.BitPosn
                            td logicstate.ContiguousCount
                            
                          end
                        end
                      end
                    end
                    td do 
                      table do
                        th do "Device Name" end
                        th do "LogicState Number" end
                        th do "BitPosn" end
                        th do "Contiguous Count" end
                        right_logicstate.each do |logicstate |
                          tr do 
                            td logicstate.DeviceName
                            td logicstate.LogicStateNumber
                            td logicstate.BitPosn
                            td logicstate.ContiguousCount
                          end
                        end
                      end
                    end
                  end
                end
                mcf_leftquery  = "Select A.* from (Select MP.MCFName MCFName,MF.CRC CRC , MF.GOLType GOLType from MCF MF Inner Join MCFPhysicalLayout MP ON MP.MCFName = MF.MCFName where MP.InstallationName like '#{installationname}') A Left outer Join (Select MP1.MCFName MCFName,MF1.CRC CRC , MF1.GOLType GOLType from MCF1 MF1 Inner Join MCFPhysicalLayout1 MP1 ON MP1.MCFName = MF1.MCFName where MP1.InstallationName like '#{installationname}') B ON A.MCFName = B.MCFName and A.CRC = B.CRC and A.GOLType = B.GOLType where B.MCFName is null"
                mcf_rightquery = "Select A.* from (Select MP.MCFName MCFName,MF.CRC CRC , MF.GOLType GOLType from MCF1 MF Inner Join MCFPhysicalLayout1 MP ON MP.MCFName = MF.MCFName where MP.InstallationName like '#{installationname}') A Left outer Join (Select MP1.MCFName MCFName,MF1.CRC CRC , MF1.GOLType GOLType from MCF MF1 Inner Join MCFPhysicalLayout MP1 ON MP1.MCFName = MF1.MCFName where MP1.InstallationName like '#{installationname}') B ON A.MCFName = B.MCFName and A.CRC = B.CRC and A.GOLType = B.GOLType where B.MCFName is null"
                left_mcf = Mcfptc.find_by_sql(mcf_leftquery)
                right_mcf = Mcfptc.find_by_sql(mcf_rightquery)
                unless left_mcf.blank? && right_mcf.blank?
                  comparisonflag = true
                  div "", :style => "clear:both; padding-top:20px;width:auto;"
                  div "MCF" , :style => "color:#F2F2F2;font-family: Arial; font-size:13px;font-weight:bold;"
                  div "", :style => "clear:both; padding-top:10px;width:auto;"
                  table do
                    td do 
                      table do
                        th do "MCFName" end
                        th do "CRC" end
                        th do "GOLType" end
                        left_mcf.each do |mcf |
                          tr do 
                            td mcf.MCFName
                            td mcf.CRC
                            td mcf.GOLType
                          end
                        end
                      end
                    end
                    td do 
                      table do
                        th do "MCFName" end
                        th do "CRC" end
                        th do "GOLType" end
                        right_mcf.each do |mcf |
                          tr do 
                            td mcf.MCFName
                            td mcf.CRC
                            td mcf.GOLType
                          end
                        end
                      end
                    end
                  end
                end
                left_mcfphylayout  = Mcfphysicallayout.find_by_sql("Select A.* from MCFPhysicalLayout A Left Outer Join MCFPhysicalLayout1 B On A.PhysLayoutName = B.PhysLayoutName and A.GCName = B.GCName and A.MCFName = B.MCFName and A.Subnode = B.Subnode and A.InstallationName = B.InstallationName Where A.InstallationName Like '#{installationname}' and B.PhysLayoutNumber is null")
                right_mcfphylayout = Mcfphysicallayout.find_by_sql("Select A.* from MCFPhysicalLayout1 A Left Outer Join MCFPhysicalLayout B On A.PhysLayoutName = B.PhysLayoutName and A.GCName = B.GCName and A.MCFName = B.MCFName and A.Subnode = B.Subnode and A.InstallationName = B.InstallationName Where A.InstallationName Like '#{installationname}' and B.PhysLayoutNumber is null")
                unless left_mcfphylayout.blank? && right_mcfphylayout.blank?
                  comparisonflag = true
                  div "", :style => "clear:both; padding-top:20px;width:auto;"
                  div "Mcfphysicallayout" , :style => "color:#F2F2F2;font-family: Arial; font-size:13px;font-weight:bold;"
                  div "", :style => "clear:both; padding-top:10px;width:auto;"
                  table do
                    td do 
                      table do
                        th do "PhysLayout Number" end
                        th do "PhysLayout Name" end
                        th do "GCName" end
                        th do "MCFName" end
                        th do "Subnode" end
                        th do "Installation Name" end
                        left_mcfphylayout.each do |mcfphylayout |
                          tr do 
                            td mcfphylayout.PhysLayoutNumber
                            td mcfphylayout.PhysLayoutName
                            td mcfphylayout.GCName
                            td mcfphylayout.MCFName
                            td mcfphylayout.Subnode
                            td mcfphylayout.InstallationName
                          end
                        end
                      end
                    end
                    td do 
                      table do
                        th do "PhysLayout Number" end
                        th do "PhysLayout Name" end
                        th do "GCName" end
                        th do "MCFName" end
                        th do "Subnode" end
                        th do "Installation Name" end
                        right_mcfphylayout.each do |mcfphylayout |
                          tr do 
                            td mcfphylayout.PhysLayoutNumber
                            td mcfphylayout.PhysLayoutName
                            td mcfphylayout.GCName
                            td mcfphylayout.MCFName
                            td mcfphylayout.Subnode
                            td mcfphylayout.InstallationName
                          end
                        end
                      end
                    end
                  end
                end
                left_ptcaspect  = Ptcaspect.find_by_sql("Select A.* from PTCAspect A Left Outer Join PTCAspect1 B On A.PTCCode = B.PTCCode and A.AspectName = B.AspectName and A.InstallationName = B.InstallationName Where A.InstallationName Like '#{installationname}' and B.PTCCode is null")
                right_ptcaspect = Ptcaspect.find_by_sql("Select A.* from PTCAspect1 A Left Outer Join PTCAspect B On A.PTCCode = B.PTCCode and A.AspectName = B.AspectName and A.InstallationName = B.InstallationName Where A.InstallationName Like '#{installationname}' and B.PTCCode is null")
                unless left_ptcaspect.blank? && right_ptcaspect.blank?
                  comparisonflag = true
                  div "", :style => "clear:both; padding-top:20px;width:auto;"
                  div "Ptcaspect" , :style => "color:#F2F2F2;font-family: Arial; font-size:13px;font-weight:bold;"
                  div "", :style => "clear:both; padding-top:10px;width:auto;"
                  table do
                    td do 
                      table do
                        th do "PTCCode" end
                        th do "AspectName" end
                        th do "InstallationName" end
                        left_ptcaspect.each do |ptcaspect |
                          tr do 
                            td ptcaspect.PTCCode
                            td ptcaspect.AspectName
                            td ptcaspect.InstallationName
                          end
                        end
                      end
                    end
                    td do 
                      table do
                        th do "PTCCode" end
                        th do "AspectName" end
                        th do "InstallationName" end
                        right_ptcaspect.each do |ptcaspect |
                          tr do 
                            td ptcaspect.PTCCode
                            td ptcaspect.AspectName
                            td ptcaspect.InstallationName
                          end
                        end
                      end
                    end
                  end
                end
                left_ptcdevice  = Ptcdevice.find_by_sql("Select A.* from PTCDevice A Left Outer Join PTCDevice1 B On A.Id = B.Id and ifNull(A.TrackNumber,0) = ifNull(B.TrackNumber,0) and A.WSMMsgPosition = B.WSMMsgPosition and A.WSMBitPosition = B.WSMBitPosition and A.PTCDeviceName = B.PTCDeviceName and A.InstallationName = B.InstallationName and ifnull(A.SiteDeviceID,'') = ifnull(B.SiteDeviceID,'') and A.Subnode = B.Subnode and ifnull(A.Direction,'') = ifnull(B.Direction,'') and ifnull(A.Milepost,'') = ifnull(B.Milepost,'') and ifnull(A.SubdivisionNumber,'') = ifnull(B.SubdivisionNumber,'') and ifnull(A.SiteName,'') = ifnull(B.SiteName,'') and ifnull(A.GCName,'') = ifnull(B.GCName,'') Where A.InstallationName Like '#{installationname}' and B.PTCDevicename is null")
                right_ptcdevice = Ptcdevice.find_by_sql("Select A.* from PTCDevice1 A Left Outer Join PTCDevice B On A.Id = B.Id and ifNull(A.TrackNumber,0) = ifNull(B.TrackNumber,0) and A.WSMMsgPosition = B.WSMMsgPosition and A.WSMBitPosition = B.WSMBitPosition and A.PTCDeviceName = B.PTCDeviceName and A.InstallationName = B.InstallationName and ifnull(A.SiteDeviceID,'') = ifnull(B.SiteDeviceID,'') and A.Subnode = B.Subnode and ifnull(A.Direction,'') = ifnull(B.Direction,'') and ifnull(A.Milepost,'') = ifnull(B.Milepost,'') and ifnull(A.SubdivisionNumber,'') = ifnull(B.SubdivisionNumber,'') and ifnull(A.SiteName,'') = ifnull(B.SiteName,'') and ifnull(A.GCName,'') = ifnull(B.GCName,'') Where A.InstallationName Like '#{installationname}' and B.PTCDevicename is null")       
                unless left_ptcdevice.blank? && right_ptcdevice.blank?
                  comparisonflag = true
                  div "", :style => "clear:both; padding-top:20px;width:auto;"
                  div "Ptcdevice" , :style => "color:#F2F2F2;font-family: Arial; font-size:13px;font-weight:bold;"
                  div "", :style => "clear:both; padding-top:10px;width:auto;"
                  table do
                    tr do 
                      table do
                        th do "Id" end
                        th do "Track Number" end
                        th do "WSMMsg Position" end
                        th do "WSMBit Position" end
                        th do "PTCDevice Name" end
                        th do "Site DeviceID" end
                        th do "Subnode" end
                        th do "Direction" end
                        th do "Milepost" end
                        th do "Subdivision Number" end
                        th do "Site Name" end
                        th do "GCName" end
                        left_ptcdevice.each do |ptcdevice |
                          tr do 
                            td ptcdevice.Id
                            td ptcdevice.TrackNumber
                            td ptcdevice.WSMMsgPosition
                            td ptcdevice.WSMBitPosition
                            td ptcdevice.PTCDeviceName
                            td ptcdevice.SiteDeviceID
                            td ptcdevice.Subnode
                            td ptcdevice.Direction
                            td ptcdevice.Milepost
                            td ptcdevice.SubdivisionNumber
                            td ptcdevice.SiteName
                            td ptcdevice.GCName
                          end
                        end
                      end
                    end
                    div "", :style => "clear:both; padding-top:10px;width:auto;"
                    tr do 
                      table do
                        th do "Id" end
                        th do "Track Number" end
                        th do "WSMMsg Position" end
                        th do "WSMBit Position" end
                        th do "PTCDevice Name" end
                        th do "Site DeviceID" end
                        th do "Subnode" end
                        th do "Direction" end
                        th do "Milepost" end
                        th do "Subdivision Number" end
                        th do "Site Name" end
                        th do "GCName" end
                        right_ptcdevice.each do |ptcdevice |
                          tr do 
                            td ptcdevice.Id
                            td ptcdevice.TrackNumber
                            td ptcdevice.WSMMsgPosition
                            td ptcdevice.WSMBitPosition
                            td ptcdevice.PTCDeviceName
                            td ptcdevice.SiteDeviceID
                            td ptcdevice.Subnode
                            td ptcdevice.Direction
                            td ptcdevice.Milepost
                            td ptcdevice.SubdivisionNumber
                            td ptcdevice.SiteName
                            td ptcdevice.GCName
                          end
                        end
                      end
                    end
                  end
                end
                leftquery  = "Select  A.* from (Select P.PTCDeviceName DeviceName,S.NumberOfLogicStates Ls , S.Conditions Conditions, S.StopAspect StopAspect,S.HeadA HeadA,S.HeadB HeadB,S.HeadC HeadC,S.AspectId1 AspectId1,S.AltAspect1 AltAspect1,S.AspectId2 AspectId2,S.AltAspect2 AltAspect2,S.AspectId3 AspectId3, S.AltAspect3 AltAspect3 from Signal S Inner Join PTCDevice P ON P.Id = S.Id Where P.InstallationName Like '#{installationname}') A Left outer Join (Select P1.PTCDeviceName DeviceName,S1.NumberOfLogicStates Ls , S1.Conditions Conditions, S1.StopAspect StopAspect, S1.HeadA HeadA, S1.HeadB HeadB, S1.HeadC HeadC, S1.AspectId1 AspectId1, S1.AltAspect1 AltAspect1, S1.AspectId2 AspectId2, S1.AltAspect2 AltAspect2, S1.AspectId3 AspectId3 , S1.AltAspect3 AltAspect3 from Signal1 S1 Inner Join PTCDevice1 P1 ON P1.Id = S1.Id Where P1.InstallationName Like '#{installationname}') B On A.DeviceName = B.DeviceName And A.Ls = B.Ls and ifNull(A.Conditions,'') = ifNull(B.Conditions,'') and ifNull(A.StopAspect,0) = ifNull(B.StopAspect,0) and ifNull(A.HeadA,'') = ifNull(B.HeadA,'') and ifNull(A.HeadB,'') = ifNull(B.HeadB,'') and ifNull(A.HeadC,'') = ifNull(B.HeadC,'') and ifNull(A.AspectId1,0) = ifNull(B.AspectId1,0) and ifNull(A.AltAspect1,'') = ifNull(B.AltAspect1,'') and ifNull(A.AspectId2,0) = ifNull(B.AspectId2,0) and ifNull(A.AltAspect2,'') = ifNull(B.AltAspect2,'') and ifNull(A.AspectId3,0) = ifNull(B.AspectId3,0) and ifNull(A.AltAspect3,'') = ifNull(B.AltAspect3,'') where B.DeviceName is null"
                rightquery = "Select  A.* from (Select P.PTCDeviceName DeviceName,S.NumberOfLogicStates Ls , S.Conditions Conditions, S.StopAspect StopAspect,S.HeadA HeadA,S.HeadB HeadB,S.HeadC HeadC,S.AspectId1 AspectId1,S.AltAspect1 AltAspect1,S.AspectId2 AspectId2,S.AltAspect2 AltAspect2,S.AspectId3 AspectId3, S.AltAspect3 AltAspect3 from Signal1 S Inner Join PTCDevice1 P ON P.Id = S.Id Where P.InstallationName Like '#{installationname}') A Left outer Join (Select P1.PTCDeviceName DeviceName,S1.NumberOfLogicStates Ls , S1.Conditions Conditions, S1.StopAspect StopAspect, S1.HeadA HeadA, S1.HeadB HeadB, S1.HeadC HeadC, S1.AspectId1 AspectId1, S1.AltAspect1 AltAspect1, S1.AspectId2 AspectId2, S1.AltAspect2 AltAspect2, S1.AspectId3 AspectId3 , S1.AltAspect3 AltAspect3 from Signal S1 Inner Join PTCDevice P1 ON P1.Id = S1.Id Where P1.InstallationName Like '#{installationname}') B On A.DeviceName = B.DeviceName And A.Ls = B.Ls and ifNull(A.Conditions,'') = ifNull(B.Conditions,'') and ifNull(A.StopAspect,0) = ifNull(B.StopAspect,0) and ifNull(A.HeadA,'') = ifNull(B.HeadA,'') and ifNull(A.HeadB,'') = ifNull(B.HeadB,'') and ifNull(A.HeadC,'') = ifNull(B.HeadC,'') and ifNull(A.AspectId1,0) = ifNull(B.AspectId1,0) and ifNull(A.AltAspect1,'') = ifNull(B.AltAspect1,'') and ifNull(A.AspectId2,0) = ifNull(B.AspectId2,0) and ifNull(A.AltAspect2,'') = ifNull(B.AltAspect2,'') and ifNull(A.AspectId3,0) = ifNull(B.AspectId3,0) and ifNull(A.AltAspect3,'') = ifNull(B.AltAspect3,'') where B.DeviceName is null"
                left_signal = Signals.find_by_sql(leftquery )
                right_signal = Signals.find_by_sql(rightquery)
                unless left_signal.blank? && right_signal.blank?
                  comparisonflag = true
                  div "", :style => "clear:both; padding-top:20px;width:auto;"
                  div "Signals" , :style => "color:#F2F2F2;font-family: Arial; font-size:13px;font-weight:bold;"
                  div "", :style => "clear:both; padding-top:10px;width:auto;"
                  table do
                    tr do 
                      table do
                        th do "DeviceName" end
                        th do "NumberOfLogicStates" end
                        th do "Conditions" end
                        th do "StopAspect" end
                        th do "HeadA" end
                        th do "HeadB" end
                        th do "HeadC" end
                        th do "AspectId1" end
                        th do "AltAspect1" end
                        th do "AspectId2" end
                        th do "AltAspect2" end
                        th do "AspectId3" end
                        th do "AltAspect3" end
                        left_signal.each do |signal |
                          tr do 
                            td signal.DeviceName
                            td signal.Ls
                            td signal.Conditions
                            td signal.StopAspect
                            td signal.HeadA
                            td signal.HeadB
                            td signal.HeadC
                            td signal.AspectId1
                            td signal.AltAspect1
                            td signal.AspectId2
                            td signal.AspectId3
                            td signal.AltAspect3
                            td signal.Conditions
                          end
                        end
                      end
                    end
                    div "", :style => "clear:both; padding-top:10px;width:auto;"
                    tr do 
                      table do
                        th do "DeviceName" end
                        th do "NumberOfLogicStates" end
                        th do "Conditions" end
                        th do "StopAspect" end
                        th do "HeadA" end
                        th do "HeadB" end
                        th do "HeadC" end
                        th do "AspectId1" end
                        th do "AltAspect1" end
                        th do "AspectId2" end
                        th do "AltAspect2" end
                        th do "AspectId3" end
                        th do "AltAspect3" end
                        right_signal.each do |signal |
                          tr do 
                            td signal.DeviceName
                            td signal.Ls
                            td signal.Conditions
                            td signal.StopAspect
                            td signal.HeadA
                            td signal.HeadB
                            td signal.HeadC
                            td signal.AspectId1
                            td signal.AltAspect1
                            td signal.AspectId2
                            td signal.AspectId3
                            td signal.AltAspect3
                            td signal.Conditions
                          end
                        end
                      end
                    end
                  end
                end
                left_switch  = Switch.find_by_sql("Select A.* from (Select P.PTCDeviceName DeviceName, S.SwitchType swtype ,S.NumberOfLogicStates Ls from Switch S Inner Join PTCDevice P ON P.Id = S.Id Where P.InstallationName Like '#{installationname}') A Left outer Join (Select P1.PTCDeviceName DeviceName, S1.SwitchType swtype , S1.NumberOfLogicStates Ls from Switch1 S1 Inner Join PTCDevice1 P1 ON P1.Id = S1.Id Where P1.InstallationName Like '#{installationname}') B On A.DeviceName = B.DeviceName And A.Ls = B.Ls And A.swtype = B.swtype where B.DeviceName is null")
                right_switch = Switch.find_by_sql("Select A.* from (Select P.PTCDeviceName DeviceName, S.SwitchType swtype ,S.NumberOfLogicStates Ls from Switch1 S Inner Join PTCDevice1 P ON P.Id = S.Id Where P.InstallationName Like '#{installationname}') A Left outer Join (Select P1.PTCDeviceName DeviceName, S1.SwitchType swtype , S1.NumberOfLogicStates Ls from Switch S1 Inner Join PTCDevice P1 ON P1.Id = S1.Id Where P1.InstallationName Like '#{installationname}') B On A.DeviceName = B.DeviceName And A.Ls = B.Ls And A.swtype = B.swtype where B.DeviceName is null")
                unless left_switch.blank? && right_switch.blank?
                  comparisonflag = true
                  div "", :style => "clear:both; padding-top:20px;width:auto;"
                  div "Switch" , :style => "color:#F2F2F2;font-family: Arial; font-size:13px;font-weight:bold;"
                  div "", :style => "clear:both; padding-top:10px;width:auto;"
                  table do
                    td do 
                      table do
                        th do "DeviceName" end
                        th do "SwitchType" end
                        th do "NumberOfLogicStates" end
                        left_switch.each do |switch |
                          tr do 
                            td switch.DeviceName
                            td switch.swtype
                            td switch.Ls
                          end
                        end
                      end
                    end
                    td do 
                      table do
                        th do "DeviceName" end
                        th do "SwitchType" end
                        th do "NumberOfLogicStates" end
                        right_switch.each do |switch |
                          tr do 
                            td switch.DeviceName
                            td switch.swtype
                            td switch.Ls
                          end
                        end
                      end
                    end
                  end
                end
                left_hd  = Hazarddetector.find_by_sql("Select A.* from (Select P.PTCDeviceName DeviceName, H.NumberOfLogicStates Ls from HazardDetector H Inner Join PTCDevice P ON P.Id = H.Id Where P.InstallationName Like '#{installationname}') A Left outer Join (Select P1.PTCDeviceName DeviceName, H1.NumberOfLogicStates Ls from HazardDetector1 H1 Inner Join PTCDevice1 P1 ON P1.Id = H1.Id Where P1.InstallationName Like '#{installationname}') B On A.DeviceName = B.DeviceName And A.Ls = B.Ls  where B.DeviceName is null")
                right_hd = Hazarddetector.find_by_sql("Select A.* from (Select P.PTCDeviceName DeviceName, H.NumberOfLogicStates Ls from HazardDetector1 H Inner Join PTCDevice1 P ON P.Id = H.Id Where P.InstallationName Like '#{installationname}') A Left outer Join (Select P1.PTCDeviceName DeviceName, H1.NumberOfLogicStates Ls from HazardDetector H1 Inner Join PTCDevice P1 ON P1.Id = H1.Id Where P1.InstallationName Like '#{installationname}') B On A.DeviceName = B.DeviceName And A.Ls = B.Ls  where B.DeviceName is null")
                unless left_hd.blank? && right_hd.blank?
                  comparisonflag = true
                  div "", :style => "clear:both; padding-top:20px;width:auto;"
                  div "Hazarddetector" , :style => "color:#F2F2F2;font-family: Arial; font-size:13px;font-weight:bold;"
                  div "", :style => "clear:both; padding-top:10px;width:auto;"
                  table do
                    td do 
                      table do
                        th do "DeviceName" end
                        th do "NumberOf LogicStates" end
                        left_hd.each do |hd |
                          tr do 
                            td hd.DeviceName
                            td hd.Ls
                          end
                        end
                      end
                    end
                    td do 
                      table do
                        th do "DeviceName" end
                        th do "NumberOf LogicStates" end
                        right_hd.each do |hd |
                          tr do 
                            td hd.DeviceName
                            td hd.Ls
                          end
                        end
                      end
                    end
                  end
                end
                # All values are equl no difference
                if (comparisonflag == false)
                  div "", :style => "clear:both; padding-top:10px;width:auto;"
                  div "All the values are matched" , :style => "padding-left:10px;color:#F2F2F2;font-family: Arial; font-size:13px;"
                  div "", :style => "clear:both; padding-top:10px;width:auto;"
                end
              end
            end
            x1 =  Installationtemplate.find_by_sql("Select A.* from Installationtemplate A Left Outer Join Installationtemplate1 B On A.InstallationName = B.InstallationName where B.InstallationName is NULL")
            unless x1.blank?
              div "", :style => "clear:both; padding-top:10px;width:auto;"
              div "Not matched installations in Database(#{database1}): " , :style => "color:#CFD638;font-family: Arial; font-size:13px;font-weight:bold;"
              div "", :style => "clear:both; padding-top:10px;width:auto;"
              x1.each do |x|
                div "#{x.InstallationName}" , :style => "padding-left:10px;color:#F2F2F2;font-family: Arial; font-size:13px;"
              end
              div "", :style => "clear:both; padding-top:10px;width:auto;"
            end
            x2 =  Installationtemplate.find_by_sql("Select A.* from Installationtemplate1 A Left Outer Join Installationtemplate B On A.InstallationName = B.InstallationName where B.InstallationName is NULL")
            unless x2.blank?
              div "", :style => "clear:both; padding-top:10px;width:auto;"
              div "Not matched installations in Database(#{database2}): " , :style => "color:#CFD638;font-family: Arial; font-size:13px;font-weight:bold;"
              div "", :style => "clear:both; padding-top:10px;width:auto;"
              x2.each do |y|
                div "#{y.InstallationName}" , :style => "padding-left:10px;color:#F2F2F2;font-family: Arial; font-size:13px;"
              end
              div "", :style => "clear:both; padding-top:10px;width:auto;"
            end
          end
        end
      end
      @displayhtmlcontent = mab.to_s
    rescue Exception => e
      error_flag = true
      @displayhtmlcontent = "<div style='padding-left:10px;color:#FF0000;font-family: Arial; font-size:13px;'>Error :#{e.message}</div>" 
    end
    initialdb = RAILS_ROOT+"/db/InitialDB/iviu/GEOPTC.db"
    ActiveRecord::Base.establish_connection(:adapter => "sqlite3" , :database  => initialdb)
    savefilepath = RAILS_ROOT+'/oce_configuration/'+session[:user_id]+'/tmp/Databse_Comparison-report.html'
    File.open(savefilepath,'w') {|f| 
      if error_flag == true
        f.write("<div style='padding-left:10px;color:#FF0000;font-family: Arial; font-size:13px;'>#{@displayhtmlcontent}</div>")
      else
        f.write("<div style='clear:both; padding-top:10px;width:auto;'></div>")
        f.write("<div style='padding-left:10px;color:#F2F2F2;font-family: Arial; font-size:13px;'>Database 1 : #{database1}</div>")
        f.write("<div style='clear:both; padding-top:10px;width:auto;'></div>")
        f.write("<div style='padding-left:10px;color:#F2F2F2;font-family: Arial; font-size:13px;'>Database 2 : #{database2}</div>")
        f.write("<div style='clear:both; padding-top:20px;width:auto;'></div>")
        f.write(@displayhtmlcontent)
      end
    }
    session[:comp_rep_path] = savefilepath
    render :partial => "databasecomparison" 
  end
  
  ####################################################################
  # Function:      merge_data
  # Parameters:    params[:database1] , params[:database2] 
  # Retrun:        None
  # Renders:       None
  # Description:   Merge database1 , database2 and give the one compare database
  ####################################################################
  def merge_data
    begin
      database1 = params[:database1] 
      database2 = params[:database2] 
      time = Time.new
      strdatetime= time.strftime("%Y%m%d%H%M%S")
      mergeddatabasepath = "#{session[:OCE_ConfigPath]}tmp/Comp_Tool_#{strdatetime}.db"
      initialdb = RAILS_ROOT+"/db/InitialDB/iviu/GEOPTC.db"
      
      existingfileslist = Dir[session[:OCE_ConfigPath]+"tmp/*.db"]
      existingfileslist.each do |existing_db_file|
        File.delete existing_db_file
      end
      htmllists = Dir[session[:OCE_ConfigPath]+"tmp/*.html"]
      htmllists.each do |htmllist|
        File.delete htmllist
      end
      ActiveRecord::Base.establish_connection(:adapter => "sqlite3" , :database  => initialdb)
      db = SQLite3::Database.new(database1)
      db1installationvalid = db.execute("select InstallationName from InstallationTemplate")
      db.close
      db = SQLite3::Database.new(database2)
      db2installationvalid = db.execute("select InstallationName from InstallationTemplate")
      db.close
      returnvalue = ""
      if (!db1installationvalid.blank? && !db2installationvalid.blank?) 
        session[:comparedatabasepath] = nil
        FileUtils.cp(database1, mergeddatabasepath)
        ActiveRecord::Base.establish_connection(:adapter => "sqlite3" , :database  => mergeddatabasepath)
        ActiveRecord::Schema.define do
          sql = "CREATE TABLE [ATCSConfig1] ("
          sql << "[Subnode] INTEGER  NULL,"
          sql << "[SubnodeName] TEXT  NOT NULL,"
          sql << "[GCName] TEXT  NOT NULL,"
          sql << "[UCN] INTEGER  NULL,"
          sql << "[InstallationName] TEXT  NULL,"
          sql << "PRIMARY KEY ([Subnode],[GCName],[InstallationName])"
          sql << ")"
          execute sql
          
          sql = "CREATE TABLE [Approval1] ("
          sql << "[InstallationName] TEXT  NOT NULL,"
          sql << "[Approver] TEXT  NULL,"
          sql << "[ApprovalDate] DATE  NULL,"
          sql << "[ApprovalTime] TIME  NULL,"
          sql << "[ApprovalCRC] INTEGER  NULL,"
          sql << "[ApprovalStatus] TEXT  NULL,"
          sql << "PRIMARY KEY ([InstallationName],[ApprovalDate],[ApprovalTime])"
          sql << ")"
          execute sql
          
          sql = "CREATE TABLE Aspect1 ("
          sql << "'Index' INTEGER,AspectName TEXT, "
          sql << "GCName TEXT NOT NULL, "
          sql << "InstallationName TEXT, "
          sql << "PRIMARY KEY ('Index', InstallationName, GCName), Foreign Key (InstallationName) References GCFile (InstallationName), "
          sql << "Foreign Key (GCName) References GCFile1 (GCName))"
          execute sql
          
          sql = "CREATE TABLE GCFile1 ("
          sql << "GCName TEXT NOT NULL,"
          sql << "InstallationName TEXT NOT NULL,"
          sql << "PRIMARY KEY (GCName, InstallationName),Foreign Key (InstallationName) "
          sql << "References InstallationTemplate1 (InstallationName)) "
          execute sql
          
          sql = "CREATE TABLE HazardDetector1 ("
          sql << "Id INTEGER PRIMARY KEY, "
          sql << "NumberOfLogicStates INTEGER,"
          sql << "Foreign Key (Id) References PTCDevice1 (Id)) "
          execute sql
          
          sql = "CREATE TABLE InstallationTemplate1("
          sql << "InstallationName TEXT PRIMARY KEY)"
          execute sql
          
          sql = "CREATE TABLE [LogicState1] ("
          sql << "[LogicStateNumber] INTEGER  NULL,"
          sql << "[BitPosn] INTEGER  NULL,"
          sql << "[ContiguousCount] INTEGER  NULL,"
          sql << "[Id] INTEGER  NOT NULL,"
          sql << "PRIMARY KEY ([LogicStateNumber],[Id])"
          sql << ") "
          execute sql
          
          sql = "CREATE TABLE [MCF1] ("
          sql << "[MCFName] TEXT  PRIMARY KEY NULL,"
          sql << "[CRC] INTEGER  NULL,"
          sql << "[GOLType] INTEGER  NULL"
          sql << ") "
          execute sql
          
          sql = "CREATE TABLE [MCFPhysicalLayout1] ("
          sql << "[PhysLayoutNumber] INTEGER  NOT NULL PRIMARY KEY AUTOINCREMENT,"
          sql << "[PhysLayoutName] TEXT  NULL,"
          sql << "[GCName] TEXT  NOT NULL,"
          sql << "[MCFName] TEXT  NOT NULL,"
          sql << "[Subnode] INTEGER  NOT NULL,"
          sql << "[InstallationName] TEXT  NULL"
          sql << ") "
          execute sql
          
          sql = "CREATE TABLE PTCAspect1 ("
          sql << "PTCCode INTEGER NOT NULL,"
          sql << "AspectName TEXT NOT NULL, "
          sql << "InstallationName TEXT NOT NULL,"
          sql << "PRIMARY KEY (PTCCode, InstallationName),"
          sql << "Foreign Key (InstallationName) "
          sql << "References InstallationTemplate1 (InstallationName)) "
          execute sql
          
          sql = "CREATE TABLE [PTCDevice1] ("
          sql << "[Id] INTEGER  PRIMARY KEY AUTOINCREMENT NULL,"
          sql << "[TrackNumber] INTEGER  NULL,"
          sql << "[WSMMsgPosition] INTEGER  NULL,"
          sql << "[WSMBitPosition] INTEGER  NULL,"
          sql << "[PTCDeviceName] TEXT  NOT NULL,"
          sql << "[InstallationName] TEXT  NOT NULL,"
          sql << "[SiteDeviceID] TEXT  NULL,"
          sql << "[Subnode] INTEGER  NULL,"
          sql << "[Direction] TEXT  NULL,"
          sql << "[Milepost] TEXT  NULL,"
          sql << "[SubdivisionNumber] TEXT  NULL,"
          sql << "[SiteName] TEXT  NULL,"
          sql << "[GCName] TEXT  NULL"
          sql << ")"
          execute sql
          
          sql = "CREATE TABLE [Signal1] ("
          sql << "[Id] INTEGER  PRIMARY KEY NULL,"
          sql << "[NumberOfLogicStates] INTEGER  NULL,"
          sql << "[Conditions] TEXT  NULL,"
          sql << "[StopAspect] INTEGER  NULL,"
          sql << "[HeadA] TEXT  NULL,"
          sql << "[HeadB] TEXT  NULL,"
          sql << "[HeadC] TEXT  NULL,"
          sql << "[AspectId1] INTEGER  NULL,"
          sql << "[AltAspect1] TEXT  NULL,"
          sql << "[AspectId2] INTEGER  NULL,"
          sql << "[AltAspect2] TEXT  NULL,"
          sql << "[AspectId3] INTEGER  NULL,"
          sql << "[AltAspect3] TEXT  NULL"
          sql << ") "
          execute sql
          
          sql = "CREATE TABLE Switch1 ("
          sql << "Id INTEGER PRIMARY KEY, "
          sql << "SwitchType INTEGER, "
          sql << "NumberOfLogicStates INTEGER,"
          sql << "Foreign Key (Id) References PTCDevice1 (Id)) "
          execute sql
          
          sql = "CREATE TABLE Versions1 ("
          sql << "Id INTEGER PRIMARY KEY, "
          sql << "SchemaVersion INTEGER, "
          sql << "ApprovalCRCVersion INTEGER)"
          execute sql
        end
        createsiteptcdb(database2, mergeddatabasepath )
        returnvalue = ""
      else
        databas_eempty_check =""
        if db1installationvalid.blank?
          databas_eempty_check ="Database 1"
        elsif db2installationvalid.blank?
          databas_eempty_check ="Database 2"
        end
        returnvalue = "No Installations available in #{databas_eempty_check}"
      end
      render :text =>returnvalue
    rescue Exception => e
      render :text =>e.message
    end
  end
  
  ####################################################################
  # Function:      downloadcomparison_report
  # Parameters:    session[:comp_rep_path]
  # Retrun:        None
  # Renders:       send_file
  # Description:   Download the database comparison log
  ####################################################################
  def downloadcomparison_report
    path =""
    unless session[:comp_rep_path].blank?
        if File.exist?(session[:comp_rep_path])
          path = session[:comp_rep_path]
          send_file(path, :filename => "Database_comparison_Report.html",:dispostion=>'inline',:status=>'200 OK',:stream=>'true' )
        end
    else
      render :text => ""
    end
  end
  
end
