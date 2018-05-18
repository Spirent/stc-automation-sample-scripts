#################################################################################################
# Title 		:		HLTAPI_IGMPHighScale.tcl									        	#
# Purpose       :       Verify the capture filter for IGMP works for HLTAPI				        #
#																								#
# Copyright (C) 2007 by Spirent Communciations, Inc.											#
# All Rights Reserved																			#
#																								#
# By accessing or executing this software, you agree to be bound by the terms of this			#
# agreement.																					#
#																								#
# Redistribution and use of this software in source and binary forms, with or without			#
# modification, are permitted provided that the following conditions are met:					#
#																								#
#	1.	Redistribution of source code must contain the above copyright notice, this list		#
#		of conditions, and the following disclaimer.											#
#																								#
#	2.	Redistribution in binary form must reproduce the above copyright notice, this list		#
#		of conditions and the following disclaimer in the documentation and/or other 			#
#		materials provided with the distribution.												#
#																								#
#	3.	Neither the name Spirent Communications nor the names of its contributors may be		#
#		used to endorse or promote products derived from this software without specific			#
#		prior written permission.																#
#																								#
# This software is provided by the copyright holders and contributors [as is] and any			#
# express or implied warranties, limited to, the implied warranties of merchantability			#
# and fitness for a particular pripose are disclamed.  In no event shall Spirent 				#
# Communications, Inc. or its contributors be liable for any direct, indirect, incidental,		#
# special, exemplary, or consequential damages (including, but not limited to: procurement		#
# of substitute goods or services; loss of use, data or profits; or business interruption)		#
# however caused and on any theory of liablility, whether in contract, strict liability,		#
# or tort (including negligence or otherwise) arising in any way out of the use of this			#
# software, even if advised of the possibility of such damage.									#
#																								#
# Summary		:		This script creates a Capture filter test to verify that the HLTAPI     #
#                           Capture filter command works and filters for only IGMP              #
#                           frames that match a specific pattern.  All of the ports that are    #
#                           used in the script are connected back to back.  The script only     #
#                           uses the first two ports that are passed to it.                     #
#																								#
# Attributes Tested: 	sth::interface_config 													#
#							port_handle, intf_ip_addr, gateway, netmask, intf_mode, 			#
#							phy_mode, speed, autonegotiation, mode, duplex, src_mac_addr		#
#						sth::packet_control												        #
#                       sth::packet_config_filter                                               #
#																								#
# Config		:		Any number of Ethernet ports connected to a DUT                         #
#																								#
# Note          :																				#
#																								#
# Body          :       -- loads the needed libraries											#
#                       -- declares the global variables to be used throughout the script		#
#                       -- connects to the chassis, reserves the ports, and sets up the			#
#                              handles for future use											#
#                       -- creates the ports and attributes										#
#                       -- runs the Ping command with preset values and verifies the returned   #
#                               information                                                     #
#                       -- runs the Ping command again, with a change to the number of pings    #
#                               sent, and verifies (using capture) that the correct number      #
#                               was sent/received                                               #
#						-- runs the Ping command again, with a change to the interval, and      #
#                               verifies (using capture) that the interval set was the one that #
#                               was actually sent                                               #
#                       -- runs the Ping command again, with a change to the host IP address,   #
#                               and verifies(using capture) that the host value that was set    #
#                               is the actual one that was sent                                 #
#                       -- runs the Ping command multiple times with the number of times        #
#                               defined by the input from the THoT line                         #
#						-- destroys the configuration, and exits the shell						#
#																								#
# Variables used :	device, portlist, timeout, runtime, ipAddressList, gatewayList, 			#
#					macAddressList, portMediaType, portAutoNeg, portSpeed, portDuplex, 			#
#					portNetmask, portIPgatewayList, HLTLogFile, media, speed, mediaList,        #
#                   speedList, passFail, initialCount, numberIterations, scriptLog,             #
#                   Result, helperFile, logValue, hPortlist                                     #
#																								#
# External procedures used : OpenLogFile, HLTCRS, CreatePortList                                #
#																								#
# Pre-requisites : 	1) Configuration (described above)											#
#					2) Minimum HLTAPI 2.0														#
#																								#
# Input         :  None																			#
# Output        :  script log, 																	#
#																								#
# Software Req	:	HLTAPI package	 															#
# Est. Time Req	:																				#
# Pass/Fail Criteria:  Script fails if: 1) Any command returns an error							#
#																								#
# Revison History  :																			#
#             Created: - Quinten Pierce 7/20/07													#
#																								#
# Test Type: Sanity, Acceptance, Regression														#
#
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
# possibility of such damage.																								#
#################################################################################################

# Run sample:
#            c:>tclsh HLTAPI_IGMP_HighScale.tcl 10.61.44.2 3/1 3/3
#            c:>tclsh HLTAPI_IGMP_HighScale.tcl "10.61.44.2 10.61.44.7" 3/1 3/3

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
set portlist "$port1 $port2"

