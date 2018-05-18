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
# File Name:            HLTAPI_RFC3918.tcl
#
# Description:          This script demonstrates the use of Spirent HLTAPI to setup RFC3918 test
#
# Test Step:            1. Reserve and connect chassis ports
#                       2. Create multicast group and igmp client
#                       3. Create multicast and unicast streams
#                       4. For each test type, create test, run it, get result and delete the test handle
#
# Dut Configuration:
#                   None
#
# Topology
#                                      
#                [STC  2/1]---------[DUT ]---------[STC  2/2]
#
#################################

# Run sample:
#            c:\>tclsh HLTAPI_RFC3918.tcl 10.61.44.2 3/1 3/3
#            c:\>tclsh HLTAPI_RFC3918.tcl "10.61.44.2 10.61.44.7" 3/1 3/3

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
                    -hlt2stcmappingfile hlt2StcMapping \
                    -hlt2stcmapping 1\
                    -log_level 7

########################################
# Step1: Reserve and connect chassis ports
########################################
set returnedString [sth::connect -device $device_list -port_list $port_list];
if {![keylget returnedString status ]} {
puts $returnedString
    return "Reserve port FAILED"
}
keylget returnedString port_handle.$device1.$port1 port1 
keylget returnedString port_handle.$device2.$port2 port2

########################################
# Step2: Config interface
########################################
set returnedString [sth::interface_config -port_handle $port1 \
                                          -intf_mode   ethernet \
                                          -mode config \
                                          -intf_ip_addr 192.168.1.10 \
                                          -gateway 192.168.1.100 \
                                          -autonegotiation 1 \
                                          -arp_send_req 1 ]

if {![keylget returnedString status ]} {
puts $returnedString
    return "Interface config FAILED"
}
puts $returnedString

set returnedString [sth::interface_config -port_handle $port2 \
                                          -intf_mode   ethernet \
                                          -mode config \
                                          -intf_ip_addr 192.168.1.100 \
                                          -gateway 192.168.1.10 \
                                          -autonegotiation 1 \
                                          -arp_send_req 1 ]

if {![keylget returnedString status ]} {
puts $returnedString
    return "Interface config FAILED"
}
puts $returnedString

################################################
# Step3: #create multicast group and igmp client 
#################################################
set returnedString [sth::emulation_multicast_group_config \
                        -mode "create" \
                        -ip_addr_start 225.0.0.1\
                        -num_groups 5]

if {![keylget returnedString status ]} {
puts $returnedString
    return "Create multicast group FAILED"
}

set McGroupHandle [keylget returnedString handle]

set returnedString [sth::emulation_igmp_config \
                        -mode "create" \
                        -igmp_version v2 \
                        -port_handle port2 \
                        -count 1 \
                        -intf_ip_addr 6.41.1.100 \
                        -neighbor_intf_ip_addr 6.41.1.10]

if {![keylget returnedString status ]} {
puts $returnedString
    return "Create igmp client FAILED"
}
set IGMPSessionHandle1 [keylget returnedString handle]

#create membership for igmp client
set returnedString [sth::emulation_igmp_group_config \
        	         -mode "create" \
        	         -group_pool_handle $McGroupHandle \
        	         -session_handle $IGMPSessionHandle1]
if {![keylget returnedString status ]} {
puts $returnedString
    return "Create membership for igmp client FAILED"
}

#################################################################
# Step4: create the multicast and unicast stream for RFC3918 test
################################################################
set returnedString  [sth::traffic_config \
                        -mode "create" \
                        -port_handle $port1 \
                        -l2_encap "ethernet_ii" \
                        -mac_src "00.00.88.00.00.02" \
                        -mac_dst "01.00.5E.00.00.01" \
                        -length_mode "fixed" \
                        -l3_length 256 \
                        -l3_protocol ipv4 \
                        -ip_src_addr 6.41.1.10 \
                        -emulation_dst_handle $McGroupHandle \
                        -mac_discovery_gw 6.41.1.100\
                        -rate_pps 50]

if {![keylget returnedString status ]} {
puts $returnedString
    return "Create multicast stream FAILED"
}

set multiStreamHnd [keylget returnedString stream_id]

#create the unicast stream for RFC3918 mixed class test
set returnedString  [sth::traffic_config \
                        -mode "create" \
                        -port_handle port1 \
                        -l2_encap "ethernet_ii" \
                        -mac_src "00.00.88.00.00.02" \
                        -mac_dst "01.00.5E.00.00.01" \
                        -length_mode "fixed" \
                        -l3_length 256 \
                        -l3_protocol ipv4 \
                        -ip_src_addr 6.41.1.10 \
                        -mac_discovery_gw 6.41.1.100 \
                        -ip_dst_addr 6.41.1.100 \
                        -rate_pps 50]

