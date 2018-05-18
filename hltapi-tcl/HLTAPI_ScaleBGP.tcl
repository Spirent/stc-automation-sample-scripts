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
# Description:               This script demonstrates the use of Spirent HLTAPI to setup 1500 BGP routers and 1 route per router.
################################################################################################################################                            

# Run sample:
#            c:>tclsh HLTAPI_ScaleBGP.tcl 10.61.44.2 3/1

package require SpirentHltApi

set device     [lindex $argv 0]
set portlist   [lindex $argv 1]

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
#Name: CreateBGPList
#Purpose: To create a keyed list of BGP information from specifically defined previously created lists
#Input:  Port list, BGP Router IP address list, BGP SUT IP address list, BGP Gateway list, BGP local AS list,
#        BGP remote AS list, BGP local router ID, BGP VLAN id (if present)
#Output: keyed list of parameters, main key is port id
#######################################################
proc CreateBGPList {finishedList portList routerIP sutIP gateway localAS remoteAS localID {vlanID foo}} {
   	set finishedList ""
    if {$vlanID == "foo"} {
        set vlanID {}
        for {set x 0} {$x < [llength $portList]} {incr x} {
            set vlanID [concat $vlanID 1]
        }   ;# end for loop
    }   ;#  end if statement

    for {set x 0} {$x < [llength $portList]} {incr x} {
        set var "\{[lindex $portList $x] \{\{bgprIP [lindex $routerIP $x]\} \
        \{bgpSUTip [lindex $sutIP $x]\} \{bgpGateway [lindex $gateway $x]\} \
        \{bgpLocalAS [lindex $localAS $x]\} \{bgpRemoteAS [lindex $remoteAS $x]\} \
        \{bgpLocalID [lindex $localID $x]\} \{bgpVLANid [lindex $vlanID $x]\}\}\}"
        set finishedList [concat $finishedList $var]
    }  ;# end for loop
    return $finishedList
}  ;# end procedure


