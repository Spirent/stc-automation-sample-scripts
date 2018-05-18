#########################################################################################################################
#
# File Name:           HLTAPI_sip_proxy_server.py                 
# Description:         This script demonstrates the use of Spirent HLTAPI to setup SIP in proxy server scenario.
#                      
# Test Steps:          
#                    1. Reserve and connect chassis ports
#                    2. Configure SIP proxy server
#                    3. Configure SIP caller
#                    4. Register caller and callee
#                    5. Check register state before establishing sip call
#                    6. Establish a call between caller and callee via proxy server, initiated by sip caller
#                    7. Release resources 
#                                                                       
# Topology:
#                    STC Port2                      STC Port1                       
#                  [SIP caller]------------------[SIP proxy server]----------------[SIP callee]
#                                                                         
#  
################################################################################
# 
# Run sample:
#            c:>python HLTAPI_sip_proxy_server.py 10.61.44.2 3/1 3/3
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
    logfile                                          = 'HLTAPI_sip_proxy_server_logfile',
    vendorlogfile                                    = 'HLTAPI_sip_proxy_server_stcExport',
    vendorlog                                        = '1',
    hltlog                                           = '1',
    hltlogfile                                       = 'HLTAPI_sip_proxy_server_hltExport',
    hlt2stcmappingfile                               = 'HLTAPI_sip_proxy_server_hlt2StcMapping',
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
# Step2. Configure SIP proxy server
########################################

device_ret0 = sth.emulation_sip_config (
        mode                                             = 'create',
        port_handle                                      = port_handle[0],
        count                                            = '10',
        name                                             = 'Callee1',
        mac_address_start                                = '00:10:94:00:00:01',  
        vlan_id1                                         = '500',    
        vlan_ether_type1                                 = '0x8100',
        vlan_id_mode1                                    = 'fixed',
        vlan_id_step1                                    = '0',
        local_ip_addr                                    = '150.1.0.5',
        remote_ip_addr                                   = '150.1.0.1',
        gateway_enable                                   = '1',
        gateway_ipv4_address                             = '150.1.0.3',
        local_username_prefix                            = 'callee',
        local_username_suffix                            = '1000',
        local_username_suffix_step                       = '3',
        registration_server_enable                       = '1',
        registrar_address                                = '150.1.0.5',
        desired_expiry_time                              = '100000',
        call_accept_delay_enable                         = '0',
        response_delay_interval                          = '5',
        media_payload_type                               = 'SIP_MEDIA_ITU_G711_64K_160BYTE',
        media_port_number                                = '50550',
        remote_username_prefix                           = 'caller',
        remote_username_suffix                           = '300',
        remote_username_suffix_step                      = '3')

status = device_ret0['status']
if (status == '0') :
    print("run sth.emulation_sip_config failed")
    print(device_ret0)
else:
    print("***** run sth.emulation_sip_config successfully")
    
sipCallee = device_ret0['handle']
    
########################################
# Step3. Configure SIP caller
########################################

device_ret1 = sth.emulation_sip_config (
        mode                                             = 'create',
        port_handle                                      = port_handle[1],
        count                                            = '10',
        name                                             = 'Caller1',
        mac_address_start                                = '00:10:94:00:10:03',    
        vlan_id1                                         = '600',    
        vlan_ether_type1                                 = '0x8100',
        vlan_id_mode1                                    = 'fixed',
        local_ip_addr                                    = '160.1.0.2',
        remote_ip_addr                                   = '160.1.0.1',
        remote_ip_addr_step                              = '0',
        local_username_prefix                            = 'caller',
        local_username_suffix                            = '300',
        local_username_suffix_step                       = '3',
        registration_server_enable                       = '1',
        registrar_address                                = '150.1.0.5',
        desired_expiry_time                              = '100000',
        media_payload_type                               = 'SIP_MEDIA_ITU_G711_64K_160BYTE',
        media_port_number                                = '50550',
        remote_username_prefix                           = 'callee',
        remote_username_suffix                           = '1000',
        remote_username_suffix_step                      = '3',
        call_using_aor                                   = '1',
        remote_host                                      = '150.1.0.5',
        remote_host_step                                 = '1')

status = device_ret1['status']
if (status == '0') :
    print("run sth.emulation_sip_config failed")
    print(device_ret1)
else:
    print("***** run sth.emulation_sip_config successfully")
    
sipCaller = device_ret1['handle']

#config part is finished
sth.invoke ('stc::perform saveasxml -filename sip_proxyserver.xml')

#Turn on capture
TurnOnCapture (port_handle[1],"port2")

########################################
# Step4. Register caller and callee
########################################

handleList = [sipCallee,sipCaller]

for sipHandle in handleList :
    ctrl_ret1 = sth.emulation_sip_control (
        handle                                           = sipHandle,
        action                                           = 'register')

    status = ctrl_ret1['status']
    if (status == '0') :
        print("run sth.emulation_sip_control failed")
        print(ctrl_ret1)
    else:
        print "***** run sth.emulation_sip_control successfully"
        
time.sleep (10)

########################################
# Step5. Check register state before establishing sip call
########################################

stateFlag = 0

for sipHandle in handleList :
    results_ret1 = sth.emulation_sip_stats (
        handle                                           = sipHandle,
        mode                                             = 'device',
        action                                           = 'collect');
        
    status = results_ret1['status']
    if (status == '0') :
        print("run sth.emulation_sip_stats failed")
        print(results_ret1)
    else:
        print("***** run sth.emulation_sip_stats successfully, and results is:")
        print(results_ret1)
        
    # Enum: NOT_REGISTERED|REGISTERING|REGISTRATION_SUCCEEDED|REGISTRATION_FAILED|REGISTRATION_CANCELED|UNREGISTERING
        
    regState = results_ret1[sipHandle]['registration_state']
    
    if stateFlag == 0 :
        print "\n Register state of %s : %s " % (sipHandle,regState)
        if regState != "REGISTRATION_SUCCEEDED":
            stateFlag = 1
            print "\n Failed to register " + sipHandle
    else :
        print "Failed to register " + sipHandle
        TurnOffCapture (port_handle[1],"SIP")
        

########################################
# Step6. Establish a call between caller and callee via proxy server, initiated by sip caller
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
    
##############################################################
# Step7. Release resources
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

    