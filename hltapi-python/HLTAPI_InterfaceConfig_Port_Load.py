################################################################################
#
# File Name:                 HLTAPI_InterfaceConfig_Port_Load.py
#
# Description:               This script demonstrates how to configure interface and check speed of the interface.
#
# Test steps:               
#                            1. Reserve and connect chassis ports
#                            2. Configure interface
#                            3. Check interface stats
#                            4. Release resources
#
# Topology:
#                            STC port1  ---------------- STC port2 
#
################################################################################
# 
# Run sample:
#            c:>python HLTAPI_InterfaceConfig_Port_Load.py 10.61.44.2 3/1 3/3

import sth
import time
from sys import argv
filename,device,port1,port2 = argv
port_list = [port1,port2]
port_handle = []

#Config the parameters for the logging
test_sta = sth.test_config (
    log                                              = '1',
    logfile                                          = 'HLTAPI_InterfaceConfig_Port_Load_logfile',
    vendorlogfile                                    = 'HLTAPI_InterfaceConfig_Port_Load_stcExport',
    vendorlog                                        = '1',
    hltlog                                           = '1',
    hltlogfile                                       = 'HLTAPI_InterfaceConfig_Port_Load_hltExport',
    hlt2stcmappingfile                               = 'HHLTAPI_InterfaceConfig_Port_Load_hlt2StcMapping',
    hlt2stcmapping                                   = '1',
    log_level                                        = '7')

status = test_sta['status']
if  status == '0' :
    print "run sth.test_config failed"
    print test_sta
else:
    print "***** run sth.test_config successfully"


########################################
# Step1. Reserve and connect chassis ports
########################################

intStatus = sth.connect (
    device    = device,
    port_list = port_list);

status = intStatus['status']
i = 0
if  status == '1' :
    for port in port_list :
        port_handle.append(intStatus['port_handle'][device][port])
        print "\n reserved ports",port,":", port_handle[i],": port_handle[%s]" % i
        i += 1
else :
    print "\nFailed to retrieve port handle!\n"
    print port_handle

##############################################################
#config the parameters for optimization and parsing
##############################################################

test_ctrl_sta = sth.test_control (
        action                                           = 'enable')

status = test_ctrl_sta['status']
if (status == '0') :
    print("run sth.test_control failed")
    print(test_ctrl_sta)
else:
    print("***** run sth.test_control successfully")

##############################################################
#Step2: Configure interface
##############################################################
print "Configure interface on port1"

speed = 'ether1000'

returnedString = sth.interface_config (
        mode                                              = 'config',
        port_handle                                       = port_handle[0],
        create_host                                       = 'false',
        intf_mode                                         = 'ethernet',
        speed                                             = speed,
        scheduling_mode                                   = 'PORT_BASED',
        port_load                                         = '100',
        port_loadunit                                     = 'PERCENT_LINE_RATE')
        
status = returnedString['status']
if (status == '0') :
    print("run sth.interface_config failed")
    print returnedString
else:
    print("***** run sth.interface_config successfully")
    print returnedString

#config part is finished
sth.invoke ('stc::perform saveasxml -filename interfaceconfig_port_load.xml')
    
##############################################################
#Step3: Check interface stats
##############################################################
print "Check interface stats of port1"

returnedString = sth.interface_stats (
        port_handle                                       = port_handle[0])

status = returnedString['status']
if (status == '0') :
    print("run sth.interface_config failed")
    print returnedString
else:
    print("***** run sth.interface_config successfully")
    print returnedString
    validspeed = returnedString['intf_speed']
    
if validspeed == '1000' :
    print "Config port speed as 1G successfully"
else :    
    print "Supported speed of port1 is : %s" % validspeed
    print "Configured port speed : %s is not supported by port1 , and the port speed has been set to %s. " % (speed , validspeed)

##############################################################
# Step4. Release resources
##############################################################
print "Release resources"
cleanup_sta = sth.cleanup_session (
    port_handle                                      = [port_handle[0],port_handle[1]],
    clean_dbfile                                     = '1')

status = cleanup_sta['status']
if  status == '0' :
    print "run sth.cleanup_session failed"
    print cleanup_sta
else:
    print "***** run sth.cleanup_session successfully"
    
print "**************Finish***************"
