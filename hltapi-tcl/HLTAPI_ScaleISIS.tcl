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
# File Name:                 HLTAPI_xxx.tcl
# Description:               This script demonstrates the use of Spirent HLTAPI to setup 100 ISIS routers and 1 route per router.
################################################################################################################################                            

# Run sample:
#            c:>tclsh HLTAPI_ScaleISIS.tcl 10.61.44.2 3/1

package require SpirentHltApi

set device     [lindex $argv 0]
set portlist   [lindex $argv 1]

set timeout 15
set runtime 60
set isisUpWait 150
set isisDownWait 45
set isisSystemIdList {000011010001 000011020001} 

set isisIpv4AddrList {11.1.1.11 11.2.1.11}
set isisPrefixLenList {16 16} 
set isisIpVersionList {4 4} 
set isisRoutingLevelList {L2 L2}
set isisWideMetricsList {1 1} 
set isisRouteIpv4AddrList {83.0.1.0 84.0.1.0}
set isisRoutePrefixLenList {27 27}
set isisIpv6AddrList {2000:11:1:0:1:0:0:111 2000:11:2:0:1:0:0:111}
set isisIpv6PrefixLenList {64 64}
set isisIpv6VersionList {6 6}
set isisIpv6RouterIdIpv4AddrList {11.1.1.111 11.2.1.111}
set isisRouteIpv6AddrList {102:0:0:1:0:0:0:0 102:1:0:1:0:0:0:0}
set isisRouteIpv6PrefixLenList {64 64}
set ipv4AddrList {11.1.0.2 11.2.0.2}
set ipv4GatewayList {11.1.0.1 11.2.0.1}
set macAddrList {00.10.94.11.00.01 00.10.94.12.00.01}
set portNetmaskList {255.255.0.0 255.255.0.0}
set ipv6AddrList {2000:11:1:0:0:0:0:2 2000:11:2:0:0:0:0:2}
set ipv6GatewayList {2000:11:1:0:0:0:0:1 2000:11:2:0:0:0:0:1} 
set ipv6PrefixLenList {64 64}
set portMediaTypeList {fiber fiber}
set portAutoNegList {1 1}
set portSpeedList {ether1000 ether1000}
set portDuplexList {full full}
set connectPortList {}
set hPortlist {}
set portIPgatewayList {}

set isisRouters 100
set numIterations 1
set checkDUT 0

set dutCommandType "Juniper"
set DUTIP 10.99.0.168
set username spirent
set password spirent
set enablePassword spirent

set scriptLog "HLTAPI_OSPFv2_ISISov4"
set passFail PASS


#######################################################
#Name: CreatePortList
#Purpose: To create a keyed list for Port information from specifically defined previously created lists
#Input:  Port list, IP address list, Gateway list, MAC address list, Media type list, Autonegotiation list
#        Port Speed list (used if autoneg is turned off), Port duplex list, Port netmask list
#Output: keyed list of parameters, main key is port id
#######################################################
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


#######################################################
#Name: incrementIpV4Address
#Purpose: To increment a given IPv4 address by the increment value
#Input:  Initial IPv4 addresss, IPv4 increment value
#Output: Incremented IPv4 address
#######################################################
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

#######################################################
#Name: CreateISISList
#Purpose: To create a keyed list of ISIS information from specifically defined previously created lists
#Input:  Port list, ISIS Router IP address list, ISIS prefix length list, System ID list, IP version list,
#        Routing level list, Wide Metrics (on or off), ISIS VLAN id (if present)
#Output: keyed list of parameters, main key is port id
#######################################################
proc CreateISISList {finishedList portList routerIP prefixLength systemID ipVersion routingLevel wideMetrics {vlanID foo}} {
    if {$vlanID == "foo"} {
        set vlanID {}
        for {set x 0} {$x < [llength $portList]} {incr x} {
            set vlanID [concat $vlanID 1]
        }   ;# end for loop
    }   ;#  end if statement

    for {set x 0} {$x < [llength $portList]} {incr x} {
        set var "\{[lindex $portList $x] \{\{isisrIP [lindex $routerIP $x]\} \
        \{prefixLength [lindex $prefixLength $x]\} \{systemID [lindex $systemID $x]\} \
        \{ipVersion [lindex $ipVersion $x]\} \{routingLevel [lindex $routingLevel $x]\} \
        \{wideMetrics [lindex $wideMetrics $x]\} \{isisVLANid [lindex $vlanID $x]\}\}\}"
        set finishedList [concat $finishedList $var]
    }  ;# end for loop
    return $finishedList
}  ;# end procedure

