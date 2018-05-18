#################################################################################################
# Title   :	  HLTAPI_ScaleRIPv1_Vlan.tcl							#
# Purpose :       To Test Functionality of RIPv1 with Vlan					#
#												#
# Copyright (C) 2007 by Spirent Communciations, Inc.						#
# All Rights Reserved										#
#												#
# By accessing or executing this software, you agree to be bound by the terms of this		#
# agreement.											#
#												#
# Redistribution and use of this software in source and binary forms, with or without		#
# modification, are permitted provided that the following conditions are met:			#
#												#
#	1.	Redistribution of source code must contain the above copyright notice, this list#
#		of conditions, and the following disclaimer.					#
#												#
#	2.	Redistribution in binary form must reproduce the above copyright notice, this 	#
#		list of conditions and the following disclaimer in the documentation and/or	#
#		other materials provided with the distribution.					#
#												#
#	3.	Neither the name Spirent Communications nor the names of its contributors may be#
#		used to endorse or promote products derived from this software without specific	#
#		prior written permission.							#
#												#
# This software is provided by the copyright holders and contributors [as is] and any		#
# express or implied warranties, limited to, the implied warranties of merchantability		#
# and fitness for a particular pripose are disclamed.  In no event shall Spirent 		#
# Communications, Inc. or its contributors be liable for any direct, indirect, incidental,	#
# special, exemplary, or consequential damages (including, but not limited to: procurement	#
# of substitute goods or services; loss of use, data or profits; or business interruption)	#
# however caused and on any theory of liablility, whether in contract, strict liability,	#
# or tort (including negligence or otherwise) arising in any way out of the use of this		#
# software, even if advised of the possibility of such damage.					#
#												#
# Description	:	This script creates RIPv1 routers and routes; Starts the routers; waits #
#                       and then Stops the Routers; Delete the Routes and Routers               #
#                       The intent is to test the Functionalify of RIPv1 with Vlan		#
#												#
# Body          :       -- Load HLTAPI								#
#                       -- Declares the global variables to be used throughout the script	#
#                       -- creates procedures to create the keyed lists used for variable	#
#                              retrieval							#
#                       -- Connects to the chassis, reserves the ports, and sets up the	    	#
#                              handles for future use						#
#                       -- Creates the ports and attributes					#
#                       -- Creates the RIP routers and routes					#
#                       -- Start routers, waits for 60 seconds and checks the DUT		#
#                       -- Stop routers 							#
#			-- Deletes the configuration of RIP 					#
#			-- destroys the configuration, and exits the shell			#
#												#
# Created 	:										#
#             Created: - Abhay Karthik 08/08/07							#
#################################################################################################

# Run sample:
#            c:>tclsh HLTAPI_ScaleRIPv1_Vlan.tcl 10.61.44.2 3/1 3/3
#            c:>tclsh HLTAPI_ScaleRIPv1_Vlan.tcl "10.61.44.2 10.61.44.7" 3/1 3/3

package require SpirentHltApi

set devicelist      [lindex $argv 0]
set port1        [lindex $argv 1]
set port2        [lindex $argv 2]
set i 1
foreach device $devicelist {
    set device$i $device
    incr i
}
set device$i $device
set portlist "$port1 $port2"

###################################
### Name: incrementIpV4Address
### Purpose: To increment a given IPv4 address by the increment value
### Input:  Initial IPv4 addresss, IPv4 increment value
### Output: Incremented IPv4 address
###################################
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
        puts "<error>ERROR: Cannot increment ip past 255.0.0.0"
    }
    return ${o1}.${o2}.${o3}.${o4}
}

