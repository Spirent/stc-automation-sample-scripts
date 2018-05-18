#########################################################################################################################
#
# File Name:           HLTAPI_Results.py                 
# Description:         This HLTAPI python script demonstrates the procedure of get DRV(Dynamic Result View) results
#                      and realtime results in DHCP scenario.
#                      
# Test Steps:          
#                      1. Reserve and connect chassis ports
#                      2. Create DHCP server and DHCP client on port2 and port1
#                      3. Start DHCP server and Bind DHCP device on DHCP client
#                      4. View DHCP info
#                      5. Create a host block on port2
#                      6. Create two streamblocks on port1 and port2
#                      7. Start traffic 
#                      8. Get traffic DRV results
#                      9. Get realtime results
#                      10. Stop traffic
#                      11. Get EOT results
#                      12. Cleanup sessions and release ports
#                                                                       
# Topology:
#                      STC Port2                      STC Port1                       
#                     [DHCP Server]------------------[DHCP clients]
#                     [Host Block]                                                     
#  
#                                                                          
################################################################################
# 
# Run sample:
#            c:>python HLTAPI_Results.py 10.61.44.2 3/1 3/3
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
    logfile                                          = 'HLTAPI_Results_logfile',
    vendorlogfile                                    = 'HLTAPI_Results_stcExport',
    vendorlog                                        = '1',
    hltlog                                           = '1',
    hltlogfile                                       = 'HLTAPI_Results_hltExport',
    hlt2stcmappingfile                               = 'HHLTAPI_Results_hlt2StcMapping',
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
# Step 2: Create DHCP server and DHCP client on port2 and port1
##############################################################

#start to create the device: Host 3
device_ret0 = sth.emulation_dhcp_server_config (
    mode                                             = 'create',
    ip_version                                       = '4',
    encapsulation                                    = 'ETHERNET_II',
    ipaddress_count                                  = '245',
    ipaddress_pool                                   = '10.1.1.10',
    ipaddress_increment                              = '1',
    port_handle                                      = port_handle[1],
    lease_time                                       = '3600',
    ip_repeat                                        = '0',
    remote_mac                                       = '00:00:01:00:00:01',
    ip_address                                       = '10.1.1.2',
    ip_prefix_length                                 = '24',
    ip_gateway                                       = '10.1.1.1',
    ip_step                                          = '0.0.0.1',
    local_mac                                        = '00:10:94:00:00:02',
    count                                            = '1');

status = device_ret0['status']
if (status == '0') :
    print "run sth.emulation_dhcp_server_config failed"
    print device_ret0
else:
    print "***** run sth.emulation_dhcp_server_config successfully"

#Start to create the device: Host 4
device_ret1port = sth.emulation_dhcp_config (
    mode                                             = 'create',
    ip_version                                       = '4',
    port_handle                                      = port_handle[0],
    starting_xid                                     = '0',
    lease_time                                       = '60',
    outstanding_session_count                        = '1000',
    request_rate                                     = '100',
    msg_timeout                                      = '60000',
    retry_count                                      = '4',
    max_dhcp_msg_size                                = '576',
    release_rate                                     = '100');

status = device_ret1port['status']
if (status == '0') :
    print "run sth.emulation_dhcp_config failed"
    print device_ret1port
else:
    print "***** run sth.emulation_dhcp_config successfully"

dhcp_handle = device_ret1port['handles']

device_ret1 = sth.emulation_dhcp_group_config (
    mode                                             = 'create',
    dhcp_range_ip_type                               = '4',
    encap                                            = 'ethernet_ii',
    handle                                           = dhcp_handle,
    opt_list                                         = ['1','6','15','33','44'],
    host_name                                        = 'client_@p-@b-@s',
    ipv4_gateway_address                             = '192.85.2.1',
    mac_addr                                         = '00:10:94:00:00:01',
    mac_addr_step                                    = '00:00:00:00:00:01',
    num_sessions                                     = '1');

status = device_ret1['status']
if (status == '0') :
    print "run sth.emulation_dhcp_group_config failed"
    print device_ret1
else:
    print "***** run sth.emulation_dhcp_group_config successfully"

#config part is finished
sth.invoke ('stc::perform saveasxml -filename results.xml')

#Set data packet capture and start capture
packet_config_buffers = sth.packet_config_buffers (
    port_handle = 'all',
    action = 'wrap');
    
packet_control = sth.packet_control (
    port_handle = 'all',
    action = 'start');
    

##############################################################
# Step 3: Start DHCP server and Bind DHCP device on DHCP client
##############################################################

ctrl_ret1 = sth.emulation_dhcp_server_control (
    port_handle                                      = port_handle[1],
    action                                           = 'connect',
    ip_version                                       = '4');

status = ctrl_ret1['status']
if (status == '0') :
    print "run sth.emulation_dhcp_server_control failed"
    print ctrl_ret1
else:
    print "***** run sth.emulation_dhcp_server_control successfully"

ctrl_ret2 = sth.emulation_dhcp_control (
    port_handle                                      = port_handle[0],
    action                                           = 'bind',
    ip_version                                       = '4');

status = ctrl_ret2['status']
if (status == '0') :
    print "run sth.emulation_dhcp_control failed"
    print ctrl_ret2
else:
    print "***** run sth.emulation_dhcp_control successfully"

time.sleep( 10 )
##############################################################
#Step 4: View DHCP info
##############################################################

results_ret1 = sth.emulation_dhcp_server_stats (
    port_handle                                      = port_handle[1],
    action                                           = 'COLLECT',
    ip_version                                       = '4');

