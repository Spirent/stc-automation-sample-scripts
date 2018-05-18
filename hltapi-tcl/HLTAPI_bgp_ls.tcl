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
# File Name:     HLTAPI_bgp_ls.tcl
#
# Objective: This script demonstrates the use of Spirent HLTAPI to setup ISIS with Segment Routing
#
# Test Step:
#    1. Reserve and connect chassis ports         
#    2. Config BGP on Port1 & port2 with Link state NLRI's
#    3. Start BGP 
#    4. Get BGP Info
#    5. Release resources
# 
#Topology: B2B
#################################
package require SpirentHltApi

##############################################################
#config the parameters for the logging
##############################################################

set test_sta [sth::test_config\
    -log          1\
    -logfile      bgp_hlt_sr_logfile\
    -vendorlogfile    bgp_hlt_sr_stcExport\
    -vendorlog    1\
    -hltlog       1\
    -hltlogfile       bgp_hlt_sr_hltExport\
    -hlt2stcmappingfile           bgp_hlt_sr_hlt2StcMapping\
    -hlt2stcmapping   1\
    -log_level    7]

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
    -action       enable]

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

#start to create the device: Device 1
#API to configure bgp router
set device_ret0 [sth::emulation_bgp_config\
    -mode         enable\
    -retries      100 \
    -vpls_version     VERSION_00 \
    -routes_per_msg   2000 \
    -staggered_start_time         100 \
    -update_interval  30 \
    -retry_time       30 \
    -staggered_start_enable       1\
    -md5_key_id       1 \
    -md5_key      Spirent \
    -md5_enable       0 \
    -ip_stack_version 4\
    -port_handle      $port1\
    -bgp_session_ip_addr          interface_ip \
    -remote_ip_addr   193.85.1.3 \
    -ip_version       4 \
    -remote_as    1 \
    -hold_time    90 \
    -restart_time     90 \
    -route_refresh    0 \
    -local_as     1001 \
    -active_connect_enable        1 \
    -stale_time       90 \
    -graceful_restart_enable      0 \
    -local_router_id  192.0.0.3 \
    -mac_address_start 00:10:94:00:00:01 \
    -local_ip_addr    193.85.1.1 \
    -next_hop_ip      193.85.1.3 \
    -netmask      24 \
]

set status [keylget device_ret0 status]
if {$status == 0} {
    puts "run sth::emulation_bgp_config failed"
    puts $device_ret0
} else {
    puts "***** run sth::emulation_bgp_config successfully"
}
set bgp_router1 [lindex [keylget device_ret0 handle] 0]


#API to configure BGP link state route
set link_state_hnd [sth::emulation_bgp_route_config\
    -mode    add \
    -handle  $bgp_router1\
    -route_type          link_state\
    -ls_as_path          1\
    -ls_as_path_segment_type sequence\
    -ls_enable_node      true\
    -ls_identifier       0\
    -ls_identifiertype       customized\
    -ls_next_hop         1.0.0.1\
    -ls_next_hop_type    ipv4\
    -ls_origin           igp\
    -ls_protocol_id      OSPF_V2\
    -ls_link_desc_flag       "as_number|bgp_ls_id|OSPF_AREA_ID|igp_router_id"\
    -ls_link_desc_as_num     1\
    -ls_link_desc_bgp_ls_id  1666667\
    -ls_link_desc_ospf_area_id           0\
    -ls_link_desc_igp_router_id_type     ospf_non_pseudo_node\
    -ls_link_desc_igp_router_id          1.0.0.1\
    -ls_node_attr_flag       "SR_ALGORITHMS|SR_CAPS"\
    -ls_node_attr_sr_algorithms          "LINK_METRIC_BASED_SPF"\
    -ls_node_attr_sr_value_type          "label"\
    -ls_node_attr_sr_capability_flags    "ipv4"\
    -ls_node_attr_sr_capability_base_list    "100"\
    -ls_node_attr_sr_capability_range_list   "100"]
    

if {$status == 0} {
    puts "run sth::emulation_bgp_route_config failed"
    puts $link_state_hnd
} else {
    puts "***** run sth::emulation_bgp_route_config successfully"
    puts $link_state_hnd
}
set lsLinkConfigHnd [keylget link_state_hnd handles]

