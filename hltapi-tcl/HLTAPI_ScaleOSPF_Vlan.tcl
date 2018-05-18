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
# Description:               This script demonstrates the use of Spirent HLTAPI to setup 400 OSPF routers for 400 vlans and 1 route per router.
################################################################################################################################  

# Run sample:
#            c:>tclsh HLTAPI_ScaleOSPF_Vlan.tcl 10.61.44.2 3/1

package require SpirentHltApi

set device     [lindex $argv 0]
set portlist   [lindex $argv 1]

#Define global variables
set timeout 15
set runtime 60
set ospfUpWait 120
set ospfDownWait 45

set connectPortList {}
set hPortlist {}
set portIPgatewayList {}

set ospfRouters 400
set numIterations 1
set checkDUT 0

set dutCommandType "Juniper"
set DUTIP 10.99.0.168
set username spirent
set password spirent
set enablePassword spirent

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
set ospfIpv4AddrList {11.1.0.11 11.2.0.11}
set ospfPrefixLenList {16 16}
set ospfAreaList {0.0.0.0 0.0.0.0}
set ospfNetworkTypeList {broadcast broadcast}
set ospfRouteIpv4AddrList {81.0.1.0 82.0.1.0}
set ospfRoutePrefixLenList {27 27}
set scriptLog "HLTAPI_ScaleOSPF_VLAN"

set passFail PASS
set logValue 0
set capture 0

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
#Author: Todd Cool
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
        puts "ERROR: Cannot increment ip past 255.0.0.0"
    }

    return ${o1}.${o2}.${o3}.${o4}
}

#######################################################
#Name: CreateOSPFList
#Author: Quinten Pierce
#Purpose: To create a keyed list of OSPFv2 information from specifically defined previously created lists
#Input:  Port list, OSPF Router IP address list, OSPF Area list, OSPF Area type list, OSPF Network Type list
#        Instance ID (OSPFv3 only), Priority, Cost, Retransmit Interval, Hello Interval, Dead Timer, Options, MTU
#        Any list that is within {} is set to a default value if no list is given
#Output: keyed list of parameters, main key is port id
#######################################################
proc CreateOSPFList {finishedList portList routerIP routerID prefixLength area networkType {vlanID foo} {instanceID foo} {priority foo} \
            {cost foo} {retransmitInterval foo} {helloInterval foo} {deadTimer foo} {options foo} {mtu foo}} {

    if {$vlanID == "foo"} {
        set vlanID {}
        for {set x 0} {$x < [llength $portList]} {incr x} {
            set vlanID [concat $vlanID 1]
        }   ;# end for loop
    }   ;#  end if statement
    if {$instanceID == "foo"} {
        set instanceID {}
        for {set x 0} {$x < [llength $portList]} {incr x} {
            set instanceID [concat $instanceID 0]
        }   ;# end for loop
    }   ;#  end if statement
    if {$priority == "foo"} {
        set priority {}
        for {set x 0} {$x < [llength $portList]} {incr x} {
            set priority [concat $priority 0]
        }   ;# end for loop
    }   ;#  end if statement
    if {$cost == "foo"} {
        set cost {}
        for {set x 0} {$x < [llength $portList]} {incr x} {
            set cost [concat $cost 1]
        }   ;# end for loop
    }   ;#  end if statement
    if {$retransmitInterval == "foo"} {
        set retransmitInterval {}
        for {set x 0} {$x < [llength $portList]} {incr x} {
            set retransmitInterval [concat $retransmitInterval 5]
        }   ;# end for loop
    }   ;#  end if statement
    if {$helloInterval == "foo"} {
        set helloInterval {}
        for {set x 0} {$x < [llength $portList]} {incr x} {
            set helloInterval [concat $helloInterval 10]
        }   ;# end for loop
    }   ;#  end if statement
    if {$deadTimer == "foo"} {
        set deadTimer {}
        for {set x 0} {$x < [llength $portList]} {incr x} {
            set deadTimer [concat $deadTimer 40]
        }   ;# end for loop
    }   ;#  end if statement
    if {$options == "foo"} {
        set options {}
        for {set x 0} {$x < [llength $portList]} {incr x} {
            set options [concat $options 0x02]
        }   ;# end for loop
    }   ;#  end if statement
    if {$mtu == "foo"} {
        set mtu {}
        for {set x 0} {$x < [llength $portList]} {incr x} {
            set mtu [concat $mtu 1500]
        }   ;# end for loop
    }   ;#  end if statement


    for {set x 0} {$x < [llength $portList]} {incr x} {
        set var "\{[lindex $portList $x] \{\{routerIP [lindex $routerIP $x]\} \
        \{routerID [lindex $routerID $x]\} \{prefixLength [lindex $prefixLength $x]\} \
        \{area [lindex $area $x]\} \{networkType [lindex $networkType $x]\} \{vlanID [lindex $vlanID $x]\} \
        \{instanceID [lindex $instanceID $x]\} \{priority [lindex $priority $x]\} \
        \{cost [lindex $cost $x]\} \{retransmitInterval [lindex $retransmitInterval $x]\} \
        \{helloInterval [lindex $helloInterval $x]\} \{deadTimer [lindex $deadTimer $x]\} \
        \{options [lindex $options $x]\} \{mtu [lindex $mtu $x]\}\}\}"
        set finishedList [concat $finishedList $var]
    }  ;# end for loop
    return $finishedList
}   ;# end procedure

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
proc convert {systemId} {
	set newId "[string range $systemId 0 3].[string range $systemId 4 7].[string range $systemId 8 11]"
	return $newId
}