status = results_ret1['status']
if (status == '0') :
    print "run sth.emulation_dhcp_server_stats failed"
    print results_ret1
else:
    print "***** run sth.emulation_dhcp_server_stats successfully, and results is:"
    print  results_ret1;

results_ret2 = sth.emulation_dhcp_stats (
    port_handle                                      = port_handle[0],
    action                                           = 'collect',
    mode                                             = 'detailed_session',
    ip_version                                       = '4');

status = results_ret2['status']
if (status == '0') :
    print "run sth.emulation_dhcp_stats failed"
    print results_ret2
else:
    print "***** run sth.emulation_dhcp_stats successfully, and results is:"
    print  results_ret2;

print "\nDHCP client IP : ", results_ret2['group']['dhcpv4blockconfig1']['1']['ipv4_addr'];

##############################################################
#Step 5: Create a host block on port2
##############################################################
hostblock = sth.emulation_device_config (
    mode = 'create',
    port_handle = port_handle[1],
    intf_ip_addr = '10.1.1.200',
    count = '10',
    gateway_ip_addr = '10.1.1.254');
    
status = hostblock['status']
if (status =='0') :
    print "run sth.emulation_device_config failed"
    print hostblock
else:
    print "***** run sth.emulation_device_config successfully."
    

##############################################################
#Step 6: Create two streamblocks on port1 and port2
##############################################################

#get host handle from hostblock and DHCP_group_config
hd1 = device_ret1['handle']
hd2 = hostblock['handle']

streamblock = sth.traffic_config (
    mode = 'create',
    port_handle = port_handle[0],
    port_handle2 = port_handle[1],
    emulation_src_handle = hd1,
    emulation_dst_handle = hd2,
    bidirectional = '1');

status = streamblock['status']
if (status =='0') :
    print "run sth.traffic_config failed"
    print streamblock
else:
    print "***** run sth.traffic_config successfully."

streamId = streamblock ['stream_id']
streamIdList = list(streamId.values())

##############################################################
#Step 7: Start traffic 
##############################################################

traffic_ctrl = sth.traffic_control (
    port_handle = 'all',
    action = 'run');
    
status = traffic_ctrl['status']
if (status =='0') :
    print "run sth.traffic_control_start failed"
    print traffic_ctrl
else:
    print "***** run sth.traffic_control_start successfully."
    
    
##############################################################
#Step 8 : Get traffic DRV results
##############################################################
drv_stats = sth.drv_stats (
    query_from                                       = [port_handle[0],port_handle[1]],
    drv_name                                         = 'drv1',
    properties                                       = 'Port.Name Port.RxTotalFrameCount Port.TxTotalFrameCount',
    group_by                                         = 'Port.Name')

status = drv_stats['status']
if (status =='0') :
    print "run sth.drv_stats failed"
    print drv_stats
else:
    print "***** Get results on port level successfully."
    print "Port level results are : ",drv_stats

drv_stats = sth.drv_stats (
    query_from                                       = streamIdList,
    drv_name                                         = 'drv2',
    properties                                       = 'StreamBlock.PortName StreamBlock.Name StreamBlock.RxFrameCount StreamBlock.TxFrameCount',
    where                                            = 'Streamblock.RxFrameCount != Streamblock.TxFrameCount')

status = drv_stats['status']
if (status =='0') :
    print "run sth.drv_stats failed"
    print drv_stats
else:
    print "***** Get results on streamblock level successfully."
    print "Streamblock level results are : ",drv_stats

########################################
# Step9. Get realtime results
########################################
print "Get realtime results on port2"
traffic_ctrl_ret = sth.traffic_control (
        port_handle                                      = [port_handle[0]],
        action                                           = 'run');

status = traffic_ctrl_ret['status']
if (status == '0') :
    print("run sth.traffic_control failed")
    print(traffic_ctrl_ret)
else:
    print("***** run sth.traffic_control successfully") 
    print traffic_ctrl_ret    

time.sleep(1)
    
traffic_results_ret = sth.traffic_stats (
        port_handle                                      = port_handle[1],
        mode                                             = 'aggregate');

status = traffic_results_ret['status']
if (status == '0') :
    print("run sth.traffic_stats failed")
    print(traffic_results_ret)
else:
    print("***** run sth.traffic_stats successfully, realtime results on port2 are:")
    print traffic_results_ret

time.sleep(1)

##############################################################
#Step 10: Stop traffic
##############################################################
time.sleep( 5 )
traffic_ctrl = sth.traffic_control (
    port_handle = 'all',
    action = 'stop');
    
status = traffic_ctrl['status']
if (status =='0') :
    print "run sth.traffic_control_stop failed"
    print traffic_ctrl
else:
    print "***** run sth.traffic_control_stop successfully."

##############################################################
#Step 11: Get EOT results 
##############################################################
time.sleep(3)    

print "Get EOT results on port2"

traffic_results_ret = sth.traffic_stats (
        port_handle                                      = port_handle[1],
        mode                                             = 'aggregate');

status = traffic_results_ret['status']
if (status == '0') :
    print("run sth.traffic_stats failed")
    print(traffic_results_ret)
else:
    print("***** run sth.traffic_stats successfully, EOT results on port2 are:")
    print traffic_results_ret
    
##############################################################
#Step 12: Cleanup sessions and release ports
##############################################################

cleanup_sta = sth.cleanup_session (
    port_handle                                      = [port_handle[0],port_handle[1]],
    clean_dbfile                                     = '1');

status = cleanup_sta['status']
if (status == '0') :
    print "run sth.cleanup_session failed"
    print cleanup_sta
else:
    print "***** run sth.cleanup_session successfully"
    
print "**************Finish***************"
 