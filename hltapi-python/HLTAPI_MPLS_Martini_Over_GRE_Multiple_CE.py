#########################################################################################################################
#
# File Name:           HLTAPI_MPLS_Martini_Over_GRE_Multiple_CE.py                 
# Description:         This script demonstrates the use of Spirent HLTAPI to setup MPLS L2VPN over GRE in martini method.
#                      
# Test Steps:          
#             1.Reserve and connect chassis ports
#             2.Configure interfaces
#             3.Configure OSPF router on port2
#             4.Configure OSPF IPv4 LSA
#             5.Configure LDP router on port2
#             6.Configure LDP IPv4 Prefix
#             7.Configure GRE tunnel on port2
#             8.Start LDP router
#             9.Configure MPLS L2VPN PE on port2
#             10.Create MPLS L2VPN CE on port1 
#             11.Create MPLS L2VPN CE on port2
#             12.Create MPLS L2VPN traffic
#             13.Start OSPF router
#             14.Start catpure and start traffic
#             15.Stop traffic and stop catpure
#             16.Get traffic statistics
#             17. Release resources
#
#                                                                       
# Topology:
#    loop: 4.4.4.4/32      loop: 220.1.1.1/32          loop:2.2.2.4/32             loop:3.3.3.4/32
#      _                            _                          _                           _
#      |                            |                          |                           |
#      |                            |                          |                           |
#      |                            |                          |                           |
#   [STC Port1]              13/31 DUT 13/32  GRE-Tunnel   [STC Port2]                [STC Port2]
#     [CE]------------------------[PE]------------------------[PE]------------------------[CE]
#         .11                   .1    .1                   .11    .1                   .11
#                13.31.0.0/16               13.32.0.0/16                 120.1.1.0/24
#     BGP1001                     BGP123                     BGP123                      BGP1001
#
################################################################################
# 
# Run sample:
#            c:>python HLTAPI_MPLS_Martini_Over_GRE_Multiple_CE.py 10.61.44.2 3/1 3/3
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
    logfile                                          = 'HLTAPI_MPLS_Martini_Over_GRE_Multiple_CE_logfile',
    vendorlogfile                                    = 'HLTAPI_MPLS_Martini_Over_GRE_Multiple_CE_stcExport',
    vendorlog                                        = '1',
    hltlog                                           = '1',
    hltlogfile                                       = 'HLTAPI_MPLS_Martini_Over_GRE_Multiple_CE_hltExport',
    hlt2stcmappingfile                               = 'HHLTAPI_MPLS_Martini_Over_GRE_Multiple_CE_hlt2StcMapping',
    hlt2stcmapping                                   = '1',
    log_level                                        = '7')

status = test_sta['status']
if  status == '0' :
    print "run sth.test_config failed"
    print test_sta
else:
    print "***** run sth.test_config successfully"


########################################
# Step1.Reserve and connect chassis ports
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
# Step2.Configure interfaces
########################################
print "Configure interface"

for i in range(0,len(port_list)) :
    returnedString = sth.interface_config (
        mode                                              = 'config',
        port_handle                                       = port_handle[i],
        intf_mode                                         = 'ethernet',
        phy_mode                                          = 'fiber',
        autonegotiation                                   = '1')
    
    status = returnedString['status']
    if (status == '0') :
        print("run sth.interface_config failed")
        print returnedString
    else:
        print("***** run sth.interface_config successfully")
        print returnedString

##############################################################
# Step3.Configure OSPF router on port2
##############################################################
device_ret0 = sth.emulation_ospf_config (
        mode                                             = 'create',
        session_type                                     = 'ospfv2',
        port_handle                                      = port_handle[1],
        intf_prefix_length                               = '16',
        router_priority                                  = '12',
        mac_address_start                                = '00:10:94:00:00:32',
        area_id                                          = '0.0.0.0',
        router_id                                        = '13.32.0.11',
        gateway_ip_addr                                  = '13.32.0.1',
        intf_ip_addr                                     = '13.32.0.11')

