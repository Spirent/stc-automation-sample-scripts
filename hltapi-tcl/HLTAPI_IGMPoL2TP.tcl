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
# File Name:            HLTAPI_IGMPoL2TP.tcl
#
# Description:          This script demonstrates the use of Spirent HLTAPI to setup IGMP over L2TP test
#
# Topology:
#	LAC(stc)----------------DUT------------IPv4 Host(stc)
#      172.16.0.2   172.16.0.1   172.17.0.1      172.17.0.2
#				
# DUT Config:
# 	vpdn enable
# 	vpdn-group 1
#	 accept dialin l2tp virtual-template 10 remote HosLAC
#	 local name HosLNS
#	 no l2tp tunnel authentication
#	 l2tp tunnel receive-window 1024
#	 l2tp tunnel framing capabilities all
#	 l2tp tunnel bearer capabilities all
#	
#	ip local pool rui_ippool 10.88.55.1 10.88.55.10
#	
#	interface virtual-template 10
#	 ip address 10.88.55.11 255.255.255.0
#	 peer default ip address pool rui_ippool
#	 no ppp authentication
#	 ppp timeout idle 42000
#
########################################################################

# Run sample:
#            c:>tclsh HLTAPI_IGMPoL2TP.tcl 10.61.44.2 3/1 3/3
#            c:>tclsh HLTAPI_IGMPoL2TP.tcl "10.61.44.2 10.61.44.7" 3/1 3/3

package require SpirentHltApi

set device_list      [lindex $argv 0]
set dstPort        [lindex $argv 1]
set srcPort        [lindex $argv 2]
set i 1
foreach device $device_list {
    set device$i $device
    incr i
}
set device$i $device
set port_list "$dstPort $srcPort"

::sth::test_config  -logfile hltLogfile \
                    -log 1\
                    -vendorlogfile stcExport\
                    -vendorlog 1\
                    -hltlog 1\
                    -hltlogfile hltExport\
                    -hlt2stcmappingfile hlt2StcMapping \
                    -hlt2stcmapping 1\
                    -log_level 7

#### Define needed harwares

set mac_addr_tgen1	 "00:10:94:00:00:11"
set mac_addr_tgen2	 "00:10:94:00:00:22"
set dut_intf_tgen1_ip    "172.16.0.1"
set dut_intf_tgen2_ip    "172.17.0.1"
set tgen1_intf_dut_ip	 "172.16.0.2"
set tgen2_intf_dut_ip	 "172.17.0.2"
set tunnel_count 	 1
set session_count 	 1
set mc_group_ip 	 "225.0.0.25"
set mc_group_count 	 1

puts "-----------------------------Reserve the Ports------------------------"
set returnedString [sth::connect -device $device_list -port_list  $port_list ]
keylget returnedString port_handle.$device1.$dstPort tgen1_port
puts "LAC Port Handle:  $tgen1_port "
keylget returnedString port_handle.$device2.$srcPort tgen2_port
puts "LNS Port Handle:  $tgen2_port\n"


puts "-----------------------------Config TGEN1 and TGEN2------------------------"
set returnedString [sth::interface_config \
                                    -port_handle 	$tgen1_port \
                                    -mode 		config \
                                    -intf_ip_addr 	$tgen1_intf_dut_ip	\
                                    -gateway      	$dut_intf_tgen1_ip    \
                                    -src_mac_addr 	$mac_addr_tgen1	 \
                                    -autonegotiation 	1 \
                                    -arp_send_req 	1 \
                                    -arp_req_retries 	10 \
									-phy_mode 		copper \
                                    ]
puts "$returnedString"
set returnedString [sth::interface_config \
								-port_handle 		$tgen2_port \
                                -mode 			config \
                                -intf_ip_addr 		$tgen2_intf_dut_ip	\
								-gateway      		$dut_intf_tgen2_ip       \
                                -src_mac_addr 		$mac_addr_tgen2	        \
								-autonegotiation 	1 \
                                -arp_send_req 		1 \
                                -arp_req_retries 	10 \
                                -phy_mode 		copper \
                                 ]
puts "$returnedString\n"


puts "------------------------------Config LAC in TGEN1 -------------------------"
set returnedString [sth::l2tp_config \
                                  -mode                	lac \
                                  -port_handle          $tgen1_port \
                                  -hostname            	"HosLAC" \
                                  -auth_mode            none \
                                  -l2_encap            	ethernet_ii \
                                  -l2tp_src_addr        $tgen1_intf_dut_ip \
                                  -l2tp_dst_addr       	$dut_intf_tgen1_ip    \
                                  -num_tunnels 	 	$tunnel_count \
                                  -sessions_per_tunnel 	$session_count \
                                  -hello_interval 	255 \
                                  -hello_req 		1 \
                                  -redial_timeout 	10 \
                                  -redial_max 3 \
                                  ]
keylget returnedString handles lac_handles
puts "$returnedString\n"



puts "---------------------------Connect the LAC and LNS--------------------------"
set returnedString [sth::l2tp_control -handle $lac_handles -action connect]
puts "$returnedString"

set returnedString [sth::l2tp_stats   -handle $lac_handles -mode aggregate]
puts "$returnedString\n"


