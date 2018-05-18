#################################
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
# File Name:                 HLTAPI_ScaleRSVP.tcl
#
# Description:               This script demonstrates the use of Spirent HLTAPI to setup 100 RSVP routers on each port (2 ports) with 1 tunnel on each router.
#################################

# Run sample:
#            c:>tclsh HLTAPI_ScaleRSVP.tcl 10.61.44.2 3/1 3/3
#            c:>tclsh HLTAPI_ScaleRSVP.tcl "10.61.44.2 10.61.44.7" 3/1 3/3

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

#################################
#Name: incrementIpV4Address
#Purpose: To increment a given IPv4 address by the increment value
#Input:  Initial IPv4 addresss, IPv4 increment value
#Output: Incremented IPv4 address
#################################
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
#################################

#Define global variables
set timeout 15
set hPortlist {}
set ipv4AddrList {11.1.1.1 11.1.10.1} 
set ipv4GatewayList {11.1.10.1 11.1.1.1} 
set srcMacList {00.10.94.00.00.01 00.10.94.01.00.01} 
set portNetmaskList {255.255.0.0 255.255.0.0} 
set portMediaTypeList {copper copper} 
set portAutoNegList {1 1} 
set portSpeedList {ether1000 ether1000} 
set portDuplexList {full full}  
set rsvpIpv4AddrList {11.1.1.11 11.1.10.11} 
set rsvpSUTIpv4AddrList {11.1.10.11 11.1.1.11} 
set rsvpTunnelIDList {10101 10201} 

#Turn off implicit Apply internally
set controlStatus [sth::test_control -action enable]

#Connecting to chassis
puts "\n*****************  Connecting to the chassis *****************"
set chassConnect [sth::connect -device $device -timeout $timeout -port_list $portlist]

if {[keylget chassConnect status]==1} {
	puts "Successfully connected to chassis $device"
} else {
	puts "Unable to connect to chassis $device: [keylget chassConnect log]"
	return
} 

#Configuring port interface
set portIndex 0
foreach port $portlist {
	set device [lindex $devicelist $portIndex] 
    set hPort($device.$port) [keylget chassConnect port_handle.$device.$port]
    set hPortlist [concat $hPortlist $hPort($device.$port)]
    puts "\n*****************  Configuring port interface ****************"
    set intStatus [sth::interface_config   -port_handle       $hPort($device.$port) \
                                           -intf_ip_addr      [lindex $ipv4AddrList $portIndex] \
                                           -gateway           [lindex $ipv4GatewayList $portIndex] \
                                           -netmask           [lindex $portNetmaskList $portIndex] \
                                           -intf_mode         ethernet \
                                           -phy_mode          [lindex $portMediaTypeList $portIndex] \
                                           -speed             [lindex $portSpeedList $portIndex] \
                                           -autonegotiation   [lindex $portAutoNegList $portIndex]\
                                           -mode              config \
                                           -duplex            [lindex $portDuplexList $portIndex] \
                                           -src_mac_addr      [lindex $srcMacList $portIndex] \
                                           -arp_send_req      1]
    if {[keylget intStatus status]==1} {
        puts "Successfully configured port $port interface"
    } else {
	    puts "Unable to configure port $port interface: [keylget intStatus log]"
		return
    }
    incr portIndex
}
puts "\n**************  Port Configuration is Complete  **************"

puts "\n************  Configuring RSVP router parameters  ************"
#Configuring RSVP router parameters
set portIndex 0
foreach port $portlist {
	set device [lindex $devicelist $portIndex] 
    set routerStatus [sth::emulation_rsvp_config   \
                             	-mode                   	enable \
                             	-port_handle            	$hPort($device.$port) \
                                -intf_ip_addr           	[lindex $rsvpIpv4AddrList $portIndex] \
                                -intf_ip_addr_step      	0.0.0.1 \
                                -intf_prefix_length			16 \
                                -neighbor_intf_ip_addr  	[lindex $rsvpSUTIpv4AddrList $portIndex] \
                                -neighbor_intf_ip_addr_step 0.0.0.1 \
                                -gateway_ip_addr        	[lindex $rsvpSUTIpv4AddrList $portIndex] \
                                -gateway_ip_addr_step   	0.0.0.1 \
                                -count                  	100 \
                                -egress_label_mode      	nextlabel \
                                -min_label_value        	16 \
                                -max_label_value        	65535]
                                
     if {[keylget routerStatus status] == 1} {
	     set hRSVPRouter($port) [keylget routerStatus handles]
	     puts "Successfully created RSVP router(s) on port $port"
	     puts "Handle for RSVP router(s) on $port is $hRSVPRouter($port)"
     } else {
	     puts "Unable to configure RSVP router(s) on port $port: [keylget routerStatus log]"
		 return
     }
     incr portIndex
}
puts "\n************  RSVP Router Configuration Complete  *************"

puts "\n*******************  Creating RSVP tunnels  *******************"
#Create 1 tunnel on each router 
set ingress [lindex $rsvpIpv4AddrList 0]
set egress  [lindex $rsvpIpv4AddrList 1]
set tunnelId [lindex $rsvpTunnelIDList 0]

