#################################
#
# File Name:         HLTAPI_PPPoE_DHCPV6PD_TRAFFIC_B2B.py
#
# Description:       This script demonstrates the use of Spirent HLTAPI to setup PPPoE server and client,DHCPv6-PD server and #                    client,and create/trigger traffic between PPPoE server and client.
#                    
#
# Test Step:         1. Reserve and connect chassis ports
#                    2. Interface config
#                    3. Create pppoe server 
#                    4. Create dhcpv6-pd server
#                    5. Create pppoe client 
#                    6. Create dhcpv6-pd client
#                    7. Create stream block
#                    8. Connect pppoe server and pppoe client
#                    9. Start dhcpv6 server and bind dhcpv6 client
#                    10. Start and stop traffic
#                    11. Get results
#                    12. Release resources
# DUT configuration:
#           none
#
# Topology
#                        [STC Port1]                                   [STC Port2]                     
#                 dhcpv6pd over pppoe device------------------dhcpv6pd over pppoe device
#                        
#                                         
#
#################################

# Run sample:
#            c:>python HLTAPI_PPPoE_DHCPV6PD_TRAFFIC_B2B.py 10.61.44.2 3/1 3/3


import sth
import time
from sys import argv

filename,device,port1,port2 = argv
port_list = [port1,port2]
port_handle = []


#Config the parameters for the logging
test_sta = sth.test_config (
    log                                              = '1',
    logfile                                          = 'pppoe_dhcpv6pd_traffic_logfile',
    vendorlogfile                                    = 'pppoe_dhcpv6pd_traffic_stcExport',
    vendorlog                                        = '1',
    hltlog                                           = '1',
    hltlogfile                                       = 'pppoe_dhcpv6pd_traffic_hltExport',
    hlt2stcmappingfile                               = 'pppoe_dhcpv6pd_traffic_hlt2StcMapping',
    hlt2stcmapping                                   = '1',
    log_level                                        = '7')

status = test_sta['status']
if  status == '0' :
    print "run sth.test_config failed"
    print test_sta
else:
    print "***** run sth.test_config successfully"


########################################
#Step1. Reserve and connect chassis ports
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
        action                                           = 'enable');

status = test_ctrl_sta['status']
if (status == '0') :
    print("run sth.test_control failed")
    print(test_ctrl_sta)
else:
    print("***** run sth.test_control successfully")



##############################################################
# Step2: Config interface
##############################################################

int_ret0 = sth.interface_config (
        mode                                             = 'config',
        port_handle                                      = port_handle[0],
        ipv6_gateway                                     = '1000::2',
        ipv6_intf_addr                                   = '1000::1',
        autonegotiation                                  = '1',
        arp_send_req                                     = '1');

status = int_ret0['status']
if (status == '0') :
    print("run sth.interface_config failed")
    print(int_ret0)
else:
    print("***** run sth.interface_config successfully")

int_ret1 = sth.interface_config (
        mode                                             = 'config',
        port_handle                                      = port_handle[1],
        ipv6_gateway                                     = '1000::1',
        ipv6_intf_addr                                   = '1000::2',
        autonegotiation                                  = '1',
        arp_send_req                                     = '1');

status = int_ret1['status']
if (status == '0') :
    print("run sth.interface_config failed")
    print(int_ret1)
else:
    print("***** run sth.interface_config successfully")


##############################################################
# Step3: create pppoe server 
##############################################################
device_ret0 = sth.pppox_server_config (
        mode                                             = 'create',
        encap                                            = 'ethernet_ii',
        protocol                                         = 'pppoe',
        ipv6_pool_prefix_step                            = '2::',
        ipv6_pool_intf_id_start                          = '::1',
        ipv6_pool_intf_id_step                           = '::2',
        ipv6_pool_addr_count                             = '50',
        ipv6_pool_prefix_len                             = '64',
        ipv6_pool_prefix_start                           = '1000::',
        port_handle                                      = port_handle[0],
        gateway_ipv6_addr                                = '2000::1',
        intf_ipv6_addr_step                              = '::2',
        mac_addr                                         = '00:10:94:01:00:01',
        ip_cp                                            = 'ipv6_cp',
        num_sessions                                     = '1');

