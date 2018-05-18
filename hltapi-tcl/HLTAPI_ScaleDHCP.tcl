#################################################################################################
# Title 	:	HLTAPI_ScaleDHCP.tcl			     				#
# Purpose       :       To Test the functionality of DHCPv4					#
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
# Description	:	This script creates DHCP sessions; Bind the sessions; waits		#
#                       and then release the session; Delete the sessions 		        #
#                       The intent is to test the functionalify of DHCPv4			#
#												#
# Body          :       -- Load HLTAPI								#
#                       -- Declares the global variables to be used throughout the script	#
#                       -- creates procedures to create the keyed lists used for variable	#
#                              retrieval							#
#                       -- Connects to the chassis, reserves the ports, and sets up the	    	#
#                              handles for future use						#
#                       -- Creates the ports and attributes					#
#                       -- Creates the DHCP sessions						#
#                       -- Bind the sessions, waits for 60 seconds and checks the DUT		#
#                       -- Release the sessions							#
#			-- Deletes the configuration of DHCP	 				#
#			-- Destroys the configuration, and exits the shell			#
#												#
# Created 	:										#
#             Created: - Abhay Karthik 08/08/07							#
#################################################################################################

# Run sample:
#            c:>tclsh HLTAPI_ScaleDHCP.tcl 10.61.44.2 3/1

package require SpirentHltApi

set device     [lindex $argv 0]
set portlist   [lindex $argv 1]

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
### Name: CreateDHCPList
### Purpose: To create a keyed list of DHCP information from specifically defined previously created lists
### Input:  Port list, Enable DHCP on the port, DHCP encapsulation list, Initial MAC address list,
###    Request rate (if present), Release rate (if present), DHCP inner VLAN id (if present),
###    DHCP QinQ outer VLAN id (if present)
### Output: keyed list of parameters, main key is port id
###################################
proc CreateDHCPList {finishedList portList dhcpEnable dhcpEncap macAddr {requestRate foo} {releaseRate foo} \
             {vlanId foo} {qinqOuter foo}} {

    if {$requestRate == "foo"} {
        set requestRate {}
        for {set x 0} {$x < [llength $portList]} {incr x} {
            set requestRate [concat $requestRate 50]
        }   ;# end for loop
    }   ;#  end if statement

    if {$releaseRate == "foo"} {
        set releaseRate {}
        for {set x 0} {$x < [llength $portList]} {incr x} {
            set releaseRate [concat $releaseRate 200]
        }   ;# end for loop
    }   ;#  end if statement

    if {$vlanId == "foo"} {
        set vlanId {}
        for {set x 0} {$x < [llength $portList]} {incr x} {
            set vlanId [concat $vlanId 1]
        }   ;# end for loop
    }   ;#  end if statement

    if {$qinqOuter == "foo"} {
        set qinqOuter {}
        for {set x 0} {$x < [llength $portList]} {incr x} {
            set qinqOuter [concat $qinqOuter 1]
        }   ;# end for loop
    }   ;#  end if statement

    for {set x 0} {$x < [llength $portList]} {incr x} {
        set var "\{[lindex $portList $x] \{\{dhcpEnable [lindex $dhcpEnable $x]\} \
        \{dhcpEncap [lindex $dhcpEncap $x]\} \{macAddr [lindex $macAddr $x]\} \
        \{requestRate [lindex $requestRate $x]\} \{releaseRate [lindex $releaseRate $x]\} \
        \{vlanId [lindex $vlanId $x]\} \{qinqOuter [lindex $qinqOuter $x]\}\}\}"
        set finishedList [concat $finishedList $var]
    }  ;# end for loop
    return $finishedList
}  ;# end procedure

###################################
###   Start DHCP Test
###   
###################################
puts "**************  Start DHCP Test *********************"

set portIPgatewayList {}
set connectPortList {}
set hPortlist {}
set dhcpList {}

