#########################################################################################################################
#
# File Name:           HLTAPI_LACP.py                 
# Description:         This script demonstrates the use of Spirent HLTAPI to setup LACP in B2B connection.
#                      
# Test Steps:          
#                    1. Reserve and connect chassis ports
#                    2. Configure interfaces
#                    3. Enable LACP
#                    4. Start LACP 
#                    5. Get LACP Info
#                    6. Stop LACP
#                    7. Retrive LACP statistics
#                    8. Release resources
#                                                                       
# Topology:
#                      STC Port2                    STC Port1                       
#                     [LACP port]------------------[LACP port]
#                                                                         
#  
################################################################################
# 
# Run sample:
#            c:>python HLTAPI_LACP.py 10.61.44.2 3/1 3/3
#

import sth
import time
from sys import argv
filename,device,port1,port2 = argv
port_list = [port1,port2]
port_handle = []

#Config the parameters for the logging
test_sta = sth.test_config (
    log                                              = '1',
    logfile                                          = 'HLTAPI_LACP_logfile',
    vendorlogfile                                    = 'HLTAPI_LACP_stcExport',
    vendorlog                                        = '1',
    hltlog                                           = '1',
    hltlogfile                                       = 'HLTAPI_LACP_hltExport',
    hlt2stcmappingfile                               = 'HHLTAPI_LACP_hlt2StcMapping',
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
    
############################################
# Step2: Configure interfaces             
############################################
print "Configure interface"

for i in range(0,len(port_list)) :
    returnedString = sth.interface_config (
        mode                                              = 'config',
        port_handle                                       = port_handle[i],
        intf_mode                                         = 'ethernet',
        phy_mode                                          = 'fiber')
    
    status = returnedString['status']
    if (status == '0') :
        print("run sth.interface_config failed")
        print returnedString
    else:
        print("***** run sth.interface_config successfully")
        print returnedString
        
############################################
# Step3: Enable LACP                       
############################################
print "Enable LACP on port1"
device_ret0 = sth.emulation_lacp_config (
        mode                                             = 'enable',
        port_handle                                      = port_handle[0],
        local_mac_addr                                   = '00:94:01:00:00:01',
        act_system_priority                              = '1000',
        act_system_id                                    = '00:00:00:00:01:01',
        lacp_activity                                    = 'active',
        act_port_number                                  = '10',
        act_lacp_port_priority                           = '101',
        act_port_key                                     = '100',
        act_lacp_timeout                                 = 'short');

status = device_ret0['status']
if (status == '0') :
    print("run sth.emulation_lacp_config failed")
    print(device_ret0)
else:
    print("***** run sth.emulation_lacp_config successfully")

print "Enable LACP on port2"
device_ret1 = sth.emulation_lacp_config (
        mode                                             = 'enable',
        port_handle                                      = port_handle[1],
        local_mac_addr                                   = '00:94:02:00:00:02',
        act_system_priority                              = '5000',
        act_system_id                                    = '00:00:00:00:01:01',
        lacp_activity                                    = 'active',
        act_port_number                                  = '10',
        act_lacp_port_priority                           = '501',
        act_port_key                                     = '500',
        act_lacp_timeout                                 = 'short');

status = device_ret1['status']
if (status == '0') :
    print("run sth.emulation_lacp_config failed")
    print(device_ret1)
else:
    print("***** run sth.emulation_lacp_config successfully")

#config part is finished
sth.invoke ('stc::perform saveasxml -filename lacp.xml')

############################################
#step4: Start LACP                          
############################################
print "Start LACP on port1"
ctrl_ret1 = sth.emulation_lacp_control (
        port_handle                                      = port_handle[0],
        action                                           = 'start');

status = ctrl_ret1['status']
if (status == '0') :
    print("run sth.emulation_lacp_control failed")
    print(ctrl_ret1)
else:
    print("***** run sth.emulation_lacp_control successfully")

print "Start LACP on port2"
ctrl_ret2 = sth.emulation_lacp_control (
        port_handle                                      = port_handle[1],
        action                                           = 'start');

status = ctrl_ret2['status']
if (status == '0') :
    print("run sth.emulation_lacp_control failed")
    print(ctrl_ret2)
else:
    print("***** run sth.emulation_lacp_control successfully")

############################################
#step5: Get LACP Info                      
############################################
print "Wait 30 seconds......"
time.sleep(10)

results_ret1 = sth.emulation_lacp_info (
        port_handle                                      = port_handle[0],
        mode                                             = 'state',
        action                                           = 'collect');

status = results_ret1['status']
if (status == '0') :
    print("run sth.emulation_lacp_info failed")
    print(results_ret1)
else:
    print("***** run sth.emulation_lacp_info successfully, and results is:")
    print(results_ret1)

results_ret2 = sth.emulation_lacp_info (
        port_handle                                      = port_handle[1],
        mode                                             = 'state',
        action                                           = 'collect');

status = results_ret2['status']
if (status == '0') :
    print("run sth.emulation_lacp_info failed")
    print(results_ret2)
else:
    print("***** run sth.emulation_lacp_info successfully, and results is:")
    print(results_ret2)

############################################
#step6: Stop LACP                           
############################################
print "Stop LACP on port1"
ctrl_ret1 = sth.emulation_lacp_control (
        port_handle                                      = port_handle[0],
        action                                           = 'stop');

status = ctrl_ret1['status']
if (status == '0') :
    print("run sth.emulation_lacp_control failed")
    print(ctrl_ret1)
else:
    print("***** run sth.emulation_lacp_control successfully")

print "Stop LACP on port2"
ctrl_ret2 = sth.emulation_lacp_control (
        port_handle                                      = port_handle[1],
        action                                           = 'stop');

status = ctrl_ret2['status']
if (status == '0') :
    print("run sth.emulation_lacp_control failed")
    print(ctrl_ret2)
else:
    print("***** run sth.emulation_lacp_control successfully")
    
############################################
#step7: Retrive LACP statistics             
############################################
print "Wait 10 seconds......"
time.sleep(10)

results_ret1 = sth.emulation_lacp_info (
        port_handle                                      = port_handle[0],
        mode                                             = 'aggregate',
        action                                           = 'collect');

status = results_ret1['status']
if (status == '0') :
    print("run sth.emulation_lacp_info failed")
    print(results_ret1)
else:
    print("***** run sth.emulation_lacp_info successfully, and results is:")
    print(results_ret1)

results_ret2 = sth.emulation_lacp_info (
        port_handle                                      = port_handle[1],
        mode                                             = 'aggregate',
        action                                           = 'collect');

status = results_ret2['status']
if (status == '0') :
    print("run sth.emulation_lacp_info failed")
    print(results_ret2)
else:
    print("***** run sth.emulation_lacp_info successfully, and results is:")
    print(results_ret2)
    
##############################################################
# Step8: Release resources
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