#######################################################
#Name: CreateBGPRouteList
#Purpose: To create a keyed list of BGP information from specifically defined previously created lists
#Input:  Port list, Prefix (Starting route address), Netmask (for route block)
#Output: keyed list of parameters, main key is port id
#######################################################
proc CreateBGPRouteList {finishedList portList route netmask} {
	set finishedList ""
    for {set x 0} {$x < [llength $portList]} {incr x} {
        set var "\{[lindex $portList $x] \{\{route [lindex $route $x]\} \
        \{netmask [lindex $netmask $x]\}\}\}"
        set finishedList [concat $finishedList $var]
    }   ;# end for loop
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


# Define global variables
set connectPortList {}
set hPortlist {}
set timeout 15
set runtime 10
set BGPipv4AddressList {60.25.0.10 60.26.0.10 60.27.0.10 60.28.0.10}
set BGPipv4gatewayList {60.25.0.1 60.26.0.1 60.27.0.1 60.28.0.1}
set BGPmacAddressList {00.00.00.01.00.01 00.00.02.00.00.01 00.00.03.00.00.01 00.00.04.00.00.01}
set portMediaTypeList {fiber fiber fiber fiber}
set portAutoNegList {1 1 1 1}
set portSpeedList {ether100 ether100 ether100 ether100}
set portDuplexList {full full full full}
set portNetmaskList {255.255.0.0 255.255.0.0 255.255.0.0 255.255.0.0}
set portIPgatewayList {}
set bgprIPv4List {60.25.1.11 60.26.1.11 60.27.1.11 60.28.1.11}
set bgpSUTIPv4List {60.25.0.1 60.26.0.1 60.27.0.1 60.28.0.1}
set bgpGatewayStepipv4List {60.25.0.1 60.26.0.1 60.27.0.1 60.28.0.1}
set bgpASList {1001 1001 1001 1001}
set bgpPeerASList {123 123 123 123}
set bgpLocalIDipv4List {60.25.1.11 60.26.1.11 60.27.1.11 60.28.1.11}
set bgpVlanIdList {201 202 203 204}
set bgpInfoList {}
set bgpRouteIPv4List {120.0.10.0 120.0.20.0 120.0.30.0 120.0.40.0}
set bgpRouteNetmaskList {255.255.255.0 255.255.255.0 255.255.255.0 255.255.255.0}
set bgpIPv4RouteList {}
set numRoutersStep 100
set maxBgpRouters 1500
set dutConnected 1
set vlanEnable 0
set protocolEnable {1 1}

set passFail PASS
set scriptLog "HLTAPI_ScaleBgp.log"
set tcid ""
set TCreport ""
set Result 0
set ret ""
set DUTIP 10.99.0.168

set ret [sth::test_control -action enable]
set controlStatus [keylget ret status]

#  Create the keyed list of information for the ports
set portIPgatewayList [CreatePortList $portIPgatewayList $portlist $BGPipv4AddressList $BGPipv4gatewayList $BGPmacAddressList $portMediaTypeList $portAutoNegList $portSpeedList $portDuplexList $portNetmaskList]
puts "**************  Created the keyed list for the port parameters **************"

#Connect to chassis & reserve port
puts "Connecting to $device, $portlist"
set ret [sth::connect -device $device \
			         			 -port_list $portlist]
set intStatus [keylget ret status]

if {$intStatus} {
    #Retrieve port handles for later use
    foreach port $portlist {
        set hPort($device.$port) [keylget ret port_handle.$device.$port]
		set hPortlist [concat $hPortlist $hPort($device.$port)]
    }
} else {
	set passFail FAIL
    puts "<error>Error retrieving the port handles, error message was $ret"
    exit
}

# Connect to chassis
set portTime [time {
    foreach port $portlist {
        if {$dutConnected} {
            set ret [::sth::interface_config 	-port_handle       $hPort($device.$port) \
                                                            -intf_ip_addr      [keylget portIPgatewayList $port.ipAddr] \
                                                            -gateway           [keylget portIPgatewayList $port.gateWay] \
                                                            -netmask           [keylget portIPgatewayList $port.netmask] \
                                                            -intf_mode         ethernet \
                                                            -phy_mode          fiber \
                                                            -speed             ether1000 \
                                                            -mode              config \
                                                            -src_mac_addr      [keylget portIPgatewayList $port.macAddr]]
            set intStatus [keylget ret status]
            if {! $intStatus} {
                puts "<error>Error configuring port $port with handle $hPort($device,$port)"
                puts "<error>Error message was $ret"
                set passFail FAIL
                puts "<error>Failed to configure port $port with handle $hPort($device,$port)"
                exit
            } else {
                puts "Port $port has been configured properly"
                puts "Port $port has been configured properly" 
            }
        } else {
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
                                                            -src_mac_addr      [keylget portIPgatewayList $port.macAddr]]
            set intStatus [keylget ret status]
            if {! $intStatus} {
                puts "<error>Error configuring port $port with handle $hPort($device,$port)"
                puts "<error>Error message was $ret"
                set passFail FAIL
                puts "<error>Failed to configure port $port with handle $hPort($device,$port)"
                exit
            } else {
                puts "Port $port has been configured properly"
                puts "Port $port has been configured properly" 
            }
        }
    }
}]

#  Create the keyed list of information for the BGP routers
set bgpInfoList [CreateBGPList $bgpInfoList $portlist $bgprIPv4List $bgpSUTIPv4List $bgpGatewayStepipv4List $bgpASList $bgpPeerASList $bgpLocalIDipv4List $bgpVlanIdList]
puts "**************  Created the keyed list for the BGP routers  **************"

#  Create the keyed list of information for the BGP route blocks
set bgpIPv4RouteList [CreateBGPRouteList $bgpIPv4RouteList $portlist $bgpRouteIPv4List $bgpRouteNetmaskList]
puts "**************  Created the keyed list for the route blocks  **************"

foreach port $portlist {
    set routerIp($port) [keylget bgpInfoList $port.bgprIP]
    set localId($port)  [keylget bgpInfoList $port.bgpLocalID]
    set routeNextHopIp($port) [keylget bgpInfoList $port.bgprIP]
    set routeBlockIp($port) [keylget bgpIPv4RouteList $port.route]
}

