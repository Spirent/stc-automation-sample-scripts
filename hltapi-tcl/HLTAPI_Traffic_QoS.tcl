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
# File Name:                 HLTAPI_Traffic_QoS.tcl
#
# Description:               This script demonstrates how to configure traffic QoS and query the result based on the QoS value
#
# Test step:                1.Config the stream block with multiple inner and outer vlan priority
#                           2.Start the taffic. Get the real time results filter based both on the inner and outer vlan priority
#                           3.Stop the traffic. Get the EOT result.
#
#                           4.Config the stream block with mutiple tos value
#                           5.Start the taffic. Get the real time results filter based on the qos value
#                           6.Stop the traffic. Get the EOT result.
#
#                           7.Config the stream block with mutiple dscp value
#                           8.Start the taffic. Get the real time results filter based on the dscp value
#                           9.Stop the traffic. Get the EOT result.
#####################################

# Run sample:
#            c:>tclsh HLTAPI_Traffic_QoS.tcl 10.61.44.2 3/1 3/3
#            c:>tclsh HLTAPI_Traffic_QoS "10.61.44.2 10.61.44.7" 3/1 3/3

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


#step1. Test configure vlan priority
if {$step1} {
	#Config the stream block with multiple inner and outer vlan priority
	set streamBlk1 [sth::traffic_config -mode create\
					-port_handle $port1 \
					-l2_encap ethernet_ii_vlan\
					-fill_type prbs \
					-vlan_id 1\
					-vlan_id_count 3\
					-vlan_id_step 1 \
					-vlan_user_priority {1 2 3}\
					-vlan_id_outer 100 \
					-vlan_id_outer_step 1 \
					-vlan_id_outer_count 3 \
					-vlan_outer_user_priority {4 5 6} \
					-transmit_mode continuous\
					-rate_pps 1000\
					-l3_protocol ipv4\
					-ip_src_addr 10.0.0.11\
					-ip_dst_addr 10.0.0.1]

	set vlanstreamHandle [keylget streamBlk1 stream_id]

	stc::perform SaveasXml -config system1 -filename "./vlanqostest.xml"

	puts "Start the generator..."
	set x [sth::traffic_control -action run -port_handle $port1 -get vlan_pri]
	after 300
	#

	set trafficStats [sth::traffic_stats -mode aggregate -port_handle $port2]
	puts "Wait for 30 seconds..."
	puts "realtime, outer vlan pri is : $trafficStats\n"
	after 3000

	puts "stop the traffic"
	set x [sth::traffic_control -action stop -port_handle $port1]
	#

	set trafficStats [sth::traffic_stats -mode aggregate -port_handle $port2]
	puts "Wait for 30 seconds..."
	puts "eot, outer vlan pri is :$trafficStats\n"

	puts "Start the generator again for filter innner vlan..."
	set x [sth::traffic_control -action run -port_handle $port1 -get vlan_pri_inner]
	after 300
	#

	set trafficStats [sth::traffic_stats -mode aggregate -port_handle $port2]
	puts "Wait for 30 seconds..."
	puts "realtime, inner vlan pri is : $trafficStats\n"
	after 3000

	puts "stop the traffic"
	set x [sth::traffic_control -action stop -port_handle $port1]

	after 300
	#

	set trafficStats [sth::traffic_stats -mode aggregate -port_handle $port2]
	puts "Wait for 30 seconds..."
	puts "eot, inner vlan pri is : $trafficStats\n"
	after 3000


	puts "disable the vlan stream"
	set ret [sth::traffic_config -mode disable -stream_id $vlanstreamHandle]
}

if {$step2} {
	puts "create the dscp stream"
	set streamBlk1 [sth::traffic_config -mode create\
					-port_handle $port1\
					-l2_encap ethernet_ii\
					-ip_dscp  26 \
					-ip_dscp_step 1\
					-ip_dscp_count 3\
					-transmit_mode continuous\
					-rate_pps 10000\
					-l3_protocol ipv4\
					-ip_src_addr 10.0.0.11\
					-ip_dst_addr 10.0.0.1\
					-l4_protocol tcp\
					-tcp_src_port 1000\
					-tcp_dst_port 2000]

	set dscpstreamHandle [keylget streamBlk1 stream_id]

	puts "Start the generator..."
	set x [sth::traffic_control -action run -port_handle $port1 -get dscp]
	after 300

	set trafficStats [sth::traffic_stats -mode aggregate -port_handle $port2]
	puts "Wait for 30 seconds..."
	puts "real time dscp value is : $trafficStats\n"
	after 300

	puts "stop the traffic"
	set x [sth::traffic_control -action stop -port_handle $port1]

	set trafficStats [sth::traffic_stats -mode aggregate -port_handle $port2]
	puts "Wait for 30 seconds..."
	puts "eot, dscp is :$trafficStats\n"

	puts "disable the vlan stream"
	set ret [sth::traffic_config -mode disable -stream_id $dscpstreamHandle]
}

if {$step3} {
    puts "create the tos stream"
    set streamBlk1 [sth::traffic_config -mode create\
                -port_handle $port1 \
                -l2_encap ethernet_ii\
                -ip_tos_field  2 \
                -ip_tos_step 1 \
                -ip_tos_count 3 \
                -ip_precedence 2 \
                -ip_mbz 1\
                -transmit_mode continuous\
                -rate_pps 1000\
                -l3_protocol ipv4\
                -ip_src_addr 10.0.0.11\
                -ip_dst_addr 10.0.0.1\
                -l4_protocol tcp\
                -tcp_src_port 1000\
                -tcp_dst_port 2000  ]
    
	set tosstreamHandle [keylget streamBlk1 stream_id]

	puts "Start the generator..."
	set x [sth::traffic_control -action run -port_handle $port1 -get tos]
	after 300

	set trafficStats [sth::traffic_stats -mode aggregate -port_handle $port2]
	puts "Wait for 30 seconds..."
	puts "real time tos value is : $trafficStats\n"
	after 300

	puts "stop the traffic"
	set x [sth::traffic_control -action stop -port_handle $port1]

	stc::perform SaveasXml -config system1 -filename "./tostest.xml"

	set trafficStats [sth::traffic_stats -mode aggregate -port_handle $port2]
	puts "Wait for 30 seconds..."
	puts "eot, tos is :$trafficStats\n"

	puts "disable the vlan stream"
	set ret [sth::traffic_config -mode disable -stream_id $tosstreamHandle] 
}

puts "_SAMPLE_SCRIPT_SUCCESS"
exit;
