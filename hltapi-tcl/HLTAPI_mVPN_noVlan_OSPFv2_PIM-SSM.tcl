# Copyright (c) 2010 by Spirent Communications, Inc.
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
# TFile Name:     HLTAPI_mVPN_noVlan_OSPFv2_PIM-SSM.tcl
#
# Objective: This script demonstrates the use of Spirent HLTAPI to setup MVPN working with PIM SSM
#
# Test Step:
#                    1. Reserve and connect chassis ports                             
#                    2. Config pos interface
#                    3. Add MVPN Provider Port
#                    4. Add MVPN Customer Port
#                    5. Config MVPN:
#                       Config the P-side Router, select OSPFv2 as IGP, enable P router.
#                       Config the CE Router, use PIM-SSM for P and C network.
#                       Create traffic from customer CE to "provider & customer CE" .
#                    6. Start MVPN
#                    7. Get MVPN Info
#                    8. Start MVPN Traffic
#                    9. Stop MVPN Traffic
#                   10. Get MVPN Traffic Stats
#                   11. Stop MVPN
#                   12. Delete MVPN Configuration
#                   13. Release resources
# 
#Topology:
#                         
#                [STC Provider port]--------+----------- Port [DUT] Port --------+-----------[STC Customer port]     
#
# Dut Configuration:
#                Configure the DUT as a MVPN PE.
#################################

# Run sample:
#            c:>tclsh HLTAPI_mVPN_noVlan_OSPFv2_PIM-SSM.tcl 10.61.44.2 3/1 3/3
#            c:>tclsh HLTAPI_mVPN_noVlan_OSPFv2_PIM-SSM.tcl "10.61.44.2 10.61.44.7" 3/1 3/3

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

############################################
# Step1: Reserve and connect chassis ports #
############################################
set returnedString [sth::connect -device $device_list -port_list $port_list]
if {![keylget returnedString status ]} {
puts $returnedString
    return "FAILED"
}

set portHandle1 [keylget returnedString port_handle.$device1.$port1]
set portHandle2 [keylget returnedString port_handle.$device2.$port2]
set hPortlist "$portHandle1 $portHandle2"

############################################
# Step2: Config pos interface              #
############################################

foreach port $hPortlist {
    set returnedString [sth::interface_config   -port_handle       $port \
                                                -mode              config \
                                                -phy_mode          copper \
                                                -duplex            full \
                                                -intf_mode         ethernet]
    if {![keylget returnedString status ]} {
	puts $returnedString
        return "FAILED"
    }
}

############################################
# Step3: Config MVPN Provider Port         #
############################################

set cmdStatus [sth::emulation_mvpn_provider_port_config -port_handle $portHandle1 \
                                                        -action add \
                                                        -dut_interface_ipv4_addr 6.23.1.1 \
                                                        -dut_interface_ipv4_prefix_length 24 \
                                                        -dut_interface_ipv4_addr_step 0.0.1.0 ]
set status [keylget cmdStatus status]
if { $status} {
    puts "pass"
} else {
    puts "add provider port error."
    puts [keylget cmdStatus log]
    return
}

############################################
# Step4: Config MVPN Customer Port         #
############################################

set cmdStatus [sth::emulation_mvpn_customer_port_config -port_handle $portHandle2 \
                                                        -action add \
                                                        -dut_interface_ipv4_addr 6.24.1.1 \
                                                        -dut_interface_ipv4_prefix_length 24 \
                                                        -dut_interface_ipv4_addr_step 0.0.1.0 ]
set status [keylget cmdStatus status]
if { $status} {
    puts "pass"
} else {
    puts "add customer port error."
    puts [keylget cmdStatus log]
    return
}

############################################
# Step5: Config MVPN Parameters            #
############################################

