class PagesController < ApplicationController
  before_action :authenticate_user!, only: [:secret]
  def index
  	ActiveRecord::Base.establish_connection(:adapter => "sqlite3" , :database  => "#{Rails.root}/db/new.sqlite3")
  	ActiveRecord::Schema.define(version: 20161205060401) do

  create_table "delayed_jobs", force: :cascade do |t|
    t.integer  "priority",   default: 0, null: false
    t.integer  "attempts",   default: 0, null: false
    t.text     "handler",                null: false
    t.text     "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string   "locked_by"
    t.string   "queue"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["priority", "run_at"], name: "delayed_jobs_priority"
  end

  create_table "users", force: :cascade do |t|
    t.string   "name"
    t.string   "email",                  default: "", null: false
    t.string   "encrypted_password",     default: "", null: false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          default: 0,  null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.string   "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string   "unconfirmed_email"
    t.integer  "failed_attempts",        default: 0,  null: false
    t.string   "unlock_token"
    t.datetime "locked_at"
    t.datetime "created_at",                          null: false
    t.datetime "updated_at",                          null: false
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["unlock_token"], name: "index_users_on_unlock_token", unique: true
  end

        # ActiveRecord::Schema.define do
        #   sql = "CREATE TABLE [ATCSConfig1] ("
        #   sql << "[Subnode] INTEGER  NULL,"
        #   sql << "[SubnodeName] TEXT  NOT NULL,"
        #   sql << "[GCName] TEXT  NOT NULL,"
        #   sql << "[UCN] INTEGER  NULL,"
        #   sql << "[InstallationName] TEXT  NULL,"
        #   sql << "PRIMARY KEY ([Subnode],[GCName],[InstallationName])"
        #   sql << ")"
        #   execute sql
          
        #   sql = "CREATE TABLE [Approval1] ("
        #   sql << "[InstallationName] TEXT  NOT NULL,"
        #   sql << "[Approver] TEXT  NULL,"
        #   sql << "[ApprovalDate] DATE  NULL,"
        #   sql << "[ApprovalTime] TIME  NULL,"
        #   sql << "[ApprovalCRC] INTEGER  NULL,"
        #   sql << "[ApprovalStatus] TEXT  NULL,"
        #   sql << "PRIMARY KEY ([InstallationName],[ApprovalDate],[ApprovalTime])"
        #   sql << ")"
        #   execute sql
          
        #   sql = "CREATE TABLE Aspect1 ("
        #   sql << "'Index' INTEGER,AspectName TEXT, "
        #   sql << "GCName TEXT NOT NULL, "
        #   sql << "InstallationName TEXT, "
        #   sql << "PRIMARY KEY ('Index', InstallationName, GCName), Foreign Key (InstallationName) References GCFile (InstallationName), "
        #   sql << "Foreign Key (GCName) References GCFile1 (GCName))"
        #   execute sql
          
        #   sql = "CREATE TABLE GCFile1 ("
        #   sql << "GCName TEXT NOT NULL,"
        #   sql << "InstallationName TEXT NOT NULL,"
        #   sql << "PRIMARY KEY (GCName, InstallationName),Foreign Key (InstallationName) "
        #   sql << "References InstallationTemplate1 (InstallationName)) "
        #   execute sql
          
        #   sql = "CREATE TABLE HazardDetector1 ("
        #   sql << "Id INTEGER PRIMARY KEY, "
        #   sql << "NumberOfLogicStates INTEGER,"
        #   sql << "Foreign Key (Id) References PTCDevice1 (Id)) "
        #   execute sql
          
        #   sql = "CREATE TABLE InstallationTemplate1("
        #   sql << "InstallationName TEXT PRIMARY KEY)"
        #   execute sql
          
        #   sql = "CREATE TABLE [LogicState1] ("
        #   sql << "[LogicStateNumber] INTEGER  NULL,"
        #   sql << "[BitPosn] INTEGER  NULL,"
        #   sql << "[ContiguousCount] INTEGER  NULL,"
        #   sql << "[Id] INTEGER  NOT NULL,"
        #   sql << "PRIMARY KEY ([LogicStateNumber],[Id])"
        #   sql << ") "
        #   execute sql
          
        #   sql = "CREATE TABLE [MCF1] ("
        #   sql << "[MCFName] TEXT  PRIMARY KEY NULL,"
        #   sql << "[CRC] INTEGER  NULL,"
        #   sql << "[GOLType] INTEGER  NULL"
        #   sql << ") "
        #   execute sql
          
        #   sql = "CREATE TABLE [MCFPhysicalLayout1] ("
        #   sql << "[PhysLayoutNumber] INTEGER  NOT NULL PRIMARY KEY AUTOINCREMENT,"
        #   sql << "[PhysLayoutName] TEXT  NULL,"
        #   sql << "[GCName] TEXT  NOT NULL,"
        #   sql << "[MCFName] TEXT  NOT NULL,"
        #   sql << "[Subnode] INTEGER  NOT NULL,"
        #   sql << "[InstallationName] TEXT  NULL"
        #   sql << ") "
        #   execute sql
          
        #   sql = "CREATE TABLE PTCAspect1 ("
        #   sql << "PTCCode INTEGER NOT NULL,"
        #   sql << "AspectName TEXT NOT NULL, "
        #   sql << "InstallationName TEXT NOT NULL,"
        #   sql << "PRIMARY KEY (PTCCode, InstallationName),"
        #   sql << "Foreign Key (InstallationName) "
        #   sql << "References InstallationTemplate1 (InstallationName)) "
        #   execute sql
          
        #   sql = "CREATE TABLE [PTCDevice1] ("
        #   sql << "[Id] INTEGER  PRIMARY KEY AUTOINCREMENT NULL,"
        #   sql << "[TrackNumber] INTEGER  NULL,"
        #   sql << "[WSMMsgPosition] INTEGER  NULL,"
        #   sql << "[WSMBitPosition] INTEGER  NULL,"
        #   sql << "[PTCDeviceName] TEXT  NOT NULL,"
        #   sql << "[InstallationName] TEXT  NOT NULL,"
        #   sql << "[SiteDeviceID] TEXT  NULL,"
        #   sql << "[Subnode] INTEGER  NULL,"
        #   sql << "[Direction] TEXT  NULL,"
        #   sql << "[Milepost] TEXT  NULL,"
        #   sql << "[SubdivisionNumber] TEXT  NULL,"
        #   sql << "[SiteName] TEXT  NULL,"
        #   sql << "[GCName] TEXT  NULL"
        #   sql << ")"
        #   execute sql
          
        #   sql = "CREATE TABLE [Signal1] ("
        #   sql << "[Id] INTEGER  PRIMARY KEY NULL,"
        #   sql << "[NumberOfLogicStates] INTEGER  NULL,"
        #   sql << "[Conditions] TEXT  NULL,"
        #   sql << "[StopAspect] INTEGER  NULL,"
        #   sql << "[HeadA] TEXT  NULL,"
        #   sql << "[HeadB] TEXT  NULL,"
        #   sql << "[HeadC] TEXT  NULL,"
        #   sql << "[AspectId1] INTEGER  NULL,"
        #   sql << "[AltAspect1] TEXT  NULL,"
        #   sql << "[AspectId2] INTEGER  NULL,"
        #   sql << "[AltAspect2] TEXT  NULL,"
        #   sql << "[AspectId3] INTEGER  NULL,"
        #   sql << "[AltAspect3] TEXT  NULL"
        #   sql << ") "
        #   execute sql
          
        #   sql = "CREATE TABLE Switch1 ("
        #   sql << "Id INTEGER PRIMARY KEY, "
        #   sql << "SwitchType INTEGER, "
        #   sql << "NumberOfLogicStates INTEGER,"
        #   sql << "Foreign Key (Id) References PTCDevice1 (Id)) "
        #   execute sql
          
        #   sql = "CREATE TABLE Versions1 ("
        #   sql << "Id INTEGER PRIMARY KEY, "
        #   sql << "SchemaVersion INTEGER, "
        #   sql << "ApprovalCRCVersion INTEGER)"
        #   execute sql
        # end
  	# puts ActiveRecord::Base.connection.inspect #.execute('CREATE DATABASE IF NOT EXISTS new_database')
  end
end
end
