################################################################################
#
# File Name:         HLTAPI_DHCPv6_basic.py
#
# Description:       This script demonstrates the use of Spirent HLTAPI to setup DHCPv6 Client/Server test.
#                    In this test, DHCP Server and clients are emulated in back-to-back mode.
#
# Test Step:         1. Reserve and connect chassis ports
#                    2. Interface config
#                    3. Config dhcpv6 server host
#                    4. Config dhcpv6 client 
#                    5. Start dhcpv6 server
#                    6. Bound Dhcpv6 clients
#                    7  Retrive Dhcpv6 session results
#                    8. Stop Dhcpv6 server and client
#                    9. Release resources
#
#
# Topology
#                   STC Port1                      STC Port2                       
#                [DHCPv6 Server]------------------[DHCPv6 clients]
#                                              
#                                         
#
################################################################################

# Run sample:
#            c:>python HLTAPI_DHCPv6_basic.py 10.61.44.2 3/1 3/3


import sth
import time
from sys import argv

filename,device,port1,port2 = argv
port_list = [port1,port2]
port_handle = []
print port_list

#Config the parameters for the logging
test_sta = sth.test_config (
    log                                              = '1',
    logfile                                          = 'dhcpv6_logfile',
    vendorlogfile                                    = 'dhcpv6_stcExport',
    vendorlog                                        = '1',
    hltlog                                           = '1',
    hltlogfile                                       = 'dhcpv6_hltExport',
    hlt2stcmappingfile                               = 'dhcpv6_hlt2StcMapping',
    hlt2stcmapping                                   = '1',
    log_level                                        = '7');

status = test_sta['status']
if (status == '0') :
    print "run sth.test_config failed"
    print test_sta
else:
    print "***** run sth.test_config successfully"

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
    


#########################################
## Step3: Config dhcpv6 server host
#########################################
device_ret0 = sth.emulation_dhcp_server_config (
    mode                                             = 'create',
    encapsulation                                    = 'ethernet_ii',
    port_handle                                      = port_handle[1],
    ip_version                                       = '6',
    server_emulation_mode                            = 'DHCPV6',
    local_ipv6_addr                                  = '2012::2',
    gateway_ipv6_addr                                = '2012::1',
    prefix_pool_start_addr                           = '2002::1');

status = device_ret0['status']
if (status == '0') :
    print "run sth.emulation_dhcp_server_config failed"
    print device_ret0
else:
    print "***** run sth.emulation_dhcp_server_config successfully"

dhcpserver_handle = device_ret0['handle']['dhcpv6_handle']

#########################################
## Step4: Config dhcpv6 client
#########################################

device_ret1port = sth.emulation_dhcp_config (
    mode                                             = 'create',
    ip_version                                       = '6',
    port_handle                                      = port_handle[0],
    dhcp6_outstanding_session_count                 = '1',
    dhcp6_release_rate                               = '100',
    dhcp6_request_rate                               = '100',
    dhcp6_renew_rate                                 = '100');

status = device_ret1port['status']
if (status == '0') :
    print "run sth.emulation_dhcp_config failed"
    print device_ret1port
else:
    print "***** run sth.emulation_dhcp_config successfully"

dhcp_handle = device_ret1port['handles']


device_ret1 = sth.emulation_dhcp_group_config (
    mode                                             = 'create',
    dhcp_range_ip_type                               = '6',
    dhcp6_client_mode                                = 'DHCPV6',
    encap                                            = 'ethernet_ii',
    handle                                           = dhcp_handle,
    mac_addr                                         = '00.00.10.95.11.15',
    mac_addr_step                                    = '00:00:00:00:00:01',
    num_sessions                                     = '20',
    local_ipv6_addr                                  = '2009::2',
    gateway_ipv6_addr                                = '2005::1');


status = device_ret1['status']
if (status == '0') :
    print "run sth.emulation_dhcp_group_config failed"
    print device_ret1
else:
    print "***** run sth.emulation_dhcp_group_config successfully"

#config part is finished
sth.invoke ('stc::perform saveasxml -filename dhcpv6_basic.xml')


#########################################
## Step5: Start Dhcp Server 
#########################################
ctrl_ret1 = sth.emulation_dhcp_server_control (
    port_handle                                      = port_handle[1],
    action                                           = 'connect',
    ip_version                                       = '6');

status = ctrl_ret1['status']
if (status == '0') :
    print "run sth.emulation_dhcp_server_control failed"
    print ctrl_ret1
else:
    print "***** run sth.emulation_dhcp_server_control successfully"


#########################################
## Step6: Bound Dhcp clients
#########################################
ctrl_ret2 = sth.emulation_dhcp_control (
    port_handle                                      = port_handle[0],
    action                                           = 'bind',
    ip_version                                       = '6');

status = ctrl_ret2['status']
if (status == '0') :
    print "run sth.emulation_dhcp_control failed"
    print ctrl_ret2
else:
    print "***** run sth.emulation_dhcp_control successfully"


time.sleep( 30 )
print "Wait for 30 secs till all the clients are assigned with valid ipv6 addresses...........\n"


############################################################
## Step7: Retrive Dhcpv6 Client and Server results
############################################################

results_ret1 = sth.emulation_dhcp_server_stats (
    port_handle                                      = port_handle[1],
    action                                           = 'COLLECT',
    ip_version                                       = '6');

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
    ip_version                                       = '6');

status = results_ret2['status']
if (status == '0') :
    print "run sth.emulation_dhcp_stats failed"
    print results_ret2
else:
    print "***** run sth.emulation_dhcp_stats successfully, and results is:"
    print  results_ret2;


#########################################
## Step8: Stop Dhcpv6 server and client
#########################################

ctrl_ret1 = sth.emulation_dhcp_server_control (
    port_handle                                      = port_handle[1],
    action                                           = 'reset',
    ip_version                                       = '6');

status = ctrl_ret1['status']
if (status == '0') :
    print "run sth.emulation_dhcp_server_control_stop failed"
    print ctrl_ret1
else:
    print "***** run sth.emulation_dhcp_server_control_stop successfully"

ctrl_ret2 = sth.emulation_dhcp_control (
    port_handle                                      = port_handle[0],
    action                                           = 'release',
    ip_version                                       = '6');

status = ctrl_ret2['status']
if (status == '0') :
    print "run sth.emulation_dhcp_control failed"
    print ctrl_ret2
else:
    print "***** run sth.emulation_dhcp_control_stop successfully"


########################################
#step9: Release resources
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
 