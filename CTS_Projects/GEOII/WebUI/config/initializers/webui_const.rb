#-----------------------------------------------------------
# UDP Request/Reply Manager commands
#-----------------------------------------------------------
REQUEST_COMMAND_LOG                     = 1
REQUEST_COMMAND_GEO_LOG                 = 2
REQUEST_COMMAND_VERIFY_SCREEN           = 3
REQUEST_COMMAND_SET_PARAMETER           = 4
REQUEST_COMMAND_UPLOAD_FILE             = 5
REQUEST_COMMAND_REPORT                  = 7
REQUEST_COMMAND_SET_UCN                 = 8
REQUEST_COMMAND_TIME                    = 9
REQUEST_COMMAND_RESET                   = 10
REQUEST_COMMAND_VERIFY_SCREEN_IVIU      = 11
REQUEST_COMMAND_SET_PROP_IVIU           = 12
REQUEST_COMMAND_LS                      = 14
REQUEST_COMMAND_LOCATION                = 15
REQUEST_COMMAND_SIMPLE_REQUEST          = 17
REQUEST_COMMAND_CDL_COMPILER            = 22
REQUEST_COMMAND_UNSOL_EVENTS            = 23
REQUEST_COMMAND_CONF_PACKAGE_UPLOAD     = 24
REQUEST_COMMAND_GEO_STATISTICS          = 102
REQUEST_COMMAND_SET_VERBOSITY           = 103
REQUEST_COMMAND_GET_MODULES             = 105  
REQUEST_COMMAND_FILE_DOWNLOAD           = 204

REQUEST_USER_PRESENCE = 1
REQUEST_USER_PRESENCE_SAFEMODE = 8
REQUEST_RC2_KEY = 8
REQUEST_SET_TO_DEFAULT = 6
REQUEST_REBOOT = 9
REQUEST_CLEAR_ECD = 20
REQUEST_CLEAR_CIC = 21
REQUEST_GEO_OBJ_MSG = 104
SIMPLE_CMD_SET_MCFCRC = 17


#-----------------------------------------------------------
# directories
#-----------------------------------------------------------
ECD_DIR = "/mnt/ecd/0"

# cdl
#-----------------------------------------------------------
DOWNLOAD_CDL_LOG = 17
DLOWLOAD_CDL_FILE = 13
CDL_FILE_PATH = '/usr/safetran/ecd/0'
CDL_IS_ANSWERED_TRUE = "1"
CDL_IS_ANSWERED_FALSE = "0"
CDL_START_COMPILE = 0
CDL_COMPILE_FINISHED = 2

CDL_GCP_EQUAL = 0
CDL_GCP_GREATER_THAN = 1
CDL_GCP_LESS_THAN = 2
CDL_GCP_NOT_EQUAL = 3
CDL_GCP_GREATER_THAN_OR_EQUAL = 4
CDL_GCP_LESS_THAN_OR_EQUAL = 5

CDL_GEO_EQUAL = 5
CDL_GEO_GREATER_THAN = 2
CDL_GEO_LESS_THAN = 0
CDL_GEO_NOT_EQUAL = 4
#CDL_GEO_GREATER_THAN_OR_EQUAL = ?
#CDL_GEO_LESS_THAN_OR_EQUAL = ?

#-----------------------------------------------------------
# UDP Request/Reply Connection Information
#-----------------------------------------------------------
REQUEST_UDP_PORT = 33333
REPLY_UDP_PORT   = 22222
REQUEST_REPLY_IP_ADDR = "127.0.0.1"

#-----------------------------------------------------------
#UDP request state values
#-----------------------------------------------------------
REQUEST_STATE_START = 0
REQUEST_STATE_PROCESSING  = 1
REQUEST_STATE_COMPLETED = 2
REQUEST_STATE_CANCEL_REQUEST = -1
REQUEST_STATE_CANCEL_COMPLETED  = -2

#-----------------------------------------------------------
# UDP Command Types
#-----------------------------------------------------------
CLEAR_HISTORY       = 0
GET_FIRST           = 1
GET_NEXT            = 2
GET_PREVIOUS        = 3
GET_LAST            = 4
HISTORY_REPLY       = 5
NO_TRAIN_MOVE_AVAIL = 6
GET_ALL             = 7

#-----------------------------------------------------------
# Expressions
#-----------------------------------------------------------
INVALID_EXPR = -1

#-----------------------------------------------------------
#Data Types
#-----------------------------------------------------------
McfParamIntegerType = "IntegerType"
McfParamEnumerationType = "Enumeration"

