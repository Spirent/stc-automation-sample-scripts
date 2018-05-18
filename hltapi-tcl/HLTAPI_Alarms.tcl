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
# File Name:            HLTAPI_Alarms.tcl
#
# Description:          This script demonstrates the use of Spirent HLTAPI to setup Sonet Alarms test
#
# Test Step:            1. Reserve and connect chassis ports
#                       2. Config sonet interface
#                       3. Start momentary line_ais alarm
#                       4. Check alarms stats after starting line_ais alarm
#                       5. Reset all alarms indications
#                       6. Check alarms stats after resetting alarms
#                       7. Start continuous line_ais alarm
#                       8. Stop continuous line_ais alarm
#                       9. Check alarms stats
#                       10.Release resources
#################################

# Run sample:
#            c:>tclsh HLTAPI_Alarms.tcl 10.61.44.2 3/1 3/3
#            c:>tclsh HLTAPI_Alarms.tcl "10.61.44.2 10.61.44.7" 3/1 3/3

package require SpirentHltApi

set device_list      [lindex $argv 0]
set port1        [lindex $argv 1]
set port2        [lindex $argv 2]
set port_list "$port1 $port2"
set i 1
foreach device $device_list {
    set device$i $device
    incr i
}
set device$i $device

::sth::test_config  -logfile alarms_hltLogfile \
                    -log 1 \
                    -vendorlogfile alarms_stcExport\
                    -vendorlog 1\
                    -hltlog 1\
                    -hltlogfile alarms_hltExport \
					-hlt2stcmappingfile alarms_hlt2StcMapping \
                    -hlt2stcmapping 1 \
                    -log_level 7
					
#step 1 : reserve and connect 
set returnedString [sth::connect -device $device_list -port_list $port_list]
puts $returnedString
keylget returnedString status status
if {!$status} {
	puts $returnedString
    puts "  FAILED:  $status"
	return
}

keylget returnedString port_handle.$device2.$port2 hltHostPort
keylget returnedString port_handle.$device1.$port1 hltSourcePort
set portList "$hltHostPort $hltSourcePort"

#step 2 : config sonet interface
set portSpeed "oc192"
set portMode "pos_ppp"
set frameMode "sonet"

 foreach port $portList {
    set returnedString [ sth::interface_config	-mode config \
    						-port_handle $port \
    						-intf_mode  $portMode \
                                                -speed      $portSpeed \
                                                -framing           $frameMode \
                       ]
 puts "\n$returnedString"   
 } 
################################################################################


#step 3 : start momentary line_ais alarm
puts "--------- testing momentary line_ais alarm ---------"
set returnedString [sth::alarms_control -port_handle $hltSourcePort \
                    -alarm_type line_ais \
                    -count 5 \
                    -interval 5 \
                    -state 1]

puts "\n$returnedString"

set alarms ""
#step 4 : get alarms stats
foreach port $portList {
    set returnedString [sth::alarms_stats -port_handle $port]

    puts "\n$returnedString"
    keylget returnedString active_alarms alarms
    puts "\n active_alarms on $port: \n$alarms"
}

#step 5 : reset alarms
foreach port $portList {
    set returnedString [sth::alarms_control -port_handle $port -reset 1]
    puts "\n$returnedString"
}

#step 6 : get alarms stats after resetting
unset alarms
set alarms ""

foreach port $portList {
    set returnedString [sth::alarms_stats -port_handle $port]

    puts "\n$returnedString"
    keylget returnedString active_alarms alarms
    puts "\n active_alarms on $port: \n$alarms"
    
    if {$alarms != "--"} {
        puts "failed in resetting"
		return
    }
}

#step 6 : start continuous line_ais alarm
puts "--------- testing continuous line_ais alarm ---------"

set returnedString [sth::alarms_control -port_handle $hltSourcePort \
                    -alarm_type line_ais \
                    -mode continuous \
                    -state 1]

puts "\n$returnedString"

after 30000

#step 7 : stop continuous line_ais alarm

set returnedString [sth::alarms_control -port_handle $hltSourcePort \
                    -alarm_type line_ais \
                    -state 0]

puts "\n$returnedString"


#step 8 : get alarms stats
unset alarms
set alarms ""

foreach port $portList {
    set returnedString [sth::alarms_stats -port_handle $port]

    puts "\n$returnedString"
    keylget returnedString active_alarms alarms
    puts "\n active_alarms on $port: \n$alarms"
}

set returnedString [::sth::cleanup_session -port_list $portList]
puts "_SAMPLE_SCRIPT_SUCCESS"
