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
# File Name:                 HLTAPI_Traffic_Rtp.tcl
#
# Description:               This script demonstrates how to creat RTP traffic
#######################################

# Run sample:
#            c:>tclsh HLTAPI_Traffic_Rtp.tcl 10.61.44.2 3/1 3/3
#            c:>tclsh HLTAPI_Traffic_Rtp "10.61.44.2 10.61.44.7" 3/1 3/3

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

# Setup global variables
set timeOut 20
set step1 1
set step2 1
set step3 1

set verdict PASS

::sth::test_config  -logfile toshltLogfile \
                    -log 1\
                    -vendorlogfile tosstcExport\
                    -vendorlog 1\
                    -hltlog 1\
                    -hltlogfile toshltExport\
                    -hlt2stcmappingfile toshlt2StcMapping \
                    -hlt2stcmapping 1\
                    -log_level 7

#
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

#create the RTP traffic
set streamBlk1 [sth::traffic_config -mode create\
                -port_handle $port1 \
                -l2_encap ethernet_ii \
                -fill_type prbs \
                -transmit_mode continuous\
                -rate_pps 1000\
                -l3_protocol ipv4\
                -ip_src_addr 10.0.0.11\
                -ip_dst_addr 10.0.0.1 \
                -l4_protocol rtp \
                -ssrc 1000 \
                -timestamp_initial_value 210 \
                -timestamp_increment 64 \
                -rtp_csrc_count 2 \
                -csrc_list {2100 3800}]

#Modify the RTP taffic 
set streamBlk1 [sth::traffic_config -mode modify\
                -stream_id streamblock1 \
                -l4_protocol rtp \
                -rtp_payload_type 4 \
                -rtp_csrc_count 3 \
                -timestamp_initial_value 2 \
                -timestamp_increment 64 \
                -csrc_list {2100 3800 4500}]


stc::perform SaveasXml -config system1 -filename "./RTPtest.xml"
#config parts are finished

puts "_SAMPLE_SCRIPT_SUCCESS"
exit;
