
#Mcf.find_by_mcf_status(1).mcfcrc
TRACK_CARD = 15
PSO_CARD = 29
SSCC_CARD = 20
AND_CARD = 21
MAIN_SSCC_CARD = 14
RIO_CARD = 8
NGCP_APP_CARD = 18

#MCFCRC = Gwe.find(:first, :select => "mcfcrc").try(:mcfcrc) || 0

Gwe.refresh_mcfcrc

VLP_CARD = 9
SSCC_TEST_CARD = 91
SSCC_CARD_USED = 0 

PASSWORD_ON = 2
PASSWORD_NOMATCH = 0
PASSWORD_MATCH = 1
PASSWORD_SUPER_MATCH = 2
PASSWORD_MATCH_BOTH = 3
PASSWORD_4K_DISABLED = 4

#Param_Config = 2
#Param_Status = 3
#Param_Diagnostics = 4
#Param_Command = 5
Param_IPMAP = 6
Param_OPMAP = 7
Param_IP_OP_MAP = 3

Param_Config = 2
Param_Status = 3
Param_Diagnostics = 6
Param_Command = 4

PRG_MENU = "MAIN PROGRAM menu"
MENU_ID = "MAIN_Menu"
CON_NAME = "programming"
PHY_LAYPUT = "ParamPhysicalLayout"
CFG_FILE = "CFG File"

#Data Types
MCF_Integer_Type = "IntegerType"
MCF_Enumerator_Type = "Enumeration"

#Pages Sizes for Pagination

MAINTENANCE_LOG_PAGE_SIZE = 10

#contansts for logs
TRAINLOG_PATH="app/views/logs/trainlog.txt"
DIAGNOSTICSLOG_PATH="app/views/logs/diagnosticlog.txt"
MAINTENANCELOG_FILENAME = "Maintlog"
DOWNLOADALLLOG_PATH="app/views/logs/"
DOWNLOADALLLOG_FILENAME = "Logs.zip"
MAINTENANCELOG_FILEPATH = "app/views/logs/Main/"

REQUEST_SELECT_RANGE=106
REQUEST_CARD_VERSION=105
AND_DETAIL_CARDINDEX=28