set timeout 15
set runtime 30
set ipAddressList {60.25.0.10 60.26.0.10 60.27.0.10 60.28.0.10}
set gatewayList {60.25.0.1 60.26.0.1 60.27.0.1 60.28.0.1}
set macAddressList {00.00.00.01.00.01 00.00.02.00.00.01 00.00.03.00.00.01 00.00.04.00.00.01}
set portMediaType {copper copper copper copper}
set portAutoNeg {1 1 1 1}
set portSpeed {ether100 ether100 ether100 ether100}
set portDuplex {full full full full}
set portNetmask {255.255.0.0 255.255.0.0 255.255.0.0 255.255.0.0}

set dhcpEnable {1 1 1 1}
set dhcpEncapList {ethernet_ii ethernet_ii ethernet_ii ethernet_ii}
set macAddrStartList {00.10.94.01.00.01 00.10.94.02.00.01 00.10.94.03.00.01 00.10.94.04.00.01}
set requestRateList {50 50 50 50}
set releaseRateList {300 300 300 300}
set vlanIDList {201 211 221 231}
### numSessions can be a list to make the script interactive
set numSessions 25
### Highscale Session count
set numSessionsMaxClients 50
set numVlans 5
set vlanStep 1

###################################
### Create port list
###
###################################
set portIPgatewayList [CreatePortList $portIPgatewayList $portlist $ipAddressList $gatewayList $macAddressList $portMediaType $portAutoNeg $portSpeed $portDuplex $portNetmask]
puts "**************  Created the keyed list for the port parameters **************"

set ret [ sth::test_control -action enable]
set controlStatus [keylget ret status]
puts "The Control Status is: $controlStatus is: enable"