if {![keylget returnedString status ]} {
puts $returnedString
    return "Create unicast stream FAILED"
}

set uniStreamHnd [keylget returnedString stream_id]

#################################################################
# Step5: create RFC3918 test
################################################################
puts "create RFC3918 mixed class test..................\n"
set returnedString [sth::test_rfc3918_config  -mode create\
                                    -test_type mixed_tput\
                                    -multicast_streamblock  $multiStreamHnd\
                                    -unicast_streamblock $uniStreamHnd \
                                    -join_group_delay 15 \
                                    -leave_group_delay 15 \
                                    -mc_msg_tx_rate 2000 \
                                    -latency_type FIFO \
                                    -test_duration_mode seconds \
                                    -test_duration 20 \
                                    -result_delay  10 \
                                    -start_test_delay 5 \
                                    -frame_size_mode custom \
                                    -frame_size 256 \
                                    -learning_frequency learn_every_iteration \
                                    -l2_learning_rate 100 \
                                    -l3_learning_rate 200 \
                                    -group_count_mode custom \
                                    -group_count {10 20} \
                                    -enable_same_frame_size 0 \
                                    -unicast_frame_size_mode custom \
                                    -unicast_frame_size 128 \
                                    -mc_traffic_percent_mode custom \
                                    -mc_traffic_percent 30]

if {![keylget returnedString status ]} {
puts $returnedString
    return "Create RFC3918 mixed class test FAILED"
}

set testHnd [keylget returnedString handle]

 stc::perform SaveasXml -config system1 -filename "./RFC3918test.xml"
 
puts "Start RFC3918 mixed class test..................\n"
set returnedString [sth::test_rfc3918_control -action run -wait 1 -cleanup 0]

puts "Get Result of RFC3918 mixed class test ..................\n"
set results [sth::test_rfc3918_info -test_type mixed_tput -clear_result 0]

puts "the RFC3918 mixed class test result is $results\n"

puts "Delete mixed class test handle"
set returnedString [sth::test_rfc3918_config  -mode delete -handle $testHnd]

#after 5000

puts "create RFC3918 aggregated multicast throughput test..................\n"
set returnedString [sth::test_rfc3918_config  -mode create\
                                    -test_type agg_tput\
                                    -multicast_streamblock  $multiStreamHnd\
                                    -join_group_delay 15 \
                                    -leave_group_delay 15 \
                                    -mc_msg_tx_rate 2000 \
                                    -latency_type FIFO \
                                    -test_duration_mode seconds \
                                    -test_duration 20 \
                                    -result_delay  10 \
                                    -start_test_delay 5 \
                                    -frame_size_mode custom \
                                    -frame_size 256 \
                                    -learning_frequency learn_every_iteration \
                                    -l2_learning_rate 100 \
                                    -l3_learning_rate 200 \
                                    -group_count_mode custom \
                                    -group_count {10 20}]

if {![keylget returnedString status ]} {
puts $returnedString
    return "create RFC3918 aggregated multicast throughput test FAILED"
}

set testHnd [keylget returnedString handle]

puts "Start RFC3918 aggregated multicast throughput test..................\n"
set returnedString [sth::test_rfc3918_control -action run -wait 1 -cleanup 0]

puts "Get Result of aggregated multicast throughput test ..................\n"
set results [sth::test_rfc3918_info -test_type agg_tput -clear_result 0]

puts "aggregated multicast throughput test result is $results\n"

puts "Delete aggregated throughput test handle"
set returnedString [sth::test_rfc3918_config  -mode delete -handle $testHnd]

#after 5000

puts "create RFC3918 scaled group forwarding matrix test..................\n"
set returnedString [sth::test_rfc3918_config  -mode create\
                                    -test_type matrix\
                                    -multicast_streamblock  $multiStreamHnd\
                                    -join_group_delay 15 \
                                    -leave_group_delay 15 \
                                    -mc_msg_tx_rate 2000 \
                                    -latency_type FIFO \
                                    -test_duration_mode seconds \
                                    -test_duration 20 \
                                    -result_delay  10 \
                                    -start_test_delay 5 \
                                    -frame_size_mode custom \
                                    -frame_size 256 \
                                    -load_start 10 \
                                    -load_end 10 \
                                    -group_count_mode custom \
                                    -group_count 60]

if {![keylget returnedString status ]} {
puts $returnedString
    return "create RFC3918 scaled group forwarding matrix test FAILED"
}

