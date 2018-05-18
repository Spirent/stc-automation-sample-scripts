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
# File Name:         HLTAPI_FC.tcl
#
# Description:      This script demonstrates the use of Spirent HLTAPI to setup FC connnection
#
# Test Step:         1. Reserve and connect chassis ports
#                    2. Config FC node on Port1
#                    3. Start FC login
#                    4. Retrive Statistics
#                    5. Start FC logout
#                    6. Retrive Traffic Statistics
#                    7. Release resources
#
#
# Topology
#                   FC Node                     FC Fabric
#                   [STC  2/1]-----------------[DUT ]
#
########################################

# Run sample:
#            c:>tclsh HLTAPI_FC_NPport.tcl 10.61.44.2 3/1

package require SpirentHltApi

########################################
# Step1: Reserve and connect chassis ports
########################################
set device               [lindex $argv 0]
set hltPort1              [lindex $argv 1]
set returnedString [sth::connect -device $device -port_list  [list $hltPort1]]
puts $returnedString
if {![keylget returnedString status ]} {
    puts "  FAILED."
	return
}
keylget returnedString port_handle.$device.$hltPort1 srcPort

########################################
# Step2: Config LAC on Port1
########################################
set returnedString [sth::fc_config  -port_handle     $srcPort   \
                   -mode            create  \
                   -nport_count       2 \
                   -wwpn            "20:00:00:10:94:00:00:01" \
                   -wwpn_step       "00:00:00:00:00:00:00:01" \
                   -wwnn            "10:00:00:10:94:00:00:01" \
                   -host_type       "initiator" \
                   -login_delay     10 \
                   -logout_delay    10 \
                   ]
puts $returnedString
if {![keylget returnedString status ]} {
    puts "  FAILED. "
	return
}
keylget returnedString handle fcSrc

#config parts are finished

########################################
# Step3: Start FC login
########################################
set returnedString [sth::fc_control -handle $fcSrc -action login]
puts $returnedString
if {![keylget returnedString status ]} {
    puts "  FAILED:  $returnedString"
	return
}

after 10000

########################################
# Step4: Retrive Statistics
########################################
set returnedString [sth::fc_stats   -handle $fcSrc -mode summary]
puts $returnedString
if {![keylget returnedString status ]} {
    puts "  FAILED. "
	return
}

########################################
# Step5: Start FC logout
########################################
set returnedString [sth::fc_control -handle $fcSrc -action logout]
puts $returnedString
if {![keylget returnedString status ]} {
    puts "  FAILED. "
	return
}

after 10000

########################################
# Step6: Retrive Statistics
########################################
set returnedString [sth::fc_stats   -handle $fcSrc -mode summary]
puts $returnedString
if {![keylget returnedString status ]} {
    puts "  FAILED. "
	return
}

########################################
# Step9: Release resources
########################################
set returnedString [::sth::cleanup_session -port_list [list $srcPort]]
puts $returnedString
if {![keylget returnedString status ]} {
    puts "  FAILED. "
	return
}


puts "_SAMPLE_SCRIPT_SUCCESS"