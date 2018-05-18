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
# File Name:            HLTAPI_Traffic_Fill_Pattern.tcl
#
# Description:          This script demonstrates the use of Spirent HLTAPI to setup RFC3918 test
#
# Test Step:            1. Create a burst traffic with payload fill pattern constant, fill value 200. Then start the traffic.
#                       2. Modify the stream to payload fill pattern increment, fill value 3. Then start the traffic.
#                       3. Modify the stream to payload fill pattern decrement, fill value 1000. Then start the traffic.

#################################

# Run sample:
#            c:>tclsh HLTAPI_Traffic_Fill_Pattern.tcl 10.61.44.2 3/1 3/3
#            c:>tclsh HLTAPI_Traffic_Fill_Pattern "10.61.44.2 10.61.44.7" 3/1 3/3

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

::sth::test_config  -logfile toshltLogfile \
                    -log 1\
                    -vendorlogfile tosstcExport\
                    -vendorlog 1\
                    -hltlog 1\
                    -hltlogfile toshltExport\
                    -hlt2stcmappingfile toshlt2StcMapping \
                    -hlt2stcmapping 1\
                    -log_level 7

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

# Start connect and reserve the ports
#
#1 - Connect to the chassis, reserve one port.
puts "Connect to the chassis";
set ret [sth::connect -device $device_list -port_list $port_list];

set status [keylget ret status]
if {$status} {
    set port1 [keylget ret port_handle.$device1.$port1]
    set port2 [keylget ret port_handle.$device2.$port2]
} else {
    set passFail FAIL
    puts "Error retrieving the port handles, error message was $ret"
	return
}
set port_list "$port1 $port2";

set ret [sth::interface_config 	-mode config \
                        -port_handle port1 \
                        -intf_ip_addr 6.43.1.8 \
                        -gateway 6.43.1.1]

set ret [sth::interface_config 	-mode config \
                        -port_handle port2 \
                        -intf_ip_addr 6.44.1.8 \
                        -gateway 6.44.1.1]


#fill_value :Specifies the value for a constant fill pattern or start value for a increment or decrement pattern interger, default value is 0
#-fill_type :  Specifies the fill pattern type to be used for payload. Possible 
#                   values are CONSTANT, INCR, DECR and PRBS. The default 
#                   value is CONSTANT. The types are described below: 
#                   CONSTANT - Use fixed fill pattern.
#                   INCR - Use incrementing value to fill the rest of the frame. 
#                          The step value is 1. The starting value is fixed. 
#                   DECR - Use decrementing value to fill the rest of the frame. 
#                         The step value is 1. The starting value is fixed.
#                   PRBS - Use a pseudo-random bit sequence to fill the rest of 
#                         the frame. The PRBS pattern is shared across streams that 
#                         use the PRBS as the fill pattern.

#Create a burst traffic with payload fill pattern constant, fill value 200.  
set ret [sth::traffic_config -mode create\
                -port_handle $port1 \
                -l2_encap ethernet_ii\
                -l3_protocol ipv4\
                -ip_src_addr 6.43.1.8\
                -fill_type constant \
                -fill_value 200 \
                -transmit_mode single_burst\
                -pkts_per_burst 200 \
                -mac_discovery_gw 6.43.1.1 \
                -ip_dst_addr 6.44.1.8]

#config parts are finished

TurnOnCapture $port_list "CT-1"
puts "Start the generator..."
set ret1 [sth::traffic_control  -action run  -stream_handle streamblock1]

stc::sleep 3

TurnOffCapture $port_list "CT-1"

stc::sleep 3

#Modify the stream to payload fill pattern increment, fill value 3
set ret [sth::traffic_config -mode modify\
                -stream_id streamblock1 \
                -fill_type incr \
                -fill_value 3]



TurnOnCapture $port_list "CT-1"
puts "Start the generator..."
set ret1 [sth::traffic_control  -action run  -stream_handle streamblock1]

stc::sleep 3

TurnOffCapture $port_list "CT-2"

stc::sleep 3

#Modify the stream to payload fill pattern decrement, fill value 1000.
set ret [sth::traffic_config -mode modify \
                -stream_id streamblock1 \
                -fill_type decr \
                -fill_value 1000 ]



TurnOnCapture $port_list "CT-2"
puts "Start the generator..."
set ret1 [sth::traffic_control  -action run  -stream_handle streamblock1]

stc::sleep 3

TurnOffCapture $port_list "CT-3"

stc::perform SaveasXml -config system1 -filename "./test.xml"
set ret [sth::cleanup_session  -port_handle port1 port2]

puts "_SAMPLE_SCRIPT_SUCCESS"
exit



