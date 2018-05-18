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
# TFile Name:     HLTAPI_isis_sr.tcl
#
# Objective: This script demonstrates the use of Spirent HLTAPI to setup ISIS with Segment Routing
#
# Test Step:
#                    1. Reserve and connect chassis ports                             
#                    2. Config ISIS on POrt1 & port2 with Segment routing enabled in the routes
#                    3. Config bound stream traffic between ISIS router on port2 to ISIS LSP's configured on port1
#                    4. Start ISIS 
#                    5. Start Traffic
#                    6. Start MVPN
#                    7. Get ISIS Info
#                    8. Get Traffic Stats
#                    9. Release resources
# 
#Topology: B2B
#                             
#
#################################
package require SpirentHltApi

##############################################################
#config the parameters for the logging
##############################################################

set test_sta [sth::test_config\
        -log                                              1\
        -logfile                                          HLTAPI_isis_sr_logfile\
        -vendorlogfile                                    HLTAPI_isis_sr_stcExport\
        -vendorlog                                        1\
        -hltlog                                           1\
        -hltlogfile                                       HLTAPI_isis_sr_hltExport\
        -hlt2stcmappingfile                               HLTAPI_isis_sr_hlt2StcMapping\
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

#start to create the device: Router 1
#API to configure ISIS router
set device_ret0 [sth::emulation_isis_config\
        -mode                                             enable\
        -authentication_mode                              none\
        -intf_metric                                      1\
        -holding_time                                     30\
        -port_handle                                      $port1\
        -router_id                                        192.0.0.1 \
        -mac_address_start                                00:10:94:00:00:01 \
        -intf_ip_prefix_length                            24 \
        -intf_ip_addr                                     10.1.1.1 \
        -gateway_ip_addr                                  10.1.1.2 \
        -hello_interval                                   10 \
        -ip_version                                       4 \
        -graceful_restart_restart_time                    3 \
        -routing_level                                    L2 \
        -lsp_refresh_interval                             900 \
        -psnp_interval                                    2 \
        -intf_type                                        broadcast \
        -graceful_restart                                 0 \
        -wide_metrics                                     1 \
        -hello_padding                                    true \
        -area_id                                          000001 \
]

set status [keylget device_ret0 status]
if {$status == 0} {
    puts "run sth::emulation_isis_config failed"
    puts $device_ret0
} else {
    puts "***** run sth::emulation_isis_config successfully"
}
set isis_hnd1 [lindex [keylget device_ret0 handle] 0]

#API to configure ISIS LSP with segment routing enabled
set lspStatus [sth::emulation_isis_lsp_generator \
    -mode create \
    -handle $isis_hnd1 \
    -type tree \
    -loopback_adver_enable true\
    -tree_if_type POINT_TO_POINT\
    -ipv4_internal_emulated_routers NONE\
    -ipv4_internal_simulated_routers ALL\
    -ipv4_internal_count 0 \
    -tree_max_if_per_router 2\
    -tree_num_simulated_routers 2\
    -router_id_start 3.0.0.1 \
    -ipv4_addr_start 3.0.0.0 \
    -system_id_start 100000000001 \
    -isis_level LEVEL2\
    -segment_routing_enabled true\
    -sr_algorithms 0\
    -sr_cap_range 100\
    -sr_cap_value 100\
    -sr_cap_value_type label]


set status [keylget lspStatus status]
if {$status == 0} {
    puts "run sth::emulation_isis_lsp_generator failed"
    puts $lspStatus
} else {
    puts "***** run sth::emulation_isis_lsp_generator successfully"
    puts $lspStatus
}
set lsp1 [keylget lspStatus lsp_handle]

#start to create the device: Router 2
#API to configure ISIS router
set device_ret1 [sth::emulation_isis_config\
        -mode                                             enable\
        -authentication_mode                              none\
        -intf_metric                                      1\
        -holding_time                                     30\
        -port_handle                                      $port2\
        -router_id                                        192.0.0.2 \
        -mac_address_start                                00:10:94:00:00:02 \
        -intf_ip_prefix_length                            24 \
        -intf_ip_addr                                     10.1.1.2 \
        -gateway_ip_addr                                  10.1.1.1 \
        -hello_interval                                   10 \
        -ip_version                                       4 \
        -graceful_restart_restart_time                    3 \
        -routing_level                                    L2 \
        -lsp_refresh_interval                             900 \
        -psnp_interval                                    2 \
        -intf_type                                        broadcast \
        -graceful_restart                                 0 \
        -wide_metrics                                     1 \
        -hello_padding                                    true \
        -area_id                                          000001 \
]

set status [keylget device_ret1 status]
if {$status == 0} {
    puts "run sth::emulation_isis_config failed"
    puts $device_ret1
} else {
    puts "***** run sth::emulation_isis_config successfully"
}

set isis_hnd2 [lindex [keylget device_ret1 handle] 0]

#API to configure ISIS LSP with segment routing enabled
set lspStatus1 [sth::emulation_isis_lsp_generator \
    -mode create \
    -handle $isis_hnd2 \
    -type tree \
    -tree_if_type POINT_TO_POINT\
    -loopback_adver_enable true\
    -ipv4_internal_emulated_routers NONE\
    -ipv4_internal_simulated_routers ALL\
    -ipv4_internal_count 10 \
    -tree_max_if_per_router 2\
    -tree_num_simulated_routers 2\
    -router_id_start 4.0.0.1 \
    -ipv4_addr_start 4.0.0.0 \
    -system_id_start 100000000002 \
    -isis_level LEVEL2\
    -segment_routing_enabled true\
    -sr_algorithms 0\
    -sr_cap_range 100\
    -sr_cap_value 100\
    -sr_cap_value_type label]


set status [keylget lspStatus1 status]
if {$status == 0} {
    puts "run sth::emulation_isis_lsp_generator failed"
    puts $lspStatus1
} else {
    puts "***** run sth::emulation_isis_lsp_generator successfully"
    puts $lspStatus1
}

##############################################################
#create traffic
##############################################################

set src_hdl [lindex [keylget device_ret1 handle] 0]

#API to configure traffic
set streamblock_ret1 [::sth::traffic_config    \
        -mode                                             create\
        -port_handle                                      $port2\
        -emulation_src_handle                             $src_hdl\
        -emulation_dst_handle                             $lsp1\
        -tunnel_bottom_label                              $src_hdl\
        -l3_protocol                                      ipv4\
        -ip_id                                            0\
        -ip_dst_addr                                      192.0.0.1\
        -ip_ttl                                           255\
        -ip_hdr_length                                    5\
        -ip_protocol                                      253\
        -ip_fragment_offset                               0\
        -ip_mbz                                           0\
        -ip_precedence                                    6\
        -ip_tos_field                                     0\
        -enable_control_plane                             0\
        -l3_length                                        128\
        -name                                             StreamBlock_2-2\
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
        -burst_loop_count                                 1\
        -transmit_mode                                    multi_burst\
        -inter_stream_gap                                 12\
        -rate_percent                                     10\
        -mac_discovery_gw                                 10.1.1.1 \
]

set status [keylget streamblock_ret1 status]
if {$status == 0} {
    puts "run sth::traffic_config failed"
    puts $streamblock_ret1
} else {
    puts "***** run sth::traffic_config successfully"
}

stc::perform SaveAsXml -FileName "HLTAPI_isis_sr.xml"
#config parts are finished

##############################################################
#start devices
##############################################################


set device_list [lindex [keylget device_ret0 handle] 0]

set ctrl_ret2 [sth::emulation_isis_control    \
        -handle                                           $device_list\
        -mode                                             start\
]

set status [keylget ctrl_ret2 status]
if {$status == 0} {
    puts "run sth::emulation_isis_control failed"
    puts $ctrl_ret2
} else {
    puts "***** run sth::emulation_isis_control successfully"
}

set device_list [lindex [keylget device_ret1 handle] 0]

set ctrl_ret2 [sth::emulation_isis_control    \
        -handle                                           $device_list\
        -mode                                             start\
]

set status [keylget ctrl_ret2 status]
if {$status == 0} {
    puts "run sth::emulation_isis_control failed"
    puts $ctrl_ret2
} else {
    puts "***** run sth::emulation_isis_control successfully"
}


sleep 30
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

set results_ret2 [sth::emulation_isis_info    \
        -handle                                           $device\
        -mode                                             stats\
]

set status [keylget results_ret2 status]
if {$status == 0} {
    puts "run sth::emulation_isis_info failed"
    puts $results_ret2
} else {
    puts "***** run sth::emulation_isis_info successfully, and results is:"
    puts "$results_ret2\n"
}

set device [lindex [keylget device_ret1 handle] 0]

set results_ret3 [sth::emulation_isis_info    \
        -handle                                           $device\
        -mode                                             stats\
]

set status [keylget results_ret3 status]
if {$status == 0} {
    puts "run sth::emulation_isis_info failed"
    puts $results_ret3
} else {
    puts "***** run sth::emulation_isis_info successfully, and results is:"
    puts "$results_ret3\n"
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

