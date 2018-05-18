#########################################################################################################################
#
# File Name:           HLTAPI_PYTHON_DHCP_with_traffic.py                 
# Description:         This HLTAPI python script demonstrates the procedure to setup DHCP server and DHCP client,
#                      and then emulate traffic between DHCP client and normal host(s).
#                      DHCP server and client(s) are emulated in loopback(back-to-back) mode.After DHCP client(s) got 
#                      IP address(es) from DHCP server,a emulated host block is created to communicate with DHCP client(s).
#
# Main Steps:          Step 1: Connect to chassis and reserve ports                                
#                      Step 2: Create DHCP server and DHCP client on port2 and port1
#                      Step 3: Start DHCP server and Bind DHCP device on DHCP client
#                      Step 4: View DHCP info
#                      Step 5: Create a host block on port2
#                      Step 6: Create two streamblocks on port1 and port2
#                      Step 7: Start traffic and stop traffic
#                      Step 8: Get traffic result
#                      Step 9: Cleanup sessions and release ports
#
#                                                                       
# Topology:
#                      STC Port2                      STC Port1                       
#                     [DHCP Server]------------------[DHCP clients]
#                     [Host Block]                                                     
#  
#                                                                          
#########################################################################################################################
import sth

import time
##############################################################
#Config the parameters for the logging
##############################################################

test_sta = sth.test_config (
    log                                              = '1',
    logfile                                          = 'dhcp_w_t_logfile',
    vendorlogfile                                    = 'dhcp_w_t_stcExport',
    vendorlog                                        = '1',
    hltlog                                           = '1',
    hltlogfile                                       = 'dhcp_w_t_hltExport',
    hlt2stcmappingfile                               = 'dhcp_w_t_hlt2StcMapping',
    hlt2stcmapping                                   = '1',
    log_level                                        = '7');

status = test_sta['status']
if (status == '0') :
    print "run sth.test_config failed"
    print test_sta
else:
    print "***** run sth.test_config successfully"


##############################################################
#Config the parameters for optimization and parsing
##############################################################

test_ctrl_sta = sth.test_control (
    action                                           = 'enable');

status = test_ctrl_sta['status']
if (status == '0') :
    print "run sth.test_control failed"
    print test_ctrl_sta
else:
    print "***** run sth.test_control successfully"


##############################################################
# Step1: Connect to chassis and reserve ports
##############################################################

i = 0
device = "10.61.47.130"
port_list = ['1/1','1/2']
port_handle = []
intStatus = sth.connect (
    device                                           = device,
    port_list                                        = port_list,
    offline                                          = 0 );

status = intStatus['status']

if (status == '1') :
    for port in port_list :
        port_handle.append(intStatus['port_handle'][device][port])
        print "\n reserved ports",port,":", port_handle[i],": port_handle[%s]" % i
        i += 1
else :
    print "\nFailed to retrieve port handle!\n"
    print port_handle


##############################################################
#Interface config
##############################################################

int_ret0 = sth.interface_config (
    mode                                             = 'config',
    port_handle                                      = port_handle[0],
    intf_mode                                        = 'ethernet',
    duplex                                           = 'full',
    autonegotiation                                  = '1');

status = int_ret0['status']
if (status == '0') :
    print "run sth.interface_config failed"
    print int_ret0
else:
    print "***** run sth.interface_config successfully"

int_ret1 = sth.interface_config (
    mode                                             = 'config',
    port_handle                                      = port_handle[1],
    intf_mode                                        = 'ethernet',
    duplex                                           = 'full',
    autonegotiation                                  = '1');

status = int_ret1['status']
if (status == '0') :
    print "run sth.interface_config failed"
    print int_ret1
else:
    print "***** run sth.interface_config successfully"


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

time.sleep( 5 )
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

#config part is finished
sth.invoke ('stc::perform saveasxml -filename dhcp_with_traffic.xml')

##############################################################
#Step 7: Start traffic and stop traffic
##############################################################
#start traffic
traffic_ctrl = sth.traffic_control (
    port_handle = 'all',
    action = 'run');
    
status = traffic_ctrl['status']
if (status =='0') :
    print "run sth.traffic_control_start failed"
    print traffic_ctrl
else:
    print "***** run sth.traffic_control_start successfully."

#Stop traffic
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

#Stop capture and get captured pcap file
packet_stats = sth.packet_stats (
    port_handle = 'all',
    action = 'filtered',
    stop = '1',
    format = 'pcap',
    filename = 'dhcp_with_traffic.pcap');
    
packet_info = sth.packet_info (
    port_handle = port_handle[1],
    action = 'status');

##############################################################
#Step 8: Get traffic result
##############################################################
time.sleep( 2 )
traffic_result = sth.traffic_stats (
    port_handle = [port_handle[0],port_handle[1]],
    mode = 'aggregate');

status = traffic_result['status']
if (status =='0') :
    print "run sth.traffic_stats failed"
    print traffic_result
else:
    print "***** run sth.traffic_stats successfully."
    print "aggregate traffic result : ",traffic_result; 

##############################################################
#Step 9: Cleanup sessions and release ports
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
 