#API to configure Link contents under BGL LS route
set ls_link_hnd [sth::emulation_bgp_route_config\
    -mode    add\
    -handle  $bgp_router1\
    -route_handle        $lsLinkConfigHnd \
    -route_type          link_state\
    -ls_link_attr_flag       "SR_ADJ_SID"\
    -ls_link_attr_link_protection_type       "EXTRA_TRAFFIC"\
    -ls_link_attr_value     9001\
    -ls_link_attr_value_type label\
    -ls_link_attr_weight    1\
    -ls_link_attr_te_sub_tlv_type      "local_ip|remote_ip"\
    -ls_link_desc_flags    "ipv4_intf_addr|IPV4_NBR_ADDR"\
    -ls_link_desc_ipv4_intf_addr        1.0.0.1\
    -ls_link_desc_ipv4_neighbor_addr    1.0.0.2\
    -ls_link_attr_te_local_ip       1.0.0.1\
    -ls_link_attr_te_remote_ip       1.0.0.2\
    ]
       

set status [keylget ls_link_hnd status]
if {$status == 0} {
    puts "run sth::emulation_bgp_route_config failed"
    puts $ls_link_hnd
} else {
    puts "***** run sth::emulation_bgp_route_config successfully"
    puts $ls_link_hnd
}

#API to configure IPv4 Prefix under BGL LS route
set ipv4_prefix_hnd [sth::emulation_bgp_route_config\
    -mode    add \
    -handle  $bgp_router1\
    -route_handle        $lsLinkConfigHnd \
    -route_type          link_state\
    -ls_prefix_attr_flags    "PREFIX_METRIC|SR_PREFIX_SID"\
    -ls_prefix_attr_algorithm 0\
    -ls_prefix_attr_prefix_metric          1\
    -ls_prefix_attr_value   101\
    -ls_prefix_desc_flags   "ip_reach_info|ospf_rt_type"\
    -ls_prefix_desc_ip_prefix_count 1\
    -ls_prefix_desc_ip_prefix_type ipv4_prefix\
    -ls_prefix_desc_ipv4_prefix 1.0.0.0\
    -ls_prefix_desc_ipv4_prefix_length 24\
    -ls_prefix_desc_ipv4_prefix_step 1\
    -ls_prefix_desc_ospf_route_type intra_area]
    
    

set status [keylget ipv4_prefix_hnd status]
if {$status == 0} {
    puts "run sth::emulation_bgp_route_config failed"
    puts $ipv4_prefix_hnd
} else {
    puts "***** run sth::emulation_bgp_route_config successfully"
    puts $ipv4_prefix_hnd
}

#start to create the device: Device 2
#API to configure BGP router
set device_ret1 [sth::emulation_bgp_config\
    -mode         enable\
    -retries      100 \
    -vpls_version     VERSION_00 \
    -routes_per_msg   2000 \
    -staggered_start_time         100 \
    -update_interval  30 \
    -retry_time       30 \
    -staggered_start_enable       1\
    -md5_key_id       1 \
    -md5_key      Spirent \
    -md5_enable       0 \
    -ip_stack_version 4\
    -port_handle      $port2\
    -bgp_session_ip_addr          interface_ip \
    -remote_ip_addr   193.85.1.1 \
    -ip_version       4 \
    -remote_as    1001 \
    -hold_time    90 \
    -restart_time     90 \
    -route_refresh    0 \
    -local_as     1 \
    -active_connect_enable        1 \
    -stale_time       90 \
    -graceful_restart_enable      0 \
    -local_router_id  192.0.0.3 \
    -mac_address_start 00:10:94:00:00:03 \
    -local_ip_addr    193.85.1.3 \
    -next_hop_ip      193.85.1.1 \
    -netmask      24 \
]

set status [keylget device_ret1 status]
if {$status == 0} {
    puts "run sth::emulation_bgp_config failed"
    puts $device_ret1
} else {
    puts "***** run sth::emulation_bgp_config successfully"
}
set bgp_router1 [lindex [keylget device_ret1 handle] 0]

#API to configure BGL Link State route
set link_state_hnd [sth::emulation_bgp_route_config\
    -mode    add \
    -handle  $bgp_router1\
    -route_type          link_state\
    -ls_as_path          1\
    -ls_as_path_segment_type sequence\
    -ls_enable_node      true\
    -ls_identifier       0\
    -ls_identifiertype       customized\
    -ls_next_hop         1.0.0.2\
    -ls_next_hop_type    ipv4\
    -ls_origin           igp\
    -ls_protocol_id      OSPF_V2\
    -ls_link_desc_flag       "as_number|bgp_ls_id|OSPF_AREA_ID|igp_router_id"\
    -ls_link_desc_as_num     1\
    -ls_link_desc_bgp_ls_id  1666667\
    -ls_link_desc_ospf_area_id           0\
    -ls_link_desc_igp_router_id_type     ospf_non_pseudo_node\
    -ls_link_desc_igp_router_id          1.0.0.2\
    -ls_node_attr_flag       "SR_ALGORITHMS|SR_CAPS"\
    -ls_node_attr_sr_algorithms          "LINK_METRIC_BASED_SPF"\
    -ls_node_attr_sr_value_type          "label"\
    -ls_node_attr_sr_capability_flags    "ipv4"\
    -ls_node_attr_sr_capability_base_list    "100"\
    -ls_node_attr_sr_capability_range_list   "100"]
    