status = device_ret0['status']
if (status == '0') :
    print("run sth.emulation_ospf_config failed")
    print(device_ret0)
else:
    print("***** run sth.emulation_ospf_config successfully")

ospfRouterPE = device_ret0['handle'].split()[0]

############################################
# Telnet to DUT to config OSPF protocol
############################################
#EX_TelnetOpen $DUTIP $dutUserName $dutPassWord -timeout 5 -passwordPrompt "Password:" -prompt ">"
#EX_TelnetSendCommand "en" -prompt "Password:"
#EX_TelnetSendCommand $enablePassword -prompt "#"
#EX_TelnetSendCommand "configure terminal"

#EX_TelnetSendCommand "interface gigabitEthernet 13/31"
#EX_TelnetSendCommand "ip ospf network broadcast"
#EX_TelnetSendCommand "interface gigabitEthernet 13/31"
#EX_TelnetSendCommand "ip ospf network broadcast"

#EX_TelnetClose
############################################

##############################################################
# Step4.Configure OSPF IPv4 LSA
##############################################################
#Create OSPF router LSA on the Provide side 
device_ret0_router0 = sth.emulation_ospf_lsa_config (
        mode                                             = 'create',
        type                                             = 'router',
        handle                                           = ospfRouterPE,
        adv_router_id                                    = '2.2.2.4',
        link_state_id                                    = '255.255.255.255',
        router_abr                                       = '0',
        router_asbr                                      = '1',
        router_link_mode                                 = 'create',
        router_link_type                                 = 'stub',
        router_link_id                                   = '2.2.2.4',
        router_link_data                                 = '255.255.255.255',
        router_link_metric                               = '1');

status = device_ret0_router0['status']
if (status == '0') :
    print("Failed to create OSPF prefix on PE router.")
    print(device_ret0_router0)
else:
    print("***** Successfully to create OSPF prefix on PE router.")

##############################################################
# Step5.Configure LDP router on port2
##############################################################
print "Configure LDP on PE router"

device_ldp = sth.emulation_ldp_config (
        mode                                             = 'create',
        handle                                           = ospfRouterPE,
        peer_discovery                                   = 'targeted',
        label_adv                                        = 'unsolicited',
        label_start                                      = '39',
        intf_ip_addr                                     = '13.32.0.11',
        intf_prefix_length                               = '16',
        loopback_ip_addr                                 = '2.2.2.4',
        remote_ip_addr                                   = '220.1.1.1',
        gateway_ip_addr                                  = '13.32.0.1',
        lsr_id                                           = '2.2.2.4')

status = device_ldp['status']
if (status == '0') :
    print("Failed to create LDP router")
    print(device_ldp)
else:
    print("***** Create LDP router successfully")

ldpRouterPE = device_ldp['handle']

############################################
# Telnet to DUT to config LDP protocol
############################################
#EX_TelnetOpen $DUTIP $dutUserName $dutPassWord -timeout 5 -passwordPrompt "Password:" -prompt ">"
#EX_TelnetSendCommand "en" -prompt "Password:"
#EX_TelnetSendCommand $enablePassword -prompt "#"
#EX_TelnetSendCommand "configure terminal"

#EX_TelnetSendCommand "interface gigabitEthernet 13/32"
#EX_TelnetSendCommand "mpls label protocol ldp"
#EX_TelnetSendCommand "mpls ip"

#EX_TelnetClose
############################################

##############################################################
# Step6.Configure LDP IPv4 Prefix
##############################################################
print "Create LSP on PE router"

ldp_route = sth.emulation_ldp_route_config (
        mode                                             = 'create',
        handle                                           = ldpRouterPE,
        fec_type                                         = 'prefix',
        fec_ip_prefix_length                             = '24',
        fec_ip_prefix_start                              = '120.1.1.1',
        num_lsps                                         = '1');

status = ldp_route['status']
if (status == '0') :
    print("Failed to create LDP prefix on PE")
    print(ldp_route)
else:
    print("***** Create LDP prefix on PE successfully")
    
