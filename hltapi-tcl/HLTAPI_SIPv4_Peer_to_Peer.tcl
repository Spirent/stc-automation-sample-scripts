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
# File Name:            HLTAPI_SIPv4_Peer_to_Peer.tcl
#
# Description:          This script demonstrates the use of Spirent HLTAPI to setup peer-to-peer SIPv4 test
#
# Test Step:            1. Reserve and connect chassis ports
#                       2. Configure SIP callees (UASs) on one port, and SIP callers (UACs) on the other port 
#                       3. Establish a call between callers and callees
#                       4. Retrieve SIP statistics
#                       5. Delete sip hosts and release port resources
#################################

# Run sample:
#            c:>tclsh HLTAPI_SIPv4_Peer_to_Peer.tcl 10.61.44.2 3/1 3/3
#            c:>tclsh HLTAPI_SIPv4_Peer_to_Peer.tcl "10.61.44.2 10.61.44.7" 3/1 3/3

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

#######################################################
#Name: TurnOnCapture
#Author: Quinten Pierce
#Purpose: To turn on capture, either Hardware or Cut-Thru for a list of ports
#Input:  Port Handle list, capture type
#Output: fileNameList.  The list of filenames created is returned to the calling procedure/program
#                 Capture is turned on for the ports in the port handle list
#######################################################
proc TurnOnCapture {portHandleList {captureType  "HW"} {fileName "PortNum"}} {
    set captureHndList ""

    foreach portHnd $portHandleList {
        puts "Turn on capture on $portHnd"
        set capture [stc::get $portHnd -children-capture]
        stc::perform CaptureStart -CaptureProxyId $capture
        lappend captureHndList $capture
    }

    return $captureHndList
}   ;# end procedure

#######################################################
#Name: TurnOffCapture
#Author: Quinten Pierce
#Purpose: To turn off capture, and to retrieve the captured frames
#Input:  Port Handle list
#Output: None.  Capture is turned off, and the frames are retrieved
#######################################################
proc TurnOffCapture {portHandleList {fileName CaptureFilePort}} {
    set fileNameList {}
    set count 1;
    foreach portHnd $portHandleList {
        puts "Turn off capture on $portHnd"
        set captureHnd [stc::get $portHnd -children-capture]
        stc::perform CaptureStop -CaptureProxyId $captureHnd
        set name $fileName$count
        puts "Saving capture to $name"
        stc::perform SaveSelectedCaptureData -CaptureProxyId $captureHnd -filename "$name.pcap"
        lappend fileNameList "$name.pcap"
        incr count
    }
    puts "Save file Name list = $fileNameList"
    return $fileNameList
}

::sth::test_config  -logfile sip_peer_hltLogfile \
                    -log 1\
                    -vendorlogfile sip_peer_stcExport\
                    -vendorlog 1\
                    -hltlog 1\
                    -hltlogfile sip_peer_hltExport \
                    -hlt2stcmapping 1 \
                    -log_level 7

#step 1 : reserve and connect 
set returnedString [sth::connect -device $device_list -port_list $port_list]

puts $returnedString
keylget returnedString status status
if {!$status} {
    return "  FAILED:  $status"
}

keylget returnedString port_handle.$device2.$port2 hltHostPort
keylget returnedString port_handle.$device1.$port1 hltSourcePort

#step 2 : configure SIP callees
set returnedString [sth::emulation_sip_config -port_handle $hltSourcePort \
                                                -mode create \
                                                -count 2 \
                                                -name Callee1 \
                                                -mac_address_start 00:10:94:00:00:01 \
                                                -local_ip_addr 192.1.0.15 \
                                                -remote_ip_addr 192.1.0.1 \
                                                -local_username_prefix callee \
                                                -local_username_suffix 1000 \
                                                -local_username_suffix_step 3 \
                                                -registration_server_enable 0 \
                                                -registrar_address 150.48.0.20 \
                                                -call_accept_delay_enable 0 \
                                                -call_using_aor 1 \
                                                -remote_host 192.1.0.1 \
                                                -remote_host_step 1 ]
puts "\n$returnedString"

keylget returnedString status status
if {$status} {
    puts "\nConfiugring SIP callee is completed"
}

keylget returnedString handle sipCallee

#step 3: configure SIP callers
set returnedString [sth::emulation_sip_config -port_handle $hltHostPort \
                                                -mode create \
                                                -count 2 \
                                                -name Callee1 \
                                                -mac_address_start 00:10:94:00:01:03 \
                                                -local_ip_addr 192.1.0.1 \
                                                -local_ip_addr_step 1 \
                                                -remote_ip_addr 192.1.0.15 \
                                                -remote_ip_addr_step 0 \
                                                -local_username_prefix caller \
                                                -local_username_suffix 3000 \
                                                -local_username_suffix_step 3 \
                                                -registration_server_enable 0 \
                                                -call_using_aor 1 \
                                                -remote_host 192.1.0.15  \
                                                -remote_host_step 1 \
                                                ]
puts "\n$returnedString"

keylget returnedString status status

if {$status} {
    puts "\nConfiugring SIP callee is completed"
}

keylget returnedString handle sipCaller

# save sip configuration to xml file
stc::perform saveasxml -filename sip.xml
#config parts are finished

#turn on capture
TurnOnCapture $hltHostPort "CT"

set handleList "$sipCallee $sipCaller"

#step 5: establish a call between callers and callees, no registering when peer to peer
set returnedString [sth::emulation_sip_control  -action establish \
                                                -handle $sipCaller]

puts "\n$returnedString"

stc::sleep 2

set ret [sth::emulation_sip_control  -action terminate \
                                                -handle $sipCaller]
set startStatus [keylget ret status]
  puts "\n$startStatus"
  
#turn off capture
TurnOffCapture $hltHostPort "CT"

#step 6: retrieve statistics
set returnedString [sth::emulation_sip_stats    -handle "$sipCaller $sipCallee"\
                                                -action collect \
                                                -mode device ]

puts "\n$returnedString"

# clear statistics
set returnedString [sth::emulation_sip_stats    -handle $sipCaller \
                                                -action clear \
                                                -mode device ]
puts "\n$returnedString"

# retrieve statistics
set returnedString [sth::emulation_sip_stats    -handle "$sipCaller $sipCallee"\
                                                -action collect \
                                                -mode device ]
puts "\n$returnedString"

# step 7: delete sip host
set returnedString [sth::emulation_sip_config -handle $sipCaller \
                                                -mode delete \
                   ]
puts "\n$returnedString"

set returnedString [sth::emulation_sip_config -handle $sipCallee \
                                                -mode delete \
                   ]
puts "\n$returnedString"

# step 8: release resouces
set hPortlist "$hltSourcePort"
set returnedString [::sth::cleanup_session -port_list $hPortlist]
puts "_SAMPLE_SCRIPT_SUCCESS"