proc incrementIpV4Address {ipToIncrement {ipIncrementValue 0.0.0.1}} {
    set ipList   [split $ipToIncrement    .]
    set incrVals [split $ipIncrementValue .]
    set o4 [expr [lindex $ipList 3] + [lindex $incrVals 3]]
    set o3 [expr [lindex $ipList 2] + [lindex $incrVals 2]]
    set o2 [expr [lindex $ipList 1] + [lindex $incrVals 1]]
    set o1 [expr [lindex $ipList 0] + [lindex $incrVals 0]]

    if {$o4 > 255} {incr o3; set o4 [expr $o4 - 256]}
    if {$o3 > 255} {incr o2; set o3 [expr $o3 - 256]}
    if {$o2 > 255} {incr o1; set o2 [expr $o2 - 256]}
    if {$o1 > 255} {
        puts "ERROR: Cannot increment ip past 255.0.0.0"
    }

    return ${o1}.${o2}.${o3}.${o4}
}

proc CreatePortList {finishedList portList ipAddress gateway macAddress mediaType autoNegotiation speed duplex netmask} {
	set finishedList ""
    for {set x 0} {$x < [llength $portList]} {incr x} {
        set var "\{[lindex $portList $x] \{\{ipAddr [lindex $ipAddress $x]\} \
        \{gateWay [lindex $gateway $x]\} \{macAddr [lindex $macAddress $x]\} \
        \{mediaType [lindex $mediaType $x]\} \{autoNeg [lindex $autoNegotiation $x]\} \
        \{speed [lindex $speed $x]\} \{duplex [lindex $duplex $x]\} \
        \{netmask [lindex $netmask $x]\}\}\}"
        set finishedList [concat $finishedList $var]
    }  ;# end for loop
    return $finishedList
}    ;# end procedure

set HLTLogFile "HLT_IGMP_HighScale.log"
set media "fiber"
set speed "ether1000"
set passFail PASS
set maxPortRate 10
set runtime 1
set maxGroups 1
set dutConnected 0
set vlanEnabled 1
set igmpGroupAddressStartList 225.1.0.1
set scriptLog "HLTAPI_IGMP_HighScale.log"
set Result 0
set logValue 7
set capture 0
set hPortlist ""
set helperFile "HLTAPI_IGMP_HighScale_helper.tcl"
set username "spirent"
set password "spirent"
set enablePassword "spirent"
set DUTIP 10.99.0.191
set protocolEnable 1

#Load the information from the helper file

set controlStatus [sth::test_control -action enable]

set timeHnd [open "IGMPHighScaleTestTimeRun.txt" "w"]
puts $timeHnd "Start IGMP HighScale Test...\n"