#-----------------------------------------------------------
#Data Kind
#-----------------------------------------------------------
DataKindNVCfg = 0
DataKindVCfg = 1
DataKindSATCfg = 6
DataKindRouteCfg = 7

#-----------------------------------------------------------
#Card Information Type
#-----------------------------------------------------------
VitalConfiguration = 1
NonVitalConfiguration = 2
Status = 3
Command = 4
CardSWSettings = 5
Diagnostic = 6
LCfg = 7
DefaultConfigurationstatus = 8
CardHWconfiguration2 = 9
CardsoftwareSettings2 = 10
SATCommand = 11
SATStatus = 12
SATCfg = 13
SATRouteCfg = 14
CardHWconfiguration1s = 15
SATConfigurationForAllSATs = 97
SATRouteConfigurationForAllSATs = 98
#StatusforUser Cfg/IO cards with status + Non Vital Configuration + Vital Configuration = 99
CommandStatusNVitalConfigVitalConfig = 100

#-----------------------------------------------------------
#LOG FILE PATHS
#-----------------------------------------------------------
EVENT_LOG_FILE = "/usr/safetran/WebUI/log/event_log.txt"
DISP_LOG_FILE = "/usr/safetran/WebUI/log/diag_log.txt"
GEO_EVENT_LOG_FILE = "/tmp/log_all.txt"
CDL_LOG_FILE = "/mnt/ecd/0/cdl_log.txt"
#-----------------------------------------------------------

#-----------------------------------------------------------
#JOURNAL TYPES
#-----------------------------------------------------------
EVENT_JRNL_T = 1
DIAG_JRNL_T  = 2
CDL_JRNL_T   = 3
#-----------------------------------------------------------

#-----------------------------------------------------------
#LOG TYPES
#-----------------------------------------------------------
STATUS_LOG_T = 1
DISP_LOG_T   = 2
DIAG_LOG_T   = 6
ALL_LOG_T    = 7

VLP_STATUS_LOG_T = 11
VLP_SUMMARY_LOG_T = 12
VLP_SHUTDOWN_LOG_T = 14
#-----------------------------------------------------------
# LOG FIELDS 
#-----------------------------------------------------------
LOGFLD_EQUIPMENT = 0
LOGFLD_SITENAME = 1
LOGFLD_CARDSLOT = 2 
LOGFLD_TYPE = 3
LOGFLD_TEXT = 4
LOGFLD_MAX = 5
#-----------------------------------------------------------
# LOG FILTER OPERATORS 
#-----------------------------------------------------------
LOGOP_EQUALS = 0
LOGOP_CONTAINS = 1
LOGOP_STARTSWITH = 2
LOGOP_MAX = 3
#-----------------------------------------------------------
# LOG FILTER LOGICAL OPERATORS 
#-----------------------------------------------------------
LOGLOGIC_AND = 0
LOGLOGIC_OR = 1

#-----------------------------------------------------------
# LOG COMMANDS
#-----------------------------------------------------------
LOG_CMD_FIRST = 1
LOG_CMD_PREV = 2
LOG_CMD_NEXT = 3
LOG_CMD_LAST = 4
LOG_CMD_ALL = 5

# Report types
CONFIG_REPORT               = 2
VERSION_REPORT              = 1

# Initializing Product Type
# PRODUCT_TYPE_IVIU_WEBUI = 0
# PRODUCT_TYPE_IVIU_OCE = 1
PRODUCT_TYPE_GCP_WEBUI = 2
GCP_PRODUCT = 0

PRODUCT_TYPE_GEO_WEBUI = 0
PRODUCT_TYPE_GEO_OCE = 1

# Running WebUI in Local Machine - 1 , Console - 0
LOCAL_MACHINE_WEBUI = 0

OCE_MODE,OCE_ADMIN, WEBUI_VERSION = GenericHelper.read_config_xml
#--- OCE ADMIN = 1 is enables the oceadmin user login
#OCE_ADMIN = 0

#--- OCE_MODE = 0 for GEO2 WebUI
#--- OCE_MODE = 1 for OCE WebUI
#OCE_MODE = 0

if OCE_MODE == 0
  PRODUCT_TYPE = PRODUCT_TYPE_GEO_WEBUI
else
  PRODUCT_TYPE = PRODUCT_TYPE_GEO_OCE
end

#-----------------------------------------------------------
#Time interval for Diagnostic messages check in secs
#-----------------------------------------------------------
if PRODUCT_TYPE == 0 || PRODUCT_TYPE == 2
  DIAG_MSG_TIME = 30
