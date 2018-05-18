# Copyright (c) 2007 by Spirent Communications, Inc.
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
#
#
# File Name:       HLTAPI_multiProtocols.tcl
#
# Description:    This script demonstrates the use of enable mutiple protocols on one router
#
# Test Step:      1. Create router under port1 and enable LDP, RSVP and RIP protocol on it
#                 2. Create router under port2 and enable BGP, ISIS, OSPF and PIM protocol on it
###################################################################################

# Run sample:
#            c:>tclsh HLTAPI_MultiProtocols.tcl 10.61.44.2 3/1 3/3
#            c:>tclsh HLTAPI_MultiProtocols.tcl "10.61.44.2 10.61.44.7" 3/1 3/3

package require SpirentHltApi

set device_list      [lindex $argv 0]
set srcPort        [lindex $argv 1]
set dstPort        [lindex $argv 2]
set i 1
foreach device $device_list {
    set device$i $device
    incr i
}
set device$i $device
set port_list "$srcPort $dstPort";

::sth::test_config  -logfile hltLogfile \
                    -log 1\
                    -vendorlogfile stcExport\
                    -vendorlog 1\
                    -hltlog 1\
                    -hltlogfile hltExport\
                    -hlt2stcmappingfile NDM_Mapping \
                    -hlt2stcmapping 1\
                    -log_level 7

set dut_intf_tgen_ip    {"13.25.0.1"   "13.31.0.1"}
set tgen_intf_dut_ip     {"13.25.0.2" "13.31.0.2"}

set returnedString [sth::connect -device $device_list -port_list $port_list ]
keylget returnedString port_handle.$device1.$srcPort tgen1_port
keylget returnedString port_handle.$device2.$dstPort tgen2_port

