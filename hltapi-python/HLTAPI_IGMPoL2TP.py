################################################################################
#
# File Name:         HLTAPI_IGMPoL2TP.py
#
# Description:       This script demonstrates the use of Spirent HLTAPI to setup IGMP over L2TP test.
#
# Test Steps:         1. Reserve and connect chassis ports
#                     2. Configure LAC on port1
#                     3. Enable IGMP on LAC 
#                     4. Configure multicast group
#                     5. Bound the IGMP and the Multicast Group
#                     6. Configure downstream traffic : port2 -> port1
#                     7. Join IGMP to multicast group
#                     8. Get IGMP Stats
#                     9. Start capture
#                    10. Start traffic
#                    11. Stop traffic
#                    12. Stop and save capture
#                    13. Verify interface stats
#                    14. Configure IGMP Host leave from Multicast Group
#                    15. Start traffic again
#                    16. Verify port stats after IGMP host leaving multicast group
#                    17. Release resources
#
# Topology:
#                LAC(STC port1)----------------DUT------------IPv4 Host(STC port2)
#                   172.16.0.2       172.16.0.1   172.17.0.1      172.17.0.2
# DUT Config:
#    vpdn enable
#    vpdn-group 1
#     accept dialin l2tp virtual-template 10 remote HosLAC
#     local name HosLNS
#     no l2tp tunnel authentication
#     l2tp tunnel receive-window 1024
#     l2tp tunnel framing capabilities all
#     l2tp tunnel bearer capabilities all
#    
#    ip local pool rui_ippool 10.88.55.1 10.88.55.10
#    
#    interface virtual-template 10
#     ip address 10.88.55.11 255.255.255.0
#     peer default ip address pool rui_ippool
#     no ppp authentication
#     ppp timeout idle 42000
#                                              
################################################################################
# 
# Run sample:
#            c:\>python HLTAPI_IGMPoL2TP.py 10.61.44.2 1/1 1/2

import sth
import time
from sys import argv
filename,device,port1,port2 = argv
port_list = [port1,port2]
port_handle = []

