#################################
#
# File Name:         HLTAPI_DHCP_Server_relay_agent.py
#
# Description:       This script demonstrates the use of Spirent HLTAPI to setup DHCP Server test.
#                    In this test, DHCP Server assigns ip addresses to DHCP clients in different network through Relay agent.
#
# Test Step:         1. Reserve and connect chassis ports
#                    2. Interface config
#                    3. Config dhcp server host
#                    4. Config dhcp server relay agent pool
#                    5. Config dhcpv4 client 
#                    6. Start dhcp server
#                    7. Bound Dhcp clients
#                    8. Retrive Dhcp session results
#                    9. Stop Dhcp server and client
#                    10. Release resources
#
# DUT configuration:
#
#             ip dhcp relay information option
#             ip dhcp relay information trust-all
#             !
#             interface FastEthernet 1/0
#               ip address 100.1.0.1 255.255.255.0
#               duplex full
#
#            interface FastEthernet 2/0
#              ip address 110.0.0.1 255.255.255.0
#              ip helper-address 100.1.0.8
#              duplex full
#
# Topology
#                 STC Port1        DHCP Relay Agent            STC Port2                       
#             [DHCP Server]---------------[DUT]--------------[DHCP clients]
#                           100.1.0.0/24         110.0.0.0/24    
#                                         
#
#################################

# Run sample:
#            c:>python HLTAPI_DHCP_Server_relay_agent.py 10.61.44.2 3/1 3/3
#           

import sth
import time
from sys import argv

filename,device,port1,port2 = argv
port_list = [port1,port2]
port_handle = []
print port_list

########################################
#Step1: Reserve and connect chassis ports
########################################
intStatus = sth.connect (
    device    = device,
    port_list = port_list);

status = intStatus['status']
i = 0
if (status == '1') :
    for port in port_list :
        port_handle.append(intStatus['port_handle'][device][port])
        print "\n reserved ports",port,":", port_handle[i],": port_handle[%s]" % i
        i += 1
else :
    print "\nFailed to retrieve port handle!\n"
    print port_handle


########################################
# Step2: Interface config
########################################

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
    

########################################
# Step3: Config dhcp server host
########################################

device_ret0 = sth.emulation_dhcp_server_config (
    mode                                             = 'create',
    encapsulation                                    = 'ETHERNET_II',
    ipaddress_count                                  = '245',
    ipaddress_pool                                   = '100.1.0.9',
    ipaddress_increment                              = '1',
    port_handle                                      = port_handle[1],
    lease_time                                       = '60',
    ip_repeat                                        = '0',
    remote_mac                                       = '00:00:01:00:00:01',
    ip_address                                       = '100.1.0.8',
    ip_prefix_length                                 = '24',
    ip_gateway                                       = '100.1.0.1',
    ip_step                                          = '0.0.0.1',
    local_mac                                        = '00:10:94:00:00:02',
    count                                            = '1');

status = device_ret0['status']
if (status == '0') :
    print "run sth.emulation_dhcp_server_config failed"
    print device_ret0
else:
    print "***** run sth.emulation_dhcp_server_config successfully"

dhcpserver_handle = device_ret0['handle']['dhcp_handle']

########################################
# Step4: Config dhcp server relay agent pool
########################################
server_relay_agent_config = sth.emulation_dhcp_server_relay_agent_config (
    mode                                             = 'create',
    handle                                           = dhcpserver_handle,
    relay_agent_ipaddress_pool                       = '110.0.0.5',
    relay_agent_ipaddress_step                       = '0.0.0.1',
    relay_agent_ipaddress_count                      = '50',
    relay_agent_pool_count                           = '2',
    relay_agent_pool_step                            = '1.0.0.0',
    prefix_length                                    = '24');

status = server_relay_agent_config['status']
if (status == '0') :
    print "run sth.emulation_dhcp_server_relay_agent_config failed"
    print server_relay_agent_config
else:
    print "***** run run sth.emulation_dhcp_server_relay_agent_config successfully"


########################################
# Step5: Config dhcpv4 client
########################################

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
    mac_addr                                         = '00.00.10.95.11.15',
    mac_addr_step                                    = '00:00:00:00:00:01',
    num_sessions                                     = '20');


status = device_ret1['status']
if (status == '0') :
    print "run sth.emulation_dhcp_group_config failed"
    print device_ret1
else:
    print "***** run sth.emulation_dhcp_group_config successfully"



#config part is finished
sth.invoke ('stc::perform saveasxml -filename dhcp_server_relay_agent.xml')



########################################
# Step6: Start Dhcp Server 
########################################

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

########################################
# Step7: Bound Dhcp clients
########################################

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

########################################
# Step8: Retrive Dhcp session results
########################################

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


########################################
# Step9: Stop Dhcp server and client
########################################
ctrl_ret1 = sth.emulation_dhcp_server_control (
    port_handle                                      = port_handle[1],
    action                                           = 'reset',
    ip_version                                       = '4');

status = ctrl_ret1['status']
if (status == '0') :
    print "run sth.emulation_dhcp_server_control failed"
    print ctrl_ret1
else:
    print "***** run sth.emulation_dhcp_server_control successfully"

ctrl_ret2 = sth.emulation_dhcp_control (
    port_handle                                      = port_handle[0],
    action                                           = 'release',
    ip_version                                       = '4');

status = ctrl_ret2['status']
if (status == '0') :
    print "run sth.emulation_dhcp_control failed"
    print ctrl_ret2
else:
    print "***** run sth.emulation_dhcp_control successfully"


########################################
#step10: Release resources
########################################
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
 



