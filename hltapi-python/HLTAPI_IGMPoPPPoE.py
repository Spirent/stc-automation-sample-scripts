################################################################################
#
# File Name:         HLTAPI_IGMPoPPPoE.py
#
# Description:       This script demonstrates the use of Spirent HLTAPI to setup IGMP over PPPoE.
#
# Test Steps:        1. Reserve and connect chassis ports
#                    2. Configure interface on port2
#                    3. Connect PPPoE on port1
#                    4. Configure IGMP over PPPoE on Port1
#                    5. Configure Multicast group
#                    6. Bound the IGMP and the Multicast Group
#                    7. Connect PPPoE client and check status
#                    8. Join IGMP to multicast group
#                    9. Get IGMP Stats
#                    10. Setup ipv4 multicast traffic
#                    11. Start capture
#                    12. Start traffic
#                    13. Stop traffic
#                    14. Stop and save capture
#                    15. Get traffic statistics
#                    16. Release resources
#
# Topology:
#               IGMPoPPPoE Client        PTA                Host
#                   STC port1  --------- DUT ----------- STC port2 
# 
################################################################################
# 
# Run sample:
#            c:\>python HLTAPI_IGMPoPPPoE.py 10.61.44.2 1/1 1/2

import sth
import time
from sys import argv
filename,device,port1,port2 = argv
port_list = [port1,port2]
port_handle = []

#Config the parameters for the logging
test_sta = sth.test_config (
    log                                              = '1',
    logfile                                          = 'HLTAPI_IGMPoPPPoE_logfile',
    vendorlogfile                                    = 'HLTAPI_IGMPoPPPoE_stcExport',
    vendorlog                                        = '1',
    hltlog                                           = '1',
    hltlogfile                                       = 'HLTAPI_IGMPoPPPoE_hltExport',
    hlt2stcmappingfile                               = 'HHLTAPI_IGMPoPPPoE_hlt2StcMapping',
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
        action                                           = 'enable');

status = test_ctrl_sta['status']
if (status == '0') :
    print("run sth.test_control failed")
    print(test_ctrl_sta)
else:
    print("***** run sth.test_control successfully")
    
    
##############################################################
# Step 2. Configure interface on port2
##############################################################
print "Configure interface on port2"
int_ret1 = sth.interface_config (
        mode                                             = 'config',
        port_handle                                      = port_handle[1],
        intf_ip_addr                                     = '20.0.0.2',
        autonegotiation                                  = '1',
        gateway                                          = '20.0.0.1',
        arp_send_req                                     = '1',
        arp_req_retries                                  = '10');

status = int_ret1['status']
if (status == '0') :
    print("run sth.interface_config failed")
    print(int_ret1)
else:
    print("***** run sth.interface_config successfully")
    print(int_ret1)

##############################################################
# Step 3. Connect PPPoE on port1
##############################################################
print "Connect PPPoE on port1"
device_ret0 = sth.pppox_config (
        mode                                             = 'create',
        encap                                            = 'ethernet_ii',
        protocol                                         = 'pppoe',
        ip_cp                                            = 'ipv4_cp',
        port_handle                                      = port_handle[0],
        username                                         = 'spirent',
        password                                         = 'spirent',
        num_sessions                                     = '1',
        auth_mode                                        = 'chap',
        chap_ack_timeout                                 = '10',
        config_req_timeout                               = '10',
        ipcp_req_timeout                                 = '10',
        auto_retry                                       = '1',
        max_auto_retry_count                             = '10',
        max_echo_acks                                    = '10',
        max_ipcp_req                                     = '10')
        
status = device_ret0['status']
if (status == '0') :
    print("run sth.pppox_config failed")
    print(device_ret0)
else:
    print("***** run sth.pppox_config successfully")

pppox_handles = device_ret0['handles']

##############################################################
# Step 4. Configure IGMP over PPPoE on Port1
##############################################################
print "Config IGMP over PPPoE on Port1"

device_cfg_ret0 = sth.emulation_igmp_config (
        mode                                             = 'create',
        handle                                           = pppox_handles,
        igmp_version                                     = 'v2',
        robustness                                       = '2',
        older_version_timeout                            = '400',
        unsolicited_report_interval                      = '10');

status = device_cfg_ret0['status']
if (status == '0') :
    print("run sth.emulation_igmp_config failed")
    print(device_cfg_ret0)
else:
    print("***** run sth.emulation_igmp_config successfully")

igmpSession = device_cfg_ret0['handle']
    
##############################################################
# Step 5. Configure Multicast group
##############################################################
print "Configure Multicast group"
groupStatus = sth.emulation_multicast_group_config (
        ip_addr_start                                    = '225.0.0.25',
        mode                                             = 'create',
        num_groups                                       = '1')
        
status = groupStatus['status']
if (status == '0') :
    print("***** Created Multicast Group failed")
    print(groupStatus)
else:
    print("***** Created Multicast Group successfully")
    
igmpGroup = groupStatus['handle']

##############################################################
# Step 6. Bound the IGMP and the Multicast Group
##############################################################
print "Bound IGMP to multicast group"
membershipStatus = sth.emulation_igmp_group_config (
        session_handle                                   = igmpSession,
        mode                                             = 'create',
        group_pool_handle                                = igmpGroup);

