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
# File Name:         HLTAPI_PPPoX_DualStackOverAtm.tcl
#
# Description:      This script demonstrates the use of Spirent HLTAPI to setup PPPoeoa with dual stack
#
# Test Step:         1. Reserve and connect chassis ports
#                    2. Config Gig Interface on port2
#                    2. Config pppoeoa with dual stack on port1
#                    4. Start pppoeoa connect and check status
#                    5. Setup both ipv4 and ipv6 traffic
#                    6. Start traffic
#                    7. Check traffic statistics
#                    8. Release resources
#
# Topology
#                    PPPoX Client       PTA               Host
#                   STC1 (ATM) --------- DUT ----------- STC2 (Gig or Tengig)
#
########################################

# Run sample:
#            c:>tclsh HLTAPI_PPPoX_DualStackOverAtm.tcl 10.61.44.2 3/1 3/3
#            c:>tclsh HLTAPI_PPPoX_DualStackOverAtm.tcl "10.61.44.2 10.61.44.7" 3/1 3/3

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
set port_list "$port1 $port2"

::sth::test_config  -logfile hltLogfile \
                        -log 1\
                        -vendorlogfile stcExport\
                        -vendorlog 1\
                        -hltlog 1\
                        -hltlogfile hltExport\
                        -hlt2stcmappingfile hlt2stcMapping \
                        -hlt2stcmapping 1\
                        -log_level 7

set ipv4_traffic 1  
set ipv6_traffic 1

########################################
puts "\nStep1: Reserve and connect chassis ports"
########################################
set returnedString [sth::connect -device $device1 -port_list  $port1]
puts $returnedString 
set returnedString [sth::connect -device $device2 -port_list  $port2]
puts $returnedString 

########################################
puts "\nStep2: Config Gig Interface on port2"
########################################
set returnedString [sth::interface_config \
                            -port_handle port2 \
                            -mode config \
                            -intf_ip_addr "22.28.0.2" \
                            -gateway    "22.28.0.1" \
                            -ipv6_intf_addr "2002:0:0:2222::2" \
                            -ipv6_gateway  "2002:0:0:2222::1" \
                            -autonegotiation 1 \
                            -arp_send_req 1 \
                            -arp_req_retries 10 \
                        ]
puts $returnedString

########################################
puts "\nStep3: Config pppoeoa with dual stack on Port1"
########################################
set returnedString [sth::pppox_config \
                       -port_handle port1 \
                       -mode create\
                       -ip_cp "ipv4v6_cp" \
                       -encap "llcsnap ethernet_ii_vlan" \
                       -protocol pppoeoa\
                       -username "spirent" \
                       -password "spirent" \
                       -num_sessions 1 \
                       -vlan_id 330 \
                       -vlan_id_step 1 \
                       -vlan_id_count 1 \
                       -vpi 0 \
                       -vpi_count 1 \
                       -vci 330 \
                       -vci_step 1 \
                       -vci_count 1 \
                       -pvc_incr_mode vci \
                       -auth_mode "chap" \
                       -chap_ack_timeout 10\
                       -config_req_timeout 10\
                       -ipcp_req_timeout 10\
                       -auto_retry 1\
                       -max_auto_retry_count 10\
                       -max_echo_acks 10\
                       -max_ipcp_req 10]
keylget returnedString handles pppox_handles
puts $returnedString

########################################
puts "\nStep4: Start pppoeoa connect and check status"
########################################
set returnedString [sth::pppox_control -handle $pppox_handles -action connect]
puts $returnedString
after 60000
set returnedString [sth::pppox_stats  -handle $pppox_handles  -mode aggregate]
set sessions_up [keylget returnedString aggregate.sessions_up]
puts "total session_up: $sessions_up"
  
########################################
puts "\nStep5: Setup both ipv4 and ipv6 traffic"
########################################  
if {$ipv6_traffic} {
    set returnedString [sth::traffic_config \
                            -mode create \
                            -port_handle port1 \
                            -rate_pps 100 \
                            -l3_protocol ipv6 \
                            -l3_length 128\
                            -transmit_mode continuous\
                            -length_mode fixed \
                            -emulation_src_handle $pppox_handles \
                            -ipv6_dst_addr "2002:0:0:2222::2"]
    puts "ipv6 upstream: $returnedString"
    keylget returnedString stream_id streamv6_up_id
    
    set returnedString [sth::traffic_config \
                            -mode create \
                            -port_handle port2 \
                            -rate_pps 50 \
                            -l3_protocol ipv6 \
                            -l3_length 128\
                            -transmit_mode continuous\
                            -length_mode fixed \
                            -emulation_dst_handle $pppox_handles \
                            -ipv6_src_addr "2002:0:0:2222::2"]
    puts "ipv6 downstream: $returnedString"
    keylget returnedString stream_id streamv6_down_id
}