#######################################################
#Name: endingIpV4Address
#Purpose: To get the ending IPv4 address of the route block
#Input: Start IPv4, Prefix, number of routes, and increment
#Output: Ending IPv4 address of the route block
#For example, Start IP 192.0.1.0 Prefix 24 # of Routes 10 Increment 2 -> Ending IP 192.0.19.0
#######################################################
proc IPv4ToInt { ipAddr } {
   set val 0
   foreach field [split $ipAddr .] {
      set val [expr "(wide($val)<<8) + $field"]
   }
   return $val
}

proc IntToIPv4 { val } {
   return "[expr ($val>>24)&0xff].[expr ($val>>16)&0xff].[expr ($val>>8)&0xff].[expr $val&0xff]"
}

proc endingIpV4Address {ipAddr prefix {count 1} {increment 1}} {
    set start [IPv4ToInt $ipAddr]
    set val [expr "$start + ((($count-1)*$increment)<<(32-$prefix))"]
    return [IntToIPv4 $val]
}

#######################################################
#Name: incrSystemId
#Author: Wanluck Komes
#Purpose: To increment a given system Id by the increment value
#Input:  Initial System Id, step value
#Output: Incremented system Id
#######################################################
proc incrSystemId {address {incrValue 000000000001}} {

 	set ipList {}
	set incrVals {}
	for {set i 0} {$i < 6} {incr i} {
		set ipList [linsert $ipList $i [string range $address [expr 2*$i] [expr 2*$i+1]]] 
		set incrVals [linsert $incrVals $i [string range $incrValue [expr 2*$i] [expr 2*$i+1]]] 
	}

	set o6 [expr 0x[lindex $ipList 5] + 0x[lindex $incrVals 5]]
    set o5 [expr 0x[lindex $ipList 4] + 0x[lindex $incrVals 4]]
    set o4 [expr 0x[lindex $ipList 3] + 0x[lindex $incrVals 3]]
    set o3 [expr 0x[lindex $ipList 2] + 0x[lindex $incrVals 2]]
    set o2 [expr 0x[lindex $ipList 1] + 0x[lindex $incrVals 1]]
    set o1 [expr 0x[lindex $ipList 0] + 0x[lindex $incrVals 0]]

    if {$o6 > 255} {incr o5; set o6 [expr $o6 - 256]}
    if {$o5 > 255} {incr o4; set o5 [expr $o5 - 256]}
    if {$o4 > 255} {incr o3; set o4 [expr $o4 - 256]}
    if {$o3 > 255} {incr o2; set o3 [expr $o3 - 256]}
    if {$o2 > 255} {incr o1; set o2 [expr $o2 - 256]}
    if {$o1 > 255} {
        puts "ERROR: Cannot increment system id past ff"
    }

    return "[format %02x $o1][format %02x $o2][format %02x $o3][format %02x $o4][format %02x $o5][format %02x $o6]"
}

proc convert {systemId} {
	set newId "[string range $systemId 0 3].[string range $systemId 4 7].[string range $systemId 8 11]"
	return $newId
}

#To turn off implicit Apply internally
::sth::test_control -action enable

#Create the keyed list for port interfaces
set portIPgatewayList [CreatePortList $portIPgatewayList $portlist $ipv4AddrList $ipv4GatewayList $macAddrList $portMediaTypeList $portAutoNegList $portSpeedList $portDuplexList $portNetmaskList]
#Create the keyed list for port interfaces