##############################################################
# Step7.Configure GRE tunnel on port2
##############################################################
print "Create GRE Tunnel on PE router"

gre_ret = sth.emulation_gre_config (
        gre_tnl_type                                     = '4',
        gre_tnl_addr                                     = '2.2.2.4',
        gre_tnl_addr_step                                = '0.0.0.1',
        gre_tnl_addr_count                               = '1',
        gre_src_mode                                     = 'increment',
        gre_src_addr                                     = '13.32.0.11',
        gre_src_addr_step                                = '0.0.0.1',
        gre_src_addr_count                               = '1',
        gre_dst_mode                                     = 'increment',
        gre_dst_addr                                     = '13.32.0.1',
        gre_dst_addr_step                                = '0.0.0.1',
        gre_dst_addr_count                               = '1')
        
if (gre_ret == '') :
    print("Failed to create GRE tunnel on PE")
    print(gre_ret)
else:
    print("***** Create GRE tunnel on PE successfully")

greTunnel = gre_ret
    
############################################
# Telnet to DUT to config GRE tunnel 
############################################
#EX_TelnetOpen $DUTIP $dutUserName $dutPassWord -timeout 5 -passwordPrompt "Password:" -prompt ">"
#EX_TelnetSendCommand "en" -prompt "Password:"
#EX_TelnetSendCommand $enablePassword -prompt "#"
#EX_TelnetSendCommand "configure terminal"

#EX_TelnetSendCommand "interface Tunnel112"
#EX_TelnetSendCommand "ip unnumbered Loopback1"
#EX_TelnetSendCommand "tag-switching ip"
#EX_TelnetSendCommand "tunnel source 13.32.0.1"
#EX_TelnetSendCommand "tunnel destination 13.32.0.11"
#EX_TelnetSendCommand "mpls ip"

#EX_TelnetClose
############################################

##############################################################
# Step8.Start LDP router
##############################################################
print "Start LDP router"

ctrl_ldp = sth.emulation_ldp_control (
        handle                                           = ldpRouterPE,
        mode                                             = 'start');

status = ctrl_ldp['status']
if (status == '0') :
    print("Start LDP router on PE router failed")
    print(ctrl_ldp)
else:
    print("***** Start LDP router on PE successfully")
    
##############################################################
# Step9.Configure MPLS L2VPN PE on port2
##############################################################
print "Configure PE router"

pe_ret = sth.emulation_mpls_l2vpn_pe_config (
        mode                                             = 'enable',
        port_handle                                      = port_handle[1],
        vpn_type                                         = 'martini_pwe',
        igp_session_handle                               = ospfRouterPE,
        targeted_ldp_session_handle                      = ldpRouterPE,
        tunnel_handle                                    = greTunnel,
        pe_count                                         = '1')
        
status = ctrl_ldp['status']
if (status == '0') :
    print("Create PE router failed")
    print(ctrl_ldp)
else:
    print("***** Create PE router successfully")
    
vpnRouterPE = pe_ret['handle']

##############################################################
# Step10.Create MPLS L2VPN CE on port1 
##############################################################
print "Create MPLS CE on left side"
ce_site = sth.emulation_mpls_l2vpn_site_config (
        mode                                             = 'create',
        port_handle                                      = port_handle[0],
        pe_loopback_ip_addr                              = '220.1.1.1',
        pe_loopback_ip_step                              = '0.0.0.0',
        pe_loopback_ip_prefix                            = '32',
        site_count                                       = '1',
        vc_id                                            = '1500',
        vpn_id                                           = '100')

status = ce_site['status']
if (status == '0') :
    print("Failed to create MPLS CE on left side")
    print(ce_site)
else:
    print("***** Create CE on left side successfully")

ceCustomSide = ce_site['handle']
    
##############################################################
# Step11.Create MPLS L2VPN CE on port2
##############################################################
print "Create CE on right side"

