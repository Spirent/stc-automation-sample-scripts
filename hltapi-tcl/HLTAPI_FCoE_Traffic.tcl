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
# File Name:         HLTAPI_FCoE_Traffic.tcl
#
# Description:      This script demonstrates the use of Spirent HLTAPI to setup FCoE Raw Traffic
#
# Test Step:         1. Reserve and connect chassis ports
#                    2. Genearte L2 Traffic on Port1 and Port2
#                    3. Create FCoE and FIP Raw Traffic
#                    4. Run the Traffic
#                    5. Release resources
#
# Dut Configuration:
#                   None
#
# Topology
#                                      FCF
#                [STC  2/1]---------[DUT e1/35]---------[STC  2/2]
#
########################################

# Run sample:
#            c:>tclsh HLTAPI_FCoE_Traffic.tcl 10.61.44.2 3/1 3/3
#            c:>tclsh HLTAPI_FCoE_Traffic.tcl "10.61.44.2 10.61.44.7" 3/1 3/3

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

#FCoE/FIP Traffic Parameters
set fip_header "-fp 1 -sp 0 -a 0 -s 0 -f 0"
set fc_header  "-h_did 000000000 -h_sid 000000 -h_type 00 -h_framecontrol 000000 \
                -h_seqid 00 -h_dfctl  00 -h_seqcnt 0000 -h_origexchangeid 0000 \
               "
########################################
# Step1: Reserve and connect chassis ports
########################################
set returnedString [sth::connect -device $device_list -port_list $port_list]
puts $returnedString
if {![keylget returnedString status ]} {
    puts "  FAILED. "
	return
}
keylget returnedString port_handle.$device1.$port1 srcPort
keylget returnedString port_handle.$device2.$port2 dstPort

########################################
# Step2: Genearte L2 Traffic on Port1 and Port2
########################################
#Crate L2 Streamblocks on Port1 and Port2
set returnedString  [sth::traffic_config \
                        -mode            create \
                        -port_handle    $srcPort \
                        -l2_encap       ethernet_ii \
                        -transmit_mode  continuous \
                        -l3_length      1002 \
                        -length_mode    fixed \
                        -rate_pps       1000\
                       ]
puts $returnedString
if {![keylget returnedString status ]} {
    puts "  FAILED. "
	return
}
keylget returnedString stream_id sb1

set returnedString  [sth::traffic_config \
                        -mode            create \
                        -port_handle    $dstPort \
                        -l2_encap       ethernet_ii \
                        -transmit_mode  continuous \
                        -l3_length      1002 \
                        -length_mode    fixed \
                        -rate_pps       1000\
                       ]
if {![keylget returnedString status ]} {
puts $returnedString
    puts "  FAILED. "
	return
}
keylget returnedString stream_id sb2


########################################
# Step3: Create FCoE and FIP Raw Traffic 
########################################
#Create FCoE Flogi Req on sb1
set fcoe_traffic_config  "sth::fcoe_traffic_config \
                               -mode                create \
                               -handle              $sb1 \
                               -sof                 sofn3 \
                               -eof                 eofn \
                               $fc_header \
                               -pl_id               flogireq \
                               -pl_nodename         10:00:10:94:00:00:00:01 \
                            "
set returnedString [eval $fcoe_traffic_config]

#Create FIP Discovery Advertisement on sb2
set fip_traffic_config  "sth::fip_traffic_config \
                              -mode         create \
                              -handle       $sb2 \
                             $fip_header \
                             -dl_id         {priority macaddr nameid fabricname fka_adv_period} \
                             -priority      64 \
                             -vlanid        100 \
                             -macaddr       00:10:94:00:00:01 \
                             -nameid        10:00:10:94:00:00:00:01 \
                             -fabricname    20:00:10:94:00:00:00:01 \
                         "
set returnedString [eval $fip_traffic_config]
if {![keylget returnedString status ]} {
puts $returnedString
    puts "  FAILED. "
	return
}

#config parts are finished

########################################
# Step4: Run the Traffic
########################################
# Starting the capture
sth::packet_control -port_handle $srcPort -action start
sth::packet_control -port_handle $dstPort -action start

set returnedString [sth::traffic_control -port_handle all  -action run]
if {![keylget returnedString status ]} {
puts $returnedString
    puts "  FAILED. "
	return
}

# Stopping the capture
sth::packet_control -port_handle $srcPort -action stop
sth::packet_control -port_handle $dstPort -action stop
# Save the capture
sth::packet_stats -port_handle $srcPort -action filtered -format pcap -filename $srcPort.pcap
sth::packet_stats -port_handle $dstPort -action filtered -format pcap -filename $dstPort.pcap


########################################
# Step5 Release resources
########################################
set returnedString [::sth::cleanup_session -port_list [list $srcPort $dstPort]]
if {![keylget returnedString status ]} {
puts $returnedString
    puts "  FAILED. "
	return
}

puts "_SAMPLE_SCRIPT_SUCCESS"