#Config the parameters for the logging
test_sta = sth.test_config (
    log                                              = '1',
    logfile                                          = 'HLTAPI_IGMPoL2TP_logfile',
    vendorlogfile                                    = 'HLTAPI_IGMPoL2TP_stcExport',
    vendorlog                                        = '1',
    hltlog                                           = '1',
    hltlogfile                                       = 'HLTAPI_IGMPoL2TP_hltExport',
    hlt2stcmappingfile                               = 'HLTAPI_IGMPoL2TP_hlt2StcMapping',
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
# Step 2. Configure LAC on port1
##############################################################
print "Create LAC on port1"
device_lac = sth.l2tp_config (
        mode                                             = 'lac',
        port_handle                                      = port_handle[0],
        hostname                                         = 'HosLAC',
        auth_mode                                        = 'none',
        l2_encap                                         = 'ethernet_ii',
        l2tp_src_addr                                    = '172.16.0.2',
        l2tp_dst_addr                                    = '172.16.0.1',
        num_tunnels                                      = '1',
        sessions_per_tunnel                              = '1',
        hello_interval                                   = '255',
        hello_req                                        = 'TRUE',
        redial_timeout                                   = '10',
        redial_max                                       = '3')

        
status = device_lac['status']
if (status == '0') :
    print("run sth.l2tp_config failed")
    print(device_lac)
else:
    print("***** run sth.l2tp_config successfully")

lac_handles = device_lac['handles']

##############################################################
# Step 2. Connect LAC and get LAC stats
##############################################################
print "Connect LAC"
lac_connect = sth.l2tp_control (
    handle                                               = lac_handles,
    action                                                  = 'connect')

status = lac_connect['status']
if (status == '0') :
    print("run sth.l2tp_control failed")
    print(lac_connect)
else:
    print("***** run sth.l2tp_control successfully")
    print(lac_connect)
    

print "Get l2tp LAC stats"
lac_stats = sth.l2tp_stats (
    handle                                               = lac_handles,
    mode                                                  = 'aggregate')

status = lac_stats['status']
if (status == '0') :
    print("run sth.l2tp_stats failed")
    print(lac_stats)
else:
    print("***** run sth.l2tp_stats successfully")
    print(lac_stats)

##############################################################
# Step 3. Enable IGMP on LAC 
##############################################################
print "Enable IGMP on LAC"
device_igmp = sth.emulation_igmp_config (
        mode                                             = 'create',
        handle                                           = lac_handles,
        older_version_timeout                            = '400',
        robustness                                       = '2',
        unsolicited_report_interval                      = '10',
        igmp_version                                     = 'v3');

status = device_igmp['status']
if (status == '0') :
    print("run sth.emulation_igmp_config failed")
    print(device_igmp)
else:
    print("***** run sth.emulation_igmp_config successfully")
    print(device_igmp)

igmpSession = device_igmp['handle']

##############################################################
# Step 4. Configure multicast group
##############################################################
print "Configure multicast group"
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
    print(groupStatus)
    
igmpGroup = groupStatus['handle']

##############################################################
# Step 5. Bound the IGMP and the Multicast Group
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
    
##############################################################
# Step 6. Configure downstream traffic : port2 -> port1
##############################################################
print "Configure downstream traffic : port2 -> port1"
streamblock = sth.traffic_config (
        mode                                             = 'create',
        port_handle                                      = port_handle[1],
        rate_pps                                         = '1000',
        l2_encap                                         = 'ethernet_ii',
        l3_protocol                                      = 'ipv4',
        l3_length                                        = '108',
        transmit_mode                                    = 'continuous',
        length_mode                                      = 'fixed',
        ip_src_addr                                      = '172.17.0.2',
        ip_dst_addr                                      = '225.0.0.25',
        mac_src                                          = '00:10:94:00:00:11',
        mac_dst                                          = '01.00.5E.00.00.11')
        
status = streamblock['status']
if (status == '0') :
    print("run sth.traffic_config failed")
    print(streamblock)
else:
    print("***** run sth.traffic_config successfully")
    print(streamblock)

##############################################################
# Step 7. Join IGMP to multicast group
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

#config part is finished
sth.invoke ('stc::perform saveasxml -filename igmpol2tp.xml')
##############################################################
# Step 8. Get IGMP Stats
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
# Step 9. Start capture
##############################################################
print "Start capture"
packet_control = sth.packet_control (
    port_handle                                          = 'all',
    action                                                  = 'start')

##############################################################
# Step 10. Start traffic
##############################################################
print "Start traffic on all ports"
traffic_ctrl_ret = sth.traffic_control (
        port_handle                                      = [port_handle[0],port_handle[1]],
        action                                           = 'run');

status = traffic_ctrl_ret['status']
if (status == '0') :
    print("run sth.traffic_control failed")
    print(traffic_ctrl_ret)
else:
    print("***** run sth.traffic_control successfully")
    print(traffic_ctrl_ret)

##############################################################
# Step 11. Stop traffic
##############################################################
print "Stop traffic"
traffic_ctrl_ret = sth.traffic_control (
        port_handle                                      = [port_handle[0],port_handle[1]],
        action                                           = 'stop');

status = traffic_ctrl_ret['status']
if (status == '0') :
    print("stop sth.traffic_control failed")
    print(traffic_ctrl_ret)
else:
    print("***** stop sth.traffic_control successfully")
    print(traffic_ctrl_ret)

##############################################################
# Step 12. Stop and save capture
##############################################################
print "Stop and save capture"
packet_stats1 = sth.packet_stats (
    port_handle = port_handle[0],
    action = 'filtered',
    stop = '1',
    format = 'pcap',
    filename = 'igmpol2tp_port1.pcap');
    
##############################################################
# Step 13. Verify interface stats
##############################################################
print "Verify interface stats"
port2_stats = sth.interface_stats (
    port_handle                                          = port_handle[1])

print "port2 stats : %s " % port2_stats
port2_Tx = port2_stats['tx_generator_ipv4_frame_count']
port2_Rx = port2_stats['rx_sig_count']
print "port2_Tx : %s" % port2_Tx
print "port2_Rx : %s" % port2_Rx

port1_stats = sth.interface_stats (
    port_handle                                          = port_handle[0])

print "port1 stats : %s " % port1_stats
port1_Tx = port1_stats['tx_generator_ipv4_frame_count']
port1_Rx = port1_stats['rx_sig_count']
print "port1_Tx : %s" % port1_Tx
print "port1_Rx : %s" % port1_Rx

##############################################################
# Step 14. Configure IGMP Host leave from Multicast Group
##############################################################
print " Leave IGMP Hosts from the Multicast Group"
leaveStatus = sth.emulation_igmp_control (
        handle                                           = igmpSession,
        mode                                             = 'leave');

status = leaveStatus['status']
if (status == '0') :
    print("***** IGMP Hosts left IGMP group failed")
    print(leaveStatus)
else:
    print("***** IGMP Hosts left IGMP group successfully")

##############################################################
# Step 15. Start traffic again
##############################################################   
print "Start traffic again" 
traffic_ctrl_ret = sth.traffic_control (
        port_handle                                      = [port_handle[0],port_handle[1]],
        action                                           = 'run');

status = traffic_ctrl_ret['status']
if (status == '0') :
    print("run sth.traffic_control failed")
    print(traffic_ctrl_ret)
else:
    print("***** run sth.traffic_control successfully")
    
##############################################################
# Step 16. Verify port stats after IGMP host leaving multicast group
############################################################## 
print "Verify port stats after IGMP host leaving multicast group"
port2_stats = sth.interface_stats (
    port_handle                                          = port_handle[1])

print "port2 stats : %s " % port2_stats
port2_Tx = port2_stats['tx_generator_ipv4_frame_count']
port2_Rx = port2_stats['rx_sig_count']
print "port2_Tx : %s" % port2_Tx
print "port2_Rx : %s" % port2_Rx

port1_stats = sth.interface_stats (
    port_handle                                          = port_handle[0])

print "port1 stats : %s " % port1_stats
port1_Tx = port1_stats['tx_generator_ipv4_frame_count']
port1_Rx = port1_stats['rx_sig_count']
print "port1_Tx : %s" % port1_Tx
print "port1_Rx : %s" % port1_Rx   

##############################################################
# Step 17. Release resources
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