foreach port $portlist {
	set tunnelHandleList($port) {}
	foreach router $hRSVPRouter($port) {
		set routeStatus [sth::emulation_rsvp_tunnel_config     \
                                       	-mode               create \
                                        -handle             $router \
                                        -ingress_ip_addr    $ingress \
                                        -egress_ip_addr     $egress \
                                        -count              1 \
                                        -tunnel_id_start    $tunnelId \
                                        -extended_tunnel_id 0.0.0.0]
                                        
    	if {[keylget routeStatus status]==1} {
	    	set hTunnel($port.$router) [keylget routeStatus tunnel_handle]
	    	puts "Successfully configured tunnel $tunnelId src $ingress dst $egress on router $router"
	    	puts "Handle for RSVP Tunnel on $router is $hTunnel($port.$router)\n"
	    	set tunnelHandleList($port) [concat $tunnelHandleList($port) $hTunnel($port.$router)]
    	} else {
	    	puts "Unable to configure tunnel on router $router: [keylget routeStatus log]"
			return
    	}
    	set ingress [incrementIpV4Address $ingress]
		set egress  [incrementIpV4Address $egress]
		incr tunnelId
	}; #end router loop
	set ingress [lindex $rsvpIpv4AddrList 1]
	set egress  [lindex $rsvpIpv4AddrList 0]
	set tunnelId [lindex $rsvpTunnelIDList 1]
}; #end port loop

#config parts are finished

#Apply the configuration
set controlStatus [sth::test_control -action sync]       
puts "\n***************  Tunnel Configuration Complete  ***************"


puts "\n********************  Staring RSVP routers ********************"
#Start RSVP routers
set portIndex 0
foreach port $portlist {
	set device [lindex $devicelist $portIndex] 
    set startStatus [sth::emulation_rsvp_control    -mode       	start \
                                              		-port_handle    $hPort($device.$port)]
    
    if {[keylget startStatus status]==1} {
	    puts "Successfully started RSVP router(s) on port $port"
    } else {
	    puts "Unable to start RSVP router(s) on port $port: [keylget startStatus log]"
		return
    }
	incr portIndex
}

puts "\n*****************  Wait for RSVP to come up *******************"
stc::sleep 120

puts "\n***************  Checking RSVP router(s) info *****************"
foreach port $portlist {
	foreach router $hRSVPRouter($port) {
        set statsStatus [sth::emulation_rsvp_info    -mode           stats \
                                                     -handle         $router]
                                                     
        if {[keylget statsStatus status]==1} {
            puts "\nPort $port, RSVP $router"
            puts "\tnumLSPs        :[keylget statsStatus lsp_count]"
            puts "\tlspCreated     :[keylget statsStatus lsp_created]"
            puts "\tlspDeleted     :[keylget statsStatus lsp_deleted]"
            puts "\tlspConnecting  :[keylget statsStatus lsp_connecting]"
            puts "\tnumLSPsSetup   :[keylget statsStatus num_lsps_setup]"
        } else {
            puts "\nRSVP statistics for router $router on port $port is not available"
			return
        }
    }
}

puts "\n***************  Checking RSVP tunnel(s) info *****************"
foreach port $portlist {
   foreach router $hRSVPRouter($port) {
       set statsStatus [sth::emulation_rsvp_tunnel_info  -handle  $router]
    
       if {[keylget statsStatus status]==1} {
        	puts "\nPort $port, RSVP $router"
            puts "\tnumLsps [keylget statsStatus total_lsp_count]"
            puts "\tinboundLsps [keylget statsStatus inbound_lsp_count]"
            puts "\toutboundLsps [keylget statsStatus outbound_lsp_count]"
            puts "\toutboundUp [keylget statsStatus outbound_up_count]"
            puts "\toutboundDown [keylget statsStatus outbound_down_count]"
            puts "\toutboundConnect [keylget statsStatus outbound_connect_count]"
            puts "\toutboundList [keylget statsStatus outbound_lsps]"
            puts "\tsrcAddr [keylget statsStatus source]"
            puts "\tdirection [keylget statsStatus direction]"
            puts "\tingressIpList [keylget statsStatus ingress_ip]"
            puts "\tegressIpList [keylget statsStatus egress_ip]"
            puts "\ttunnelIdList [keylget statsStatus tunnel_id]"
            puts "\tlspIdList [keylget statsStatus lsp_id]"
            puts "\tlabelList [keylget statsStatus label]"

       } else {
       		puts "\nRSVP statistics for router $router on port $port is not available"
			return
       }
   }
}; #end foreach port

puts "\n******  Tearing down tunnel(s) and Stopping router(s)  ********"
set portIndex 0
foreach port $portlist {
	set device [lindex $devicelist $portIndex] 
	puts "\n***************  Tearing down RSVP tunnels(s) *****************"
    set routeStatus [sth::emulation_rsvp_control     -mode       stop \
                                                     -teardown   $tunnelHandleList($port) \
                                                     -port_handle $hPort($device.$port)]
                                                     
    if {[keylget routeStatus status]==1} {
	    puts "Successfully torn down RSVP tunnels on port $port"
    } else {
	    puts "Unable to tear down RSVP tunnels on port $port: [keylget routeStatus log]"
		return
    }     ;# end if-else statement
	
    puts "\n*****************  Stopping RSVP router(s) *********************"
    set routerStatus [sth::emulation_rsvp_control    -mode       stop \
                                                     -port_handle $hPort($device.$port)]
    if {[keylget routerStatus status]==1} {
	     puts "Successfully stopped RSVP router(s) on port $port"
    } else {
	     puts "Unable to stop RSVP router(s) on port $port"
		 return
    }
	incr portIndex
}  ;# end foreach loop

#Apply the configuration
set controlStatus [sth::test_control -action sync]

puts "\n*********************  Cleaning up ports  **********************"
set portIndex 0
foreach port $portlist {
	set device [lindex $devicelist $portIndex] 
    set intStatus [sth::cleanup_session -port_list $hPort($device.$port)]
    
    if {[keylget intStatus status]==1} {
	    puts "Successfully cleaned up port $port"
    } else {
        puts "Unable to clean up port $port: [keylget intStatus log]"
		return
    }  ;# end if-else statement
	incr portIndex
}   ;# end foreach loop

puts "\n************************  Complete  ****************************"
puts "_SAMPLE_SCRIPT_SUCCESS"


