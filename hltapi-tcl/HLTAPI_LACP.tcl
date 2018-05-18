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
# File Name:         HLTAPI_LACP.tcl
#
# Description:      This script demonstrates the use of Spirent HLTAPI to setup LACP test
#
# Test Step:         1. Reserve and connect chassis ports
#                    2. Config pos interface
#                    3. Enable LACP
#                    4. Start LACP ports
#                    5. Get LACP Info
#                    6. Stop LACP
#                    7. Retrive LACP statistics
#                    8. Release resources
#
# Dut Configuration:
#                   1. No DUT in useing
#                   2. Back to Back (B2B) test
#
# Topology
#                LACP Port                          LACP Port
#                [STC  2/1]-------------------------[STC 2/2 ]
#
#################################

# Run sample:
#            c:>tclsh HLTAPI_LACP.tcl 10.61.44.2 3/1 3/3
#            c:>tclsh HLTAPI_LACP.tcl "10.61.44.2 10.61.44.7" 3/1 3/3

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

############################################
# Step1: Reserve and connect chassis ports #
############################################
set cmdReturn [sth::connect -device $device_list -port_list $port_list]
if {![keylget cmdReturn status ]} {
	puts "FAILED: $cmdReturn"
    return
}
set portHandle1 [keylget cmdReturn port_handle.$device1.$port1]
set portHandle2 [keylget cmdReturn port_handle.$device2.$port2]
set portList "$portHandle1 $portHandle2"

############################################
# Step2: Config pos interface              #
############################################
foreach port $portList {
    set cmdReturn [sth::interface_config   -port_handle       $port \
                                                -mode              config \
                                                -phy_mode          copper \
                                                -duplex            full \
                                                -intf_mode         ethernet]
    if {![keylget cmdReturn status ]} {
		puts "FAILED: $cmdReturn"
        return
    }
}

############################################
# Step3: Enable LACP                       #
############################################

puts "\n################ Enable Lacp on port 1\n"
set cmdReturn [sth::emulation_lacp_config -port_handle $portHandle1 \
                                          -mode enable \
                                          -local_mac_addr "00:94:01:00:00:01" \
                                          -act_port_key 100 \
                                          -act_lacp_port_priority 101 \
                                          -act_port_number 10 \
                                          -act_lacp_timeout short \
                                          -lacp_activity active \
                                          -act_system_priority 1000 \
                                          -act_system_id "00:00:00:00:01:01" ]
if {[keylget cmdReturn status]} {
    puts "Pass"
} else {
    puts "Fail"
    puts "Info" . [keylget cmdReturn log]
	return
}

puts "\n################ Enable Lacp on port 2\n"
set cmdReturn [sth::emulation_lacp_config -port_handle $portHandle2 \
                                          -mode enable \
                                          -local_mac_addr "00:94:02:00:00:02" \
                                          -act_port_key 500 \
                                          -act_lacp_port_priority 501 \
                                          -act_port_number 10 \
                                          -act_lacp_timeout short \
                                          -lacp_activity active \
                                          -act_system_priority 5000 \
                                          -act_system_id "00:00:00:00:01:01"]
if {[keylget cmdReturn status]} {
    puts "Pass"
} else {
    puts "Fail"
    puts "Info" . [keylget cmdReturn log]
	return
}

#config parts are finished

############################################
#step4 Start LACP                          #
############################################

puts "\n################ Start Lacp on port 1\n"
set cmdReturn [sth::emulation_lacp_control -port_handle $portHandle1\
                                           -action start]
if {[keylget cmdReturn status]} {
    puts "Pass"
} else {
    puts "Fail"
    puts "Info" . [keylget cmdReturn log]
	return
}

puts "\n################ Start Lacp on port 2\n"
set cmdReturn [sth::emulation_lacp_control -port_handle $portHandle2\
                                           -action start]

if {[keylget cmdReturn status]} {
    puts "Pass"
} else {
    puts "Fail"
    puts "Info" . [keylget cmdReturn log]
	return
}

############################################
#step5 Get LACP Info                       #
############################################

puts "\n################ sleep 30s\n"
after 30000

puts "\n################ Get Lacp state info on port 1\n"
set cmdReturn [sth::emulation_lacp_info -port_handle $portHandle1\
                                           -action collect \
                                           -mode state]
if {[keylget cmdReturn status]} {
    set sessionState [keylget cmdReturn lacp_state]
    if { $sessionState == "UP"} {
        puts "Pass"
    } else {
        puts "Fail. Lacp session 1 hasn't come up."
		return
    }
} else {
    puts "Fail"
    puts "Info" . [keylget cmdReturn log]
	return
}

puts "\n################ Get Lacp state info on port 2\n"
set cmdReturn [sth::emulation_lacp_info -port_handle $portHandle2\
                                           -action collect \
                                           -mode state]

if {[keylget cmdReturn status]} {
    set sessionState [keylget cmdReturn lacp_state]
    if { $sessionState == "UP"} {
        puts "Pass"
    } else {
        puts "Fail. Lacp session 2 hasn't come up."
		return
    }
} else {
    puts "Fail"
    puts "Info" . [keylget cmdReturn log]
	return
}

############################################
#step6 Stop LACP                           #
############################################

puts "\n################ Stop Lacp on port 1\n"
set cmdReturn [sth::emulation_lacp_control -port_handle $portHandle1\
                                           -action stop]
if {[keylget cmdReturn status]} {
    puts "Pass"
} else {
    puts "Fail"
    puts "Info" . [keylget cmdReturn log]
	return
}

puts "\n################ Stop Lacp on port 2\n"
set cmdReturn [sth::emulation_lacp_control -port_handle $portHandle2\
                                           -action stop]
if {[keylget cmdReturn status]} {
    puts "Pass"
} else {
    puts "Fail"
    puts "Info" . [keylget cmdReturn log]
	return
}

############################################
#step7 Retrive LACP statistics             #
############################################

puts "\n################ sleep 10s\n"
stc::sleep 10

puts "\n################ Get all Lacp info on port 1\n"
set cmdReturn [sth::emulation_lacp_info -port_handle $portHandle1\
                                           -action collect]
if {[keylget cmdReturn status]} {
    set sessionState [keylget cmdReturn lacp_state]
    if { $sessionState != "UP"} {
        set prePdusTx1 [keylget cmdReturn pdus_tx]
        puts "Pass"
    } else {
        puts "Fail. Lacp session 1 hasn't gone down."
        set finalResult "Failed."
		return
    }
} else {
    puts "Fail"
    puts "Info" . [keylget cmdReturn log]
	return
}

puts "\n################ Get all Lacp info on port 2\n"
set cmdReturn [sth::emulation_lacp_info -port_handle $portHandle2\
                                           -action collect]
if {[keylget cmdReturn status]} {
    set sessionState [keylget cmdReturn lacp_state]
    if { $sessionState != "UP"} {
        set prePdusTx2 [keylget cmdReturn pdus_tx]
        puts "Pass"
    } else {
        puts "Fail. Lacp session 2 hasn't gone down."
		return
    }
} else {
    puts "Fail"
    puts "Info" . [keylget cmdReturn log]
	return
}

############################################
#step8 Release resources                   #
############################################

set returnedString [::sth::cleanup_session -port_list $portList]
if {![keylget returnedString status ]} {
	puts "FAILED $returnedString"
    return
}

puts "_SAMPLE_SCRIPT_SUCCESS"
############################################
#The End                                   #
############################################