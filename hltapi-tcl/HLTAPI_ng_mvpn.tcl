# Copyright (c) 2010 by Spirent Communications, Inc.
# All Rights Reserved
#
# By accessing or executing this software, you agree to be bound 
# by the terms of this agreement.
# 
# Redistribution and use of this software in source and binary forms,
# with or without modification, are permitted provided that the 
# following conditions are met:
#   1.  Redistribution of source code must contain the above copyright 
#       notice, this list of conditions, and the following disclaimer.
#   2.  Redistribution in binary form must reproduce the above copyright
#       notice, this list of conditions and the following disclaimer
#       in the documentation and/or other materials provided with the
#       distribution.
#   3.  Neither the name Spirent Communications nor the names of its
#       contributors may be used to endorse or promote products derived
#       from this software without specific prior written permission.
#
# This software is provided by the copyright holders and contributors 
# [as is] and any express or implied warranties, including, but not 
# limited to, the implied warranties of merchantability and fitness for
# a particular purpose are disclaimed.  In no event shall Spirent
# Communications, Inc. or its contributors be liable for any direct, 
# indirect, incidental, special, exemplary, or consequential damages
# (including, but not limited to: procurement of substitute goods or
# services; loss of use, data, or profits; or business interruption)
# however caused and on any theory of liability, whether in contract, 
# strict liability, or tort (including negligence or otherwise) arising
# in any way out of the use of this software, even if advised of the
# possibility of such damage.
#
# File Name:     HLTAPI_ng_mvpn.tcl
#
# Objective: This script demonstrates the use of Spirent HLTAPI to setup MVPN working with PIM SSM
#
# Test Step:
#                    1. Reserve and connect chassis ports                             
#                    2. Add NG-MVPN Provider Port
#                    3. Add NG-MVPN Customer Port
#                    4. Config MVPN:
#                       Config the P-side Router, select OSPFv2 as IGP,
#                       Config the CE Router, use PIM-SM for P and C network.
#                       Create traffic from customer CE to "provider & customer CE" .
#                    5. Start NG-MVPN
#                    6. Get NG-MVPN Info
#                    7. Start NG-MVPN Traffic
#                    8. Stop NG-MVPN Traffic
#                    9. Get NG-MVPN Traffic Stats
#                   10. Stop NG-MVPN
#                   11. Release resources
# 
#Topology:
#                         
#                [STC Provider port]--------+----------- Port [DUT] Port --------+-----------[STC Customer port]     
#
# Dut Configuration:
#                Configure the DUT as a NG-MVPN PE.
#################################
package require SpirentHltApi

##############################################################
#config the parameters for the logging
##############################################################

set test_sta [sth::test_config\
        -log                                              1\
        -logfile                                          ng_mvpn_logfile\
        -vendorlogfile                                    ng_mvpn_stcExport\
        -vendorlog                                        1\
        -hltlog                                           1\
        -hltlogfile                                       ng_mvpn_hltExport\
        -hlt2stcmappingfile                               ng_mvpn_hlt2StcMapping\
        -hlt2stcmapping                                   1\
        -log_level                                        7]

set status [keylget test_sta status]
if {$status == 0} {
    puts "run sth::test_config failed"
    puts $test_sta
} else {
    puts "***** run sth::test_config successfully"
}

##############################################################
#config the parameters for optimization and parsing
##############################################################

set test_ctrl_sta [sth::test_control\
        -action                                           enable]

set status [keylget test_ctrl_sta status]
if {$status == 0} {
    puts "run sth::test_control failed"
    puts $test_ctrl_sta
} else {
    puts "***** run sth::test_control successfully"
}

##############################################################
#connect to chassis and reserve port list
##############################################################

package require SpirentHltApi

set device_list      [lindex $argv 0]
set port1        [lindex $argv 1]
set port2        [lindex $argv 2]
set i 1
foreach device $device_list {
    set device$i $device
    incr i
}
set device$i $device
set port_list "$port1 $port2";

set returnedString [sth::connect -device $device_list -port_list $port_list]

keylget returnedString status status
if {!$status} {
	puts $returnedString
    puts "  FAILED:  $status"
	return
} 

keylget returnedString port_handle.$device2.$port2 port2
keylget returnedString port_handle.$device1.$port1 port1

set portList "$port1 $port2"


##############################################################
#create CE device on port1
##############################################################
#API to configure Next Gen MVPN customer router

set device_ret0_router0 [sth::emulation_mvpn_customer_port_config\
        -action add\
        -port_handle $port1\
        -dut_interface_ipv4_addr 30.1.1.1\
        -dut_interface_ipv4_addr_step 0.0.0.0\
        -dut_interface_ipv4_prefix_length 24\
        -dut_interface_ipv6_addr 3001::1\
        -dut_interface_ipv6_addr_step ::1\
        -dut_interface_ipv6_prefix_length 64\
        -mvpn_type nextgen\
        -ng_encap IPV4V6\
        -ng_multicast_traffic_role SENDER\
]

