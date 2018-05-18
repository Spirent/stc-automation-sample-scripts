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
# File Name:            HLTAPI_PPP_IPCPv4.tcl
#
# Description:          This script demonstrates the use of Spirent HLTAPI to setup IP-over-PPP-over-Pos(PPP)test
#
# Test Step:            1. Reserve and connect chassis ports
#                       2. Config pos interface
#                       3. Config PPP with IPCPv4 configuration
#                       4. Start PPP session 
#                       5. Retrive PPP statistics
#                       6. Stop PPP session 
#                       7. Release resources
#################################

# Run sample:
#            c:>tclsh HLTAPI_PPP_IPCPv4.tcl 10.61.44.2 3/1 3/3
#            c:>tclsh HLTAPI_PPP_IPCPv4.tcl "10.61.44.2 10.61.44.7" 3/1 3/3

package require SpirentHltApi

set device_list      [lindex $argv 0]
set port1        [lindex $argv 1]
set port2        [lindex $argv 2]
set i 0
foreach device $device_list {
    set device$i $device
    incr i
}
set device$i $device
set port_list "$port1 $port2"

::sth::test_config  -logfile ppp_hltLogfile \
                    -log 1\
                    -vendorlogfile ppp_stcExport\
                    -vendorlog 1\
                    -hltlog 1\
                    -hltlogfile ppp_hltExport \
					-hlt2stcmappingfile ppp_hlt2StcMapping \
                    -hlt2stcmapping 1 \
                    -log_level 7

puts "---------------step1 connect $device0 $device1/ $port1 $port2-----------------"

set returnedString [sth::connect -device $device_list -port_list [list $port1 $port2]]
    
puts $returnedString
keylget returnedString status status
if {!$status} {
    return "  FAILED:  $status"
}
    
keylget returnedString port_handle.$device0.[lindex $port_list 0] hltDstPort 
keylget returnedString port_handle.$device1.[lindex $port_list 1] hltSourcePort

puts "---------------step2 pos interface config---------------------"
set portsList "$hltSourcePort $hltDstPort"

foreach port $portsList {
    
    set returnedString [sth::interface_config -port_handle $port \
                        -mode config \
                        -intf_mode pos_ppp \
                        -framing sonet \
                        -speed oc192 ]
    
    puts "\n$returnedString"              
}

puts "------------ step3 config ppp on $hltSourcePort -----------------"

# requires the peer to set the local setting for hltSourcePort
set returnedString [sth::ppp_config -port_handle $hltSourcePort \
                                                -action config \
                                                -local_auth_mode pap \
                                                -username ss1 \
                                                -password ss1 \
                                                -ipv6_cp 0 \
                                                -local_addr  0.0.0.0 \
                                                -local_addr_given 1 \
                                                -local_addr_override 0 ] 

puts "\n$returnedString"

keylget returnedString handles pppHandle1

puts "------------ config ppp on $hltDstPort -----------------"

set returnedString [sth::ppp_config -port_handle $hltDstPort \
                                                -action config \
                                                -local_auth_mode pap \
                                                -username ss1 \
                                                -password ss1 \
                                                -ipv6_cp 0 \
                                                -local_addr  192.168.1.6 \
                                                -local_addr_given 1\
                                                -local_addr_override 0 \
                                                -peer_addr 192.168.2.3 \
                                                -peer_addr_given 1 \
                                                -peer_addr_override 0 ]
puts "\n$returnedString"

keylget returnedString handles pppHandle2

stc::perform saveasxml -filename ppp.xml
#config parts are finished

set pppHandleList "$pppHandle1 $pppHandle2"

puts "-------------------step4 start ppp session ---------------"

foreach pppHandle $pppHandleList {
    set returnedString [sth::ppp_config \
                        -action up \
                        -handle $pppHandle ]
    
    puts "\n$returnedString"
}

stc::sleep 10

puts "----------------step5 retrive PPP statistics -----------------"
foreach port $portsList {
    set returnedString [sth::ppp_stats \
                        -action collect \
                        -port_handle $port ]
    
    puts "\n$returnedString"
}

puts "\n$returnedString"

puts "-------------------step6 stop ppp session ---------------"
foreach pppHandle $pppHandleList {
    set returnedString [sth::ppp_config \
                        -action down \
                        -handle $pppHandle ]
    puts "\n$returnedString"
}

puts "-------------------step7 release resources ---------------"

set returnedString [::sth::cleanup_session -port_list $portsList]
puts "\n$returnedString"
puts "_SAMPLE_SCRIPT_SUCCESS"