set totalTime [time {
	set connectReserveTime [time {

		#Connect to chassis & reserve port
		puts "Connecting to $device_list, $portlist"
		set intStatus [sth::connect -device $device_list \
									-port_list $portlist]
		puts $intStatus
		set hPort($device1.$port1) [keylget intStatus port_handle.$device1.$port1]
		set hPort($device2.$port2) [keylget intStatus port_handle.$device2.$port2]
		set hPortlist [concat $hPortlist $hPort($device1.$port1)]
		set hPortlist [concat $hPortlist $hPort($device2.$port2)]							
	}]
	puts "\tConnect and Reserve Time: [expr [lindex $connectReserveTime 0] / 1000000] Secs"
	
	#  Create the keyed list of information for the ports
	
	set portTime [time {
		foreach port $portlist {
			set intStatus [::sth::interface_config 	-port_handle        $hPort($device.$port) \
															-intf_ip_addr       1.1.1.10 \
															-gateway            1.1.1.1 \
															-netmask            255.255.0.0 \
															-intf_mode          ethernet \
															-phy_mode           $media \
															-speed              $speed \
															-autonegotiation    1 \
															-mode               config \
															-arp_send_req       0]
			
		}
		########################
		####  Apply the configuration to the cards/STC framework
		########################
		set controlStatus [sth::test_control -action sync]
	}]
	puts "\tPort Configuration Time: [expr [lindex $portTime 0] / 1000000] Secs"
	
	set groupAddrStart [lindex $igmpGroupAddressStartList 0]
	set portIndex 0
	set groupConfigTime [time {
		foreach port $portlist {
			for {set i 0} {$i < $maxGroups} {incr i} {
				##################################
				######  Set up the multicast group
				##################################
				set groupStatus [sth::emulation_multicast_group_config \
																-ip_addr_start $groupAddrStart \
																-mode "create" \
																-num_groups 1]


				set groupAddrStart [incrementIpV4Address $groupAddrStart]
				set mcGroupHandle($i) [keylget groupStatus handle]
			}
			
			incr portIndex
		}
	}]
	puts "\tGroup Configuration Time: [expr [lindex $groupConfigTime 0] / 1000000] Secs"
	
	set portIndex 0
	set sessionConfigTime [time {
		foreach port $portlist {
			if {$vlanEnabled} {
					##################################
					######  Set up the IGMP session
					##################################
					set sessionStatus [sth::emulation_igmp_config \
																	-mode "create" \
																	-port_handle $hPort($device.$port) \
																	-igmp_version v3 \
																	-robustness 10 \
																	-count 1 \
																	-intf_ip_addr 1.1.1.10 \
																	-intf_ip_addr_step "0.0.0.1" \
																	-neighbor_intf_ip_addr 2.1.1.10 \
																	-neighbor_intf_ip_addr_step "0.0.0.0" \
																	-vlan_id 111]

					set igmpHostHandle [keylget sessionStatus handle]
			} else {
					##################################
					######  Set up the IGMP session
					##################################
					set sessionStatus [sth::emulation_igmp_config \
																	-mode "create" \
																	-port_handle $hPort($device.$port) \
																	-igmp_version v3 \
																	-robustness 10 \
																	-count 1 \
																	-intf_ip_addr 2.1.1.10 \
																	-intf_ip_addr_step "0.0.0.1" \
																	-neighbor_intf_ip_addr 1.1.1.10 \
																	-neighbor_intf_ip_addr_step "0.0.0.0"]

					set igmpHostHandle [keylget sessionStatus handle]
			}
			
			incr portIndex
		}
	}]
	puts "\tSession Configuration Time: [expr [lindex $sessionConfigTime 0] / 1000000] Secs"
	
	set portIndex 0
	set hostAttachTime [time {
		foreach port $portlist {
			if {$protocolEnable == 1} {
				##################################
				######  Attach the group to the host
				##################################
				for {set i 0} {$i < $maxGroups} {incr i} {

					set membershipStatus [sth::emulation_igmp_group_config \
																	-mode "create" \
																	-group_pool_handle $mcGroupHandle($i) \
																	-session_handle $igmpHostHandle]

					
				}
			}
			incr portIndex
		}
	}]
	puts "\tHost Attach Time: [expr [lindex $hostAttachTime 0] / 1000000] Secs"
	
	#config parts are finished
	
	########################
	####  Apply the configuration to the cards/STC framework
	########################
	set controlStatus [sth::test_control -action sync]	
	
	set portIndex 0
	set igmpJoinTime [time {
		foreach port $portlist {
			if {$protocolEnable == 1} {
				#######################
				###  Start the IGMP join
				#######################
				set igmpStatus [sth::emulation_igmp_control \
																	-mode "join" \
																	-handle $igmpHostHandle]
				
			}
			incr portIndex
		}
		########################
		####  Apply the configuration to the cards/STC framework
		########################
		set controlStatus [sth::test_control -action sync]
	}]
	
	puts "\tIGMP Join Time: [expr [lindex $igmpJoinTime 0] / 1000000] Secs"
	after 2000
	set portIndex 0
	set igmpLeaveTime [time {
		foreach port $portlist {
			if {$protocolEnable == 1} {
				#######################
				###  Leave the IGMP group
				#######################
				set igmpStatus [sth::emulation_igmp_control \
																		-mode "leave" \
																		-handle $igmpHostHandle]
				
			}
			incr portIndex
		}
		########################
		####  Apply the configuration to the cards/STC framework
		########################
		set controlStatus [sth::test_control -action sync]
	}]
	puts "\tIGMP Leave Time: [expr [lindex $igmpLeaveTime 0] / 1000000] Secs"

}]
puts "\tTotal Script Time: [expr [lindex $totalTime 0] / 1000000] Secs"

#Write all time measurement to data file
puts $::timeHnd "Connect and Reserve time is  : [expr [lindex $connectReserveTime 0] / 1000000] Secs"
puts $::timeHnd "Port Configuration time is   : [expr [lindex $portTime 0] /1000000] Secs"
puts $::timeHnd "Create MC Groups time is     : [expr [lindex $groupConfigTime 0] / 1000000] Secs"
puts $::timeHnd "Create IGMP Hosts time is    : [expr [lindex $sessionConfigTime 0] / 1000000] Secs"
puts $::timeHnd "Attaching Host to groups	  : [expr [lindex $hostAttachTime 0] / 1000000] Secs"
puts $::timeHnd "IGMP join time is            : [expr [lindex $igmpJoinTime 0] / 1000000] Secs"
puts $::timeHnd "IGMP leave time is           : [expr [lindex $igmpLeaveTime 0] / 1000000] Secs"
puts $::timeHnd "Total test time is           : [expr [lindex $totalTime 0] / 1000000] Secs"

close $::timeHnd

sth::cleanup_session -port_handle $hPortlist

puts "_SAMPLE_SCRIPT_SUCCESS"