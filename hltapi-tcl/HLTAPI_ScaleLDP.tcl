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
# File Name:                 HLTAPI_ScaleLDP.tcl
#
# Description:               This script demonstrates the use of Spirent HLTAPI to setup 250 LDP routers on each port (2 ports) with 1 LSP on each router.
#################################

# Run sample:
#            c:>tclsh HLTAPI_ScaleLDP.tcl 10.61.44.2 3/1 3/3
#            c:>tclsh HLTAPI_ScaleLDP.tcl "10.61.44.2 10.61.44.7" 3/1 3/3

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
set portMediaTypeList {fiber fiber} 
set portAutoNegList {1 1} 
set portSpeedList {ether1000 ether1000} 
set portDuplexList {full full}  
set ldpIpv4AddrList {11.1.1.2 11.1.10.2} 
set ldpSUTIpv4AddrList {11.1.10.2 11.1.1.2} 
set ldpLabelList {16 300} 
set ldpFecPrefixAddrList {140.0.1.0 140.1.1.0}

#Turn off implicit Apply internally
set controlStatus [sth::test_control -action enable]

#Connecting to chassis
puts "\n*****************  Connecting to the chassis *****************"
set chassConnect [sth::connect -device $devicelist -timeout $timeout -port_list $portlist]

if {[keylget chassConnect status]==1} {
	puts "Successfully connected to chassis $devicelist"
} else {
	puts "<error>Unable to connect to chassis $devicelist: [keylget chassConnect log]"
	return
} 

#Configuring port interface
    set hPort($device1.$port1) [keylget chassConnect port_handle.$device1.$port1]
    set hPortlist [concat $hPortlist $hPort($device1.$port1)]
    set hPort($device2.$port2) [keylget chassConnect port_handle.$device2.$port2]
    set hPortlist [concat $hPortlist $hPort($device2.$port2)]    
    puts "\n*****************  Configuring port interface ****************"
set portIndex 0
foreach porthnd $hPortlist {
    set intStatus [sth::interface_config   -port_handle       $porthnd \
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
        puts "Successfully configured port $porthnd interface"
    } else {
	    puts "<error>Unable to configure port $porthnd interface: [keylget intStatus log]"
		return
    }
    incr portIndex
}

puts "\n**************  Port Configuration is Complete  **************"

puts "\n*************  Configuring LDP router parameters  ************"
#Configuring LDP direct session parameters
set portIndex 0
foreach porthnd $hPortlist {
    set routerStatus [sth::emulation_ldp_config   \
                             	-mode                   create \
                             	-port_handle            $porthnd \
                             	-peer_discovery         link \
                             	-label_adv              unsolicited \
                             	-label_start            [lindex $ldpLabelList $portIndex] \
                             	-count                  250 \
                                -intf_ip_addr           [lindex $ldpIpv4AddrList $portIndex] \
                                -intf_ip_addr_step      0.0.0.1 \
                                -intf_prefix_length		16 \
                                -gateway_ip_addr        [lindex $ldpSUTIpv4AddrList $portIndex] \
                                -gateway_ip_addr_step   0.0.0.1 \
                                -remote_ip_addr			[lindex $ldpSUTIpv4AddrList $portIndex] \
                                -remote_ip_addr_step	0.0.0.1 \
                                -lsr_id					[lindex $ldpIpv4AddrList $portIndex] \
                                -lsr_id_step            0.0.0.1 \
                                -hello_interval			5 \
                                -keepalive_interval		60]

                                
     if {[keylget routerStatus status] == 1} {
	     set hLDPRouter($porthnd) [keylget routerStatus handle]
	     puts "Successfully created LDP router(s) on port $porthnd"
	     puts "Handle for LDP router(s) on $porthnd is $hLDPRouter($porthnd)"
     } else {
	     puts "<error>Unable to configure LDP router(s) on port $porthnd: [keylget routerStatus log]"
		 return
     }
     incr portIndex
}

puts "\n*************  LDP Router Configuration Complete  *************"