set cmdStatus [sth::emulation_mvpn_config   -mode create \
                                            -dut_loopback_ipv4_addr 220.1.1.1 \
                                            -dut_as 123 \
                                            -igp_protocol ospf \
                                            -mpls_protocol ldp \
                                            -p_router_enable 1 \
                                            -p_router_number_per_sub_interface 1 \
                                            -p_rouer_topology_type tree \
                                            -p_router_interface_ipv4_addr 91.0.0.1 \
                                            -p_router_interface_ipv4_prefix_length 30 \
                                            -p_router_loopback_ipv4_addr 91.0.0.2 \
                                            -p_router_loopback_ipv4_addr_step 0.0.0.1 \
                                            -pe_router_number_per_sub_interface 1 \
                                            -pe_router_loopback_ipv4_addr 92.1.1.1 \
                                            -pe_router_loopback_ipv4_addr_step 0.0.0.1 \
                                            -vrf_number 1 \
                                            -vrf_rd_assignment use_rt \
                                            -vrf_route_target_start 1:0 \
                                            -vrf_route_target_step 1:0 \
                                            -customer_ce_vrf_assignment round_robin \
                                            -customer_ce_bgp_as 100 \
                                            -customer_ce_bgp_as_step_per_vrf_enable 1 \
                                            -customer_ce_bgp_as_step_per_vrf 1 \
                                            -customer_ce_routing_protocol bgp \
                                            -provider_pe_vrf_assignment vpn_per_pe \
                                            -provider_pe_vrf_count 1 \
                                            -multicast_provider_pim_protocol pim_sm \
                                            -multicast_provider_rp_addr 220.1.1.1 \
                                            -multicast_customer_pim_protocol pim_sm \
                                            -multicast_customer_rp_addr 6.24.1.1 \
                                            -multicast_customer_rp_increment 0.0.0.1 \
                                            -multicast_default_mdt_addr 239.1.1.1 \
                                            -multicast_default_mdt_increment 0.0.0.1 \
                                            -multicast_data_mdt_enable 1 \
                                            -multicast_data_mdt_addr 230.1.1.1 \
                                            -multicast_data_mdt_increment 0.0.0.1 \
                                            -multicast_group_count 1 \
                                            -multicast_group_addr_start 225.0.0.1 \
                                            -multicast_group_addr_increment 0.0.0.1 \
                                            -multicast_receiver_have_same_group 1 \
                                            -customer_route_type internal \
                                            -customer_route_count_per_ce 2 \
                                            -customer_route_start 1.0.0.1 \
                                            -customer_route_step 0.0.0.1 \
                                            -customer_route_prefix_length 32 \
                                            -provider_route_count_per_ce 2 \
                                            -provider_route_start 2.0.0.1 \
                                            -provider_route_step 0.0.0.1 \
                                            -provider_route_prefix_length 32 \
                                            -vrf_route_mpls_label_type label_per_site\
                                            -vrf_route_mpls_label_start 16 \
                                            -multicast_traffic_flow_direction customer_to_provider \
                                            -multicast_traffic_all_source_enable 1\
                                            -multicast_traffic_all_receiver_enable 1\
                                            -unicast_traffic_enable 0\
                                            -unicast_traffic_flow_direction bidirectional \
                                            -unicast_traffic_stream_group_method aggregate \
                                            -traffic_frame_size 1280 \
                                            -traffic_load_percent_from_provider_port 1 \
                                            -traffic_load_percent_from_customer_port 1]

set status [keylget cmdStatus status]
if { $status} {
    puts "pass"
    set mvpnHnd [keylget cmdStatus handle]
    set streamList [keylget cmdStatus traffic_handle]
} else {
    puts "config MVPN error."
    puts [keylget cmdStatus log]
    return
}

#config parts are finished

#sleep 5 seconds
after 5000

############################################
# Step6: start MVPN                        #
############################################

set cmdStatus [sth::emulation_mvpn_control -action start -handle $mvpnHnd]
set status [keylget cmdStatus status]
if { $status} {
    puts "pass"
} else {
    puts "add provider port error."
    puts [keylget cmdStatus log]
    return
}

puts "#################### Sleep 60 seconds ########################"
after 60000

############################################
# Step7: Get MVPN Info                     #
############################################

puts "\n#################### get mvpn configuration LDP info ########################"
set cmdStatus [sth::emulation_mvpn_info -mode ldp -handle $mvpnHnd]
puts $cmdStatus   

puts "\n#################### get mvpn configuration RIP info ########################"
set cmdStatus [sth::emulation_mvpn_info -mode rip -handle $mvpnHnd]
puts $cmdStatus                                               

puts "\n#################### get mvpn configuration OSPF info ########################"
set cmdStatus [sth::emulation_mvpn_info -mode ospfv2 -handle $mvpnHnd]
puts $cmdStatus

puts "\n#################### get mvpn configuration BGP info ########################"
set cmdReturn [sth::emulation_mvpn_info -mode bgp -handle $mvpnHnd]
if {![keylget cmdReturn status] } {
    puts "Error BGP info"
    puts "Error from command was " . [keylget cmdReturn log]
	return
} else {
    puts "The command return for BGP info command is $cmdReturn"
}
# Check the status of BGP
if { [string first "router_state ESTABLISHED" $cmdReturn ] != -1} {
    puts "The route state of BGP is ESTABLISHED"
} else {
    puts "The route state of BGP is not ESTABLISHED"
	#return
}