else
  DIAG_MSG_TIME = 0
end

GEO_COMM_STATUS = 1
GEO_STATUS = 10
ZERO = 0

#--------------------------------------------------------------------------------
# CARD TYPES DEFINED FOR GEO VITAL OPTIONS AS PER GUSTAVO REGARDING BUG #6235
#--------------------------------------------------------------------------------
VITAL_TIMER_OPTION = 94
NONVITAL_TIMER_OPTION = 95
VITAL_IO_OPTION = 96
NONVITAL_IO_OPTION = 97
VITAL_USER_OPTION = 98
NONVITAL_USER_OPTION = 99

VITAL_USER_OPTION_TYPE = 203
NONVITAL_USER_OPTION_TYPE = 204
TIMERS_CONFIG_TYPE = 205
NVTIMERS_CONFIG_TYPE = 206

#-----------------------------------------------------------
# GEO Statistic IDs
#-----------------------------------------------------------
CARD_STATS_ID     = 0
VITAL_STATS_ID    = 1
NONVITAL_STATS_ID = 2
TIME_STATS_ID     = 4
SIO_STATS_ID      = 5
CONSOLE_STATS_ID  = 6
LAN_STATS_ID      = 7
VLP_STATS_ID      = 8
PTC_STATS_ID      = 9

#-----------------------------------------------------------
#File Transfer Targets
#-----------------------------------------------------------
TARGET_NV_EXECUTIVE = 1
TARGET_LOCAL_UI = 2
TARGET_WEB_UI = 3
TARGET_GEO = 4
TARGET_VITAL_CORE = 5
TARGET_CARTRIDGES = 6
TARGET_NV_CONFIG = 7
TARGET_NV_APP = 8
TARGET_VITAL_CONFIG = 9
TARGET_CONFIG = 10
TARGET_VITAL_FILES = 11
TARGET_SEAR = 12

#-----------------------------------------------------------
#File Transfer File Types
#-----------------------------------------------------------
FILE_TYPE_NONE = 0
FILE_TYPE_MCF = 1
FILE_TYPE_MEF = 2
FILE_TYPE_MEX = 3
FILE_TYPE_FPGA = 4
FILE_TYPE_XILINX = 5
FILE_TYPE_XML = 6
FILE_TYPE_MCFCRC = 7
FILE_TYPE_BIN = 8
FILE_TYPE_RC2KEY = 9
FILE_TYPE_NV_DB = 10
FILE_TYPE_CIC_BIN = 11
FILE_TYPE_PTC_DB = 12
FILE_TYPE_CDL = 13
FILE_TYPE_LLW = 14
FILE_TYPE_LLB = 15
FILE_TYPE_TGZ = 16
FILE_TYPE_CDL_LOG = 17
FILE_TYPE_SEAR_EXEC = 18
FILE_TYPE_CDL_VERSION = 19
FILE_TYPE_CONF_PACKAGE_ZIP = 20


# ECHELON MODULE CONSTANT
if PRODUCT_TYPE == PRODUCT_TYPE_GCP_WEBUI
  ECHELON_MODULE_GROUP_ID = 131
else
  ECHELON_MODULE_GROUP_ID = 25
end
# Security
DEFAULT_GCP_PASSWORD = "GCP4000"
GROUP_ID_SECURITY = 17
PASSWORD_MAINTAINER = "Maintainer Password"
PASSWORD_SUPERVISOR = "Supervisor Password"
PASSWORD_ADMIN = "Admin Password"
SECURITY_ENABLED = "Security Enabled"
SECURITY_ENABLED_NONE = 36
SECURITY_ENABLED_MAINTAINER_ONLY = 37
SECURITY_ENABLED_SUPERVISOR_ONLY = 38
SECURITY_ENABLED_MAINT_AND_SUPER = 39

#-----------------------------------------------------------
#Track Data
#-----------------------------------------------------------
TRACK_DATA_GROUP_ID = 39
TRACK_SELECTED = 201
TRACK_NOT_SELECTED = 200

#-----------------------------------------------------------
#Software update - Vital CPU/Module constants
#-----------------------------------------------------------
FILE_TYPE_EXIT_SOFTWARE = 21
FILE_TYPE_EXIT_SOFTWARE_UPDATE_PAGE = 22
FILE_TYPE_ABORT_CANCEL_SOFTWARE_UPDATE = 25

YES_NO_INPUT = 1  # yes/No question
CRC_INPUT    = 2  # CRC
TEXT_INPUT   = 3  #input text
FILE_INPUT   = 4  # File upload