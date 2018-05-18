################################################################################
#
# File Name:                 HLTAPI_InterfaceConfig_SubInterface.py
#
# Description:   Allow interface_config to config subinterfaces. The following options have been added:
#           vlan
#           vlan_id
#           vlan_cfi
#           vlan_id_count
#           vlan_id_step
#           vlan_user_priority
#           qinq_incr_mode
#           vlan_outer_id
#           vlan_outer_cfi
#           vlan_outer_count
#           vlan_outer_id_step
#           vlan_outer_user_priority
#           gateway_step
#           ipv6_gateway_step
#           intf_ip_addr_step
#           ipv6_intf_addr_step
#           src_mac_addr_step
#
# Test steps:               
#                        1. Reserve and connect chassis ports
#                        2. Configure interface on two ports
#                        3. Configure streamblock on two ports
#                        4. Start capture
#                        5. Start traffic
#                        6. Stop traffic
#                        7. Stop and save capture
#                        8. Get traffic statistics
#                        9. Release resources
#
# Topology:
#                 10.21.0.2                   10.21.0.1
#                 10.22.0.2                   10.22.0.1
#                (STC Port1) -------------------(DUT) 11.55.0.1------------11.55.0.2 (STC Port2)
#                 10.23.0.2                   10.23.0.1
#                 10.24.0.2                   10.24.0.1
#
#
################################################################################
# 
# Run sample:
#            c:>python HLTAPI_InterfaceConfig_SubInterface.py 10.61.44.2 3/1 3/3

import sth
import time
from sys import argv
filename,device,port1,port2 = argv
port_list = [port1,port2]
port_handle = []

