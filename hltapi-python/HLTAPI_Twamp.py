#########################################################################################################################
#
# File Name:           HLTAPI_Twamp.py                 
# Description:         This script demonstrates the use of Spirent HLTAPI to setup twamp in B2B mode.
#                      
# Test Steps:          
#                    1. Reserve and connect chassis ports
#                    2. Create devices on port1 and port2
#                    3. Create twamp client on device1 on port1
#                    4. Create twamp server on device2 on port2
#                    5. Create twamp session1 on twamp client 
#                    6. Create twamp session2 on twamp client 
#                    7. Start twamp server and client
#                    8. Get twamp server and client results
#                    9. Stop twamp server and client 
#                    10. Release resources
#                                                                       
# Topology:
#                    STC Port2                      STC Port1                       
#                 [twamp server]------------------[twamp client]
#                                                                         
#  
################################################################################
# 
# Run sample:
#            c:>python HLTAPI_Twamp.py 10.61.44.2 3/1 3/3
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
    logfile                                          = 'HLTAPI_Twamp_logfile',
    vendorlogfile                                    = 'HLTAPI_Twamp_stcExport',
    vendorlog                                        = '1',
    hltlog                                           = '1',
    hltlogfile                                       = 'HLTAPI_Twamp_hltExport',
    hlt2stcmappingfile                               = 'HHLTAPI_Twamp_hlt2StcMapping',
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
# Step2. Create devices on port1 and port2
########################################
#start to create the device: Host 1
device_ret0 = sth.emulation_device_config (
        mode                                             = 'create',
        ip_version                                       = 'ipv4',
        count                                            = '1',
        router_id                                        = '192.0.0.1',
        enable_ping_response                             = '0',
        encapsulation                                    = 'ethernet_ii',
        port_handle                                      = port_handle[0],
        mac_addr                                         = '00:10:94:00:00:01',
        mac_addr_step                                    = '00:00:00:00:00:01',
        resolve_gateway_mac                              = 'true',
        gateway_ip_addr_step                             = '0.0.0.0',
        intf_ip_addr                                     = '192.85.1.3',
        intf_prefix_len                                  = '24',
        gateway_ip_addr                                  = '192.85.1.1',
        intf_ip_addr_step                                = '0.0.0.1');

status = device_ret0['status']
if (status == '0') :
    print("run sth.emulation_device_config failed")
    print(device_ret0)
else:
    print("***** run sth.emulation_device_config successfully")

devicehandle1 = device_ret0['handle']

#start to create the device: Host 2
device_ret1 = sth.emulation_device_config (
        mode                                             = 'create',
        ip_version                                       = 'ipv4',
        count                                            = '1',
        router_id                                        = '192.0.0.2',
        enable_ping_response                             = '0',
        encapsulation                                    = 'ethernet_ii',
        port_handle                                      = port_handle[1],
        mac_addr                                         = '00:10:94:00:00:02',
        mac_addr_step                                    = '00:00:00:00:00:01',
        resolve_gateway_mac                              = 'true',
        gateway_ip_addr_step                             = '0.0.0.0',
        intf_ip_addr                                     = '192.85.1.1',
        intf_prefix_len                                  = '24',
        gateway_ip_addr                                  = '192.85.1.3',
        intf_ip_addr_step                                = '0.0.0.1');

status = device_ret1['status']
if (status == '0') :
    print("run sth.emulation_device_config failed")
    print(device_ret1)
else:
    print("***** run sth.emulation_device_config successfully")
    
devicehandle2 = device_ret1['handle']

########################################
# Step3. Create twamp client on device1 on port1
########################################

device_cfg_ret0 = sth.emulation_twamp_config (
        mode                                             = 'create',
        handle                                           = devicehandle1,
        type                                             = 'client',
        peer_ipv4_addr                                   = '192.85.1.1',
        ip_version                                       = 'ipv4',
        connection_retry_cnt                             = '200',
        connection_retry_interval                        = '40',
        scalability_mode                                 = 'normal');

status = device_cfg_ret0['status']
if (status == '0') :
    print("run sth.emulation_twamp_config failed")
    print(device_cfg_ret0)
else:
    print("***** run sth.emulation_twamp_config successfully")
    
########################################
# Step4. Create twamp server on device2 on port2
########################################
    
device_cfg_ret1 = sth.emulation_twamp_config (
        mode                                             = 'create',
        handle                                           = devicehandle2,
        type                                             = 'server',
        server_ip_version                                = 'ipv4',
        server_willing_to_participate                    = 'true',
        server_mode                                      = 'unauthenticated');

status = device_cfg_ret1['status']
if (status == '0') :
    print("run sth.emulation_twamp_config failed")
    print(device_cfg_ret1)
else:
    print("***** run sth.emulation_twamp_config successfully")
    
########################################
# Step5. Create twamp session1 on twamp client 
########################################

device_cfg_ret0_sessionhandle_0 = sth.emulation_twamp_session_config (
        mode                                             = 'create',
        handle                                           = devicehandle1,
        dscp                                             = '2',
        ttl                                              = '254',
        start_delay                                      = '6',
        session_name                                     = 'TwampTestSession_1',
        frame_rate                                       = '50',
        pck_cnt                                          = '200',
        session_src_udp_port                             = '5451',
        session_dst_udp_port                             = '5450',
        duration_mode                                    = 'seconds',
        padding_pattern                                  = 'random',
        padding_len                                      = '140',
        scalability_mode                                 = 'normal',
        duration                                         = '120',
        timeout                                          = '60');

status = device_cfg_ret0_sessionhandle_0['status']
if (status == '0') :
    print("run sth.emulation_twamp_session_config failed")
    print(device_cfg_ret0_sessionhandle_0)
