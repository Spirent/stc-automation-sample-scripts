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
# File Name:         HLTAPI_L2TP_B2B.tcl
#
# Description:      This script demonstrates the use of Spirent HLTAPI to setup LAC-LNStest
#
# Test Step:         1. Reserve and connect chassis ports
#                    2. Config LAC on Port1
#                    3. Config LNS on Port2
#                    4. Start LAC-LNS Connect
#                    5. Retrive Statistics
#                    6. Config Traffic
#                    7. Run Traffic and Capture the Traffic 
#                    8. Retrive Traffic Statistics
#                    9. Release resources
#
# Dut Configuration:
#                            None
#
# Topology
#                   LAC                     LNS
#                [STC  2/1]-----------------[STC 2/2 ]
#               5.5.5.60                    5.5.5.50           IP Address for L2TP Connection
#               unknown                     2.0.0.1            IP Address for  Traffic
#
########################################

# Run sample:
#            c:>tclsh HLTAPI_L2TP_B2B.tcl 10.61.44.2 3/1 3/3
#            c:>tclsh HLTAPI_L2TP_B2B.tcl "10.61.44.2 10.61.44.7" 3/1 3/3

package require SpirentHltApi

set device_list1      "10.109.121.199"
set port1        "1/1"
set device_list2      "10.109.125.4"
set port1        "1/1"
set port2        "1/1"
set i 1


########################################
# Step1: Reserve and connect chassis ports
########################################
set returnedString [sth::connect -device $device_list1 -port_list $port1]
if {![keylget returnedString status ]} {
    puts "  FAILED:  $returnedString"
	return
}
keylget returnedString port_handle.$device1.$port1 hltLACPort
set returnedString [sth::connect -device $device_list2 -port_list $port2]
if {![keylget returnedString status ]} {
    puts "  FAILED:  $returnedString"
	return
}
keylget returnedString port_handle.$device2.$port2 hltLNSPort
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
# Step2: Config LAC on Port1
########################################
set returnedString [sth::l2tp_config   \
                     -port_handle        $hltLACPort  \
                     -mode                   "lac" \
                     -l2tp_src_addr      "5.5.5.60" \
                     -l2tp_dst_addr      "5.5.5.50" \
                    ]
if {![keylget returnedString status ]} {
    puts "  FAILED:  $returnedString"
	return
}
keylget returnedString handles LAC

########################################
# Step3: Config LNSon Port2
########################################
set returnedString [sth::l2tp_config   \
                     -port_handle        $hltLNSPort  \
                     -mode                   "lns" \
                     -l2tp_dst_addr      "5.5.5.50" \
                     
                    ]
if {![keylget returnedString status ]} {
    puts "  FAILED:  $returnedString"
	return
}
keylget returnedString handles LNS
stc::perform SaveAsXml -FileName "l2tp.xml"
#config parts are finished

########################################
# Step4: Start LAC-LNS Connect
########################################
set returnedString [sth::l2tp_control -handle $LNS -action connect]
if {![keylget returnedString status ]} {
    puts "  FAILED:  $returnedString"
	return
}

set returnedString [sth::l2tp_control -handle $LAC -action connect]
if {![keylget returnedString status ]} {
    puts "  FAILED:  $returnedString"
	return
}

########################################
# Step5: Retrive Statistics
########################################
set returnedString [sth::l2tp_stats -handle $LAC -mode aggregate]
if {![keylget returnedString status ]} {
    puts "  FAILED:  $returnedString"
	return
}
while {[keylget returnedString aggregate.sessions_up]  != 1} {
    after 1500
    set returnedString [sth::l2tp_stats -handle $LAC -mode aggregate]
}

########################################
# Step6: Config Traffic
########################################
# Downstream: LNS---->LAC
set returnedString [sth::traffic_config \
                     -mode                  create \
                     -port_handle           $hltLNSPort\
                     -rate_pps              1000 \
                     -l2_encap              ethernet_ii \
                     -l3_protocol            ipv4 \
                     -l3_length              108 \
                     -transmit_mode         continuous \
                     -length_mode           fixed \
                     -emulation_dst_handle  $LAC \
                     -ip_src_addr            2.0.0.1 \
                    ]
if {![keylget returnedString status ]} {
    puts "  FAILED:  $returnedString"
	return
}
# Upstream: LAC---->LNS
set returnedString [sth::traffic_config \
                     -mode                  create \
                     -port_handle           $hltLACPort\
                     -rate_pps              500 \
                     -l2_encap              ethernet_ii \
                     -l3_protocol            ipv4 \
                     -l3_length              108 \
                     -transmit_mode         continuous \
                     -length_mode           fixed \
                     -emulation_dst_handle  $LNS \
                     -emulation_src_handle  $LAC \
                    ]
if {![keylget returnedString status ]} {
    puts "  FAILED:  $returnedString"
	return
}


########################################
# Step7: Run Traffic and Capture the Traffic 
########################################
set returnedString [sth::traffic_control -port_handle all  -action run]
if {![keylget returnedString status ]} {
puts $returnedString
    puts "  FAILED:  $returnedString"
	return
}

# Starting the capture
sth::packet_control -port_handle $hltLACPort -action start
sth::packet_control -port_handle $hltLNSPort -action start
after 10000
# Stopping the capture
sth::packet_control -port_handle $hltLACPort -action stop
sth::packet_control -port_handle $hltLNSPort -action stop
# Save the capture
sth::packet_stats -port_handle $hltLACPort -action filtered -format pcap -filename lac.pcap
sth::packet_stats -port_handle $hltLNSPort -action filtered -format pcap -filename lns.pcap


########################################
# Step8: Retrive Traffic Statistics
########################################
# LAC receives downstream and sends upstream
set returnedString [sth::traffic_stats -port_handle $hltLACPort -mode aggregate]
if {![keylget returnedString status ]} {
    puts "  FAILED:  $returnedString"
	return
}
set Rx_down [keylget returnedString $hltLACPort.aggregate.rx.total_pkt_rate]
set Tx_up [keylget returnedString $hltLACPort.aggregate.tx.total_pkt_rate]

# LNS receives upstream and sends downstream
set returnedString [sth::traffic_stats -port_handle $hltLNSPort -mode aggregate]
if {![keylget returnedString status ]} {
    puts "  FAILED:  $returnedString"
	return
}
set Rx_up [keylget returnedString $hltLNSPort.aggregate.rx.total_pkt_rate]
set Tx_down  [keylget returnedString $hltLNSPort.aggregate.tx.total_pkt_rate]

if {!($Tx_down == $Rx_down && $Tx_up == $Rx_up)} {
    puts "Tx_down: $Tx_down\nRx_down: $Rx_down\n"
    puts "Tx_up: $Tx_up\nRx_up: $Rx_up\n"
    puts "  FAILED"
	return
}


########################################
# Step9: Release resources
########################################
set returnedString [::sth::cleanup_session -port_list [list $port1 $port2]]
if {![keylget returnedString status ]} {
    puts "  FAILED:  $returnedString"
	return
}

puts "_SAMPLE_SCRIPT_SUCCESS"