puts "---------------------------Enable IGMP on LAC--------------------------------"
set returnedString [sth::emulation_igmp_config \
                	           -mode 			create  \
	                           -handle 			$lac_handles\
        	                   -older_version_timeout 	400 \
	                           -robustness 			2 \
        	                   -unsolicited_report_interval 10\
				   -igmp_version 		v3 \
				   ]
puts "$returnedString\n"
keylget returnedString handle igmpSession

puts "----------------------Config the Multicast Group-------------------------------"
set returnedString [sth::emulation_multicast_group_config \
				   -mode 		create \
				   -ip_addr_start	$mc_group_ip \
				   -num_groups 		$mc_group_count \
				   ]
keylget returnedString handle igmpGroup
puts "$returnedString\n"


puts "-------------------Bound the IMGP and the Multicast Group------------------------"
set returnedString [sth::emulation_igmp_group_config \
				   -mode 		create \
				   -group_pool_handle	$igmpGroup \
				   -session_handle	$igmpSession \
				   ]
puts "$returnedString \n"



puts "--------------------Config the Downstream Traffic: TGEN2->TGEN1------------------"
set returnedString [sth::traffic_config \
                            -mode 		create \
                            -port_handle 	$tgen2_port \
                            -rate_pps 		1000 \
                            -l2_encap 		ethernet_ii \
                            -l3_protocol 	ipv4 \
                            -l3_length 		108\
                            -transmit_mode 	continuous \
                            -length_mode 	fixed \
        	            -ip_src_addr 	$tgen2_intf_dut_ip	 \
	                    -ip_dst_addr 	$mc_group_ip \
		            -mac_src 		$mac_addr_tgen1 \
                	    -mac_dst 		"01.00.5E.00.00.11" \
                            ]
puts "$returnedString \n" 


puts "---------------------------IGMP Join the Multicast Group-----------------------"
set returnedString [sth:::emulation_igmp_control \
				-handle 		$igmpSession  \
				-mode 			join        \
				-calculate_latency 	false \
			        -leave_join_delay 	0 \
				]
puts "$returnedString "

stc::perform SaveasXml -config system1 -filename    "./IgmpoL2tp.xml"
#config parts are finished

set returnedString [sth:::emulation_igmp_info -handle $igmpSession]
puts "$returnedString \n"

puts "Start the Capture"
sth::packet_control -port_handle $tgen1_port -action start

puts "-----------------------------------Start the Traffic---------------------------"
set returnedString [sth::traffic_control  -port_handle all  -action run]
puts "$returnedString \n"

puts "After 2000\n"
after 2000

puts "-----------------------------------Stop the Traffic---------------------------"
set returnedString [sth::traffic_control     -port_handle all -action stop]
puts "$returnedString \n"

puts "Stop the Capture"
sth::packet_control -port_handle $tgen1_port -action stop

puts "After 2000\n"
after 2000
puts "Save the Capture "
sth::packet_stats -port_handle $tgen1_port -action filtered -format pcap -filename "igmpol2tp.pcap"

puts "-----------------------------------Verify the Result ---------------------------"
set src_traffic [sth::interface_stats -port_handle $tgen2_port]
puts "$src_traffic \n"
set Src_Tx [keylget src_traffic tx_generator_ipv4_frame_count]
set Src_Rx [keylget src_traffic rx_sig_count]
puts "Src Tx:--------------$Src_Tx"
puts "Src Rx:--------------$Src_Rx"

set dst_traffic [sth::interface_stats -port_handle $tgen1_port]
puts "$dst_traffic \n"
set Dst_Tx [keylget dst_traffic tx_generator_ipv4_frame_count]
set Dst_Rx [keylget dst_traffic rx_sig_count]
puts "Dst Tx:--------------$Dst_Tx"
puts "Dst Rx:--------------$Dst_Rx"

puts "$returnedString \n"
puts "---------------------------IGMP Leave the Multicast Group-----------------------"
set returnedString [sth:::emulation_igmp_control \
				-handle 		$igmpSession  \
				-mode 			leave        \
				-calculate_latency 	false \
			        -leave_join_delay 	0 \
				]
puts "$returnedString "

puts "-----------------------------------Start the Traffic---------------------------"
set returnedString [sth::traffic_control -port_handle all -action run]

puts "-----------------------------Verify the Result after Leave the Group---------------"
set src_traffic [sth::interface_stats -port_handle $tgen2_port]
puts "$src_traffic \n"
set Src_Tx [keylget src_traffic tx_generator_ipv4_frame_count]
set Src_Rx [keylget src_traffic rx_sig_count]
puts "Src Tx:--------------$Src_Tx"
puts "Src Rx:--------------$Src_Rx"

set dst_traffic [sth::interface_stats -port_handle $tgen1_port]
puts "$dst_traffic \n"
set Dst_Tx [keylget dst_traffic tx_generator_ipv4_frame_count]
set Dst_Rx [keylget dst_traffic rx_sig_count]
puts "Dst Tx:--------------$Dst_Tx"
puts "Dst Rx:--------------$Dst_Rx"

puts "_SAMPLE_SCRIPT_SUCCESS"

puts "\nScript End"
exit