###################################
### Connect to the ports and configure
###
###################################
foreach port $portlist {
    set ret [::sth::connect -device $device -timeout $timeout -port_list $port]
    set chassConnect [keylget ret status]
    puts "**************  Connected to the chassis *********************"
    if {$chassConnect} {
	set hPort($device.$port) [keylget ret port_handle.$device.$port]
	set hPortlist [concat $hPortlist $hPort($device.$port)]
	puts "**************  Retrieved the port handle  **************"
    } else {
	puts "<error>Error retrieving the port handles, error message was $ret"
	exit
    }  ;# end if-else

    set ret [::sth::interface_config 	-port_handle       $hPort($device.$port) \
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
}   ;# end foreach loop
puts "**************  Port Configuration Complete  **************"

###################################
###  This starts the section to create the DHCP sessions, start them and finish the test
###  The foreach loop allows the script to iterate through multiple session values
###  without rewriting or changing the script
###################################
puts "numSessionsMaxClients $numSessionsMaxClients and numSessions $numSessions"
foreach sessionNumber $numSessionsMaxClients {

    ###################################
    ### Create the keyed list of information for the DHCP blocks
    ###  
    ###################################
    set dhcpList [CreateDHCPList $dhcpList $portlist $dhcpEnable $dhcpEncapList $macAddrStartList \
		$requestRateList $releaseRateList]
    puts "**************  Created the keyed list for the DHCP blocks  **************"

    ###################################
    ### Config DHCP
    ###  
    ###################################
    foreach port $portlist {
	if {[keylget dhcpList $port.dhcpEnable] == 1} {
	    set ret [ sth::emulation_dhcp_config 	-mode 			create \
                                      			-port_handle 	$hPort($device.$port) \
	                               			-request_rate 	[keylget dhcpList $port.requestRate] \
							-release_rate	[keylget dhcpList $port.releaseRate] \
							-retry_count	4]
            set dhcpStatus [keylget ret status]
	    #  Create the handle to the DHCP port in case of configuration change
	    if {! $dhcpStatus} {
		puts "<error>Error configuring DHCP port on $port"
		puts "<error>Error from command was $ret"
         	exit
	    } else {
		set hDhcpPort($port) [keylget ret handles]
		puts "Configured DHCP"
	    }   ;# end if-else statement

	    ###  Apply the configuration to the cards/STC framework
   	    set ret [sth::test_control -action sync]
            set controlStatus [keylget ret status]
	    set ret [ sth::emulation_dhcp_group_config 	-mode 	create \
				-handle 		$hDhcpPort($port) \
				-encap			[keylget dhcpList $port.dhcpEncap] \
				-num_sessions		$sessionNumber \
				-mac_addr		[keylget dhcpList $port.macAddr]]

            set dhcpStatus [keylget ret status]
	    #  Create the handle to the DHCP group in case of configuration change
	    if {! $dhcpStatus} {
		puts "<error>Error configuring DHCP group on $port"
		puts "<error>Error from command was $ret"
         	exit
	    } else {
		set hDhcpGroup($port) [keylget ret handles]
		puts "Handle for DHCP group on $port is $hDhcpGroup($port)"
	    }   ;# end if-else statement
   	   
	    ###  Apply the configuration to the cards/STC framework
   	    set ret [ sth::test_control -action sync]
   	    set controlStatus [keylget ret status]
	}  ;# end if statement
    }   ;# end foreach loop
    puts "**************  DHCP group Configuration Complete  **************"

    ###################################
    ### Bind sessions
    ###  
    ###################################
    puts "************** Connecting the DHCP groups   ***********************"
    foreach port $portlist {
	if {[keylget dhcpList $port.dhcpEnable] == 1} {

	    set ret [ sth::emulation_dhcp_control -action	bind \
	                                        	 	  -port_handle 	$hDhcpPort($port)]

	    #  Write result of the command
	    set connectStatus [keylget ret status]
	    if {! $connectStatus} {
		puts "<error>Error starting DHCP group on $port"
		puts "<error>Error from command was $ret"
         	exit
	    } else {
		puts "DHCP group on port $port was started successfully"
	    }   ;# end if-else statement

 	    ###  Apply the configuration to the cards/STC framework
     	    set ret [ sth::test_control -action sync]
     	    set controlStatus [keylget ret status]
	}  ;# end if statement
    }   ;# end foreach loop
    puts "**************   Finished starting the DHCP groups  ********************"

    ###################################
    ### Wait for the session to come up 
    ### Check the DUT here for DHCP Bindings 
    ###################################
    puts "*************  Waiting for all the sessions to come up ******************"
    ::stc::sleep 10
    puts "*************  Check the DUT here for DHCP Bindings ******************"

    ###################################
    ### Disconnect Clients
    ###  
    ###################################
    foreach port $portlist {
	if {[keylget dhcpList $port.dhcpEnable] == 1} {
	    set ret [sth::emulation_dhcp_control -action		release \
	                                      			  -handle 	$hDhcpGroup($port)]

	    #  Write result of the command
	    set connectStatus [keylget ret status]
	    if {! $connectStatus} {
		puts "<error>Error stopping DHCP group on $port"
		puts "<error>Error from command was $ret"
         	exit
	    } else {
		puts "DHCP group on port $port was stopped successfully"
	    }   ;# end if-else statement
   	   
	    ####  Apply the configuration to the cards/STC framework
   	    set ret [ sth::test_control -action sync]
   	    set controlStatus [keylget ret status]
	}  ;# end if statement
    }   ;# end foreach loop

    ###################################
    ### Wait for the session to go down 
    ###  
    ###################################
    ::stc::sleep 10
    puts "************* Finished waiting for sessions to release  ***********************"

    ###################################
    ###  Attempting to delete the original DHCP groups
    ###
    ###################################
    puts "************** Resetting the DHCP groups   ***********************"
    foreach port $portlist {
    	if {[keylget dhcpList $port.dhcpEnable] == 1} {
    	    set ret [sth::emulation_dhcp_group_config 	-mode		reset \
	      								-handle 	$hDhcpGroup($port)]

	    #  Write the result of the command
	    set resetStatus [keylget ret status]
	    if {! $resetStatus} {
		puts "<error>Error resetting DHCP group on $port"
		puts "<error>Error from command was $ret"
                exit
	    } else {
		puts "DHCP group on port $port was reset successfully"
	    }   ;# end if-else statement
    
   	   ###  Apply the configuration to the cards/STC framework
   	   set ret [sth::test_control -action sync]
   	   set controlStatus [keylget ret status]
	}  ;# end if statement
    }   ;# end foreach loop
    puts "**************   Finished resetting the DHCP groups  ********************"
}  ;# end foreach loop for session values

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
puts "**************  Finished deleting the ports and routers  **************"

###  Apply the configuration to the cards/STC framework
set ret [sth::test_control -action sync]
set controlStatus [keylget ret status]
puts "**************  Test Complete  **************"
puts "_SAMPLE_SCRIPT_SUCCESS"