#Config the parameters for the logging
test_sta = sth.test_config (
    log                                              = '1',
    logfile                                          = 'HLTAPI_InterfaceConfig_SubInterface_logfile',
    vendorlogfile                                    = 'HLTAPI_InterfaceConfig_SubInterface_stcExport',
    vendorlog                                        = '1',
    hltlog                                           = '1',
    hltlogfile                                       = 'HLTAPI_InterfaceConfig_SubInterface_hltExport',
    hlt2stcmappingfile                               = 'HHLTAPI_InterfaceConfig_SubInterface_hlt2StcMapping',
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
#Step2. Configure interface on two ports
##############################################################
print "Configure interface on port1"

int_ret0 = sth.interface_config (
        mode                                             = 'config',
        port_handle                                      = port_handle[0],
        intf_ip_addr                                     = '10.21.0.2',
        intf_ip_addr_step                                = '0.1.0.0',
        gateway                                          = '10.21.0.1',
        gateway_step                                     = '0.1.0.0',
        autonegotiation                                  = '1',
        arp_send_req                                     = '1',
        arp_req_retries                                  = '10',
        phy_mode                                         = 'fiber',
        vlan_id                                          = '4',
        vlan_id_count                                    = '4',
        vlan                                             = '1')
        
status = int_ret0['status']
if (status == '0') :
    print("run sth.interface_config failed")
    print(int_ret0)
else:
    print("***** run sth.interface_config successfully")
    print int_ret0
    
print "Configure interface on port2"

int_ret1 = sth.interface_config (
        mode                                             = 'config',
        port_handle                                      = port_handle[1],
        intf_ip_addr                                     = '11.55.0.2',
        intf_ip_addr_step                                = '0.1.0.0',
        gateway                                          = '11.55.0.1',
        autonegotiation                                  = '1',
        arp_send_req                                     = '1',
        arp_req_retries                                  = '10',
        phy_mode                                         = 'fiber')
        
status = int_ret1['status']
if (status == '0') :
    print("run sth.interface_config failed")
    print(int_ret1)
else:
    print("***** run sth.interface_config successfully")
    print int_ret1

##############################################################
#Step3. Configure streamblock on two ports
##############################################################
print "Configure streamblock on port1 : port1 -> port2"
streamblock_ret1 = sth.traffic_config (
        mode                                             = 'create',
        port_handle                                      = port_handle[0],
        l2_encap                                         = 'ethernet_ii_vlan',
        l3_protocol                                      = 'ipv4',
        vlan_id                                          = '4',
        vlan_id_count                                    = '4',
        l3_length                                        = '108',
        transmit_mode                                    = 'continuous',
        length_mode                                      = 'fixed',
        ip_src_addr                                      = '10.21.0.2',
        ip_dst_addr                                      = '11.55.0.2',
        mac_discovery_gw                                 = '10.21.0.1',
        mac_discovery_gw_step                            = '0.1.0.0',
        mac_discovery_gw_count                           = '4',
        ip_src_step                                      = '0.1.0.0',
        ip_src_count                                     = '4',
        ip_dst_count                                     = '2')
                
status = streamblock_ret1['status']
if (status == '0') :
    print("run sth.traffic_config failed")
    print(streamblock_ret1)
else:
    print("***** run sth.traffic_config successfully")

print "Configure streamblock on port2 : port2 -> port1"

streamblock_ret2 = sth.traffic_config (
        mode                                             = 'create',
        port_handle                                      = port_handle[1],
        l2_encap                                         = 'ethernet_ii',
        l3_protocol                                      = 'ipv4',
        rate_pps                                         = '1000',
        l3_length                                        = '108',
        transmit_mode                                    = 'continuous',
        length_mode                                      = 'fixed',
        ip_src_addr                                      = '11.55.0.2',
        ip_dst_addr                                      = '10.21.0.2',
        ip_dst_count                                     = '4',
        ip_src_count                                     = '2',
        mac_discovery_gw                                 = '11.55.0.1')
        
status = streamblock_ret2['status']
if (status == '0') :
    print("run sth.traffic_config failed")
    print(streamblock_ret2)
else:
    print("***** run sth.traffic_config successfully")

#config part is finished
sth.invoke ('stc::perform saveasxml -filename interfaceconfig_subinterface.xml')

##############################################################
# Step4. Start capture
##############################################################
print "Start capture"
packet_control = sth.packet_control (
    port_handle                                          = 'all',
    action                                               = 'start')

##############################################################
# Step5. Start traffic
##############################################################
print "Start traffic on port1 and port2"
traffic_ctrl_ret = sth.traffic_control (
        port_handle                                      = 'all',
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
# Step6. Stop traffic
##############################################################
print "Stop traffic"
traffic_ctrl_ret = sth.traffic_control (
        port_handle                                      = 'all',
        action                                           = 'stop');

status = traffic_ctrl_ret['status']
if (status == '0') :
    print("stop sth.traffic_control failed")
    print(traffic_ctrl_ret)
else:
    print("***** stop sth.traffic_control successfully")
    print(traffic_ctrl_ret)

##############################################################
# Step7. Stop and save capture
##############################################################
print "Stop and save capture"
packet_stats1 = sth.packet_stats (
    port_handle = port_handle[0],
    action = 'filtered',
    stop = '1',
    format = 'pcap',
    filename = 'sub_port1.pcap')
    
packet_stats1 = sth.packet_stats (
    port_handle = port_handle[1],
    action = 'filtered',
    stop = '1',
    format = 'pcap',
    filename = 'sub_port2.pcap');
    
##############################################################
# Step8. Get traffic statistics
##############################################################
print "Get traffic statistics of port2"

port2_stats = sth.interface_stats (
    port_handle                                          = port_handle[1])

print "port2 stats : %s " % port2_stats
port2_Tx = port2_stats['tx_generator_ipv4_frame_count']
port2_Rx = port2_stats['rx_sig_count']
print "port2_Tx : %s" % port2_Tx
print "port2_Rx : %s" % port2_Rx

print "Get traffic statistics of port1"

port1_stats = sth.interface_stats (
    port_handle                                          = port_handle[0])

print "port1 stats : %s " % port1_stats
port1_Tx = port1_stats['tx_generator_ipv4_frame_count']
port1_Rx = port1_stats['rx_sig_count']
print "port1_Tx : %s" % port1_Tx
print "port1_Rx : %s" % port1_Rx

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