status = membershipStatus['status']
if (status == '0') :
    print("***** Bound the IGMP and the Multicast Group failed")
    print(membershipStatus)
else:
    print("***** Bound the IGMP and the Multicast Group successfully")
    print(membershipStatus)
 

#config part is finished
sth.invoke ('stc::perform saveasxml -filename igmpopppoe.xml')

##############################################################
# Step 7. Connect PPPoE client and check status
##############################################################
print "Connect PPPoE client"
pc_control = sth.pppox_control (
    action                                        = 'connect',
    handle                                        = pppox_handles)

status = pc_control['status']
if  status == '0' :
    print "run sth.pppox_control failed"
    print pc_control
else:
    print '***** run sth.pppox_control successfully'

time.sleep (60)

print "Check PPPoE client status"
    
pc_status = sth.pppox_stats (
        handle                                           = pppox_handles,
        mode                                             = 'aggregate');

status = pc_status['status']
if (status == '0') :
    print("run sth.pppox_stats failed")
    print(pc_status)
else:
    print("***** run sth.pppox_stats successfully, and results is:")
    print(pc_status)

##############################################################
# Step 8. Join IGMP to multicast group
##############################################################
print "Join IGMP to multicast group"
joinStatus = sth.emulation_igmp_control (
        handle                                           = igmpSession,
        mode                                             = 'join');

status = joinStatus['status']
if (status == '0') :
    print("Join IGMP to multicast group failed")
    print(joinStatus)
else:
    print("***** Join IGMP to multicast group successfully")
    print(joinStatus)

time.sleep(5)
##############################################################
# Step 9. Get IGMP Stats
##############################################################
print "get IGMP stats"
results_hosts = sth.emulation_igmp_info (
        handle                                           = igmpSession,
        mode                                             = 'stats');

status = results_hosts['status']
if (status == '0') :
    print("run sth.emulation_igmp_host_info failed")
    print(results_hosts)
else:
    print("***** run sth.emulation_igmp_host_info successfully, and results is:")
    print(results_hosts)

##############################################################
# Step 10. Setup ipv4 multicast traffic
##############################################################    
print "Setup ipv4 multicast traffic"
streamblock = sth.traffic_config (
        mode                                             = 'create',
        port_handle                                      = port_handle[1],
        rate_pps                                         = '1000',
        l2_encap                                         = 'ethernet_ii',
        l3_protocol                                      = 'ipv4',
        l3_length                                        = '128',
        transmit_mode                                    = 'continuous',
        length_mode                                      = 'fixed',
        ip_src_addr                                      = '20.0.0.2',
        emulation_dst_handle                             = igmpGroup)
        
status = streamblock['status']
if (status == '0') :
    print("run sth.traffic_config failed")
    print(streamblock)
else:
    print("***** run sth.traffic_config successfully")
    print(streamblock)

stream_down_id = streamblock['stream_id']

##############################################################
# Step 11. Start capture
##############################################################
print "Start capture"
packet_control = sth.packet_control (
    port_handle                                          = 'all',
    action                                               = 'start')

##############################################################
# Step 12. Start traffic
##############################################################
print "Start traffic on port2"
traffic_ctrl_ret = sth.traffic_control (
        port_handle                                      = port_handle[1],
        action                                           = 'run');

status = traffic_ctrl_ret['status']
if (status == '0') :
    print("run sth.traffic_control failed")
    print(traffic_ctrl_ret)
else:
    print("***** run sth.traffic_control successfully")
    print(traffic_ctrl_ret)

time.sleep (10)
##############################################################
# Step 13. Stop traffic
##############################################################
print "Stop traffic"
traffic_ctrl_ret = sth.traffic_control (
        port_handle                                      = [port_handle[1]],
        action                                           = 'stop');

status = traffic_ctrl_ret['status']
if (status == '0') :
    print("stop sth.traffic_control failed")
    print(traffic_ctrl_ret)
else:
    print("***** stop sth.traffic_control successfully")
    print(traffic_ctrl_ret)

##############################################################
# Step 14. Stop and save capture
##############################################################
print "Stop and save capture"
packet_stats1 = sth.packet_stats (
    port_handle = port_handle[0],
    action = 'filtered',
    stop = '1',
    format = 'pcap',
    filename = 'IGMPoPPPoE_port1.pcap');
    
##############################################################
# Step 15. Get traffic statistics
##############################################################
print "Get traffic statistics"
traffic_stats = sth.traffic_stats (
    streams                                              = stream_down_id,
    mode                                                 = 'streams')
    
Rx_Rate = traffic_stats['port2']['stream'][stream_down_id]['rx']['total_pkt_rate']
Tx_Rate = traffic_stats['port2']['stream'][stream_down_id]['tx']['total_pkt_rate']
print "IPv4 Upstream:"
print "\tTx_Rate : -------------------------- %s" % Tx_Rate
print "\tRx_Rate : -------------------------- %s" % Rx_Rate

##############################################################
# Step 16. Release resources
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