set i 1
set m 1
# Setup the routers, all parameters
while {$i < $maxBgpRouters} {
    set portIndex 0
    set routerTime [time {
        foreach port $portlist {
            if {[lindex $protocolEnable $portIndex] == 1} {
                if {$vlanEnable} {
                    for {set j 0} {$j  < $numRoutersStep} {incr j} {
                        set ret [ ::sth::emulation_bgp_config 	-mode                       enable \
                                                                            -port_handle                $hPort($device.$port) \
                                                                            -active_connect_enable      1 \
                                                                            -ip_version                 4 \
                                                                            -local_ip_addr              $routerIp($port) \
                                                                            -remote_ip_addr             [keylget bgpInfoList $port.bgpSUTip] \
                                                                            -next_hop_ip                [keylget bgpInfoList $port.bgpGateway] \
                                                                            -local_as                   [keylget bgpInfoList $port.bgpLocalAS] \
                                                                            -local_as_step		    	1 \
                                                                            -local_router_id	    	$localId($port) \
                                                                            -remote_as                  [keylget bgpInfoList $port.bgpRemoteAS] \
                                                                            -vlan_id                    [keylget portIPgatewayList $port.bgpVLANid] \
                                                                            -count                      1 \
                                                                            -netmask 					16 \
                                                                            -local_addr_step            0.0.0.1 \
                                                                            -remote_addr_step           0.0.0.0 \
                                                                            -retry_time                 30 \
                                                                            -retries                    10 \
                                                                            -routes_per_msg             2000 \
                                                                            -hold_time                  90 \
                                                                            -update_interval            30 \
                                                                            -ipv4_unicast_nlri          1]
                        set routerStatus [keylget ret status]
                        if {! $routerStatus} {
                            puts "<error>Error configuring Router $i on $port"
                            set passFail FAIL
                            puts "<error>Failed to create router $i on port $port"
                            exit
                        } else {
                            set hBGPRouter($port.$i) [keylget ret handles]
                            puts "Handle for router $i on $port is $hBGPRouter($port.$i)"
                            puts "BGP Router $i on port $port is created" 
                        }
                        set routerIp($port) [incrementIpV4Address $routerIp($port)]
                        set localId($port) [incrementIpV4Address $localId($port)]
                        incr i
                    }
                } else {
                    for {set j 0} {$j  < $numRoutersStep} {incr j} {
                        set ret [ ::sth::emulation_bgp_config 	-mode                       enable \
                                                                            -port_handle                $hPort($device.$port) \
                                                                            -active_connect_enable      1 \
                                                                            -ip_version                 4 \
                                                                            -local_ip_addr              $routerIp($port) \
                                                                            -remote_ip_addr             [keylget bgpInfoList $port.bgpSUTip] \
                                                                            -next_hop_ip                [keylget bgpInfoList $port.bgpGateway] \
                                                                            -local_as                   [keylget bgpInfoList $port.bgpLocalAS] \
                                                                            -local_as_step		    	1 \
                                                                            -local_router_id	    	$localId($port) \
                                                                            -remote_as                  [keylget bgpInfoList $port.bgpRemoteAS] \
                                                                            -count                      1 \
                                                                            -netmask 					16 \
                                                                            -local_addr_step            0.0.0.1 \
                                                                            -remote_addr_step           0.0.0.0 \
                                                                            -retry_time                 30 \
                                                                            -retries                    10 \
                                                                            -routes_per_msg             2000 \
                                                                            -hold_time                  90 \
                                                                            -update_interval            30 \
                                                                            -ipv4_unicast_nlri          1]
                        set routerStatus [keylget ret status]
                        if {! $routerStatus} {
                            puts "<error>Error configuring Router $i on $port"
                            set passFail FAIL
                            puts "<error>Failed to create router $i on port $port"
                            exit
                        } else {
                            set hBGPRouter($port.$i) [keylget ret handles]
                            puts "Handle for router $i on $port is $hBGPRouter($port.$i)"
                            puts "BGP Router $i on port $port is created" 
                        }
                        set routerIp($port) [incrementIpV4Address $routerIp($port)]
                        set localId($port) [incrementIpV4Address $localId($port)]
                        incr i
                    }
                }
            }
            incr portIndex
        }
    }]

    set portIndex 0
    set routeTime [time {
        foreach port $portlist {
            if {[lindex $protocolEnable $portIndex] == 1} {
                for {set j 0} {$j  < $numRoutersStep} {incr j} {
                    set ret [::sth::emulation_bgp_route_config 	-mode 				add \
                                                                                -handle 			$hBGPRouter($port.$m) \
                                                                                -prefix 			$routeBlockIp($port) \
                                                                                -num_routes 		10 \
                                                                                -prefix_step 		1 \
                                                                                -netmask 			[keylget bgpIPv4RouteList $port.netmask] \
                                                                                -ip_version 		4 \
                                                                                -as_path 			as_seq:[keylget bgpInfoList $port.bgpLocalAS] \
                                                                                -next_hop_ip_version 4 \
                                                                                -next_hop 			$routeNextHopIp($port) \
                                                                                -local_pref 		0 \
                                                                                -next_hop_set_mode 	manual]
                    set routeStatus [keylget ret status]
                    #  Create the handle to the BGP route block in case of configuration change
                    if {! $routeStatus} {
                        puts "<error>Error configuring route block $m on $port"
                        puts "<error>Error from command was $ret"
                        set passFail FAIL
                        puts "<error>Failed to create route block on router $m on port $port"
                        exit
                    } else {
                        set hRoute($port.$m) [keylget ret handles]
                        puts "Handle for route block on $port is $hRoute($port.$m)"
                        puts "BGP Route Block $m on port $port is created" 
                    }
                    set routeBlockIp($port) [incrementIpV4Address $routeBlockIp($port) 0.0.1.0]
                    set routeNextHopIp($port) [incrementIpV4Address $routeNextHopIp($port) 0.0.0.1]
            		incr m
                }
                incr portIndex
            }
        }
    }]

	#config parts are finished
	
	########################
	####  Apply the configuration to the cards/STC framework
	########################
	set ret [sth::test_control -action sync]
	set controlStatus [keylget ret status]
	
    if {$dutConnected} {
        set portIndex 0
        #Start the routers
        set l [expr $i - $numRoutersStep]
        set routerStartTime [time {
            foreach port $portlist {
                if {[lindex $protocolEnable $portIndex] == 1} {
                    for {set k $l} {$k < $i} {incr k} {
                        set ret [ ::sth::emulation_bgp_control -mode start -handle $hBGPRouter($port.$k)]
                        set startStatus [keylget ret status]
                        if {! $startStatus} {
                            puts "<error>Error starting Router $k on $port"
                            set passFail FAIL
                            puts "<error>Failed to start router $k on port $port"
                            exit                        
                        } else {
                            puts "Router $k on $port is started"
                            puts "BGP Router $k on port $port is started" 
                        }
                    }
                }
                incr portIndex
            }
        }]


        #set sleepTime [expr 2 * $numRoutersStep]
        #puts "Sleeping for $sleepTime seconds to wait for the routers to come up"
        #::stc::sleep $sleepTime

        set portIndex 0
        ###########Code to check the DUT##########################
    }

    puts "**************  Sleeping for $runtime seconds  **************"

    ::stc::sleep $runtime ; #  Verify on DUT that sessions are actually up, test time is $runtime seconds.

    puts "**************  Finished sleeping  **************"
}

set maxRoutersMade [expr $i - 1]
puts "The max number of BGP routers that was setup was $maxRoutersMade"

#  Delete all routers and configuration for the ports
puts "**************  Deleting the ports and BGP routers  **************"

set routerDeleteTime [time {
    foreach port $portlist {
       set ret [::sth::emulation_bgp_config -mode reset -port_handle $hPort($device.$port)]
        set routerStatus [keylget ret status]
        if {! $routerStatus} {
            puts "<error>Error deleting routers on $port"
            puts "<error>Error message for deleting router was $ret"
            set passFail FAIL
            puts "<error>Error deleting BGP routers on port $port"
            exit
        } else {
            puts "BGP routers on port $port have been deleted correctly"
            puts "BGP routers on port $port have been deleted correctly" 
        }
    }
}]

set ret [::sth::cleanup_session -port_list $hPortlist]
set intStatus [keylget ret status]
if {! $intStatus} {
	set passFail FAIL
	puts "Error message for deleting port was $ret"
    puts "Error deleting port $port"
    exit
}

puts "**************  Finished deleting the ports and routers  **************"
puts "BGP test passed"
puts "_SAMPLE_SCRIPT_SUCCESS"

exit