puts "\n#################### get mvpn configuration PIM info ########################"
set cmdReturn [sth::emulation_mvpn_info -mode pim -handle $mvpnHnd]
if {![keylget cmdReturn status]} {
    puts "Error PIM info"
    puts "Error from command was $cmdReturn"
	return
} else {
    puts "The command return for PIM info command is $cmdReturn"
}
# # Check the neighbor status of PIM
set i 0
set j 0              
while { $i >= 0 } {
	 if { [set i [string first "router_state NEIGHBOR" $cmdReturn $i] ]} {
		 if { $i != -1 } {
			  incr j
			  incr i 21       
		 }       
	
	 }
 }                                     
                
puts "The neighbor numbers of PIM is :$j "  

 if { $j == 3 } {
    puts "The route state of PIM is NEIGHBOR"
 } else {
    puts "The route state of PIM is not NEIGHBOR"
	#return
 }  

############################################
# Step8: Start MVPN Traffic                #
############################################

set cmdStatus [sth::traffic_control -port_handle all -action run -duration 30]
set status [keylget cmdStatus status]
if { $status} {
    puts "pass"
} else {
    puts "Start MVPN Traffic error."
    puts [keylget cmdStatus log]
    return
}

puts "#################### Sleep 30 seconds ########################"
after 30000

############################################
# Step9: Stop MVPN Traffic                 #
############################################

set cmdStatus [sth::traffic_control -port_handle all -action stop]
set status [keylget cmdStatus status]
if { $status} {
    puts "pass"
} else {
    puts "Stop MVPN Traffic error."
    puts [keylget cmdStatus log]
    return
}

############################################
# Step10: Get MVPN Traffic Stats           #
############################################

stc::perform SaveasXml -config system1 -filename    "./HLTAPI_mvpn1.xml"

puts "\n#################### get mVPN traffic stats ########################"
set cmdReturn [sth::traffic_stats -mode streams -streams $streamList]
if {![keylget cmdReturn status]} {
    puts "Error query mVPN streams"
    puts "Error query mVPN streams command was $cmdReturn"
	return
} else {
    puts "The return of query mVPN streams is $cmdReturn"
}

# Check point, frame loss should be <= 5%
puts "\n#################### Check the txPkg and rxPkg of the stream ########################"
foreach port $hPortlist {
    if { ![catch {keylget cmdReturn $port} ]} {
        foreach stream $streamList {
            set rxPkt [keylget cmdReturn $port.stream.$stream.rx.total_pkts]
            set txPkt [keylget cmdReturn $port.stream.$stream.tx.total_pkts]
	    if {$txPkt > 0} {
		if { [expr ($txPkt - $rxPkt) * 100.0 /$txPkt] <= 5 && [expr ($txPkt - $rxPkt) * 100.0 /$txPkt] >= 0 } {
		    puts "PASS Stream: $stream has been correctly forwarded by DUT."
		} else {
		    puts "FAILED Stream: $stream has tx $txPkt pkt, while only rx $rxPkt pkts."
				    return
		}
	    } else {
		    puts "FAILED Stream: $stream has tx $txPkt pkt, while only rx $rxPkt pkts."
	    }
        }
        
    }
}

###  Retrieve session statistics after test stops
foreach port $hPortlist {

	set cmdStatus [sth::interface_stats -port_handle $port]
	set status [keylget cmdStatus status]
	if {! $status} {
		puts "Error getting statistics on port $port"
		return
	} else {
		set portStats($port) $cmdStatus
		set rxframes($port) [keylget portStats($port) rx_frames]
		set txframes($port) [keylget portStats($port) tx_frames]
		puts "Port $port Statistics:  Tx Frames - $txframes($port), Rx Frames - $rxframes($port)"
	};

}

stc::perform SaveasXml -config system1 -filename    "./HLTAPI_mvpn2.xml"

############################################
# Step11: Stop MVPN                        #
############################################

set cmdStatus [sth::emulation_mvpn_control -action stop -handle $mvpnHnd]
set status [keylget cmdStatus status]
if { $status} {
    puts "pass"
} else {
    puts "Stop MVPN Traffic error."
    puts [keylget cmdStatus log]
    return
}

stc::perform SaveasXml -config system1 -filename    "./HLTAPI_mvpn3.xml"
############################################
#step12 Delete MVPN                        #
############################################

set cmdStatus [sth::emulation_mvpn_config -mode delete -handle $mvpnHnd]
set status [keylget cmdStatus status]
if { $status} {
    puts "pass"
} else {
    puts "add provider port error."
    puts [keylget cmdStatus log]
    return
}

############################################
#step13 Release resources                  #
############################################

set returnedString [::sth::cleanup_session -port_list $hPortlist]
if {![keylget returnedString status ]} {
puts returnedString
    return "FAILED"
}

############################################
#The End                                   #
############################################

puts "_SAMPLE_SCRIPT_SUCCESS"