###################################
### Name: CreatePortList
### Purpose: To create a keyed list for Port information from specifically defined previously created lists
### Input:  Port list, IP address list, Gateway list, MAC address list, Media type list, Autonegotiation list
###        Port Speed list (used if autoneg is turned off), Port duplex list, Port netmask list
### Output: keyed list of parameters, main key is port id
###################################
proc CreatePortList {finishedList portList ipAddress gateway macAddress mediaType autoNegotiation speed duplex netmask} {

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

###################################
### Name: CreateRipList
### Author: Abhay Karthik
### Purpose: To create a keyed list of RIP information from specifically defined previously created lists
### Input:  portlist ripRouterCountList ripRouterIdIpv4List ripRouterIdStepList ripRouterIpv4AddrList 
###        ripRouterAddrStepList ripRouterPrefixLenList ripRouterIpv4GatewayList ripRouteCountList 
###        ripRouteIpv4NextHopList ripRouteIpv4PrefixStartList ripRoutePrefixStartStepList ripRoutePrefixStartLenList
### Output: keyed list of parameters, main key is port id
###################################
proc CreateRipList {finishedList portlist ripRouterCountList ripRouterIdIpv4List ripRouterIdStepList ripRouterIpv4AddrList ripRouterAddrStepList ripRouterPrefixLenList ripRouterIpv4GatewayList ripRouteCountList ripRouteIpv4NextHopList ripRouteIpv4PrefixStartList ripRoutePrefixStartStepList ripRoutePrefixStartLenList} {

    puts "\nCreate RIP List"
    for {set x 0} {$x < [llength $portlist]} {incr x} {
	set var "\{[lindex $portlist $x] \{\{ripRouterCountList [lindex $ripRouterCountList $x]\} \{ripRouterIdIpv4List [lindex $ripRouterIdIpv4List $x]\} \{ripRouterIdStepList [lindex $ripRouterIdStepList $x]\} \{ripRouterIpv4AddrList [lindex $ripRouterIpv4AddrList $x]\} \{ripRouterAddrStepList [lindex $ripRouterAddrStepList $x]\} \{ripRouterPrefixLenList [lindex $ripRouterPrefixLenList $x]\} \{ripRouterIpv4GatewayList [lindex $ripRouterIpv4GatewayList $x]\} \{ripRouteCountList [lindex $ripRouteCountList $x]\} \{ripRouteIpv4NextHopList [lindex $ripRouteIpv4NextHopList $x]\} \{ripRouteIpv4PrefixStartList [lindex $ripRouteIpv4PrefixStartList $x]\} \{ripRoutePrefixStartStepList [lindex $ripRoutePrefixStartStepList $x]\} \{ripRoutePrefixStartLenList [lindex $ripRoutePrefixStartLenList $x]\}\}\}"
	set finishedList [concat $finishedList $var]
    }  ;# end for loop
    puts "\nRIP List is $finishedList"
    return $finishedList
}  ;# end procedure

###################################
###   Start RIPv1 Test
###   
###################################
puts "**************  Start RIPv1 Test *********************"

### Define global variables
set portIPgatewayList {}
set connectPortList {}
set hPortlist {}
set ripList {}

set timeout 15
set runtime 30
set ipAddressList {13.9.0.3 13.10.0.3}
set gatewayList {13.9.0.1 13.10.0.1}
set macAddressList {00.00.00.01.00.01 00.00.02.00.00.01}
set portMediaType {copper copper}
set portAutoNeg {1 1}
set portSpeed {ether100 ether100}
set portDuplex {full full}
set portNetmask {255.255.0.0 255.255.0.0}

# Rip global variables
set ripRouterCountList {100 100}
set ripRouterIdIpv4List {13.9.0.3 13.10.0.3}
set ripRouterIdStepList {1 1}
set ripRouterIpv4AddrList {13.9.0.3 13.10.0.3}
set ripRouterAddrStepList {0.0.0.1 0.0.0.1}
set ripRouterPrefixLenList {16 16}
set ripRouterIpv4GatewayList {13.9.0.1 13.10.0.1}
set ripUpdateIntervalList {15 15}

set ripRouteCountList {2 2}
set ripRouteIp4NextHopList {0.0.0.0 0.0.0.0}
set ripRouteIpv4PrefixStartList {25.0.0.3 50.0.0.3}
set ripRoutePrefixStartStepList {1 1}
set ripRoutePrefixStartLenList {16 16}

# Local Variable
set ripRouterVLANId {1181 1191}
set ripRouterVLANMode "fixed"
set ripRouterVLANStep 1
set ripRouterVLANPriority {6 6}

set ripTestList {0}
set ripTestList [lindex $ripTestList 0]
set ripUpdateInterval [lindex $ripUpdateIntervalList 0]
puts "# ripTestList: ripTestList ripUpdateInterval: $ripUpdateInterval"

# Rip local variables
set ripRouterSendType "broadcast"
set ripRouterType "ripv1"
set ripRouterTypeLarge "version-1"

### Create the keyed list of information for the ports
set portIPgatewayList [CreatePortList $portIPgatewayList $portlist $ipAddressList $gatewayList \
			$macAddressList $portMediaType $portAutoNeg $portSpeed $portDuplex $portNetmask]
puts "**************  Created the keyed list for the port parameters **************"

set ret [sth::test_control -action enable]
set controlStatus [keylget ret status]
puts "The Control Status is: $controlStatus is: enable"

###################################
###   Connect and Configure the Ports
###   
###################################
set chassConnect [sth::connect -device $devicelist -timeout $timeout -port_list $portlist]

if {[keylget chassConnect status]==1} {
	puts "Successfully connected to chassis $devicelist"
} else {
	puts "Unable to connect to chassis $devicelist: [keylget chassConnect log]"
	return
} 

#Configuring port interface
set portIndex 0
foreach port $portlist {
	set device [lindex $devicelist $portIndex] 
	puts "**************  Retrieve the port handle  **************"
  	set hPort($device.$port) [keylget chassConnect port_handle.$device.$port]
	set hPortlist [concat $hPortlist $hPort($device.$port)]
	
    puts "**************  Configure the Ports *********************"
    set ret [ ::sth::interface_config 	-port_handle       $hPort($device.$port) \
                                   			-intf_ip_addr      [keylget portIPgatewayList $port.ipAddr] \
	                               			-gateway           [keylget portIPgatewayList $port.gateWay] \
	                             			-netmask           [keylget portIPgatewayList $port.netmask] \
	                               			-intf_mode         ethernet \
	                               			-phy_mode          [keylget portIPgatewayList $port.mediaType] \
	                               			-speed             [keylget portIPgatewayList $port.speed] \
	                              			-autonegotiation   [keylget portIPgatewayList $port.autoNeg]\
	                             			-mode              config \
	                             			-duplex            [keylget portIPgatewayList $port.duplex] \
	                               			-src_mac_addr      [keylget portIPgatewayList $port.macAddr] \
	                              			-arp_send_req	   1]
   set intStatus [keylget ret status]
   ###  Apply the configuration to the cards/STC framework
   set ret [sth::test_control -action sync]
   set controlStatus [keylget ret status]   
   if {! $intStatus} {
    	puts "<error>Error configuring port $port with handle $hPort($device.$port)"
    	puts "<error>Error message was $ret"
	exit
   } else {
    	puts "Ports Configured"
   }  ;# end if-else statement
   
   incr portIndex
}   ;# end foreach loop

###################################
###   Start Test
###   testIncCount - Make the test interactive - To run the test many times with different Router and Route Counts
###################################
set tempRouterList {}
set tempRouteList {}
foreach testIncCount $ripTestList {

    puts "\n### Interactive"
    puts "# testIncCount: $testIncCount Router Count: $ripRouterCountList and Route Count: $ripRouteCountList"
    set numTempRouter [llength $ripRouterCountList]
    for {set j 0} {$j < $numTempRouter} {incr j} {
	set varRouterTemp [lindex $ripRouterCountList $j]
	set varRouteTemp  [lindex $ripRouteCountList $j]
        set tempRouterList [linsert $tempRouterList $j [expr $varRouterTemp + $testIncCount]]
	puts "# tempRouterList $tempRouterList"
        set tempRouteList  [linsert $tempRouteList $j  [expr $varRouteTemp + $testIncCount]]
	puts "# tempRouteList $tempRouteList"
    } ;# End of for Loop
    set ripRouterCountList $tempRouterList
    set ripRouteCountList $tempRouteList
    puts "# testIncCount: $testIncCount Router Count: $ripRouterCountList and Route Count: $ripRouteCountList"
    set tempRouterList {}
    set tempRouteList {}
    puts "### \n"
    
    #  ********************* Individual Test Starts Here ******************************************
    puts "********************* Individual Test Starts Here ******************************************"

    #  Create the keyed list of information for the RIP blocks
    puts "**************  Create the keyed list for the RIP blocks  **************"
    set ripList [CreateRipList $ripList $portlist $ripRouterCountList \
                      	$ripRouterIdIpv4List $ripRouterIdStepList \
		      	$ripRouterIpv4AddrList $ripRouterAddrStepList $ripRouterPrefixLenList $ripRouterIpv4GatewayList \
		      	$ripRouteCountList \
			$ripRouteIp4NextHopList \
			$ripRouteIpv4PrefixStartList $ripRoutePrefixStartStepList $ripRoutePrefixStartLenList]
    puts "The RIPList is: $ripList"

    ###################################
    ###   Create RIP Router and Configure the Routes
    ### 
    ###################################
    puts "**************  Create Router  **************"
    set vlanPortIndex 0	
	set portIndex 0
	foreach port $portlist {
		set device [lindex $devicelist $portIndex] 
		incr portIndex
        puts "**************  Create RIP Router  **************"
        set ret [sth::emulation_rip_config 	-mode 		create \
                                     		-port_handle 	$hPort($device.$port) \
                                    		-session_type	$ripRouterType \
                                     		-send_type 	$ripRouterSendType \
                                     		-count	 	[keylget ripList $port.ripRouterCountList] \
                                     		-router_id 	[keylget ripList $port.ripRouterIdIpv4List] \
                                     		-intf_ip_addr 	[keylget ripList $port.ripRouterIpv4AddrList] \
                                     		-intf_ip_addr_step [keylget ripList $port.ripRouterAddrStepList] \
                                     		-intf_prefix_length [keylget ripList $port.ripRouterPrefixLenList] \
                                     		-neighbor_intf_ip_addr [keylget ripList $port.ripRouterIpv4GatewayList] \
					        -gateway_ip_addr [keylget ripList $port.ripRouterIpv4GatewayList] \
						-update_interval $ripUpdateInterval \
                                     		-vlan_id 	[lindex $ripRouterVLANId $vlanPortIndex] \
                                     		-vlan_id_mode 	$ripRouterVLANMode \
                                     		-vlan_user_priority 	[lindex $ripRouterVLANPriority $vlanPortIndex]]

        set ripStatus [keylget ret status]   
	#  Create the handle to the RIP Routers in case of configuration change
	if {! $ripStatus} {
	    puts "<error>Error configuring RIP Router on $port"
	    puts "<error>Error from command was $ret"
            exit
	} else {
	    set hRipRouter($port) [keylget ret handle]
	    puts "Handle for RIP Router on $port is $hRipRouter($port)"
	}   ;# end if-else statement

       
        ###  Apply the configuration to the cards/STC framework
        set ret [sth::test_control -action sync]
        set controlStatus [keylget ret status]
	puts "**************  Create Routes for the Router **************"
	set hRipRouteList($port) ""
        set hRipRouteIndex 0	
        set hi 0	
        set ipx [keylget ripList $port.ripRouteIpv4PrefixStartList]
        puts "ipx is: $ipx"
        foreach ripRouterVar $hRipRouter($port) {
	    set ip [incrementIpV4Address $ipx 0.0.0.$hi]
	    puts " router var is $ripRouterVar ip is: $ip"
	    set ret [sth::emulation_rip_route_config 	-mode 	create \
						-handle 	$ripRouterVar \
                                     		-num_prefixes 	[keylget ripList $port.ripRouteCountList] \
                                     		-prefix_start	$ip \
                                     		-prefix_step 	[keylget ripList $port.ripRoutePrefixStartStepList] \
                                     		-prefix_length 	[keylget ripList $port.ripRoutePrefixStartLenList]]
            set ripStatus [keylget ret status]
	    #  Create the handle to the RIP Routes in case of configuration change
	    if {! $ripStatus} {
		puts "<error>Error configuring RIP Route on $port"
		puts "<error>Error from command was $ret"
         	exit
	    } else {
		set hRipRoute($port) [keylget ret route_handle]
		set hRipRouteList($port) [linsert $hRipRouteList($port) $hRipRouteIndex $hRipRoute($port)]
		puts "Handle for RIP Route on $port is $hRipRoute($port)"
	    }   ;# end if-else statement
	    incr hi 
	    incr hRipRouteIndex 
	} ;# end foreach
	puts "The Route List is: $hRipRouteList($port)"

        ###  Apply the configuration to the cards/STC framework
        set ret [sth::test_control -action sync]
        set controlStatus [keylget ret status]
    	incr hRipRouteIndex 
    }   ;# end foreach loop 
    puts "**************  Router Configuration Complete  **************"

    ###################################
    ### RIP Control - Start 
    ###  
    ###################################
    puts "************** Start RIP  ***********************"
    foreach port $portlist {
	set ret [sth::emulation_rip_control 	-mode	start \
	                               		-handle 	$hRipRouter($port)]
	set controlStatus [keylget ret status]		
	#  Report to Thot
        if {! $controlStatus} {
	    puts "<error>Error starting RIP  on $port"
	    puts "<error>Error from command was $ret"
            exit
	} else {
	    puts "RIP on port $port was started successfully"
	}   ;# end if-else statement

        ###  Apply the configuration to the cards/STC framework
        set ret [sth::test_control -action sync]
        set controlStatus [keylget ret status]
    }   ;# end foreach loop
    puts "**************   Finished starting RIP  ********************"

    ###################################
    ### Code to Check DUT and Traffic 
    ###  
    ###################################
    ::stc::sleep 60   
    puts "************** Code here to Check DUT  ***********************"

    ###################################
    ### RIP Control - Stop 
    ###  
    ###################################
    puts "************** Stop RIP  ***********************"
    foreach port $portlist {
	set ret [sth::emulation_rip_control 	-mode	stop \
	                               		-handle 	$hRipRouter($port)]
	set controlStatus [keylget ret status]				
	#  Report to Thot
        if {! $controlStatus} {
	    puts "<error>Error Stopping RIP group on $port"
	    puts "<error>Error from command was $ret"
            exit
	} else {
	    puts "RIP on port $port was stopped successfully"
	}   ;# end if-else statement

        ###  Apply the configuration to the cards/STC framework
        set ret [sth::test_control -action sync]
        set controlStatus [keylget ret status]
    }   ;# end foreach loop
    puts "**************   Finished Stopping RIP  ********************"

    ###################################
    ###  Wait for RIP Routers to go down - Additional Sleep here
    ###  
    ###################################
    ::stc::sleep 10   
    puts "************* Finished sleeping  ***********************"

    ###################################
    ###  delete RIP Routes and Routers
    ###  
    ###################################
    puts "************** Delete RIP routes   ***********************"
    foreach port $portlist {
        set ret [sth::emulation_rip_route_config 	-mode 	delete \
                                     		-route_handle 	$hRipRouteList($port)]
        set ripStatus [keylget ret status]
	#  Report to Thot
	if {! $ripStatus} {
	    puts "<error>Error Delete RIP routes on $port"
	    puts "<error>Error from command was $ret"
            exit
	} else {
	    puts "Deleted Routes on $port"
	}   ;# end if-else statement
     
        ###  Apply the configuration to the cards/STC framework
        set ret [sth::test_control -action sync]
        set controlStatus [keylget ret status]
    } ;# end for each port

    ###  delete RIP Routers
    puts "************** Delete RIP routers   ***********************"
    foreach port $portlist {
        set ret [ sth::emulation_rip_config 	-mode 	delete \
                                     		-handle 	 $hRipRouter($port)]
        set ripStatus [keylget ret status]
	#  Report to Thot
	if {! $ripStatus} {
	    puts "<error>Error Deleting RIP Routers port on $port"
	    puts "<error>Error from command was $ret"
            exit
	} else {
	    puts "Deleted Routers" 	
	}   ;# end if-else statement

        ###  Apply the configuration to the cards/STC framework
        set ret [ sth::test_control -action sync]
        set controlStatus [keylget ret status]
    } ;# end for each port
    puts "************** Deleteted RIP routers   ***********************"
} ;# end for each test
puts "************** Test Router Config Complete   *********************** \n"

###################################
###  Delete configuration for the ports
###  
###################################
puts "**************  Deleting the ports  **************"
set ret [::sth::cleanup_session -port_list $hPortlist]
set intStatus [keylget ret status]
if {! $intStatus} {
    puts "<error>Error message for deleting port was $ret"
    exit
}   ;# end if statement
puts "**************  Finished deleting the ports **************"


###  Apply the configuration to the cards/STC framework
set ret [sth::test_control -action sync]
set controlStatus [keylget ret status]
puts "************** Test Complete **************"

puts "_SAMPLE_SCRIPT_SUCCESS"