set status [keylget device_ret0_router0 status]
if {$status == 0} {
    puts "run sth::emulation_mvpn_customer_port_config failed"
    puts $device_ret0_router0
} else {
    puts "***** run sth::emulation_mvpn_customer_port_config successfully"
}
puts $device_ret0_router0
##############################################################
#create PE device on port2
##############################################################
#API to configure Next Gen MVPN Provider router
set device_ret0_router0 [sth::emulation_mvpn_provider_port_config\
        -action add\
        -port_handle $port2\
        -dut_interface_ipv4_addr 10.1.1.1\
        -dut_interface_ipv4_addr_step 1.0.0.0\
        -dut_interface_ipv4_prefix_length 24\
        -mvpn_type nextgen\
        -ng_encap IPV4\
        -ng_multicast_traffic_role RECEIVER\
]

set status [keylget device_ret0_router0 status]
if {$status == 0} {
    puts "run sth::emulation_mvpn_provider_port_config failed"
    puts $device_ret0_router0
} else {
    puts "***** run sth::emulation_mvpn_provider_port_config successfully"
}
puts $device_ret0_router0


#API to configure Next Gen MVPN wizard
set device_ret0_router0 [sth::emulation_mvpn_config \
    -mode create\
    -mvpn_type  nextgen\
    -vpn_v4_enable  1\
    -vpn_v6_enable 1\
    -provider_use_ports_enable    1\
    -dut_loopback_ipv4_addr  200.200.200.1\
    -dut_as 100\
    -igp_protocol ospf\
    -mpls_protocol rsvp\
    -igp_ospfv2_area_id 0.0.0.0\
    -igp_ospfv2_network_type native\
    -igp_ospfv2_router_priority 0\
    -igp_ospfv2_interface_cost 1\
    -igp_ospfv2_options 2\
    -igp_ospfv2_authentication_mode    none\
    -mpls_rsvp_bandwidth_per_link 10000\
    -mpls_rsvp_bandwidth_per_tunnel 0\
    -mpls_rsvp_egress_label next_available\
    -mpls_rsvp_transit accept_configured\
    -mpls_rsvp_min_label 16\
    -mpls_rsvp_max_label 65535\
    -mpls_rsvp_graceful_restart_enable 0\
    -p_router_loopback_ipv4_addr 200.200.200.2\
    -p_router_loopback_ipv4_addr_step 0.0.0.1\
    -pe_router_number_per_sub_interface 1\
    -pe_router_loopback_ipv4_addr  200.200.200.2\
    -pe_router_loopback_ipv4_addr_step  0.0.0.1\
    -customer_use_ports_enable    1\
    -vrf_number 1\
    -vrf_rd_assignment manual\
    -vrf_route_target_start   100:100\
    -vrf_route_target_step    0:1\
    -customer_ce_vrf_assignment round_robin\
    -customer_ce_bgp_as 1\
    -customer_ce_pim_protocol     sm\
    -customer_ce_routing_protocol bgp\
    -customer_ce_bgp_percent   100\
    -customer_rd_start 100:100\
    -customer_ce_bgp_as_step_per_vrf_enable 1\
    -customer_ce_bgp_as_step_per_vrf  1\
    -provider_rd_start 200:200\
    -provider_rd_step_per_vrf_enable 1\
    -provider_rd_step_per_vrf  1:0\
    -provider_pe_vrf_assignment vpn_per_pe\
    -provider_pe_vrf_count 1\
    -customer_ipv6_rp_addr    2001::1\
    -customer_ipv6_rp_increment 0:0:0:1::\
    -customer_rp_addr 1.1.1.1\
    -customer_rp_increment 0.0.0.1\
    -ipv4_group_address_increment     0.0.0.1\
    -ipv4_group_count 10\
    -ipv4_starting_group_address     226.1.1.1\
    -ipv4_unique_groups_per_sender 0\
    -ipv6_group_address_increment     ::1\
    -ipv6_group_count 10\
    -ipv6_starting_group_address     ff1e::1\
    -ipv6_unique_groups_per_sender 0\
    -provider_ipv4_vpn_route_overlap  0\
    -provider_ipv4_vpn_route_prefix_length 24\
    -provider_ipv4_vpn_route_start     110.1.1.0\
    -provider_ipv4_vpn_route_step 1\
    -customer_ipv4_vpn_route_overlap  0\
    -customer_ipv4_vpn_route_prefix_length       24\
    -customer_ipv4_vpn_route_start     100.1.1.0\
    -customer_ipv4_vpn_route_step 1\
    -vrf_route_mpls_label_type label_per_site\
    -vrf_route_mpls_label_start 16\
    -customer_route_type       internal\
    -provider_ipv6_vpn_route_start  2005::\
    -provider_ipv6_vpn_route_overlap  0\
    -provider_ipv6_vpn_route_prefix_length  64\
    -provider_ipv6_vpn_route_step 1\
    -customer_ipv6_vpn_route_start 2100::1\
    -customer_ipv6_vpn_route_overlap  0\
    -customer_ipv6_vpn_route_prefix_length 64\
    -customer_ipv6_vpn_route_step 1\
    -ipv6_vpn_route_mpls_label_type site\
    -customer_ipv6_ce_route_type internal\
    -customer_enable_all_ipv4_mcast_sender_routes_per_ce 1\
    -customer_enable_all_ipv6_mcast_sender_routes_per_ce 1\
    -multicast_traffic_enable  1\
    -provider_enable_all_ipv4_mcast_sender_routes_per_ce 1\
    -provider_enable_all_ipv6_mcast_sender_routes_per_ce 1\
    -customer_multicast_traffic_load_percent_from_ports   10\
    -multicast_frameSize    1500]
    
