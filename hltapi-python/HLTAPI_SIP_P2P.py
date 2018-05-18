#########################################################################################################################
#
# File Name:           HLTAPI_sip_p2p.py                 
# Description:         This script demonstrates the use of Spirent HLTAPI to setup SIP in Peer-to-Peer scenario.
#                      
# Test Steps:          
#                    1. Reserve and connect chassis ports
#                    2. Configure SIP callees
#                    3. Configure SIP callers
#                    4. Establish a call between callers and callees(no registering in P2P scenario)
#                    5. Retrieve statistics
#                    6. Clear statistics
#                    7. Retrieve statistics again
#                    8. Delete SIP hosts
#                    9. Release resources
#                                                                       
# Topology:
#                    STC Port2                       STC Port1                       
#                  [SIP caller]---------------------[SIP callee]
#                                                                         
#  
################################################################################
# 
# Run sample:
#            c:>python HLTAPI_sip_p2p.py 10.61.44.2 3/1 3/3
#

import sth
import time
from sys import argv
filename,device,port1,port2 = argv
port_list = [port1,port2]
port_handle = []

def TurnOnCapture (portHandleList,port):
    captureHndList = []
    for portHnd in portHandleList.split() :
        print "Turn on capture on %s" % portHnd
        capture = sth.invoke ('stc::get %s -children-capture' % portHnd)
        sth.invoke ('stc::perform CaptureStart -CaptureProxyId ' + capture)
        captureHndList.append(capture)
    return captureHndList
    
def TurnOffCapture (portHandleList,port) :
    fileNameList = []
    for portHnd in portHandleList.split() :
        print "Turn off capture on %s" % portHnd
        captureHnd = sth.invoke('stc::get %s -children-capture' % portHnd)
        sth.invoke('stc::perform CaptureStop -CaptureProxyId ' + captureHnd)
        name = port
        print "Saving capture to : " + name
        sth.invoke ('stc::perform SaveSelectedCaptureData -CaptureProxyId %s -filename %s.pcap' % (captureHnd,name))
        fileNameList.append('%s.pcap' % name)
    print "Save file Name list = %s" % fileNameList
    return fileNameList
        