if {$ipv4_traffic} {
    set returnedString [sth::traffic_config \
                            -mode create \
                            -port_handle port1 \
                            -rate_pps 100 \
                            -l3_protocol ipv4 \
                            -l3_length 128\
                            -transmit_mode continuous\
                            -length_mode fixed \
                            -emulation_src_handle $pppox_handles \
                            -ip_dst_addr "22.28.0.2"]
    puts "ipv4 upstream: $returnedString"
    keylget returnedString stream_id streamv4_up_id
    
    set returnedString [sth::traffic_config \
                            -mode create \
                            -port_handle port2 \
                            -rate_pps 50 \
                            -l3_protocol ipv4 \
                            -l3_length 128\
                            -transmit_mode continuous\
                            -length_mode fixed \
                            -emulation_dst_handle $pppox_handles \
                            -ip_src_addr "22.28.0.2"\
                            -mac_discovery_gw "22.28.0.1"]
    puts "ipv4 downstream: $returnedString"
    keylget returnedString stream_id streamv4_down_id
}

#config parts are finished

########################################
puts "\nStep6: Start traffic"
########################################
set returnedString [sth::traffic_control -port_handle port1 -action run]
puts $returnedString
set returnedString [sth::traffic_control -port_handle port2 -action run]
puts $returnedString
after 10000
  
########################################
puts "\nStep7: Check traffic statistics"
########################################
if {$ipv6_traffic} {
    set returnedString [sth::traffic_stats -streams $streamv6_up_id -mode streams]
    set Rx_Rate [keylget returnedString port1.stream.$streamv6_up_id.rx.total_pkt_rate]
    set Tx_Rate [keylget returnedString port1.stream.$streamv6_up_id.tx.total_pkt_rate]
    puts "Ipv6 Upstream:"
    puts "\tTx_Rate : -------------------------------$Tx_Rate"
    puts "\tRx_Rate : -------------------------------$Rx_Rate"
    
    set returnedString [sth::traffic_stats -streams $streamv6_down_id -mode streams]
    set Rx_Rate [keylget returnedString port2.stream.$streamv6_down_id.rx.total_pkt_rate]
    set Tx_Rate [keylget returnedString port2.stream.$streamv6_down_id.tx.total_pkt_rate]
    puts "Ipv6 Downstream:"
    puts "\tTx_Rate : -------------------------------$Tx_Rate"
    puts "\tRx_Rate : -------------------------------$Rx_Rate"
}
if {$ipv4_traffic} {
    set returnedString [sth::traffic_stats -streams $streamv4_up_id -mode streams]
    set Rx_Rate [keylget returnedString port1.stream.$streamv4_up_id.rx.total_pkt_rate]
    set Tx_Rate [keylget returnedString port1.stream.$streamv4_up_id.tx.total_pkt_rate]
    puts "Ipv4 Upstream:"
    puts "\tTx_Rate : -------------------------------$Tx_Rate"
    puts "\tRx_Rate : -------------------------------$Rx_Rate"
    
    set returnedString [sth::traffic_stats -streams $streamv4_down_id -mode streams]
    set Rx_Rate [keylget returnedString port2.stream.$streamv4_down_id.rx.total_pkt_rate]
    set Tx_Rate [keylget returnedString port2.stream.$streamv4_down_id.tx.total_pkt_rate]
    puts "Ipv4 Downstream:"
    puts "\tTx_Rate : -------------------------------$Tx_Rate"
    puts "\tRx_Rate : -------------------------------$Rx_Rate"
}

########################################
puts "\nStep8: Release resources"
########################################
set returnedString [::sth::cleanup_session -port_list [list port1 port2]]
puts $returnedString
if {![keylget returnedString status ]} {
    return "FAILED"
}

puts "_SAMPLE_SCRIPT_SUCCESS"