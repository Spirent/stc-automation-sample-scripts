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
# File Name:            HLTAPI_RFC2544.tcl
#
# Description:          This script demonstrates the use of Spirent HLTAPI to setup RFC2544 test
#
# Test Step:            1. Reserve and connect chassis ports
#                       2. Config interface
#                       3. create a streamblock used to test
#                       4. For each test type, create test, run it, get result.
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
#            c:>tclsh HLTAPI_RFC2544.tcl 10.61.44.2 3/1 3/3
#            c:>tclsh HLTAPI_RFC2544.tcl "10.61.44.2 10.61.44.7" 3/1 3/3

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

set iStatus 0;
set streamID 0;

##Enable differnet test type here
set tput_test 1
set latency_test 1
set b2b_test 1
set fl_test 1

puts "Load HLTAPI package";
package require SpirentHltApi

::sth::test_config  -logfile toshltLogfile \
                    -log 1\
                    -vendorlogfile tosstcExport\
                    -vendorlog 1\
                    -hltlog 1\
                    -hltlogfile toshltExport\
                    -hlt2stcmappingfile toshlt2StcMapping \
                    -hlt2stcmapping 1\
                    -log_level 7

########################################
# Step1: Reserve and connect chassis ports
########################################
set returnedString  [sth::connect -device $device_list -port_list $port_list];
if {![keylget returnedString status ]} {
puts $returnedString
    return "Reserve port FAILED"
}
keylget returnedString port_handle.$device1.$port1 port1 
keylget returnedString port_handle.$device2.$port2 port2
puts $returnedString

