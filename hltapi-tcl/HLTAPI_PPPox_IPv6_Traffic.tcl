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
# File Name:                 HLTAPI_PPPox_IPv6_Traffic.tcl
#
# Description:               This script demonstrates how to test IPv6 traffic over pppox
#################################


#Dut Configuration:
        #ipv6 unicast-routing
        #
        #ipv6 local pool rui-pool2 BBBB:1::/48 64
        #ipv6 dhcp pool pool22
        #    prefix-delegation BBBB:1::23F6:33BA/64 0003000100146A54561B 
        #    prefix-delegation pool rui-pool2
        #    dns-server BBBB:1::19
        #    domain-name spirent.com
        #
        #
        #int g0/3
        #    ipv6 address BBBB:1::1/64
        #    ipv6 address FE80:1::1 link-local
        #    pppoe enable group bba-group2
        #int g5/0
        #    ipv6 address aaaa:1::1/64
        #    ipv6 address FE80:2::1 link-local
        #
        #
        #
        #bba-group pppoe bba-group2
        #virtual-template 6
        #sessions per-mac limit 20
        #
        #int virtual-template 6
        #    ipv6 enable
        #    ipv6 unnumbered gigabitEthernet 0/3
        #   no ppp authentication 
        #   encapsulation ppp
        #    ipv6 nd managed-config-flag
        #    ipv6 nd other-config-flag
        #    ipv6 dhcp server pool22 rapid-commit preference 1 allow-hint
#
#Topology
#         PPPox Client                      DHCP/PPPoX Server                     IPv6Host
#                [STC  2/1]-------------[g0/3 DUT g5/0]------------------[STC 2/2 ]
#                 unknown             bbbb:1::1       aaaa:1::1                    aaaa:1::2
#
#Writer: Rxu 2009/07/29
########################################

# Run sample:
#            c:>tclsh HLTAPI_PPPox_IPv6_Traffic.tcl 10.61.44.2 3/1 3/3
#            c:>tclsh HLTAPI_PPPox_IPv6_Traffic.tcl "10.61.44.2 10.61.44.7" 3/1 3/3

package require SpirentHltApi

set device_list      [lindex $argv 0]
set srcPort        [lindex $argv 1]
set dstPort        [lindex $argv 2]
set i 1
foreach device $device_list {
    set device$i $device
    incr i
}
set device$i $device
set port_list "$srcPort $dstPort"

#stc::config automationoptions -loglevel INFO -logto stdout
::sth::test_config  -logfile hltLogfile \
                        -log 1\
                        -vendorlogfile stcExport\
                        -vendorlog 1\
                        -hltlog 1\
                        -hltlogfile hltExport\
                        -hlt2stcmappingfile hlt2stcMapping \
                        -hlt2stcmapping 1\
                        -log_level 7

set returnedString [sth::connect -device $device_list -port_list  $port_list ]
keylget returnedString port_handle.$device1.$srcPort tgen1_port
keylget returnedString port_handle.$device2.$dstPort tgen2_port
puts "###    Reserve the Ports $tgen1_port and $tgen2_port "

puts "Config TGEN1 and TGEN2................................"
set returnedString [sth::interface_config \
                                    -port_handle 	$tgen1_port \
                                    -mode 		config \
                                    -ipv6_intf_addr 	BBBB:1::2\
                                    -ipv6_gateway      	BBBB:1::1\
                                    -autonegotiation 	1 \
                                    -arp_send_req 	1 \
                                    -arp_req_retries 	10 \
                                    -phy_mode fiber \
                                    ]
puts "$returnedString"
set returnedString [sth::interface_config \
				 -port_handle 		$tgen2_port\
                                 -mode 			config \
                                 -ipv6_intf_addr     aaaa:1::2\
                                 -ipv6_gateway        aaaa:1::1\
                                 -autonegotiation 	1 \
                                 -arp_send_req 		1 \
                                 -arp_req_retries 	10 \
                                 -phy_mode fiber \
                                 ]
puts "$returnedString\n"

puts "Config PPPox......................................."
set returnedString [sth::pppox_config  -port_handle $tgen1_port  -mode create -encap "ethernet_ii" -protocol pppoe  -ip_cp ipv6_cp\
                    -auth_mode none \
                    -chap_ack_timeout 10 \
                    -config_req_timeout 10 \
                    -ipcp_req_timeout 10 \
                    -auto_retry 1 \
                    -max_auto_retry_count 10 \
                    -max_echo_acks 10 \
                    -max_ipcp_req 10 \
                    -num_sessions 4 ]
puts "$returnedString\n"
keylget returnedString handles pppox_handles

puts "\nConfig Downstream and Upstream................"                    
set returnedString [ ::sth::traffic_config  -mode create  -port_handle port2  -l2_encap ethernet_ii  -l3_protocol ipv6  -emulation_dst_handle $pppox_handles  -ipv6_src_addr aaaa:1::2  -ipv6_src_mode fixed  -mac_src 00.00.02.00.00.01  -mac_discovery_gw aaaa:1::1]
puts "downstream: $returnedString"

set returnedString [::sth::traffic_config -mode create -port_handle port1 -l2_encap ethernet_ii  -l3_protocol ipv6 -emulation_src_handle $pppox_handles  -ipv6_dst_addr aaaa:1::2 -ipv6_dst_mode fixed  -mac_discovery_gw aaaa:1::1]
puts "upstream: $returnedString"

stc::perform SaveasXml -config system1 -filename PPPoxv6.xml
#config parts are finished

puts "PPPox Start Connect................................."
set returnString_pppox [sth::pppox_control -handle $pppox_handles -action connect]
puts "$returnString_pppox\n" 

puts "Sending traffic...................................."
set temp_port_list "$tgen1_port $tgen2_port" 
foreach temp_port_handle $temp_port_list {
            #CLear traffic stats before starting test
            set control_status [sth::traffic_control\
                                    -port_handle $temp_port_handle\
                                    -action clear_stats]
            sth::interface_config -port_handle $temp_port_handle -mode modify -arp_send_req 1
            
            set control_status [sth::traffic_control \
                                                -port_handle $temp_port_handle \
                                                -action run]
}

puts "Starting the Capture......................."
sth::packet_control -port_handle port1 -action start
sth::packet_control -port_handle port2 -action start
puts "Stopping the Capture......................."
sth::packet_control -port_handle port1 -action stop
sth::packet_control -port_handle port2 -action stop
puts "Save the Capture..........................."
sth::packet_stats -port_handle port1 -action filtered -format pcap -filename port1.pcap
sth::packet_stats -port_handle port2 -action filtered -format pcap -filename port2.pcap


puts "\nVerifying the Downstream Traffic.............."
set traffic_state_downstream [sth::traffic_stats -port_handle port1 -mode aggregate]
puts " $traffic_state_downstream "
set Rx_down [keylget traffic_state_downstream port1.aggregate.rx.total_pkt_rate]
set Tx_down [keylget traffic_state_downstream port1.aggregate.tx.total_pkt_rate]
puts " Rx_down: $Rx_down\n Tx_down: $Tx_down "

puts "\nVerifying the Upstream Traffic......................"
set traffic_state_upstream [sth::traffic_stats -port_handle port2 -mode aggregate]
puts " $traffic_state_upstream "
set Rx_up [keylget traffic_state_upstream port2.aggregate.rx.total_pkt_rate]
set Tx_up [keylget traffic_state_upstream port2.aggregate.tx.total_pkt_rate]
puts " Rx_up: $Rx_up \n Tx_up: $Tx_up "

puts "Script End"
puts "_SAMPLE_SCRIPT_SUCCESS"
return