ce_site = sth.emulation_mpls_l2vpn_site_config (
        mode                                             = 'create',
        port_handle                                      = port_handle[1],
        pe_handle                                        = vpnRouterPE,
        pe_loopback_ip_addr                              = '2.2.2.4',
        pe_loopback_ip_step                              = '0.0.0.0',
        pe_loopback_ip_prefix                            = '32',
        site_count                                       = '1',
        vpn_type                                         = 'martini_pwe',
        vc_id                                            = '1500',
        vlan_id                                          = '1701',
        vpn_id                                           = '100')

status = ce_site['status']
if (status == '0') :
    print("Failed to create CE on port2")
    print(ce_site)
else:
    print("***** Create CE on right side successfully")

ceProvideSide = ce_site['handle']

############################################
# Telnet to DUT to config VRF
############################################
#EX_TelnetOpen $DUTIP $dutUserName $dutPassWord -timeout 5 -passwordPrompt "Password:" -prompt ">"
#EX_TelnetSendCommand "en" -prompt "Password:"
#EX_TelnetSendCommand $enablePassword -prompt "#"
#EX_TelnetSendCommand "configure terminal"

#EX_TelnetSendCommand "interface gigabitEthernet 13/31"
#EX_TelnetSendCommand "ip vrf forwarding vpn123"
#EX_TelnetSendCommand "ip address 13.31.0.1 255.255.0.0"

#EX_TelnetClose
    
##############################################################
# Step12.Create MPLS L2VPN traffic
##############################################################
print "Create traffic from left CE to right CE"
streamblock_ret1 = sth.traffic_config (
        mode                                             = 'create',
        port_handle                                      = port_handle[0],
        length_mode                                      = 'fixed',
        l3_length                                        = '256',
        emulation_src_handle                             = ceCustomSide,
        emulation_dst_handle                             = ceProvideSide,
        rate_pps                                         = '10')
        
status = streamblock_ret1['status']
if (status == '0') :
    print("Failed to create traffic")
    print(streamblock_ret1)
else:
    print("***** Create traffic successfully")
    
print "Create traffic from right CE to left CE"

streamblock_ret1 = sth.traffic_config (
        mode                                             = 'create',
        port_handle                                      = port_handle[1],
        length_mode                                      = 'fixed',
        l3_length                                        = '256',
        emulation_src_handle                             = ceProvideSide,
        emulation_dst_handle                             = ceCustomSide,
        rate_pps                                         = '10')
        
status = streamblock_ret1['status']
if (status == '0') :
    print("Failed to create traffic")
    print(streamblock_ret1)
else:
    print("***** Create traffic successfully")

#config part is finished
sth.invoke ('stc::perform saveasxml -filename mpls_martini_over_gre_multipleCE.xml')

##############################################################
# Step13.Start OSPF router
##############################################################
print "Start OSPF router"
ctrl_ret1 = sth.emulation_ospf_control (
        handle                                           = ospfRouterPE,
        mode                                             = 'start');

status = ctrl_ret1['status']
if (status == '0') :
    print("Start OSPF router failed")
    print(ctrl_ret1)
else:
    print("***** Start OSPF router successfully")    
    
print "Wait 20 seconds......"
time.sleep(20)

##############################################################
# Step14.Start catpure and start traffic
##############################################################
print "Start capture"
for i in range (0,len(port_list)) :
    TurnOnCapture (port_handle[i],"port%s" % i)
    
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
# Step15.Stop traffic and stop catpure
##############################################################
print "Stop traffic on port1 and port2"

traffic_ctrl_ret = sth.traffic_control (
        port_handle                                      = 'all',
        action                                           = 'stop');

status = traffic_ctrl_ret['status']
if (status == '0') :
    print("run sth.traffic_control failed")
    print(traffic_ctrl_ret)
else:
    print("***** run sth.traffic_control successfully")
    print(traffic_ctrl_ret)

print "Stop capture"

for i in range (0,len(port_list)) :
    TurnOffCapture (port_handle[i],"port%s" % i)
    
##############################################################
# Step16.Get traffic statistics
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
# Step17. Release resources
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