else:
    print("***** run sth.emulation_twamp_session_config successfully")
    
########################################
# Step6. Create twamp session2 on twamp client 
########################################

device_cfg_ret0_sessionhandle_1 = sth.emulation_twamp_session_config (
        mode                                             = 'create',
        handle                                           = devicehandle1,
        dscp                                             = '2',
        ttl                                              = '254',
        start_delay                                      = '6',
        session_name                                     = 'TwampTestSession_2',
        frame_rate                                       = '50',
        pck_cnt                                          = '200',
        session_src_udp_port                             = '5453',
        session_dst_udp_port                             = '5452',
        duration_mode                                    = 'seconds',
        padding_pattern                                  = 'random',
        padding_len                                      = '140',
        scalability_mode                                 = 'normal',
        duration                                         = '120',
        timeout                                          = '60');

status = device_cfg_ret0_sessionhandle_1['status']
if (status == '0') :
    print("run sth.emulation_twamp_session_config failed")
    print(device_cfg_ret0_sessionhandle_1)
else:
    print("***** run sth.emulation_twamp_session_config successfully")
    
#config part is finished
sth.invoke ('stc::perform saveasxml -filename twamp.xml')

########################################
# Step7. Start twamp server and client
########################################

ctrl_ret0 = sth.emulation_twamp_control (
        handle                                           = devicehandle2,
        mode                                             = 'start');

status = ctrl_ret0['status']
if (status == '0') :
    print("run sth.emulation_twamp_control failed")
    print(ctrl_ret0)
else:
    print("***** run sth.emulation_twamp_control successfully")

ctrl_ret1 = sth.emulation_twamp_control (
        handle                                           = devicehandle1,
        mode                                             = 'start');

status = ctrl_ret1['status']
if (status == '0') :
    print("run sth.emulation_twamp_control failed")
    print(ctrl_ret1)
else:
    print("***** run sth.emulation_twamp_control successfully")

########################################
# Step8. Get twamp server and client results
########################################
print "\nGet server results : "
results_ret0 = sth.emulation_twamp_stats (
        handle                                           = devicehandle2,
        mode                                             = 'server');

status = results_ret0['status']
if (status == '0') :
    print("run sth.emulation_twamp_stats failed")
    print(results_ret0)
else:
    print("***** run sth.emulation_twamp_stats successfully, and results is:")
    print(results_ret0)

print "\nGet client results : "
results_ret1 = sth.emulation_twamp_stats (
        handle                                           = devicehandle1,
        mode                                             = 'client');

status = results_ret1['status']
if (status == '0') :
    print("run sth.emulation_twamp_stats failed")
    print(results_ret1)
else:
    print("***** run sth.emulation_twamp_stats successfully, and results is:")
    print(results_ret1)
    
print "\nGet test_session results on device1 : "
results_ret2 = sth.emulation_twamp_stats (
        handle                                           = devicehandle1,
        mode                                             = 'test_session');

status = results_ret2['status']
if (status == '0') :
    print("run sth.emulation_twamp_stats failed")
    print(results_ret2)
else:
    print("***** run sth.emulation_twamp_stats successfully, and results is:")
    print(results_ret2)
    
print "\nGet port_test_session results on port1 : "

results_ret3 = sth.emulation_twamp_stats (
        port_handle                                       = port_handle[0],
        mode                                              = 'port_test_session');

status = results_ret3['status']
if (status == '0') :
    print("run sth.emulation_twamp_stats failed")
    print(results_ret3)
else:
    print("***** run sth.emulation_twamp_stats successfully, and results is:")
    print(results_ret3)

print "\nGet aggregated_client results on port1 : "

results_ret4 = sth.emulation_twamp_stats (
        port_handle                                       = port_handle[0],
        mode                                              = 'aggregated_client');

status = results_ret4['status']
if (status == '0') :
    print("run sth.emulation_twamp_stats failed")
    print(results_ret4)
else:
    print("***** run sth.emulation_twamp_stats successfully, and results is:")
    print(results_ret4)
    
print "\nGet aggregated_server results on port2 : "

results_ret5 = sth.emulation_twamp_stats (
        port_handle                                       = port_handle[1],
        mode                                              = 'aggregated_server');

status = results_ret5['status']
if (status == '0') :
    print("run sth.emulation_twamp_stats failed")
    print(results_ret5)
else:
    print("***** run sth.emulation_twamp_stats successfully, and results is:")
    print(results_ret5)
    
print "\nGet state_summary results on port1 : "

results_ret6 = sth.emulation_twamp_stats (
        port_handle                                       = port_handle[0],
        mode                                              = 'state_summary');

status = results_ret6['status']
if (status == '0') :
    print("run sth.emulation_twamp_stats failed")
    print(results_ret6)
else:
    print("***** run sth.emulation_twamp_stats successfully, and results is:")
    print(results_ret6)
    
########################################
# Step9. Stop twamp server and client 
########################################
print "\nStop twamp server and client :" 

ctrl_ret0 = sth.emulation_twamp_control (
        handle                                           = devicehandle2,
        mode                                             = 'stop');

status = ctrl_ret0['status']
if (status == '0') :
    print("run sth.emulation_twamp_control failed")
    print(ctrl_ret0)
else:
    print("***** run sth.emulation_twamp_control successfully")

ctrl_ret1 = sth.emulation_twamp_control (
        handle                                           = devicehandle1,
        mode                                             = 'stop');

status = ctrl_ret1['status']
if (status == '0') :
    print("run sth.emulation_twamp_control failed")
    print(ctrl_ret1)
else:
    print("***** run sth.emulation_twamp_control successfully") 
    
##############################################################
# Step10. Release resources
##############################################################
print "\nRelease resources :"
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