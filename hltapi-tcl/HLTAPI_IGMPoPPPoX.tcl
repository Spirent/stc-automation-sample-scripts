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
# File Name:         HLTAPI_IGMPoPPPoX.tcl
#
# Description:      This script demonstrates the use of Spirent HLTAPI to setup IGMP over PPPoE.
#
# Test Step:         1. Reserve and connect chassis ports
#                    2. Config Gig Interface on port2
#                    3. Config pppoe on Port1
#                    4. Config igmp over pppoe on Port1
#                    5  Config the Multicast Group
#                    6  Bound the IMGP and the Multicast Group
#                    7. Start pppoe connect and check status
#                    8. Start igmp join and check status
#                    9. Setup ipv4 multicast traffic
#                    10. Start traffic
#                    11. Check traffic statistics
#                    12. Release resources
#
# Topology
#           IGMPoPPPoX Client       PTA               Host
#                   STC1  --------- DUT ----------- STC2 (Gig or Tengig)
#
########################################

# Run sample:
#            c:>tclsh HLTAPI_IGMPoPPPoX.tcl 10.61.44.2 3/1 3/3
#            c:>tclsh HLTAPI_IGMPoPPPoX.tcl "10.61.44.2 10.61.44.7" 3/1 3/3

package require SpirentHltApi

set device_list      [lindex $argv 0]
set p1        [lindex $argv 1]
set p2        [lindex $argv 2]
set i 1
foreach device $device_list {
    set device$i $device
    incr i
}
set device$i $device

::sth::test_config  -logfile hltLogfile \
                        -log 1\
                        -vendorlogfile stcExport\
                        -vendorlog 1\
                        -hltlog 1\
                        -hltlogfile hltExport\
                        -hlt2stcmappingfile hlt2stcMapping \
                        -hlt2stcmapping 1\
                        -log_level 7

set pppoe_session_count 1
set mc_group_ip         "225.0.0.25"
set mc_group_count      1

########################################
puts "\nStep1: Reserve and connect chassis ports"
########################################
set returnedString [sth::connect -device $device1 -port_list  $p1]
puts $returnedString 
set returnedString [sth::connect -device $device2 -port_list  $p2]
puts $returnedString 

########################################
puts "\nStep2: Config Gig Interface on port2"
########################################
set returnedString [sth::interface_config \
                            -port_handle        port2 \
                            -mode               config \
                            -intf_ip_addr       "20.0.0.2" \
                            -gateway            "20.0.0.1" \
                            -autonegotiation    1 \
                            -arp_send_req       1 \
                            -arp_req_retries    10 \
                        ]
puts $returnedString


########################################
puts "\nStep3: Config pppoe on Port1"
########################################
set returnedString [sth::pppox_config \
                       -port_handle             port1 \
                       -mode                    create\
                       -ip_cp                   "ipv4_cp" \
                       -encap                   "ethernet_ii" \
                       -protocol                pppoe\
                       -username                "spirent" \
                       -password                "spirent" \
                       -num_sessions            $pppoe_session_count  \
                       -auth_mode               "chap" \
                       -chap_ack_timeout        10\
                       -config_req_timeout      10\
                       -ipcp_req_timeout        10\
                       -auto_retry              1\
                       -max_auto_retry_count    10\
                       -max_echo_acks           10\
                       -max_ipcp_req            10]
keylget returnedString handles pppox_handles
puts $returnedString


########################################
puts "\nStep4: Config igmp over pppoe on Port1"
########################################
set returnedString [sth::emulation_igmp_config \
                        -mode                   create  \
                        -handle                 $pppox_handles\
                        -older_version_timeout  400 \
                        -robustness             2 \
                        -unsolicited_report_interval    10\
                        -igmp_version            v2 \
                        -force_robust_join       true \
                        -force_leave             true \
                        -insert_checksum_errors  true \
                        -insert_length_errors    true \
                        -enable_df               true \
                        -pack_reports            true \
                        -enable_router_alert     true \
                        -tos_type                tos \
                        -tos                     200 \
                   ]
puts $returnedString
keylget returnedString handle igmpSession


########################################
puts "\nStep5: Config the Multicast Group"
########################################
set returnedString [sth::emulation_multicast_group_config \
                        -mode                   create \
                        -ip_addr_start          $mc_group_ip \
                        -num_groups             $mc_group_count \
                   ]
puts $returnedString
keylget returnedString handle igmpGroup


########################################
puts "\nStep6: Bound the IMGP and the Multicast Group"
########################################
set returnedString [sth::emulation_igmp_group_config \
                        -mode                   create \
                        -group_pool_handle      $igmpGroup \
                        -session_handle         $igmpSession \
                   ]
puts $returnedString

#config parts are finished

########################################
puts "\nStep7: Start pppoe connect and check status"
########################################
set returnedString [sth::pppox_control -handle $pppox_handles -action connect]
puts $returnedString
after 60000
set returnedString [sth::pppox_stats  -handle $pppox_handles  -mode aggregate]
set sessions_up [keylget returnedString aggregate.sessions_up]
puts "total session_up: $sessions_up"
  
########################################
puts "\nStep8: Start igmp join and check status"
########################################
set returnedString [sth:::emulation_igmp_control \
                        -handle                 $igmpSession  \
                        -mode                   join        \
                        -calculate_latency      false \
                        -leave_join_delay       0 \
                ]
puts "$returnedString "


########################################
puts "\nStep9: Setup ipv4 multicast traffic"
########################################  
set returnedString [sth::traffic_config \
                        -mode                   create \
                        -port_handle            port2 \
                        -rate_pps               100 \
                        -l3_protocol            ipv4 \
                        -l3_length              128\
                        -transmit_mode          continuous\
                        -length_mode            fixed \
                        -ip_src_addr            "20.0.0.2" \
                        -emulation_dst_handle   $igmpGroup]
puts "ipv4 upstream: $returnedString"
keylget returnedString stream_id stream_down_id


########################################
puts "\nStep10: Start traffic"
########################################
set returnedString [sth::traffic_control -port_handle port2 -action run]
puts $returnedString
after 10000
  
    
########################################
puts "\nStep11: Check traffic statistics"
########################################
set returnedString [sth::traffic_stats -streams $stream_down_id -mode streams]
set Rx_Rate [keylget returnedString port2.stream.$stream_down_id.rx.total_pkt_rate]
set Tx_Rate [keylget returnedString port2.stream.$stream_down_id.tx.total_pkt_rate]
puts "Ipv4 Upstream:"
puts "\tTx_Rate : -------------------------------$Tx_Rate"
puts "\tRx_Rate : -------------------------------$Rx_Rate"

stc::perform SaveasXml -config system1 -filename    "IgmpoPppoe.xml"

########################################
puts "\nStep12: Release resources"
########################################
set returnedString [::sth::cleanup_session -port_list [list port1 port2]]
puts $returnedString
if {![keylget returnedString status ]} {
puts $returnedString
    puts "  FAILED:  $returnedString"
    return
}

puts "_SAMPLE_SCRIPT_SUCCESS"