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
# File Name:     HLTAPI_l3vpn_ospfsr.tcl
#
# Objective: This script demonstrates the use of Spirent HLTAPI to setup L3VPN working with OSPF SR
#
# Test Step:
#                    1. Reserve and connect chassis ports                             
#                    2. Add L3VPN Provider Port
#                    3. Add L3VPN Customer Port
#                    4. Config L3VPN:
#                       Config the P-side Router, select OSPFv2 as IGP with SR enabled on routes
#                       Config the CE Router
#                       Create traffic from customer CE to "provider & customer CE" .
#                    5. Start protocols
#                    6. Get Info
#                    7. Start Traffic
#                    8. Get Traffic Stats
#                    9. Release resources
# 
#Topology:
#                         
#                [STC Provider port]--------+----------- Port [DUT] Port --------+-----------[STC Customer port]     
#
# Dut Configuration:
#                Configure the DUT as a L3VPN PE.
#################################

package require SpirentHltApi

##############################################################
#config the parameters for the logging
##############################################################

set test_sta [sth::test_config\
        -log                                              1\
        -logfile                                          L3VPN_SR_logfile\
        -vendorlogfile                                    L3VPN_SR_stcExport\
        -vendorlog                                        1\
        -hltlog                                           1\
        -hltlogfile                                       L3VPN_SR_hltExport\
        -hlt2stcmappingfile                               L3VPN_SR_hlt2StcMapping\
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

########################################
#Step1: Reserve and connect chassis ports
########################################

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
#create device and config the protocol on it
##############################################################

#start to create the device: PE Router 1
#API to configure BGP router
set device_ret0 [sth::emulation_bgp_config\
        -mode                                             enable\
        -retries                                          100 \
        -vpls_version                                     VERSION_00 \
        -routes_per_msg                                   2000 \
        -staggered_start_time                             100 \
        -update_interval                                  30 \
        -retry_time                                       30 \
        -staggered_start_enable                           1\
        -md5_key_id                                       1 \
        -md5_key                                          Spirent \
        -md5_enable                                       0 \
        -ipv4_mpls_vpn_nlri                               1\
        -ip_stack_version                                 4\
        -port_handle                                      $port1\
        -bgp_session_ip_addr                              router_id \
        -remote_ip_addr                                   10.0.0.1 \
        -ip_version                                       4 \
        -remote_as                                        1 \
        -hold_time                                        90 \
        -restart_time                                     90 \
        -route_refresh                                    0 \
        -local_as                                         1 \
        -active_connect_enable                            1 \
        -stale_time                                       90 \
        -graceful_restart_enable                          0 \
        -local_router_id                                  10.0.0.2 \
        -mac_address_start                                00:10:94:00:00:01 \
        -local_ip_addr                                    10.0.0.2 \
        -next_hop_ip                                      20.1.1.1 \
        -netmask                                          32 \
]

set status [keylget device_ret0 status]
if {$status == 0} {
    puts "run sth::emulation_bgp_config failed"
    puts $device_ret0
} else {
    puts "***** run sth::emulation_bgp_config successfully"
}

set bgp_router1 [lindex [keylget device_ret0 handle] 0]

#API to configure BGP IPv4 route
set device_ret0_route1 [sth::emulation_bgp_route_config\
        -handle                                           $bgp_router1\
        -mode                                             add\
        -ip_version                                       4\
        -target_type                                      as\
        -target                                           1\
        -target_assign                                    0\
        -rd_type                                          0\
        -rd_admin_step                                    0\
        -rd_admin_value                                   1\
        -rd_assign_step                                   1\
        -rd_assign_value                                  0\
        -next_hop_ip_version                              4\
        -next_hop_set_mode                                manual\
        -ipv4_mpls_vpn_nlri                               1\
        -prefix_step                                      1 \
        -prefix                                           110.1.1.0 \
        -num_routes                                       1 \
        -netmask                                          255.255.255.0 \
        -next_hop                                         10.0.0.2 \
        -atomic_aggregate                                 0 \
        -local_pref                                       10 \
        -origin                                           igp \
        -route_category                                   undefined \
        -label_incr_mode                                  fixed \
]

set status [keylget device_ret0_route1 status]
if {$status == 0} {
    puts "run sth::emulation_bgp_route_config failed"
    puts $device_ret0_route1
} else {
    puts "***** run sth::emulation_bgp_route_config successfully"
}

#start to create the device: CE IPv4 Router 1

#API to configure bgp router
set device_ret1 [sth::emulation_bgp_config\
        -mode                                             enable\
        -retries                                          100 \
        -vpls_version                                     VERSION_00 \
        -routes_per_msg                                   2000 \
        -staggered_start_time                             100 \
        -update_interval                                  30 \
        -retry_time                                       30 \
        -staggered_start_enable                           1\
        -md5_key_id                                       1 \
        -md5_key                                          Spirent \
        -md5_enable                                       0 \
        -ipv4_unicast_nlri                                1\
        -ip_stack_version                                 4\
        -port_handle                                      $port2\
        -bgp_session_ip_addr                              interface_ip \
        -remote_ip_addr                                   30.1.1.1 \
        -ip_version                                       4 \
        -remote_as                                        1 \
        -hold_time                                        90 \
        -restart_time                                     90 \
        -route_refresh                                    0 \
        -local_as                                         1 \
        -active_connect_enable                            1 \
        -stale_time                                       90 \
        -graceful_restart_enable                          0 \
        -local_router_id                                  30.1.1.2 \
        -mac_address_start                                00:10:94:00:00:03 \
        -local_ip_addr                                    30.1.1.2 \
        -next_hop_ip                                      30.1.1.1 \
        -netmask                                          24 \
]

set status [keylget device_ret1 status]
if {$status == 0} {
    puts "run sth::emulation_bgp_config failed"
    puts $device_ret1
} else {
    puts "***** run sth::emulation_bgp_config successfully"
}

set bgp_router1 [lindex [keylget device_ret1 handle] 0]

#API to configure BGP IPv4 route
set device_ret1_route1 [sth::emulation_bgp_route_config\
        -handle                                           $bgp_router1\
        -mode                                             add\
        -ip_version                                       4\
        -target_type                                      as\
        -target                                           100\
        -target_assign                                    1\
        -rd_type                                          0\
        -rd_admin_step                                    0\
        -rd_admin_value                                   100\
        -rd_assign_step                                   1\
        -rd_assign_value                                  1\
        -next_hop_ip_version                              4\
        -next_hop_set_mode                                manual\
        -ipv4_unicast_nlri                                1\
        -prefix_step                                      1 \
        -prefix                                           10.1.1.0 \
        -num_routes                                       1 \
        -netmask                                          255.255.255.0 \
        -atomic_aggregate                                 0 \
        -local_pref                                       10 \
        -origin                                           igp \
        -route_category                                   undefined \
        -label_incr_mode                                  none \
]

set status [keylget device_ret1_route1 status]
if {$status == 0} {
    puts "run sth::emulation_bgp_route_config failed"
    puts $device_ret1_route1
} else {
    puts "***** run sth::emulation_bgp_route_config successfully"
}

#start to create the device: P Router 1
#API to configure OSPF router
set device_ret2 [sth::emulation_ospf_config\
        -mode                                             create\
        -session_type                                     ospfv2\
        -authentication_mode                              none \
        -network_type                                     native\
        -option_bits                                      0x2\
        -port_handle                                      $port1\
        -router_id                                        192.0.1.1 \
        -mac_address_start                                00:10:94:00:00:01 \
        -intf_ip_addr                                     20.1.1.2 \
        -gateway_ip_addr                                  20.1.1.1 \
        -intf_prefix_length                               24 \
        -hello_interval                                   10 \
        -lsa_retransmit_delay                             5 \
        -te_metric                                        0 \
        -router_priority                                  0 \
        -te_enable                                        0 \
        -dead_interval                                    40 \
        -interface_cost                                   1 \
        -area_id                                          0.0.0.0 \
        -graceful_restart_enable                          0 \
]

set status [keylget device_ret2 status]
if {$status == 0} {
    puts "run sth::emulation_ospf_config failed"
    puts $device_ret2
} else {
    puts "***** run sth::emulation_ospf_config successfully"
}

set ospf_router0 "[lindex [keylget device_ret2 handle] 0]"

#API to configure OSPF router LSA
set device_ret2_router0 [sth::emulation_ospf_lsa_config\
        -type                                             router\
        -router_virtual_link_endpt                        0 \
        -router_asbr                                      0 \
        -adv_router_id                                    192.0.1.1 \
        -link_state_id                                    0.0.0.0 \
        -router_abr                                       0 \
        -handle                                           $ospf_router0\
        -mode                                             create\
]

set status [keylget device_ret2_router0 status]
if {$status == 0} {
    puts "run sth::emulation_ospf_lsa_config failed"
    puts $device_ret2_router0
} else {
    puts "***** run sth::emulation_ospf_lsa_config successfully"
}

set lsa11 [keylget device_ret2_router0 lsa_handle]
puts $device_ret2_router0

#API to configure OSPF router LSA contents
set device_ret2_router0 [sth::emulation_ospf_lsa_config\
        -lsa_handle                                           $lsa11\
        -mode                                             modify\
        -router_link_data 255.255.255.255\
        -router_link_id 192.0.1.1\
        -router_link_metric 1\
        -router_link_mode create\
        -router_link_type stub\
]

set status [keylget device_ret2_router0 status]
if {$status == 0} {
    puts "run sth::emulation_ospf_lsa_config failed"
    puts $device_ret2_router0
} else {
    puts "***** run sth::emulation_ospf_lsa_config successfully"
}

#API to configure OSPF router LSA contents
set device_ret2_router0 [sth::emulation_ospf_lsa_config\
        -lsa_handle                                           $lsa11\
        -mode                                             modify\
        -router_link_data 1.0.0.1\
        -router_link_id 10.0.0.2\
        -router_link_metric 1\
        -router_link_mode create\
        -router_link_type ptop\
]

set status [keylget device_ret2_router0 status]
if {$status == 0} {
    puts "run sth::emulation_ospf_lsa_config failed"
    puts $device_ret2_router0
} else {
    puts "***** run sth::emulation_ospf_lsa_config successfully"
}
set lsa11 [keylget device_ret2_router0 lsa_handle]

set lsa11 [keylget device_ret2_router0 lsa_handle]
puts $device_ret2_router0

#API to configure OSPF router LSA contents
set device_ret2_router0 [sth::emulation_ospf_lsa_config\
        -lsa_handle                                           $lsa11\
        -mode                                             modify\
        -router_link_data 255.255.255.0\
        -router_link_id 1.0.0.0\
        -router_link_metric 1\
        -router_link_mode create\
        -router_link_type stub\
]

set status [keylget device_ret2_router0 status]
if {$status == 0} {
    puts "run sth::emulation_ospf_lsa_config failed"
    puts $device_ret2_router0
} else {
    puts "***** run sth::emulation_ospf_lsa_config successfully"
}

set ospf_router0 "[lindex [keylget device_ret2 handle] 0]"

#API to configure OSPF router LSA
set device_ret2_router1 [sth::emulation_ospf_lsa_config\
        -type                                             router\
        -router_virtual_link_endpt                        0 \
        -router_asbr                                      0 \
        -adv_router_id                                    10.0.0.2 \
        -link_state_id                                    0.0.0.0 \
        -router_abr                                       0 \
        -handle                                           $ospf_router0\
        -mode                                             create\
]

set status [keylget device_ret2_router1 status]
if {$status == 0} {
    puts "run sth::emulation_ospf_lsa_config failed"
    puts $device_ret2_router1
} else {
    puts "***** run sth::emulation_ospf_lsa_config successfully"
}

set lsa22 [keylget device_ret2_router1 lsa_handle]
puts $device_ret2_router1

#API to configure OSPF router LSA contents
set device_ret2_router1 [sth::emulation_ospf_lsa_config\
        -lsa_handle                                           $lsa22\
        -mode                                             modify\
        -router_link_data 1.0.0.2\
        -router_link_id 192.0.1.1\
        -router_link_metric 1\
        -router_link_mode create\
        -router_link_type ptop\
]

set status [keylget device_ret2_router1 status]
if {$status == 0} {
    puts "run sth::emulation_ospf_lsa_config failed"
    puts $device_ret2_router1
} else {
    puts "***** run sth::emulation_ospf_lsa_config successfully"
}

#API to configure OSPF router LSA contents
set device_ret2_router1 [sth::emulation_ospf_lsa_config\
        -lsa_handle                                           $lsa22\
        -mode                                             modify\
        -router_link_data 255.255.255.255\
        -router_link_id 10.0.0.2\
        -router_link_metric 1\
        -router_link_mode create\
        -router_link_type stub\
]

set status [keylget device_ret2_router1 status]
if {$status == 0} {
    puts "run sth::emulation_ospf_lsa_config failed"
    puts $device_ret2_router1
} else {
    puts "***** run sth::emulation_ospf_lsa_config successfully"
}
set lsa22 [keylget device_ret2_router1 lsa_handle]

set lsa22 [keylget device_ret2_router1 lsa_handle]
puts $device_ret2_router1

#API to configure OSPF router LSA contents
set device_ret2_router1 [sth::emulation_ospf_lsa_config\
        -lsa_handle                                           $lsa22\
        -mode                                             modify\
        -router_link_data 255.255.255.0\
        -router_link_id 1.0.0.0\
        -router_link_metric 1\
        -router_link_mode create\
        -router_link_type stub\
]

set status [keylget device_ret2_router1 status]
if {$status == 0} {
    puts "run sth::emulation_ospf_lsa_config failed"
    puts $device_ret2_router1
} else {
    puts "***** run sth::emulation_ospf_lsa_config successfully"
}

#API to configure OSPF router info LSA 
set device_ret0_router0 [sth::emulation_ospf_lsa_config\
        -type                                router_info\
        -handle                              $ospf_router0\
        -router_info_adv_router_id 10.0.0.2\
        -router_info_instance                1\
        -router_info_opaque_type             router_information\
        -router_info_route_category          secondary\
        -router_info_scope                   area_local\
        -router_info_options                 ebit\
        -mode                                create\
]

set status [keylget device_ret0_router0 status]
if {$status == 0} {
    puts "run sth::emulation_ospf_lsa_config failed"
    puts $device_ret0_router0
} else {
    puts "***** run sth::emulation_ospf_lsa_config successfully"
    puts $device_ret0_router0
}

set routerInfoHnd [keylget device_ret0_router0 lsa_handle]

#API to configure OSPF Algorithm TLV under router info LSA
set device_ret0_algorithm_tlv [sth::emulation_ospf_tlv_config\
        -type                                algorithm_tlv\
        -algorithms                          0\
        -handle                              $routerInfoHnd\
        -mode                                create\
]

set status [keylget device_ret0_router0 status]
if {$status == 0} {
    puts "run sth::emulation_ospf_tlv_config failed"
    puts $device_ret0_algorithm_tlv
} else {
    puts "***** run sth::emulation_ospf_tlv_config successfully"
    puts $device_ret0_algorithm_tlv
}

set routerInfoHnd [keylget device_ret0_router0 lsa_handle]
#API to configure OSPF Sgement ID /Label under router info LSA
set device_ret0_sid_label_range_tlv [sth::emulation_ospf_tlv_config\
        -type                                sid_label_range_tlv\
        -handle                              $routerInfoHnd\
        -mode                                create\
        -sid_label_range_size                100\
        -sid_label_value                     100\
        -sid_label_value_type                label\
]

set status [keylget device_ret0_router0 status]
if {$status == 0} {
    puts "run sth::emulation_ospf_tlv_config failed"
    puts $device_ret0_sid_label_range_tlv
} else {
    puts "***** run sth::emulation_ospf_tlv_config successfully"
    puts $device_ret0_sid_label_range_tlv
}

#API to configure OSPF Extended Prefix LSA
set device_ret0_extended_prefix [sth::emulation_ospf_lsa_config\
        -type                                extended_prefix\
        -handle                              $ospf_router0\
        -extended_prefix_instance            1\
        -extended_prefix_opaque_type         extended_prefix\
        -extended_prefix_adv_router_id 10.0.0.2\
        -extended_prefix_route_category      unique\
        -extended_prefix_scope               area_local\
        -extended_prefix_options             ebit\
        -mode                                create\
]

set status [keylget device_ret0_router0 status]
if {$status == 0} {
    puts "run sth::emulation_ospf_lsa_config failed"
    puts $device_ret0_extended_prefix
} else {
    puts "***** run sth::emulation_ospf_lsa_config successfully"
    puts $device_ret0_extended_prefix
}

set extendedPrefixHnd [keylget device_ret0_extended_prefix lsa_handle]

#API to configure OSPF Extended prefix TLV under Extended Prefix LSA
set device_ret0_extended_prefix_tlv [sth::emulation_ospf_tlv_config\
        -type                                extended_prefix_tlv\
        -handle                              $extendedPrefixHnd\
        -mode                                create\
        -extended_prefix_addr_family         ipv4_unicast\
        -extended_prefix_addr_prefix         10.0.0.2\
        -extended_prefix_prefix_length       32\
        -extended_prefix_route_type          unspecified\
]


set status [keylget device_ret0_extended_prefix_tlv status]
if {$status == 0} {
    puts "run sth::emulation_ospf_tlv_config failed"
    puts $device_ret0_extended_prefix_tlv
} else {
    puts "***** run sth::emulation_ospf_tlv_config successfully"
    puts $device_ret0_extended_prefix_tlv
}

set extended_prefix_tlv_Hnd [keylget device_ret0_extended_prefix_tlv handle]

#API to configure OSPF prefix SID TLV under Extended Prefix LSA
set device_ret0_prefix_sid_tlv [sth::emulation_ospf_tlv_config\
        -type                                prefix_sid_tlv\
        -handle                              $extended_prefix_tlv_Hnd\
        -mode                                create\
        -prefix_sid_flags                    nbit\
        -prefix_sid_algorithm_value          0\
        -prefix_sid_index                    0\
        -prefix_sid_multi_topo_id            0\
        -prefix_sid_range_size               1\
]
set status [keylget device_ret0_prefix_sid_tlv status]
if {$status == 0} {
    puts "run sth::emulation_ospf_tlv_config failed"
    puts $device_ret0_prefix_sid_tlv
} else {
    puts "***** run sth::emulation_ospf_tlv_config successfully"
    puts $device_ret0_prefix_sid_tlv
}


#######################################
set mpls_session_handle [lindex [keylget device_ret2 handle] 0]
set igp_session_handle [lindex [keylget device_ret2 handle] 0]
set bgp_session_handle [lindex [keylget device_ret0 handle] 0]

#API to configure MPLS L3VPN PE router
set pe_router [sth::emulation_mpls_l3vpn_pe_config\
        -mode                                             enable\
        -port_handle                                      $port1\
        -pe_count                                         1\
        -enable_p_router                                  1\
        -bgp_session_handle                          $bgp_session_handle\
        -mpls_session_handle                              $mpls_session_handle\
        -igp_session_handle                               $igp_session_handle\
]

set status [keylget pe_router status]
if {$status == 0} {
    puts "run sth::emulation_mpls_l3vpn_pe_config failed"
    puts $pe_router
} else {
    puts "***** run sth::emulation_mpls_l3vpn_pe_config successfully"
}

#start to config protocol on the device: CE IPv4 Router 1

#API to configure MPLS L3VPN CE router
set device_cfg_ret0 [sth::emulation_mpls_l3vpn_site_config\
        -mode                                             create\
        -vpn_id                                           100\
        -pe_loopback_ip_prefix                            32 \
        -pe_loopback_ip_addr                              10.0.0.1 \
        -rd_start                                         1:0 \
        -port_handle                                      $port2\
        -ce_session_handle                                $bgp_router1\
        -interface_ip_addr                                30.1.1.2 \
        -interface_ip_prefix                              24 \
]

set status [keylget device_cfg_ret0 status]
if {$status == 0} {
    puts "run sth::emulation_mpls_l3vpn_site_config failed"
    puts $device_cfg_ret0
} else {
    puts "***** run sth::emulation_mpls_l3vpn_site_config successfully"
}

##############################################################
#create traffic
##############################################################

set src_hdl [lindex [keylget device_ret0_route1 handles] 0]

set dst_hdl [lindex [keylget device_ret1_route1 handles] 0]

#API to configure traffic streamblock
set streamblock_ret1 [::sth::traffic_config    \
        -mode                                             create\
        -port_handle                                      $port1\
        -emulation_src_handle                             $src_hdl\
        -emulation_dst_handle                             $dst_hdl\
        -l3_protocol                                      ipv4\
        -ip_id                                            0\
        -ip_ttl                                           255\
        -ip_hdr_length                                    5\
        -ip_protocol                                      253\
        -ip_fragment_offset                               0\
        -ip_mbz                                           0\
        -ip_precedence                                    0\
        -ip_tos_field                                     0\
        -enable_control_plane                             0\
        -l3_length                                        128\
        -name                                             VPN_IPv4_PE_StreamBlock_3\
        -fill_type                                        constant\
        -fcs_error                                        0\
        -fill_value                                       0\
        -frame_size                                       128\
        -traffic_state                                    1\
        -high_speed_result_analysis                       1\
        -length_mode                                      fixed\
        -disable_signature                                0\
        -enable_stream_only_gen                           1\
        -pkts_per_burst                                   1\
        -inter_stream_gap_unit                            bytes\
        -burst_loop_count                                 30\
        -transmit_mode                                    continuous\
        -inter_stream_gap                                 12\
        -rate_percent                                     10\
        -mac_discovery_gw                                 20.1.1.1 \
]

set status [keylget streamblock_ret1 status]
if {$status == 0} {
    puts "run sth::traffic_config failed"
    puts $streamblock_ret1
} else {
    puts "***** run sth::traffic_config successfully"
}

set src_hdl [lindex [keylget device_ret1_route1 handles] 0]

set dst_hdl [lindex [keylget device_ret0_route1 handles] 0]


set streamblock_ret2 [::sth::traffic_config    \
        -mode                                             create\
        -port_handle                                      $port2\
        -emulation_src_handle                             $src_hdl\
        -emulation_dst_handle                             $dst_hdl\
        -l3_protocol                                      ipv4\
        -ip_id                                            0\
        -ip_ttl                                           255\
        -ip_hdr_length                                    5\
        -ip_protocol                                      253\
        -ip_fragment_offset                               0\
        -ip_mbz                                           0\
        -ip_precedence                                    0\
        -ip_tos_field                                     0\
        -enable_control_plane                             0\
        -l3_length                                        128\
        -name                                             VPN_IPv4_CE_StreamBlock_2\
        -fill_type                                        constant\
        -fcs_error                                        0\
        -fill_value                                       0\
        -frame_size                                       128\
        -traffic_state                                    1\
        -high_speed_result_analysis                       1\
        -length_mode                                      fixed\
        -disable_signature                                0\
        -enable_stream_only_gen                           1\
        -pkts_per_burst                                   1\
        -inter_stream_gap_unit                            bytes\
        -burst_loop_count                                 30\
        -transmit_mode                                    continuous\
        -inter_stream_gap                                 12\
        -rate_percent                                     10\
        -mac_discovery_gw                                 30.1.1.1 \
]

set status [keylget streamblock_ret2 status]
if {$status == 0} {
    puts "run sth::traffic_config failed"
    puts $streamblock_ret2
} else {
    puts "***** run sth::traffic_config successfully"
}

stc::perform SaveAsXml -FileName "HLTAPI_l3vpn_sr.xml"
#config parts are finished

##############################################################
#start devices
##############################################################

set device_list "[lindex [keylget device_ret0 handle] 0] [lindex [keylget device_ret1 handle] 0]"

set ctrl_ret1 [sth::emulation_bgp_control    \
        -handle                                           $device_list\
        -mode                                             start\
]

set status [keylget ctrl_ret1 status]
if {$status == 0} {
    puts "run sth::emulation_bgp_control failed"
    puts $ctrl_ret1
} else {
    puts "***** run sth::emulation_bgp_control successfully"
}

set device_list [lindex [keylget device_ret2 handle] 0]

set ctrl_ret3 [sth::emulation_ospf_control    \
        -handle                                           $device_list\
        -mode                                             start\
]

set status [keylget ctrl_ret3 status]
if {$status == 0} {
    puts "run sth::emulation_ospf_control failed"
    puts $ctrl_ret3
} else {
    puts "***** run sth::emulation_ospf_control successfully"
}

##############################################################
#start traffic
##############################################################

set traffic_ctrl_ret [::sth::traffic_control    \
        -port_handle                                      "$port1 $port2 "\
        -action                                           run\
]

set status [keylget traffic_ctrl_ret status]
if {$status == 0} {
    puts "run sth::traffic_control failed"
    puts $traffic_ctrl_ret
} else {
    puts "***** run sth::traffic_control successfully"
}

##############################################################
#start to get the device results
##############################################################

set device [lindex [keylget device_ret0 handle] 0]

set results_ret1 [sth::emulation_bgp_info    \
        -handle                                           $device\
        -mode                                             stats\
]

set status [keylget results_ret1 status]
if {$status == 0} {
    puts "run sth::emulation_bgp_info failed"
    puts $results_ret1
} else {
    puts "***** run sth::emulation_bgp_info successfully, and results is:"
    puts "$results_ret1\n"
}

set device [lindex [keylget device_ret1 handle] 0]

set results_ret2 [sth::emulation_bgp_info    \
        -handle                                           $device\
        -mode                                             stats\
]

set status [keylget results_ret2 status]
if {$status == 0} {
    puts "run sth::emulation_bgp_info failed"
    puts $results_ret2
} else {
    puts "***** run sth::emulation_bgp_info successfully, and results is:"
    puts "$results_ret2\n"
}

set device [lindex [keylget device_ret0 handle] 0]

set results_ret4 [sth::emulation_bgp_route_info    \
        -handle                                           $device\
        -mode                                             advertised\
]

set status [keylget results_ret4 status]
if {$status == 0} {
    puts "run sth::emulation_bgp_route_info failed"
    puts $results_ret4
} else {
    puts "***** run sth::emulation_bgp_route_info successfully, and results is:"
    puts "$results_ret4\n"
}

set device [lindex [keylget device_ret1 handle] 0]

set results_ret5 [sth::emulation_bgp_route_info    \
        -handle                                           $device\
        -mode                                             advertised\
]

set status [keylget results_ret5 status]
if {$status == 0} {
    puts "run sth::emulation_bgp_route_info failed"
    puts $results_ret5
} else {
    puts "***** run sth::emulation_bgp_route_info successfully, and results is:"
    puts "$results_ret5\n"
}

set device_list [lindex [keylget device_ret2 handle] 0]

set results_ret7 [sth::emulation_ospfv2_info    \
        -handle                                           $device_list\
]

set status [keylget results_ret7 status]
if {$status == 0} {
    puts "run sth::emulation_ospfv2_info failed"
    puts $results_ret7
} else {
    puts "***** run sth::emulation_ospfv2_info successfully, and results is:"
    puts "$results_ret7\n"
}

set device_list [lindex [keylget device_ret2 handle] 0]

set route_results_ret7 [sth::emulation_ospf_route_info    \
        -handle                                           $device_list\
]

set status [keylget route_results_ret7 status]
if {$status == 0} {
    puts "run sth::emulation_ospf_route_info failed"
    puts $route_results_ret7
} else {
    puts "***** run sth::emulation_ospf_route_info successfully, and results is:"
    puts "$route_results_ret7\n"
}

##############################################################
#start to get the traffic results
##############################################################

set traffic_results_ret [::sth::traffic_stats    \
        -port_handle                                      "$port1 $port2 "\
        -mode                                             all\
]

set status [keylget traffic_results_ret status]
if {$status == 0} {
    puts "run sth::traffic_stats failed"
    puts $traffic_results_ret
} else {
    puts "***** run sth::traffic_stats successfully, and results is:"
    puts "$traffic_results_ret\n"
}

##############################################################
#clean up the session, release the ports reserved and cleanup the dbfile
##############################################################

set cleanup_sta [sth::cleanup_session\
        -port_handle                                      $port1 $port2 \
        -clean_dbfile                                     1]

set status [keylget cleanup_sta status]
if {$status == 0} {
    puts "run sth::cleanup_session failed"
    puts $cleanup_sta
} else {
    puts "***** run sth::cleanup_session successfully"
}

puts "**************Finish***************"

