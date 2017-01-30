module DbcomparisontoolHelper
   def createsiteptcdb(db2 , db3)
    siteptcdb = db3
    (ActiveRecord::Base.configurations["site_ptc_db"])["database"] = db2
    if File.exist?(siteptcdb)
         mcfphysicallayoutvalue = Mcfphysicallayout.find_by_sql("select * from MCFPhysicalLayout")
         value =Installationtemplate.find_by_sql("select * from InstallationTemplate")
         ptcvalues = Ptcdevice.find_by_sql("select * from PTCDevice")
         db = SQLite3::Database.new(siteptcdb)
         
         value.each do |instname|
            db.execute( "Insert into InstallationTemplate1 values('#{instname.InstallationName}')" )
         end
         for q in 0..(mcfphysicallayoutvalue.length-1) 
            db.execute("Insert into MCFPhysicalLayout1 values('#{mcfphysicallayoutvalue[q].PhysLayoutNumber}','#{mcfphysicallayoutvalue[q].PhysLayoutName}','#{mcfphysicallayoutvalue[q].GCName}','#{mcfphysicallayoutvalue[q].MCFName}','#{mcfphysicallayoutvalue[q].Subnode}','#{mcfphysicallayoutvalue[q].InstallationName}')" )   
         end

         for i in 0..(ptcvalues.length-1) 
            db.execute("Insert into PTCDevice1 (Id ,TrackNumber , WSMMsgPosition , WSMBitPosition , PTCDeviceName , InstallationName , SiteDeviceID , Subnode , Direction , Milepost , SubdivisionNumber , SiteName , GCName) values('#{ptcvalues[i].id}',#{getintegervalue(ptcvalues[i].TrackNumber)},'#{ptcvalues[i].WSMMsgPosition}','#{ptcvalues[i].WSMBitPosition}','#{ptcvalues[i].PTCDeviceName}','#{ptcvalues[i].InstallationName}','#{ptcvalues[i].SiteDeviceID}','#{ptcvalues[i].Subnode}' , '#{ptcvalues[i].Direction }' , '#{ptcvalues[i].Milepost }' , '#{ptcvalues[i].SubdivisionNumber }' , '#{ptcvalues[i].SiteName }' , '#{ptcvalues[i].GCName}')" )   
         end
         signalvalue = Signals.find_by_sql("select s.Id , s.NumberOfLogicStates , s.Conditions , s.StopAspect , s.HeadA , s.HeadB , s.HeadC , s.AspectId1 , s.AltAspect1 , s.AspectId2 , s.AltAspect2 , s.AspectId3 , s.AltAspect3  from Signal as s")
         for j in 0..(signalvalue.length-1) 
          stopaspect = getintegervalue(signalvalue[j].StopAspect) 
          aspectid1 = getintegervalue(signalvalue[j].AspectId1)   
          aspectid2 = getintegervalue(signalvalue[j].AspectId2)   
          aspectid3 = getintegervalue(signalvalue[j].AspectId3)   
          db.execute("Insert into Signal1 values('#{signalvalue[j].Id}','#{signalvalue[j].NumberOfLogicStates}','#{signalvalue[j].Conditions}',#{stopaspect},'#{signalvalue[j].HeadA}','#{signalvalue[j].HeadB}','#{signalvalue[j].HeadC}',#{aspectid1},'#{signalvalue[j].AltAspect1}',#{aspectid2},'#{signalvalue[j].AltAspect2}',#{aspectid3},'#{signalvalue[j].AltAspect3}')" )   
         end
         
         switchvalue = Switch.find_by_sql("select s.Id ,s.SwitchType, s.NumberOfLogicStates from Switch as s")
         for k in 0..(switchvalue.length-1) 
          db.execute("Insert into Switch1 values('#{switchvalue[k].Id}','#{switchvalue[k].SwitchType}','#{switchvalue[k].NumberOfLogicStates}')" )   
         end
        
         hazarddetectorvalue = Hazarddetector.find_by_sql("select h.Id ,h.NumberOfLogicStates from HazardDetector as h")
         for l in 0..(hazarddetectorvalue.length-1) 
          db.execute("Insert into HazardDetector1 values('#{hazarddetectorvalue[l].Id}','#{hazarddetectorvalue[l].NumberOfLogicStates}')" )   
         end
        
         mcfnamevalues = Array.new
         mcfnamevalues = Mcfptc.find_by_sql("select m.MCFName, m.CRC, m.GOLType  from MCF as m")
         for m in 0..(mcfnamevalues.length-1) 
           db.execute("Insert into MCF1 values('#{mcfnamevalues[m].MCFName}','#{mcfnamevalues[m].CRC}','#{mcfnamevalues[m].GOLType}')" )   
         end
         
         logicstatevalue = Array.new
         logicstatevalue=Logicstate.find_by_sql("select l.LogicStateNumber, l.BitPosn, l.ContiguousCount, l.Id from LogicState as l")
         for n in 0..(logicstatevalue.length-1)
            db.execute("Insert into LogicState1 values('#{logicstatevalue[n].LogicStateNumber}','#{logicstatevalue[n].BitPosn}','#{logicstatevalue[n].ContiguousCount}','#{logicstatevalue[n].Id}')" )   
         end
    
         aspectvalue = Array.new
         aspectvalue=Ptcaspect.find_by_sql("select * from PTCAspect")
         for o in 0..(aspectvalue.length-1)
            db.execute("Insert into PTCAspect1 values('#{aspectvalue[o].PTCCode}','#{aspectvalue[o].AspectName}','#{aspectvalue[o].InstallationName}')" )   
         end
         
         aspect = Array.new
         aspect = Aspect.find_by_sql("select * from Aspect")
         for r in 0..(aspect.length-1)
            db.execute("Insert into Aspect1 values('#{aspect[r].Index}','#{aspect[r].AspectName}','#{aspect[r].GCName}','#{aspect[r].InstallationName}')" )   
         end
         
         gcfilevalue = Array.new
         gcfilevalue = Gcfile.find_by_sql("select * from GCFile")
         for s in 0..(gcfilevalue.length-1)
            db.execute("Insert into GCFile1 values('#{gcfilevalue[s].GCName}','#{gcfilevalue[s].InstallationName}')" )   
         end
         
         approvalvalue = Array.new
         approvalvalue = Approval.find_by_sql("select * from Approval")
         for t in 0..(approvalvalue.length-1)
            db.execute("Insert into Approval1 values('#{approvalvalue[t].InstallationName}','#{approvalvalue[t].Approver}','#{approvalvalue[t].ApprovalDate}','#{approvalvalue[t].ApprovalTime}','#{approvalvalue[t].ApprovalCRC}','#{approvalvalue[t].ApprovalStatus}')" )   
         end
          
         atcsvalue = Array.new
         atcsvalue = Atcsconfig.find_by_sql("select * from ATCSConfig")
         for p in 0..(atcsvalue.length-1)
            db.execute("Insert into ATCSConfig1 values('#{atcsvalue[p].Subnode}','#{atcsvalue[p].SubnodeName}','#{atcsvalue[p].GCName}',#{getintegervalue(atcsvalue[p].UCN)} ,'#{atcsvalue[p].InstallationName}')" ) 
         end
         if Versions.table_exists?
           versionsvalue = Array.new
           versionsvalue = Versions.find_by_sql("select * from Versions")
           for u in 0..(versionsvalue.length-1)
              db.execute("Insert into Versions1 values(#{versionsvalue[u].Id},#{versionsvalue[u].SchemaVersion},#{versionsvalue[u].ApprovalCRCVersion})" )   
           end
         end
        # Close The SitePTC.DB 
        db.close
        (ActiveRecord::Base.configurations["site_ptc_db"])["database"] = siteptcdb
        session[:comparedatabasepath] = siteptcdb
     end
 end
 
 def getintegervalue(values)
     unless values.blank?
         returnvalue = values.to_i
     else
         returnvalue = "null"
     end
     return returnvalue            
  end
   
end