#Config the parameters for the logging
test_sta = sth.test_config (
    log                                              = '1',
    logfile                                          = 'HLTAPI_sip_p2p_logfile',
    vendorlogfile                                    = 'HLTAPI_sip_p2p_stcExport',
    vendorlog                                        = '1',
    hltlog                                           = '1',
    hltlogfile                                       = 'HLTAPI_sip_p2p_hltExport',
    hlt2stcmappingfile                               = 'HLTAPI_sip_p2p_hlt2StcMapping',
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
    
########################################
# Step2. Configure SIP callees
########################################    
device_ret0 = sth.emulation_sip_config (
        mode                                             = 'create',
        port_handle                                      = port_handle[0],
        count                                            = '2',
        name                                             = 'Callee1',
        mac_address_start                                = '00:10:94:00:00:01',
        local_ip_addr                                    = '192.1.0.15',
        remote_ip_addr                                   = '192.1.0.1',
        local_username_prefix                            = 'callee',
        local_username_suffix                            = '1000',
        local_username_suffix_step                       = '3',
        registration_server_enable                       = '0',
        registrar_address                                = '150.48.0.20',
        call_accept_delay_enable                         = '0',
        call_using_aor                                   = '1',
        remote_host                                      = '192.1.0.1',
        remote_host_step                                 = '1')

status = device_ret0['status']
if (status == '0') :
    print("run sth.emulation_sip_config failed")
    print(device_ret0)
else:
    print("***** run sth.emulation_sip_config successfully")
    
sipCallee = device_ret0['handle']

########################################
# Step3. Configure SIP callers
########################################

device_ret1 = sth.emulation_sip_config (
        mode                                             = 'create',
        port_handle                                      = port_handle[1],
        name                                             = 'Caller1',
        count                                            = '2',
        mac_address_start                                = '00:10:94:00:01:03',
        local_ip_addr                                    = '192.1.0.1',
        local_ip_addr_step                               = '1',
        remote_ip_addr                                   = '192.1.0.15',
        remote_ip_addr_step                              = '0',
        local_username_prefix                            = 'caller',
        local_username_suffix                            = '3000',
        local_username_suffix_step                       = '3',
        registration_server_enable                       = '0',
        call_using_aor                                   = '1',
        remote_host                                      = '192.1.0.15',
        remote_host_step                                 = '1')
        
status = device_ret1['status']
if (status == '0') :
    print("run sth.emulation_sip_config failed")
    print(device_ret1)
else:
    print("***** run sth.emulation_sip_config successfully")
    
sipCaller = device_ret1['handle']

#config part is finished
sth.invoke ('stc::perform saveasxml -filename sip_p2p.xml')

#turn on capture
TurnOnCapture (port_handle[1],"port2")

handleList = [sipCallee,sipCaller]

########################################
# Step4. Establish a call between callers and callees(no registering in P2P scenario)
########################################    

establish = sth.emulation_sip_control (
    action                                                    = 'establish',
    handle                                                    = sipCaller)

status = establish['status']
if (status == '0') :
    print("run sth.emulation_sip_control failed")
    print(establish)
else:
    print("***** run sth.emulation_sip_control successfully")
    
time.sleep(5)

terminate = sth.emulation_sip_control (
    action                                                    = 'terminate',
    handle                                                    = sipCaller)

status = terminate['status']
if (status == '0') :
    print("run sth.emulation_sip_control failed")
    print(terminate)
else:
    print("***** run sth.emulation_sip_control successfully")

#turn off capture    
TurnOffCapture (port_handle[1],"SIP")

########################################
# Step5. Retrieve statistics
########################################

results_ret1 = sth.emulation_sip_stats (
        handle                                           = [sipCaller,sipCallee],
        mode                                             = 'device',
        action                                           = 'collect');

status = results_ret1['status']
if (status == '0') :
    print("run sth.emulation_sip_stats failed")
    print(results_ret1)
else:
    print("***** run sth.emulation_sip_stats successfully, and results is:")
    print(results_ret1)

########################################
# Step6. Clear statistics
########################################

results_ret1 = sth.emulation_sip_stats (
        handle                                           = sipCaller,
        mode                                             = 'device',
        action                                           = 'clear');

status = results_ret1['status']
if (status == '0') :
    print("run sth.emulation_sip_stats failed")
    print(results_ret1)
else:
    print("***** run sth.emulation_sip_stats successfully, and results is:")
    print(results_ret1)

########################################
# Step7. Retrieve statistics again
########################################

results_ret1 = sth.emulation_sip_stats (
        handle                                           = [sipCaller,sipCallee],
        mode                                             = 'device',
        action                                           = 'collect');

status = results_ret1['status']
if (status == '0') :
    print("run sth.emulation_sip_stats failed")
    print(results_ret1)
else:
    print("***** run sth.emulation_sip_stats successfully, and results is:")
    print(results_ret1)
    
########################################
# Step8. Delete SIP hosts
########################################

device_ret1 = sth.emulation_sip_config (
        mode                                             = 'delete',
        handle                                           = sipCaller)
        
status = device_ret1['status']
if (status == '0') :
    print("run sth.emulation_sip_config failed")
    print(device_ret1)
else:
    print("***** run sth.emulation_sip_config successfully")
    
device_ret1 = sth.emulation_sip_config (
        mode                                             = 'delete',
        handle                                           = sipCallee)
        
status = device_ret1['status']
if (status == '0') :
    print("run sth.emulation_sip_config failed")
    print(device_ret1)
else:
    print("***** run sth.emulation_sip_config successfully")
    
##############################################################
# Step9. Release resources
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
    