set index 0
foreach {port1 port2} "$tgen1_port $tgen2_port"  {
    puts "################################################"
    puts "###    Part1"
    puts "###    LDP RSVP RIP"
    puts "###    10.99.0.191 g13/25, g13/26"
    puts "################################################"
    puts "Router Configuration----------"
    set routerStatus [sth::emulation_ldp_config -mode create \
                                        -port_handle $port1\
                                        -intf_ip_addr           [lindex $tgen_intf_dut_ip $index] \
                                        -loopback_ip_addr [lindex $tgen_intf_dut_ip $index] \
                                        -gateway_ip_addr  [lindex $tgen_intf_dut_ip  $index] \
                                        -remote_ip_addr    [lindex $tgen_intf_dut_ip  $index] \
                                        -graceful_recovery_timer 55 \
                                        -keepalive_interval 56 \
                                        -reconnect_time 57 \
                                        -recovery_time 58 \
                                        -egress_label_mode exnull \
                                        -label_adv   on_demand \
                                        -bfd_registration 1 \
                                       ]
    puts "LDP:  $routerStatus"
    keylget routerStatus handle router
    
    set routerStatus [sth::emulation_rip_config \
                                        -handle    $router\
                                        -mode create \
                                        -authentication_mode "null" \
                                        -send_type unicast \
                                        -neighbor_intf_ip_addr [lindex $dut_intf_tgen_ip $index] \
                                     ]
    puts "RIP:  $routerStatus"
    
    set routerStatus [sth::emulation_rsvp_config -mode create \
                                          -handle $router\
                                          -recovery_time 55 \
                                          -bfd_registration 1 \
                                        ]
    puts "RSVP: $routerStatus\n"
    
    
    puts "Start Router -----------------"
    set routerStatus [sth::emulation_ldp_control -mode start -handle $router ]
    puts "LDP:  $routerStatus"
    set routerStatus [sth::emulation_rip_control -mode start -handle $router ]
    puts "RIP:  $routerStatus"
    set routerStatus [sth::emulation_rsvp_control -mode start -handle $router ]
    puts "RSVP: $routerStatus\n"
    
    after 20000
    puts "Router Info-------------------"
    set router_state [stc::get [stc::get $router -children-ldpRouterConfig] -RouterState]
    puts "LDP:  $router_state"
    set router_state [stc::get [stc::get $router -children-ripRouterConfig] -RouterState]
    puts "RIP:  $router_state"
    set router_state [stc::get [stc::get $router -children-rsvpRouterConfig] -RouterState]
    puts "RSVP: $router_state"

    puts "********Part1 Success********\n\n\n"    
    
    incr index
    puts "################################################"
    puts "###    Part2"
    puts "###    BGP ISIS OSPF PIM"
    puts "###    10.99.0.191 g13/31, g13/32"
    puts "################################################"
    puts "Router Configuration----------"
    set routerStatus [sth::emulation_bgp_config -mode enable \
                                      -port_handle $port2\
                                      -active_connect_enable    1 \
                                      -ip_version                4 \
                                      -local_as            123 \
                                      -remote_ip_addr  [lindex $dut_intf_tgen_ip  $index] \
                                      -next_hop_ip       [lindex $dut_intf_tgen_ip  $index] \
                                      -local_ip_addr      [lindex $tgen_intf_dut_ip  $index] \
                                      -local_router_id    [lindex $tgen_intf_dut_ip  $index] \
                                      -remote_as            123\
                                    ]
    puts "BGP:  $routerStatus"
    keylget routerStatus handle router2
    
    set routerStatus [sth::emulation_pim_config -mode create \
                                      -handle $router2\
                                      -type remote_rp \
                                      -ip_version 4 \
                                      -dr_priority 5 \
                                    ]
    puts "PIM:  $routerStatus"
    
    set routerStatus [sth::emulation_ospf_config -mode create \
                                    -handle $router2\
                                    -session_type    ospfv2 \
                                    -area_id        0.0.0.0 \
                                    -network_type            broadcast \
                                ]
    puts "OSPF: $routerStatus"
    
    set routerStatus  [sth::emulation_isis_config \
                                    -handle $router2 \
                                    -mode create  \
                                    -ip_version 4 \
                                    -area_id 000000000001 \
                                   ]
    puts "ISIS: $routerStatus\n"
    
    puts "Inactive protocol-------------"
    foreach protocol {"ospf" "pim" "isis" "bgp"} {
            set routerStatus [sth::emulation_$protocol\_config -mode inactive -handle $router2]
            puts "$protocol $routerStatus"
    }

    puts "Active protocol---------------"
    foreach protocol {"ospf" "pim" "isis" "bgp"} {
            set routerStatus [sth::emulation_$protocol\_config -mode active -handle $router2]
            puts "$protocol $routerStatus"
    }
    
    puts "Start Router -----------------"
    set routerStatus [sth::emulation_bgp_control -mode start -handle $router2 ]
    puts "BGP:  $routerStatus"
    set routerStatus [sth::emulation_pim_control -mode start -handle $router2 ]
    puts "PIM:  $routerStatus"
    set routerStatus [sth::emulation_ospf_control -mode start -handle $router2 ]
    puts "OSPF: $routerStatus"
    set routerStatus [sth::emulation_isis_control -mode start -handle $router2 ]
    puts "ISIS: $routerStatus\n"
    
    after 20000
    puts "Router Info-------------------"
    set router_state [stc::get [stc::get $router2 -children-bgpRouterConfig] -RouterState]
    puts "BGP:  $router_state"
    set router_state [stc::get [stc::get $router2 -children-pimRouterConfig] -RouterState]
    puts "PIM:  $router_state"
    set router_state [stc::get [stc::get $router2 -children-ospfv2RouterConfig] -RouterState]
    puts "OSPF: $router_state"
    set router_state [stc::get [stc::get $router2 -children-isisRouterConfig] -RouterState]
    puts "ISIS: $router_state\n"
    
    puts "********Part2 Success********\n\n\n"    
}
    

set returnedString [sth::cleanup_session -port_handle [list $tgen1_port $tgen2_port]]
puts "_SAMPLE_SCRIPT_SUCCESS"
 