status = device_ret0['status']
if (status == '0') :
    print("run sth.pppox_server_config failed")
    print(device_ret0)
else:
    print("***** run sth.pppox_server_config successfully")
    deviceHdlServer = device_ret0['handle']

    
########################################
# Step4: create dhcpv6-pd server
########################################     
device_cfg_ret0 = sth.emulation_dhcp_server_config (
        mode                                             = 'enable',
        handle                                           = deviceHdlServer,
        ip_version                                       = '6',
        encapsulation                                    = 'ethernet_ii',
        preferred_lifetime                               = '604800',
        rebinding_time_percent                           = '80');

status = device_cfg_ret0['status']
if (status == '0') :
    print("run sth.emulation_dhcp_server_config failed")
    print(device_cfg_ret0)
else:
    print("***** run sth.emulation_dhcp_server_config successfully")

########################################
# Step5: create pppoe client 
########################################    
device_ret1 = sth.pppox_config (
        mode                                             = 'create',
        encap                                            = 'ethernet_ii',
        port_handle                                      = port_handle[1],
        protocol                                         = 'pppoe',
        ip_cp                                            = 'ipv6_cp',
        num_sessions                                     = '1',
        auth_mode                                        = 'chap',
        username                                         = 'spirent',
        password                                         = 'spirent',
        mac_addr                                         = '00:10:94:01:00:45',
        mac_addr_step                                    = '00:00:00:00:00:01')

status = device_ret1['status']
if (status == '0') :
    print("run sth.pppox_config failed")
    print(device_ret1)
else:
    print("***** run sth.pppox_config successfully") 
    deviceHdlClient = device_ret1['handle']
    
########################################
# Step6: create dhcpv6-pd client
########################################
device_cfg_ret1port = sth.emulation_dhcp_config (
        mode                                             = 'create',
        ip_version                                       = '6',
        port_handle                                      = port_handle[1],
        dhcp6_renew_rate                                 = '100',
        dhcp6_request_rate                               = '100',
        dhcp6_release_rate                               = '100',
        dhcp6_outstanding_session_count                  = '1');

status = device_cfg_ret1port['status']
if (status == '0') :
    print("run sth.emulation_dhcp_config failed")
    print(device_cfg_ret1port)
else:
    print("***** run sth.emulation_dhcp_config successfully")

device_cfg_ret1 = sth.emulation_dhcp_group_config (
        mode                                             = 'enable',
        handle                                           = deviceHdlClient,
        dhcp_range_ip_type                               = '6',
        dhcp6_client_mode                                = 'DHCPPD',
        num_sessions                                     = '1');

status = device_cfg_ret1['status']
if (status == '0') :
    print("run sth.emulation_dhcp_group_config failed")
    print(device_cfg_ret1)
else:
    print("***** run sth.emulation_dhcp_group_config successfully")
    

##############################################
#step7: create stream block
#############################################    

streamblock = sth.traffic_config (
    mode                                                = 'create',
    port_handle                                         = port_handle[0],
    port_handle2                                        = port_handle[1],
    emulation_src_handle                                = deviceHdlServer,
    emulation_dst_handle                                = deviceHdlClient,
    l3_protocol                                         = 'ipv6',
    l2_encap                                            = 'ethernet_ii',
    ipv6_src_addr                                       = 'aaaa:1::2',
    ipv6_src_mode                                       = 'fixed',
    mac_src                                             = '00.00.02.00.00.01',
    mac_discovery_gw                                    = 'aaaa:1::1');

status = streamblock['status']
if (status =='0') :
    print "run sth.traffic_config failed"
    print streamblock
else:
    print "***** run sth.traffic_config successfully."

#config part is finished
sth.invoke ('stc::perform saveasxml -filename pppoe_dhcpv6pd_traffic.xml')

##############################################################
# step8: connect pppoe server and pppoe client
##############################################################