if {$status == 0} {
    puts "run sth::emulation_bgp_route_config failed"
    puts $link_state_hnd
} else {
    puts "***** run sth::emulation_bgp_route_config successfully"
    puts $link_state_hnd
}
set lsLinkConfigHnd [keylget link_state_hnd handles]

##API to configure Link Contents under BGL LS route
set ls_link_hnd [sth::emulation_bgp_route_config\
    -mode    add\
    -handle  $bgp_router1\
    -route_handle        $lsLinkConfigHnd \
    -route_type          link_state\
    -ls_link_attr_flag       "SR_ADJ_SID"\
    -ls_link_attr_link_protection_type       "EXTRA_TRAFFIC"\
    -ls_link_attr_value     9001\
    -ls_link_attr_value_type label\
    -ls_link_attr_weight    1\
    -ls_link_attr_te_sub_tlv_type      "local_ip|remote_ip"\
    -ls_link_desc_flags    "ipv4_intf_addr|IPV4_NBR_ADDR"\
    -ls_link_desc_ipv4_intf_addr        1.0.0.1\
    -ls_link_desc_ipv4_neighbor_addr    1.0.0.2\
    -ls_link_attr_te_local_ip       1.0.0.1\
    -ls_link_attr_te_remote_ip       1.0.0.2\
    ]
       

set status [keylget ls_link_hnd status]
if {$status == 0} {
    puts "run sth::emulation_bgp_route_config failed"
    puts $ls_link_hnd
} else {
    puts "***** run sth::emulation_bgp_route_config successfully"
    puts $ls_link_hnd
}

#API to configure IPv4 Prefix under BGL LS route
set ipv4_prefix_hnd [sth::emulation_bgp_route_config\
    -mode    add \
    -handle  $bgp_router1\
    -route_handle        $lsLinkConfigHnd \
    -route_type          link_state\
    -ls_prefix_attr_flags    "PREFIX_METRIC|SR_PREFIX_SID"\
    -ls_prefix_attr_algorithm 0\
    -ls_prefix_attr_prefix_metric          1\
    -ls_prefix_attr_value   101\
    -ls_prefix_desc_flags   "ip_reach_info|ospf_rt_type"\
    -ls_prefix_desc_ip_prefix_count 1\
    -ls_prefix_desc_ip_prefix_type ipv4_prefix\
    -ls_prefix_desc_ipv4_prefix 1.0.0.0\
    -ls_prefix_desc_ipv4_prefix_length 24\
    -ls_prefix_desc_ipv4_prefix_step 1\
    -ls_prefix_desc_ospf_route_type intra_area]
    
    

set status [keylget ipv4_prefix_hnd status]
if {$status == 0} {
    puts "run sth::emulation_bgp_route_config failed"
    puts $ipv4_prefix_hnd
} else {
    puts "***** run sth::emulation_bgp_route_config successfully"
    puts $ipv4_prefix_hnd
}
    
stc::perform saveasxml -filename HLTAPI_bgp_ls.xml    
#config parts are finished


set device_list "[lindex [keylget device_ret0 handle] 0] [lindex [keylget device_ret1 handle] 0]"

set ctrl_ret1 [sth::emulation_bgp_control    \
    -handle       $device_list\
    -mode         start\
]

set status [keylget ctrl_ret1 status]
if {$status == 0} {
    puts "run sth::emulation_bgp_control failed"
    puts $ctrl_ret1
} else {
    puts "***** run sth::emulation_bgp_control successfully"
}
sleep 15
 
##############################################################
#start to get the device results
##############################################################

set device [lindex [keylget device_ret0 handle] 0]

set results_ret1 [sth::emulation_bgp_info    \
    -handle       $device\
    -mode         stats\
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
    -handle       $device\
    -mode         stats\
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
    -handle       $device\
    -mode         advertised\
]

set status [keylget results_ret4 status]
if {$status == 0} {
    puts "run sth::emulation_bgp_route_info failed"
    puts $results_ret4
} else {
    puts "***** run sth::emulation_bgp_route_info successfully, and results is:"
    puts "$results_ret4\n"
}
##############################################################
#clean up the session, release the ports reserved and cleanup the dbfile
##############################################################

set cleanup_sta [sth::cleanup_session\
    -port_handle      $port1 $port2 \
    -clean_dbfile     1]

set status [keylget cleanup_sta status]
if {$status == 0} {
    puts "run sth::cleanup_session failed"
    puts $cleanup_sta
} else {
    puts "***** run sth::cleanup_session successfully"
}

puts "**************Finish***************"