#Create the keyed list for port interfaces
set portIPgatewayList [CreatePortList $portIPgatewayList $portlist $ipv4AddrList $ipv4GatewayList $macAddrList $portMediaTypeList $portAutoNegList $portSpeedList $portDuplexList $portNetmaskList]
#Create the keyed list for port interfaces

#Connect to chassis and configure port inteface 
foreach port $portlist {
	puts "******  Connecting to the chassis $device port $port *******"
	#Connect to chassis
	set ret [ sth::connect -device $device -timeout $timeout -port_list $port]
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

puts "\n**************  Port configurations are complete  **************"

puts "\n*******  Part I Create and start routers through loop  *********"
	puts "Creating routers at [clock format [clock scan now] -format %T]"

for {set i 0} {$i < $numIterations} {incr i} {
	puts "\n******************  Creating OSPFv2 routers  *******************"
	#Create the keyed list of information for the OSPFv2 routers
	set ospfInfoList($i) {}
	set ospfInfoList($i) [CreateOSPFList $ospfInfoList($i) $portlist $ospfIpv4AddrList $ospfIpv4AddrList $ospfPrefixLenList $ospfAreaList $ospfNetworkTypeList]
	foreach port $portlist {
		set ret [sth::emulation_ospf_config		-mode					create \
					      										-port_handle			$hPort($device.$port) \
					      										-session_type			ospfv2 \
					      										-intf_ip_addr			[keylget ospfInfoList($i) $port.routerIP] \
					      										-intf_ip_addr_step		0.0.0.16 \
					      										-router_id				[keylget ospfInfoList($i) $port.routerID] \
					      										-router_id_step			0.0.0.16 \
					      										-gateway_ip_addr		[keylget portIPgatewayList $port.gateWay] \
					      										-gateway_ip_addr_step	0.0.0.16 \
					      										-intf_prefix_length		[keylget ospfInfoList($i) $port.prefixLength] \
					      										-area_id				[keylget ospfInfoList($i) $port.area] \
					      										-network_type			[keylget ospfInfoList($i) $port.networkType] \
					      										-count					$ospfRouters \
					      										-vlan_id				2001 \
					      										-vlan_id_mode			increment \
					      										-vlan_id_step			1\
					      										-router_priority		[keylget ospfInfoList($i) $port.priority] \
					      										-interface_cost			[keylget ospfInfoList($i) $port.cost] \
					      										-lsa_retransmit_delay	[keylget ospfInfoList($i) $port.retransmitInterval] \
					      										-dead_interval			[keylget ospfInfoList($i) $port.deadTimer] \
					      										-option_bits			[keylget ospfInfoList($i) $port.options] \
																-mac_address_start      00:10:94:00:00:31 ]

		#Create OSPFv2 router handles
		set routerStatus [keylget ret status]   
		if {!$routerStatus} {
			set passFail FAIL
       		puts "<error>Failed to configure OSPFv2 routers on port $port. Error message: $ret"
			exit
    	} else {
    		set hOspfRouter($port,$i) [keylget ret handle]
       		puts "Handle for OSPFv2 on port $port is $hOspfRouter($port,$i)"
    	}   ;# end if-else statement
	} ;# end foreach 
	# Increment the OSPF router IP for the next iteration

	for {set portIndex 0} {$portIndex < [llength $portlist]} {incr portIndex} {
		#endingIpV4Address ipAddr prefix {count 1} {increment 1}: return the end IP address of the address block
		set ipAddr [endingIpV4Address [lindex $ospfIpv4AddrList $portIndex] 32 [expr $ospfRouters + 1]]
		lset ospfIpv4AddrList $portIndex $ipAddr
	}
		puts "All routers created at [clock format [clock scan now] -format %T]"

	puts "\n**********  OSPFv2 routers configuration is complete  **********"
	
	puts "\n*****************  Creating OSPFv2 router LSAs *****************"
	#Create router LSA 
	foreach port $portlist {
		set ipAddr [keylget ospfInfoList($i) $port.routerID]
		#loop to add router LSA on each OSPFv2 router
		for {set r 0} {$r < [llength $hOspfRouter($port,$i)]} {incr r} {
    		set ret [sth::emulation_ospf_lsa_config 	-mode 				create \
    												   				-handle 			[lindex $hOspfRouter($port,$i) $r] \
    												   				-type 				router \
    												   				-adv_router_id 		$ipAddr \
    												   				-router_abr 		0 \
    												   				-router_asbr 		1]
   
                        set lsaStatus [keylget ret status]   
  			if {!$lsaStatus} {
	  			set passFail FAIL
       			puts "<error>Failed to configure OSPFv2 Router LSA on port $port. Error message: $ret"
				exit
			} else {												   		
    			set hRtrLsaHandle($port,$i,$r) [keylget ret lsa_handle]
    			set ipAddr [incrementIpV4Address $ipAddr]
    			puts "Router LSA is created on port $port."
			}   ;# end if-else statement
		}; #end r loop
	}; #end foreach creating LSA loop
	puts "\n********  OSPFv2 router LSAs configuration is complete  ********"

	puts "\n***************  Creating OSPFv2 External LSAs  ****************"
	#Create External LSA prefix 24
	set portIndex 0
	foreach port $portlist {
		set ipAddr [keylget ospfInfoList($i) $port.routerID]
		set ipPrefix [lindex $ospfRouteIpv4AddrList $portIndex]
		#loop to add external LSAs on each OSPFv2 router
		for {set r 0} {$r < [llength $hOspfRouter($port,$i)]} {incr r} {
    		set ret [ sth::emulation_ospf_lsa_config 	-mode 							create \
    												   				-handle 						[lindex $hOspfRouter($port,$i) $r] \
    												   				-type 							ext_pool \
    												   				-adv_router_id 					$ipAddr \
    												   				-ls_age 						0 \
    												   				-ls_seq 						80000001 \
    												   				-external_number_of_prefix 		1 \
    												   				-external_prefix_forward_addr 	0.0.0.0 \
    												   				-external_prefix_length 		[lindex $ospfRoutePrefixLenList $portIndex] \
    												   				-external_prefix_metric 		1 \
    												   				-external_prefix_start 			$ipPrefix \
    												   				-external_prefix_type 			1]
    		set lsaStatus [keylget ret status]  										   		
    		if {!$lsaStatus} {
       			set passFail FAIL
       			puts "<error>Failed to configure OSPFv2 External LSAs on port $port. Error message: $ret"
				exit
    		} else {												   		
    			set hExtPoolLsaHandle($port,$i,$r) [keylget ret lsa_handle]
    			set ipAddr [incrementIpV4Address $ipAddr]
    			set ipPrefix [endingIpV4Address $ipPrefix [lindex $ospfRoutePrefixLenList $portIndex] 2]
    			puts "External LSAs are created on port $port."
			};# end if-else statement	
		}; #end i loop
		incr portIndex  												   			
	}; #end foreach creating external LSAs loop
	# Increment the OSPF route for the next iteration 
	for {set portIndex 0} {$portIndex < [llength $portlist]} {incr portIndex} {
		#endingIpV4Address ipAddr prefix {count 1} {increment 1}: return the end IP address of the address block
		set ipPrefix [endingIpV4Address [lindex $ospfRouteIpv4AddrList $portIndex] [lindex $ospfRoutePrefixLenList $portIndex] [expr $ospfRouters + 1]]
		lset ospfRouteIpv4AddrList $portIndex $ipPrefix
	}
	puts "\n*******  OSPFv2 external LSAs configuration is complete  *******"

	puts "\n********************  Starting OSPFv2 routers  *****************"
		puts "Starting routers at [clock format [clock scan now] -format %T]"

	#Start OSPFv2 Routers
	foreach port $portlist {
		set ret [ sth::emulation_ospf_control 	-mode 			start \
																-handle 		$hOspfRouter($port,$i)]
                set startStatus [keylget ret status]  
		if {!$startStatus} {
			set passFail FAIL
       		puts "<error>Failed to start OSPFv2 router(s) on port $port. Error message: $ret"
			exit
		} else {
       		puts "$hOspfRouter($port,$i) on port $port has been started successfully"		
		}	;# end if-else statement	
	} ;# end foreach staring OSPFv2 routers
		puts "All routers started at [clock format [clock scan now] -format %T]"

	puts "\n**  Waiting for $ospfUpWait seconds for OSPFv2 adjacencies to come up  **"
	stc::sleep $ospfUpWait
	
	#########Code to Check DUT######################
	
}; #end configure routers loop
puts "\n*************************  End Part I  *************************"

puts "\n**************  Part II stop routers through loop  *************"
for {set i [expr $numIterations - 1]} {$i >= 0} {incr i -1} {
	puts "\n********************  Stopping OSPFv2 routers  *****************"
	#Stop OSPFv2 Routers
	foreach port $portlist {
		set ret [sth::emulation_ospf_control 	-mode 			stop \
																-handle 		$hOspfRouter($port,$i)]
                set startStatus [keylget ret status]  
		if {!$startStatus} {
			set passFail FAIL
       		puts "<error>Failed to stop OSPFv2 router(s) on port $port. Error message: $ret"
			exit
		} else {
       		puts "$hOspfRouter($port,$i) on port $port was stopped successfully"		
		}	;# end if-else statement	
	} ;# end foreach stopping OSPFv2 routers
	
	puts "\n**  Waiting for $ospfDownWait seconds for OSPFv2 adjacencies to go down  **"
	stc::sleep $ospfDownWait
	
	###########code to check DUT########################
	
	
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
}   ;# end if statement

puts "_SAMPLE_SCRIPT_SUCCESS"
puts "*********************  Cleanup is completed  *******************"

puts " OSPF test is $passFail"