set testHnd [keylget returnedString handle]

puts "Start RFC3918 scaled group forwarding matrix test..................\n"
set returnedString [sth::test_rfc3918_control -action run -wait 1 -cleanup 0]

puts "Get Result of scaled group forwarding matrix test.................\n"
set results [sth::test_rfc3918_info -test_type matrix -clear_result 0]

puts "scaled group forwarding matrix test result is $results\n"

puts "Delete scaled group forwarding matrix test handle"
set returnedString [sth::test_rfc3918_config  -mode delete -handle $testHnd]

#after 5000

puts "create RFC3918 multicast forwarding latency test.................\n"
set returnedString [sth::test_rfc3918_config  -mode create\
                                    -test_type fwd_latency\
                                    -multicast_streamblock  $multiStreamHnd\
                                    -join_group_delay 15 \
                                    -leave_group_delay 15 \
                                    -mc_msg_tx_rate 2000 \
                                    -latency_type FIFO \
                                    -test_duration_mode seconds \
                                    -test_duration 20 \
                                    -result_delay  10 \
                                    -start_test_delay 5 \
                                    -frame_size_mode custom \
                                    -frame_size 256 \
                                    -l2_learning_rate 100 \
                                    -l3_learning_rate 200 \
                                    -group_count_mode custom \
                                    -group_count 60 \
                                    -load_end 10]
if {![keylget returnedString status ]} {
puts $returnedString
    return "create RFC3918 multicast forwarding latency test FAILED"
}


set testHnd [keylget returnedString handle]

puts "Start RFC3918 multicast forwarding latency test.................\n"
set returnedString [sth::test_rfc3918_control -action run -wait 1 -cleanup 0]

puts "Get Result of RFC3918 multicast forwarding latency test.................\n"
set results [sth::test_rfc3918_info -test_type fwd_latency -clear_result 0]

puts "RFC3918 multicast forwarding latency test result is $results\n"

puts "Delete RFC3918 multicast forwarding latency test handle"
set returnedString [sth::test_rfc3918_config  -mode delete -handle $testHnd]

#after 5000

puts "create RFC3918 join leave latency test.................\n"
set returnedString [sth::test_rfc3918_config  -mode create\
                                    -test_type join_latency\
                                    -multicast_streamblock  $multiStreamHnd\
                                    -join_group_delay 15 \
                                    -leave_group_delay 15 \
                                    -mc_msg_tx_rate 2000 \
                                    -latency_type FIFO \
                                    -test_duration_mode seconds \
                                    -test_duration 20 \
                                    -result_delay  10 \
                                    -start_test_delay 5 \
                                    -group_count 60 \
                                    -load_end 10 \
                                    -frame_size 256]

set testHnd [keylget returnedString handle]

puts "Start RFC3918 join leave latency test.................\n"
set returnedString [sth::test_rfc3918_control -action run -wait 1 -cleanup 0]

puts "Get Result of RFC3918 join leave latency test.................\n"
set results [sth::test_rfc3918_info -test_type join_latency -clear_result 0]

puts "RFC3918 join leave latency test result is $results\n"

puts "Delete RFC3918 join leave latency test handle"
set returnedString [sth::test_rfc3918_config  -mode delete -handle $testHnd]

#after 5000

puts "create RFC3918 multicast group capacity test................\n"
set returnedString [sth::test_rfc3918_config  -mode create\
                                    -test_type capacity\
                                    -multicast_streamblock  $multiStreamHnd\
                                    -join_group_delay 15 \
                                    -leave_group_delay 15 \
                                    -mc_msg_tx_rate 2000 \
                                    -latency_type FIFO \
                                    -test_duration_mode seconds \
                                    -test_duration 20 \
                                    -result_delay  10 \
                                    -start_test_delay 5 \
                                    -group_upper_limit 10 \
                                    -load_end 10 \
                                    -frame_size 256]

set testHnd [keylget returnedString handle]

puts "Start RFC3918 multicast group capacity test..............\n"
set returnedString [sth::test_rfc3918_control -action run -wait 1 -cleanup 0]

puts "Get Result of multicast group capacity test................\n"
set results [sth::test_rfc3918_info -test_type capacity -clear_result 0]

puts "RFC3918 multicast group capacity test is $results\n"

puts "Delete RFC3918 multicast group capacity test handle"
set returnedString [sth::test_rfc3918_config  -mode delete -handle $testHnd]

#config part is finished

#after 5000

sth::cleanup_session -port_handle $port1 $port2 -clean_dbfile 1
puts "_SAMPLE_SCRIPT_SUCCESS"