########################################
# Step2: Config interface
########################################
set returnedString [sth::interface_config -port_handle $port1 \
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

########################################
# Step3: create streamblock to test
########################################
set returnedString [sth::traffic_config -mode create \
                                        -port_handle  $port1 \
                                        -l2_encap ethernet_ii \
                                        -l3_protocol   ipv4 \
                                        -l3_length     256 \
                                        -length_mode   fixed \
                                        -ip_src_addr   192.168.1.10 \
                                        -ip_dst_addr   192.168.1.100 \
                                        -mac_dst 00:10:94:00:00:03\
                                        -mac_src 00:10:94:00:00:02\
                                        -mac_discovery_gw 192.168.1.100]
if {![keylget returnedString status ]} {
puts $returnedString
    return "Traffic Create under port $port1 FAILED"
} else {
    set streamblock1 [keylget returnedString stream_id]
}
puts $returnedString
set returnedString [sth::traffic_config -mode create \
                                        -port_handle   port2 \
                                        -l2_encap ethernet_ii \
                                        -l3_protocol   ipv4 \
                                        -l3_length     256 \
                                        -length_mode   fixed \
                                        -ip_src_addr   192.168.1.100 \
                                        -ip_dst_addr   192.168.1.10 \
                                        -mac_dst 00:10:94:00:00:02\
                                        -mac_src 00:10:94:00:00:03\
                                        -mac_discovery_gw 192.168.1.10]

if {![keylget returnedString status ]} {
puts $returnedString
    return "Traffic Create under port $port1 FAILED"
} else {
    set streamblock1 [keylget returnedString stream_id]
}
puts $returnedString

########################################
# Step4: RFC2544 test
########################################
#latency test
if {$latency_test} {
    set returnedString [sth::test_rfc2544_config \
                        -streamblock_handle $streamblock1 \
                        -mode create \
                        -test_type latency \
                        -traffic_pattern pair\
                        -endpoint_creation 0\
                        -bidirectional 0 \
                        -iteration_count 1 \
                        -latency_type FIFO \
                        -start_traffic_delay 1 \
                        -stagger_start_delay 1 \
                        -delay_after_transmission 10 \
                        -frame_size_mode custom \
                        -frame_size {1024 1518} \
                        -test_duration_mode seconds \
                        -test_duration 30 \
                        -load_unit percent_line_rate \
                        -load_type step \
                        -load_start 20 \
                        -load_step  10 \
                        -load_end  40]
    
    stc::perform SaveasXml -config system1 -filename "RFCtestLatency.xml"
    
    set returnedString [sth::test_rfc2544_control -action run -wait 1]
    
    set results [sth::test_rfc2544_info -test_type latency -clear_result 0]
    
    puts "$results\n"  
}

#back to back test
if {$b2b_test} {
    set returnedString [sth::test_rfc2544_config \
                        -streamblock_handle streamblock1 \
                        -mode create \
                        -test_type b2b \
                        -traffic_pattern pair\
                        -endpoint_creation 0\
                        -bidirectional 0 \
                        -iteration_count 2 \
                        -latency_type FIFO \
                        -start_traffic_delay 1 \
                        -stagger_start_delay 1 \
                        -delay_after_transmission 10 \
                        -frame_size_mode custom \
                        -frame_size {1024 1518} \
                        -test_duration_mode bursts \
                        -test_duration 100 ]

    set handle [keylget returnedString handle]

    set returnedString [sth::test_rfc2544_config \
                        -mode modify \
                        -handle $handle \
                        -test_type b2b \
                        -traffic_pattern pair\
                        -endpoint_creation 0\
                        -bidirectional 1 \
                        -iteration_count 1 \
                        -start_traffic_delay 2 \
                        -frame_size_mode custom \
                        -frame_size {1024 1518 256} \
                        -test_duration_mode seconds \
                        -test_duration 30 ]

    stc::perform SaveasXml -config system1 -filename "RFCtestb2b.xml"
    
    set returnedString [sth::test_rfc2544_control -action run -wait 1]
    
    set results [sth::test_rfc2544_info -test_type b2b -clear_result 0]
    
    puts "$results\n"
}

#frame loss test
if {$fl_test} {
    set returnedString [sth::test_rfc2544_config \
                         -streamblock_handle $streamblock1 \
                         -mode create \
                         -test_type fl \
                         -traffic_pattern pair\
                         -endpoint_creation 0\
                         -bidirectional 0 \
                         -iteration_count 5 \
                         -latency_type FIFO \
                         -start_traffic_delay 1 \
                         -stagger_start_delay 1 \
                         -delay_after_transmission 10 \
                         -frame_size_mode custom \
                         -frame_size {1024 1518} \
                         -test_duration_mode seconds \
                         -test_duration 30 \
                         -load_type step \
                         -load_start 100 \
                         -load_step  20 \
                         -load_end  40]

    stc::perform SaveasXml -config system1 -filename "RFCtestframelost.xml"

    set returnedString [sth::test_rfc2544_control -action run -wait 1]

    set results [sth::test_rfc2544_info -test_type fl -clear_result 0]

    puts "$results\n"

}

#through put test
if {$tput_test} {
    set returnedString [sth::test_rfc2544_config \
                         -streamblock_handle streamblock1 \
                         -mode create \
                         -test_type throughput \
                         -traffic_pattern pair\
                         -enable_learning 0 \
                         -endpoint_creation 0\
                         -bidirectional 0 \
                         -iteration_count 1 \
                         -latency_type FIFO \
                         -start_traffic_delay 1 \
                         -stagger_start_delay 1 \
                         -delay_after_transmission 10 \
                         -frame_size_mode custom \
                         -frame_size {1518} \
                         -test_duration_mode seconds \
                         -test_duration 10 \
                         -search_mode binary \
                         -rate_lower_limit 20 \
                         -rate_upper_limit 22 \
                         -initial_rate 21 ]

    puts $returnedString

    stc::perform SaveasXml -config system1 -filename "RFCtestTput.xml"

    set returnedString [sth::test_rfc2544_control -action run -wait 1]
    
    set results [sth::test_rfc2544_info -test_type throughput -clear_result 0]

    puts "$results\n"
}

########################################
#step5: release resources
########################################
set returnedString [::sth::cleanup_session -port_list [list port1 port2]]
if {![keylget returnedString status ]} {
puts $returnedString
    return "FAILED"
}
puts "_SAMPLE_SCRIPT_SUCCESS"
########################################
#The End
########################################
