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
# File Name:         HLTAPI_FCoE_Device.tcl
#
# Description:      This script demonstrates the use of Spirent HLTAPI to setup FCoE connnection
#
# Test Step:         1. Reserve and connect chassis ports
#                    2. Create FCoE Device (ENode) on Ports
#                    3. Create Bound Stream on Fcoe Device (ENode)
#                    4. Start Device and Check Device Status
#                    5. Start Traffic and check Traffic Status
#                    6. Stop Fcoe Devices and Traffic
#                    7. Release resources
#
#
# Topology
#                    FCoE Node         Nexus         FCoE Node
#                   [STC 2/1]---------[DUT]---------[STC 2/2]
#
########################################

# Run sample:
#            c:>tclsh HLTAPI_FCoE_Device.tcl 10.61.44.2 3/1 3/3
#            c:>tclsh HLTAPI_FCoE_Device.tcl "10.61.44.2 10.61.44.7" 3/1 3/3

package require SpirentHltApi

set device_list      [lindex $argv 0]
set hltPort1        [lindex $argv 1]
set hltPort2        [lindex $argv 2]
set i 1
foreach device $device_list {
    set device$i $device
    incr i
}
set device$i $device
set port_list "$hltPort1 $hltPort2";
set vnport_count          2

########################################
# Step1: Reserve and connect chassis ports
########################################
set returnedString [sth::connect -device $device_list -port_list $port_list]
if {![keylget returnedString status ]} {
	puts $returnedString
    puts "  FAILED. "
	return
}
keylget returnedString port_handle.$device1.$hltPort1 srcPort
keylget returnedString port_handle.$device2.$hltPort2 dstPort

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
# Step2: Create FCoE Device (ENode) on Ports
########################################
set returnedString [sth::fcoe_config            \
                        -port_handle            $srcPort   \
                        -mode                   create  \
                        -encap                  ethernet_ii_vlan \
                        -mac_addr               "00:10:94:00:00:03"\
                        -vlan_id                906 \
                        -enode_count            1       \
                        -vnport_count           $vnport_count \
                        -use_wwpn               0 \
                        -wwnn                   "10:00:00:10:94:00:00:01" \
                        -wwpn                   "20:00:00:10:94:00:00:01" \
                        -wwpn_step              "00:00:00:00:00:00:00:01" \
                    ]
puts $returnedString
if {![keylget returnedString status ]} {
    puts "  FAILED. "
	return
}
keylget returnedString handle src

set returnedString [sth::fcoe_config            \
                        -port_handle            $dstPort   \
                        -mode                   create  \
                        -encap                  ethernet_ii_vlan \
                        -mac_addr               "00:20:94:00:00:03"\
                        -vlan_id                906 \
                        -enode_count            1       \
                        -vnport_count           $vnport_count \
                        -use_wwpn               0 \
                        -wwnn                   "10:00:00:10:95:00:00:01" \
                        -wwpn                   "20:00:00:10:95:00:00:01" \
                        -wwpn_step              "00:00:00:00:00:00:00:01" \
                    ]
puts $returnedString
if {![keylget returnedString status ]} {
    puts "  FAILED. "
	return
}
keylget returnedString handle dst


########################################
# Step3: Create Bound Stream on Fcoe Device (ENode)
########################################
set returnedString  [sth::traffic_config \
                        -mode                   "create" \
                        -port_handle            $srcPort \
                        -rate_pps               50 \
                        -emulation_src_handle   $src \
                        -emulation_dst_handle   $dst ]
puts $returnedString
if {![keylget returnedString status ]} {
    puts "  FAILED. "
	return
}
keylget returnedString stream_id stream_id

#config parts are finished

########################################
# Step4: Start Device and Check Device Status
########################################
set returnedString [sth::fcoe_control  -handle [list $src $dst] -action start]
puts $returnedString
if {![keylget returnedString status ]} {
    puts "  FAILED. "
	return
}

after 30000
set returnedString [sth::fcoe_stats -handle $src -mode summary]
puts $returnedString
if {![keylget returnedString status ]} {
    puts "  FAILED. "
	return
}
set vnport_up [keylget returnedString vnport_up]
if {$vnport_up != $vnport_count} {
    puts "  FAILED. "
	return
}

set returnedString [sth::fcoe_stats -handle $dst -mode summary]
puts $returnedString
if {![keylget returnedString status ]} {
    puts "  FAILED. "
	return
}
set vnport_up [keylget returnedString vnport_up]
if {$vnport_up != $vnport_count} {
    puts "  FAILED. "
	return
}


########################################
# Step5: Start Traffic and check Traffic Status
########################################
set returnedString [sth::traffic_control -port_handle all -action run]
puts $returnedString
if {![keylget returnedString status ]} {
    puts "  FAILED. "
	return
}

after 10000
set returnedString [sth::traffic_stats -streams $stream_id -mode streams]
puts $returnedString
if {![keylget returnedString status ]} {
    puts "  FAILED. "
	return
}
set Rx_Rate [keylget returnedString $srcPort.stream.$stream_id.rx.total_pkt_rate]
set Tx_Rate [keylget returnedString $srcPort.stream.$stream_id.tx.total_pkt_rate]
puts "Tx_Rate : -------------------------------$Tx_Rate"
puts "Rx_Rate : -------------------------------$Rx_Rate"


########################################
# Step6 Stop Fcoe Devices and Traffic
########################################
set returnedString [sth::traffic_control -port_handle all -action stop]
puts $returnedString
if {![keylget returnedString status ]} {
    puts "  FAILED. "
	return
}

set returnedString [sth::fcoe_control  -handle [list $src $dst] -action stop]
puts $returnedString
if {![keylget returnedString status ]} {
    puts "  FAILED. "
	return
}

########################################
# Step7 Release resources
########################################
set returnedString [::sth::cleanup_session -port_list  [list $srcPort $dstPort]]
puts $returnedString
if {![keylget returnedString status ]} {
    puts "  FAILED. "
	return
}

puts "_SAMPLE_SCRIPT_SUCCESS"