puts "\n*****************  Creating LSP IPv4 Prefix  ******************"
#Create 1 LSP IPv4 Prefix on each router
set portIndex 0
foreach port $hPortlist {
	set ipPrefix [lindex $ldpFecPrefixAddrList $portIndex]
	foreach router $hLDPRouter($port) {
		set routeStatus [sth::emulation_ldp_route_config     \
                                       	-mode               	create \
                                        -handle             	$router \
                                        -fec_type				ipv4_prefix \
                                        -fec_ip_prefix_start	$ipPrefix \
                                        -fec_ip_prefix_length	24 \
                                        -num_lsps				1 \
                                        -label_msg_type			mapping]
                                        
                                        
    	if {[keylget routeStatus status]==1} {
	    	set hLsp($port.$router) [keylget routeStatus lsp_handle]
	    	puts "Successfully configured LSP $ipPrefix on $router"
	    	puts "Handle for LDP LSP on $router is $hLsp($port.$router)\n"
    	} else {
	    	puts "<error>Unable to configure LDP LSP on $router: [keylget routeStatus log]"
			return
    	}
    	set ipPrefix [incrementIpV4Address $ipPrefix 0.0.1.0]
	}; #end router loop
	incr portIndex
}; #end port loop

#config parts are finished

#Apply the configuration
set controlStatus [sth::test_control -action sync]
       
puts "\n****************  LSP Configuration Complete  ****************"

puts "\n********************  Staring LDP routers ********************"
#Start LDP routers
foreach port $hPortlist {
    set startStatus [sth::emulation_ldp_control     -mode       start \
                                              		-handle     $hLDPRouter($port)]
    
    if {[keylget startStatus status]==1} {
	    puts "Successfully started LDP router(s) on port $port"
    } else {
	    puts "<error>Unable to start LDP router(s) on port $port: [keylget startStatus log]"
		return
    }
}

puts "\n*****************  Wait for LDP to come up  ******************"
stc::sleep 120

puts "\n***************  Checking LDP router(s) info *****************"
puts "\n*************************  Mode state ************************"
foreach port $hPortlist {
	foreach router $hLDPRouter($port) {
        set statsStatus [sth::emulation_ldp_info    -mode           state \
                                                    -handle         $router]
                                                     
        if {[keylget statsStatus status]==1} {
            puts "\nPort $port, LDP $router"
            puts "\tState 	:[keylget statsStatus session_state]"
        } else {
            puts "\n<error>LDP statistics for $router on port $port is not available"
			return
        }
    }
}
puts "\n*************************  Mode stats ************************"
foreach port $hPortlist {
	foreach router $hLDPRouter($port) {
        set statsStatus [sth::emulation_ldp_info    -mode           stats \
                                                    -handle         $router]
                                                     
        if {[keylget statsStatus status]==1} {
            puts "\nPort $port, LDP $router"
            puts "\tLDP router     :[keylget statsStatus ip_address]"
            puts "\tnumLSPsSetup   :[keylget statsStatus num_lsps_setup]"
            puts "\tTx Hello       :[keylget statsStatus linked_hellos_tx]"
            puts "\tRx_Hello       :[keylget statsStatus linked_hellos_rx]"
            puts "\tTx Withdraw    :[keylget statsStatus withdraw_tx]"
            puts "\tRx_Withdraw    :[keylget statsStatus withdraw_rx]"
            puts "\tTx Notify      :[keylget statsStatus notif_tx]"
            puts "\tRx_Notify      :[keylget statsStatus notif_rx]"
        } else {
            puts "\n<error>LDP statistics for $router on port $port is not available"
			return
        }
    }
}

puts "\n*******************  Stopping LDP routers  ******************"
#Stop LDP routers
foreach port $hPortlist {
    set stopStatus [sth::emulation_ldp_control     -mode       stop \
                                              	   -handle     $hLDPRouter($port)]
    
    if {[keylget stopStatus status]==1} {
	    puts "Successfully stopped LDP router(s) on port $port"
    } else {
	    puts "<error>Unable to stop LDP router(s) on port $port: [keylget stopStatus log]"
		return
    }
}

puts "\n********************  Cleaning up ports  ********************"
set portIndex 0
foreach port $hPortlist {
    set intStatus [sth::cleanup_session -port_list $port]
    
    if {[keylget intStatus status]==1} {
	    puts "Successfully cleaned up port $port"
    } else {
        puts "<error>Unable to clean up port $port: [keylget intStatus log]"
		return
    }  ;# end if-else statement
}   ;# end foreach loop

puts "\n***********************  Complete  **************************"

puts "_SAMPLE_SCRIPT_SUCCESS"