set status [keylget device_ret0_router0 status]
if {$status == 0} {
    puts "run sth::emulation_mvpn_config failed"
    puts $device_ret0_router0
} else {
    puts "***** run sth::emulation_mvpn_config successfully"
    puts $device_ret0_router0
}

set CeRtrv6 [keylget device_ret0_router0 handle.CeRouterV6]
set CeRtrv4 [keylget device_ret0_router0 handle.CeRouterV4]
set PeRouter [keylget device_ret0_router0 handle.PeRouter]
set PRouter [keylget device_ret0_router0 handle.PRouter]

set dst_hdl [keylget device_ret0_router0 handle.Ipv6Group]

stc::perform saveasxml -filename HLTAPI_ng_mvpn.xml 
#config parts are finished

#API to start NG-MVPN routers
set mvpn_ctrl [sth::emulation_mvpn_control -action start\
                                           -mvpn_type nextgen\
                                           -handle "$CeRtrv6 $CeRtrv4 $PeRouter $PRouter"]

set status [keylget mvpn_ctrl status]
if {$status == 0} {
    puts "run sth::emulation_mvpn_control failed"
    puts $streamblock_ret1
} else {
    puts "***** run sth::emulation_mvpn_control successfully"
}

#API to start traffic
set traffic_ctrl_ret [sth::traffic_control \
		-port_handle                                     "$port2"\
		-action                                        run];

set status [keylget traffic_ctrl_ret status]
if {$status == 0} {
    puts "run sth::emulation_mvpn_control failed"
    puts $traffic_ctrl_ret
} else {
    puts "***** run sth::emulation_mvpn_control successfully"
}


#API to get NG-MVPN stats
set mvpn_ctrl [sth::emulation_mvpn_info -mode ospfv2\
                                           -handle "$CeRtrv6 $CeRtrv4 $PeRouter $PRouter"\
                                           -mvpn_type nextgen]

set status [keylget mvpn_ctrl status]
if {$status == 0} {
    puts "run sth::emulation_mvpn_info failed"
    puts $mvpn_ctrl
} else {
    puts "***** run sth::emulation_mvpn_info successfully"
    puts $mvpn_ctrl
}

#API to stop NG-MVPN routers
set mvpn_ctrl [sth::emulation_mvpn_control -action stop\
                                           -mvpn_type nextgen\
                                           -handle "$CeRtrv6 $CeRtrv4 $PeRouter $PRouter"]

set status [keylget mvpn_ctrl status]
if {$status == 0} {
    puts "run sth::emulation_mvpn_control failed"
    puts $streamblock_ret1
} else {
    puts "***** run sth::emulation_mvpn_control successfully"
}

#API to stop traffic
set traffic_ctrl_ret [sth::traffic_control \
		-port_handle                                     "$port2"\
		-action                                        stop];

set status [keylget traffic_ctrl_ret status]
if {$status == 0} {
    puts "run sth::traffic_control failed"
    puts $traffic_ctrl_ret
} else {
    puts "***** run sth::traffic_control successfully"
}

##############################################################
#clean up the session, release the ports reserved and cleanup the dbfile
##############################################################

set cleanup_sta [sth::cleanup_session\
        -port_handle                                      $port1 $port2\
        -clean_dbfile                                     1]

set status [keylget cleanup_sta status]
if {$status == 0} {
    puts "run sth::cleanup_session failed"
    puts $cleanup_sta
} else {
    puts "***** run sth::cleanup_session successfully"
}

puts "**************Finish***************"
    