print 'Connect PPPoE server'

ps_control = sth.pppox_server_control (
    action                                        = 'connect',
    port_handle                                   = port_handle[0])

status = ps_control['status']
if  status == '0' :
    print "run sth.pppox_server_control failed"
    print ps_control
else:
    print '***** run sth.pppox_server_control successfully'


pc_control = sth.pppox_control (
    action                                        = 'connect',
    handle                                        = deviceHdlClient)

status = pc_control['status']
if  status == '0' :
    print "run sth.pppox_control failed"
    print pc_control
else:
    print '***** run sth.pppox_control successfully'

time.sleep (10)
#################################################
#step9: start dhcpv6 server and bind dhcpv6 client
#################################################

ctrl_ret3 = sth.emulation_dhcp_server_control (
        port_handle                                      = port_handle[0],
        action                                           = 'connect',
        ip_version                                       = '6');

status = ctrl_ret3['status']
if (status == '0') :
    print("run sth.emulation_dhcp_server_control failed")
    print(ctrl_ret3)
else:
    print("***** run sth.emulation_dhcp_server_control successfully")

ctrl_ret4 = sth.emulation_dhcp_control (
        port_handle                                      = port_handle[1],
        action                                           = 'bind',
        ip_version                                       = '6');

status = ctrl_ret4['status']
if (status == '0') :
    print("run sth.emulation_dhcp_control failed")
    print(ctrl_ret4)
else:
    print("***** run sth.emulation_dhcp_control successfully")
    
########################################
#step10: start and stop traffic
########################################    
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


##############################################################
# step11: get results
##############################################################
results_ret1 = sth.pppox_server_stats (
        port_handle                                           = port_handle[0],
        mode                                                  = 'aggregate');

status = results_ret1['status']
if (status == '0') :
    print("run sth.pppox_server_stats failed")
    print(results_ret1)
else:
    print("***** run sth.pppox_server_stats successfully, and results is:")
    print(results_ret1)


results_ret3 = sth.pppox_stats (
        handle                                           = deviceHdlClient,
        mode                                             = 'session');

status = results_ret3['status']
if (status == '0') :
    print("run sth.pppox_stats failed")
    print(results_ret3)
else:
    print("***** run sth.pppox_stats successfully, and results is:")
    print(results_ret3)

results_ret5 = sth.emulation_dhcp_server_stats (
        port_handle                                      = port_handle[0],
        action                                           = 'COLLECT',
        ip_version                                       = '6');

status = results_ret5['status']
if (status == '0') :
    print("run sth.emulation_dhcp_server_stats failed")
    print(results_ret5)
else:
    print("***** run sth.emulation_dhcp_server_stats successfully, and results is:")
    print(results_ret5)

results_ret6 = sth.emulation_dhcp_stats (
        port_handle                                      = port_handle[1],
        action                                           = 'collect',
        mode                                             = 'detailed_session',
        ip_version                                       = '6');

status = results_ret6['status']
if (status == '0') :
    print("run sth.emulation_dhcp_stats failed")
    print(results_ret6)
else:
    print("***** run sth.emulation_dhcp_stats successfully, and results is:")
    print(results_ret6)
    
time.sleep( 2 )
traffic_result = sth.traffic_stats (
    port_handle = [port_handle[0],port_handle[1]],
    mode = 'aggregate');

status = traffic_result['status']
if (status =='0') :
    print "run sth.traffic_stats failed"
    print traffic_result
else:
    print "***** run sth.traffic_stats successfully, and results is:"
    print "aggregate traffic result : ",traffic_result; 


##############################################################
# step12: Release resources
##############################################################

cleanup_sta = sth.cleanup_session (
        port_handle                                      = [port_handle[0],port_handle[1]],
        clean_dbfile                                     = '1');

status = cleanup_sta['status']
if (status == '0') :
    print("run sth.cleanup_session failed")
    print(cleanup_sta)
else:
    print("***** run sth.cleanup_session successfully")


print("**************Finish***************")