#Connect to chassis and configure port inteface 
foreach port $portlist {
	puts "******  Connecting to the chassis $device port $port *******"
	#Connect to chassis
	set ret [sth::connect -device $device -timeout $timeout -port_list $port]
	set chassisConnect [keylget ret status]
	if {!$chassisConnect} {
		set passFail FAIL
		puts "<error>Failed to retrieve port handle. Error message: $ret"
		exit
	} else {
	   set hPort($device.$port) [keylget ret port_handle.$device.$port]
	   set hPortlist [concat $hPortlist $hPort($device.$port)]
 	   puts "*******************  Retrieved port handle  ********************"   	
	}  ;# end if-else

	#Configure port interface
	set ret [sth::interface_config 	-port_handle       $hPort($device.$port) \
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
	                              					
        set intfConfig [keylget ret status]
	if {$intfConfig} {
	puts "Successfully configured port $port interface"

	} else {
		set passFail FAIL
		puts "<error>Failed to configure port $port port_handle $hPort($device.$port). Message: $ret"
		exit       	
	}  ;# end if-else statement
}   ;# end foreach loop

#####  Apply the configuration
::sth::test_control -action sync
puts "\n**************  Port configurations are complete  **************"

puts "\n*******  Part I Create and start routers through loop  *********"

for {set i 0} {$i < $numIterations} {incr i} {
	puts "\n******************  Creating ISISov4 routers  ******************"
	#Create the keyed list of information for the ISISov4 routers
	set isisInfoList($i) {}
	set isisInfoList($i) [CreateISISList $isisInfoList($i) $portlist $isisIpv4AddrList $isisPrefixLenList $isisSystemIdList $isisIpVersionList $isisRoutingLevelList $isisWideMetricsList]
	foreach port $portlist {
		set ret [sth::emulation_isis_config 	-mode 					create \
																-port_handle 			$hPort($device.$port) \
																-ip_version 			[keylget isisInfoList($i) $port.ipVersion] \
																-system_id 				[keylget isisInfoList($i) $port.systemID] \
																-area_id 				000000000001 \
																-count					$isisRouters \
																-hello_interval 		10 \
																-holding_time 			30 \
																-intf_ip_addr 			[keylget isisInfoList($i) $port.isisrIP] \
																-intf_ip_addr_step		0.0.0.1 \
																-intf_ip_prefix_length 	[keylget isisInfoList($i) $port.prefixLength] \
																-gateway_ip_addr		[keylget portIPgatewayList $port.gateWay] \
																-gateway_ip_addr_step	0.0.0.0 \
																-router_id				[keylget isisInfoList($i) $port.isisrIP] \
																-router_id_step			0.0.0.1 \
																-intf_metric 			1 \
																-wide_metrics 			[keylget isisInfoList($i) $port.wideMetrics] \
																-routing_level 			[keylget isisInfoList($i) $port.routingLevel]]

		#Create ISISov4 router handles
		set routerStatus [keylget ret status]
		if {!$routerStatus} {
			set passFail FAIL
       		puts "<error>Failed to configure ISISov4 routers on port $port. Error message: $ret"
       		exit
    	} else {
    		set hIsisRouter($port,$i) [keylget ret handle]
       		puts "Handle for ISISov4 on port $port is $hIsisRouter($port,$i)"
    	}   ;# end if-else statement
	} ;# end foreach 
	
	#####  Apply the configuration
	::sth::test_control -action sync
	
	# Increment the ISIS router IP and system Id for the next iteration
	for {set portIndex 0} {$portIndex < [llength $portlist]} {incr portIndex} {
		#endingIpV4Address ipAddr prefix {count 1} {increment 1}: return the end IP address of the address block
		set ipAddr [endingIpV4Address [lindex $isisIpv4AddrList $portIndex] 32 [expr $isisRouters + 1]]
		lset isisIpv4AddrList $portIndex $ipAddr
		set tmp ""
		for {set t 0} {$t < [expr 12 - [string length [format %02X $isisRouters]]]} {incr t} {
			set tmp [append tmp 0]
		}
		set tmp [append tmp [format %02X $isisRouters]]
		set system [incrSystemId [lindex $isisSystemIdList $portIndex] $tmp]
		lset isisSystemIdList $portIndex $system
	}
	
	puts "\n*********  ISISov4 routers configuration is complete  **********"

	puts "\n*************  Creating ISISov4 External Routes  ***************"
	#Create External route prefix 27
	set portIndex 0
	foreach port $portlist {
		set ipAddr [keylget isisInfoList($i) $port.isisrIP]
		set isisSystemId [keylget isisInfoList($i) $port.systemID]
		set ipPrefix [lindex $isisRouteIpv4AddrList $portIndex]
		#loop to add external route on each ISISov4 router
		for {set r 0} {$r < [llength $hIsisRouter($port,$i)]} {incr r} {
    		set ret [sth::emulation_isis_topology_route_config 	-mode 					create \
    																			-handle					[lindex $hIsisRouter($port,$i) $r] \
																				-ip_version     		4 \
																				-type 					external \
																				-router_id      		$ipAddr  \
																				-external_count 		1  \
																				-external_ip_start 		$ipPrefix \
																				-external_ip_pfx_len 	[lindex $isisRoutePrefixLenList $portIndex] \
																				-external_metric 		10 \
																				-external_metric_type 	external \
																				-router_system_id 		$isisSystemId  \
																				-router_routing_level   L2 ] 
    		set lspStatus [keylget ret status]										   		
    		if {!$lspStatus} {
       			set passFail FAIL
       			puts "<error>Failed to configure ISIS External Routes on port $port. Error message: $ret"
       			exit
    		} else {												   		
    			set hExtLspHandle($port,$i,$r) [keylget ret elem_handle]
    			set ipAddr [incrementIpV4Address $ipAddr]
    			set isisSystemId [incrSystemId $isisSystemId]
    			set ipPrefix [endingIpV4Address $ipPrefix [lindex $isisRoutePrefixLenList $portIndex] 2]
    			puts "External Routes are created on port $port."
			};# end if-else statement	
		}; #end i loop
		incr portIndex  												   			
	}; #end foreach creating external route loop
	
	#####  Apply the configuration
	::sth::test_control -action sync
	
	# Increment the ISIS route for the next iteration 
	for {set portIndex 0} {$portIndex < [llength $portlist]} {incr portIndex} {
		#endingIpV4Address ipAddr prefix {count 1} {increment 1}: return the end IP address of the address block
		set ipPrefix [endingIpV4Address [lindex $isisRouteIpv4AddrList $portIndex] [lindex $isisRoutePrefixLenList $portIndex] [expr $isisRouters + 1]]
		lset isisRouteIpv4AddrList $portIndex $ipPrefix
	}
	puts "\n*****  ISISov4 external routes configuration is complete  ******"

	puts "\n*******************  Starting ISISov4 routers  *****************"
	#Start ISISov4 Routers
	foreach port $portlist {
		for {set r 0} {$r < [llength $hIsisRouter($port,$i)]} {incr r} {
			set ret [sth::emulation_isis_control 	-mode 			start \
																	-handle 		[lindex $hIsisRouter($port,$i) $r]]
                        set startStatus [keylget ret status]
			if {!$startStatus} {
				set passFail FAIL
       			puts "<error>Failed to start ISISov4 [lindex $hIsisRouter($port,$i) $r] on port $port. Error message: $ret"
       			exit
			} else {
       			puts "[lindex $hIsisRouter($port,$i) $r] on port $port has been started successfully"		
			}	;# end if-else statement	
		}; #end r loop
	} ;# end foreach staring ISISov4 routers
	
	#####  Apply the configuration
	::sth::test_control -action sync
	
	puts "\n***  Waiting for $isisUpWait seconds for ISIS adjacencies to come up  ***"
	stc::sleep $isisUpWait
	
	#############Code to Check DUT#########################
}; #end configure routers loop
puts "\n*************************  End Part I  *************************"

 puts "\n**************  Part II stop routers through loop  *************"
 for {set i [expr $numIterations - 1]} {$i >= 0} {incr i -1} {
 	puts "\n*******************  Stopping ISISov4 routers  *****************"
 	#Stop ISISov4 Routers
 	foreach port $portlist {
 		for {set r 0} {$r < [llength $hIsisRouter($port,$i)]} {incr r} {
 			set ret [sth::emulation_isis_control 	-mode 		stop \
 																	-handle 	[lindex $hIsisRouter($port,$i) $r]]
                        set startStatus [keylget ret status]
 			if {!$startStatus} {
 				set passFail FAIL
        		puts "<error>Failed to stop ISIS [lindex $hIsisRouter($port,$i) $r] on port $port. Error message: $ret"
        		exit
 			} else {
        			puts "ISIS [lindex $hIsisRouter($port,$i) $r] on port $port was stopped successfully"		
 			}	;# end if-else statement
 		}; #end r loop	
 	} ;# end foreach stopping ISISov4 routers
 	
 	puts "\n***  Waiting for $isisDownWait seconds for ISIS adjacencies to go down  ***"
 	stc::sleep $isisDownWait
 	
 	##################Code to check DUT##################
 	
 }; #end configure routers loop
 puts "\n************************  End Part II  *************************"

#Cleanup port configuration
puts "**************  Cleaning up port configurations  ***************"
set ret [sth::cleanup_session -port_list $hPortlist]
set intfConfig [keylget ret status]
	if {$intfConfig} {
	puts "Successfully cleaned up port $port"
	} else {
	set passFail FAIL
	puts "<error>Failed to clean up port $port. Message: $ret"
	exit
}   ;# end if statement
puts "*********************  Cleanup is completed  *******************"
puts "ISIS test is $passFail"

puts "_SAMPLE_SCRIPT_SUCCESS"