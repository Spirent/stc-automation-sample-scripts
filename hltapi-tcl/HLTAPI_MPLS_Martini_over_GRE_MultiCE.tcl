####################################################################################################
# 			         																									      						    
# Title : HLTAPI_MPLS_Martini_over_GRE_MultiCE
#
# Test Case : HLTAPI_MPLS_Martini_over_GRE_MultiCE
#
# Purpose : To verify the HLTAPI command "sth::emulation_mpls_l2vpn_pe_config" can work fine.
#
# TestBed : 2 ports connect with DUT
#
# Body :
# Step 1. Connect to a chassis and reserve 2 ports(connect to DUT), config related interfaces.
# Step 2. Set the port1 as the customer side and set the port2 as the provide side.
# Step 3. Config OSPF on port1 and port2, check if the OSPF routers can establish neighbour-ship with DUT.
# Step 4. Config BGP on the provide side OSPF router, check if the BGP routers(PE) can establish IBGP neighbour-ship with DUT.
# Step 5. Config BGP on the customer side OSPF router, check if the BGP router(CE) can establish EBGP neighbour-ship with DUT.
# Step 6. Config LDP on the provide side BGP router, check if the LDP routers(PE) can establish LDP neighbour-ship with DUT.
# Step 7. Config MPLS L2VPN(Martini) PE use the command "sth::emulation_mpls_l2vpn_pe_config" with the BGP/LDP router handles.
# Step 8. Config MPLS L2VPN(Martini) CE use the command "sth::emulation_mpls_l2vpn_site_config" with the BGP/LDP router handles.
# Step 9. Start all the protocols and check if the L2VPN is up.
# Step 10. Create traffic from CE to CE, and start the traffic, and check if the traffic can be transmitted correctly.
#
# Expected Results:
# All the routing protocols can be up.
#
# Test Type: Acceptance
#
# Software Req :   HTAPI package
#
# Revison History : -Even(WuHang) 2009/08/05, PV China Team
#
# Copyright (C) 2009 by Spirent Communciations, Inc.
# All Rights Reserved
#
#
# Topology:
#
#
#loop: 4.4.4.4/32      loop: 220.1.1.1/32          loop:2.2.2.4/32             loop:3.3.3.4/32
#  _                            _                          _                           _
#  |                            |                          |                           |
#  |                            |                          |                           |
#  |                            |                          |                           |
# STC  1/5               13/31 DUT 13/32  GRE-Tunnel  1/6 STC                         STC
# [CE]------------------------[PE]------------------------[PE]------------------------[CE]
#     .11                   .1    .1                   .11    .1                   .11
#            13.31.0.0/16               13.32.0.0/16                 120.1.1.0/24
# BGP1001                     BGP123                     BGP123                      BGP1001
#
##################################################################################################

# Run sample:
#            c:>tclsh HLTAPI_MPLS_Martini_over_GRE_MultiCE.tcl 10.61.44.2 3/1 3/3
#            c:>tclsh HLTAPI_MPLS_Martini_over_GRE_MultiCE.tcl "10.61.44.2 10.61.44.7" 3/1 3/3

package require SpirentHltApi

set devicelist     [lindex $argv 0]
set port1        [lindex $argv 1]
set port2        [lindex $argv 2]
set i 1
foreach device $devicelist {
    set device$i $device
    incr i
}
set device$i $device
set portlist "$port1 $port2"

#######################################################
#Name: TurnOnCapture
#Author: Quinten Pierce
#Purpose: To turn on capture, either Hardware or Cut-Thru for a list of ports
#Input:  Port Handle list, capture type
#Output: fileNameList.  The list of filenames created is returned to the calling procedure/program
#                 Capture is turned on for the ports in the port handle list
#######################################################
proc TurnOnCapture {portHandleList {captureType  "HW"} {fileName "PortNum"}} {
    set captureHndList ""

    foreach portHnd $portHandleList {
        puts "Turn on capture on $portHnd"
        set capture [stc::get $portHnd -children-capture]
        stc::perform CaptureStart -CaptureProxyId $capture
        lappend captureHndList $capture
    }

    return $captureHndList
}   ;# end procedure

#######################################################
#Name: TurnOffCapture
#Author: Quinten Pierce
#Purpose: To turn off capture, and to retrieve the captured frames
#Input:  Port Handle list
#Output: None.  Capture is turned off, and the frames are retrieved
#######################################################
proc TurnOffCapture {portHandleList {fileName CaptureFilePort}} {
    set fileNameList {}
    set count 1;
    foreach portHnd $portHandleList {
        puts "Turn off capture on $portHnd"
        set captureHnd [stc::get $portHnd -children-capture]
        stc::perform CaptureStop -CaptureProxyId $captureHnd
        set name $fileName$count
        puts "Saving capture to $name"
        stc::perform SaveSelectedCaptureData -CaptureProxyId $captureHnd -filename "$name.pcap"
        lappend fileNameList "$name.pcap"
        incr count
    }
    puts "Save file Name list = $fileNameList"
    return $fileNameList
}

#Define global variables
set ipv4AddrList {13.31.0.11 13.32.0.11}
set ipv4GatewayList {13.31.0.1 13.32.0.1}

set macAddrList {00:10:94:00:00:31 00:10:94:00:00:32}
set portMediaTypeList {copper copper}
set portAutoNegList {1 1}
set portSpeedList {ether100 ether100}
set portDuplexList {full full}
set portNetmaskList {255.255.255.0 255.255.255.0}
set hPortlist {}
set streamList {}

#-----------------------OSPF variables
set routerIdList {4.4.4.4 2.2.2.4}

#-----------------------BGP variables
set bgpPrefixList {101.101.1.1 120.1.1.1}
set prefixMask 255.255.255.0
set dutLoopAddr 220.1.1.1

#-----------------------LDP variables
set ldpLabelList {19 39 59 79}
set ldpRouterLenList {16 16 16 16}
set ldpPrefixLenList {24 24 24 24}

#-----------------------VRF variables
set ceAddrList {13.31.0.11 120.1.1.11}

#-----------------------other variables
set passFail PASS
set ret ""
set capture 0
set ratio 0.60
set timeout 10
set DUTIP 10.99.0.191
set dutUserName "spirent"
set dutPassWord "spirent"
set enablePassword "spirent"

#------------------------------------------------step1. Connect and Config ports---------------------------------------------------
puts "\n-------------------------------------------step1. Connect and Config ports-------------------------------------"
set ret [sth::connect -device $devicelist -port_list $portlist]
set returnedString [keylget ret status]

if {$returnedString} {
    #Retrieve port handles for later use
    set hPort($device1,$port1) [keylget ret port_handle.$device1.$port1]
    set hPortlist [concat $hPortlist $hPort($device1,$port1)]
	
	set hPort($device2,$port2) [keylget ret port_handle.$device2.$port2]
    set hPortlist [concat $hPortlist $hPort($device2,$port2)]
} else {
        set passFail FAIL
        puts "\nFailed to retrieve port handle! Error message: $ret"
		return
}

set portIndex 0
foreach port $hPortlist {
	set ret [ sth::interface_config \
                                   -mode              	config \
                                   -port_handle		    $port \
                                   -intf_mode         	ethernet \
                                   -phy_mode            [lindex $portMediaTypeList $portIndex] \
                                   -speed             	[lindex $portSpeedList $portIndex] \
                                   -autonegotiation     [lindex $portAutoNegList $portIndex] \
                                   -duplex            	[lindex $portDuplexList $portIndex]]
    set intStatus [keylget ret status]
    if {!$intStatus} {
        set passFail FAIL
        puts "\nFailed to configure port $port port_handle $port. Message: $ret"
		return
    } else {
        puts "\nSuccessfully configured port $port interface"
    }
    incr portIndex
}


#------------------------------------------------step2. Config the OSPF router---------------------------------------------------
puts "\n-------------------------------------------step2. Config the OSPF router-------------------------------------"
#-Config OSPF on PE router(Provide Side)
set portIndex 1
set port2 [lindex $hPortlist $portIndex]

set ret [sth::emulation_ospf_config \
                                   -mode                   	create \
                                   -port_handle             $port2 \
                                   -session_type           	ospfv2 \
                                   -intf_ip_addr           	[lindex $ipv4AddrList $portIndex] \
                                   -router_id              	[lindex $ipv4AddrList $portIndex] \
                                   -gateway_ip_addr      	[lindex $ipv4GatewayList $portIndex] \
                                   -intf_prefix_length     	16 \
                                   -area_id                	0.0.0.0 \
                                   -router_priority        	12 \
                                   -mac_address_start       [lindex $macAddrList $portIndex]]
set routerStatus [keylget ret status]
if {!$routerStatus} {
    set passFail FAIL
    puts "\nFailed to create OSPF on provide side PE. Message: $ret"
	return
} else {
    set ospfRouterPE [keylget ret handle]
    puts "\nSuccessfully to create OSPF on provide side PE."
}
puts $ospfRouterPE

############################################
# Telnet to DUT to config OSPF protocol
############################################
#EX_TelnetOpen $DUTIP $dutUserName $dutPassWord -timeout 5 -passwordPrompt "Password:" -prompt ">"
#EX_TelnetSendCommand "en" -prompt "Password:"
#EX_TelnetSendCommand $enablePassword -prompt "#"
#EX_TelnetSendCommand "configure terminal"

#EX_TelnetSendCommand "interface gigabitEthernet 13/31"
#EX_TelnetSendCommand "ip ospf network broadcast"
#EX_TelnetSendCommand "interface gigabitEthernet 13/31"
#EX_TelnetSendCommand "ip ospf network broadcast"

#EX_TelnetClose
############################################


#------------------------------------------------step3. Config OSPF IPv4 LSA---------------------------------------------------
puts "\n-------------------------------------------step3. Config OSPF IPv4 LSA-------------------------------------"
#-Create OSPF router LSA on the Provide side
set portIndex 1

set ret [sth::emulation_ospf_lsa_config \
	                                       -mode               	create \
                                           -handle             	$ospfRouterPE \
                                           -type               	router \
                                           -adv_router_id      	[lindex $routerIdList $portIndex] \
                                           -link_state_id       255.255.255.255 \
                                           -router_abr         	0 \
                                           -router_asbr        	1 \
                                           -router_link_mode   	create \
                                           -router_link_type   	stub \
                                           -router_link_id     	[lindex $routerIdList $portIndex] \
                                           -router_link_data   	255.255.255.255 \
                                           -router_link_metric 	1]
set routeStatus [keylget ret status]
if {!$routeStatus} {
    set passFail FAIL
    puts "\nFailed to create OSPF prefix on PE router(Provide Side). Message: $ret"
	return
} else {
    puts "\nSuccessfully to create OSPF prefix on PE router(Provide Side)."
}

#------------------------------------------------step4. Config the LDP router---------------------------------------------------
puts "\n-------------------------------------------step4. Config the LDP router-------------------------------------"
#-Config LDP on PE router(Provide Side)
set routerIndex 1

set ret [sth::emulation_ldp_config \
                                        -mode               create \
                                        -handle             $ospfRouterPE \
                                        -peer_discovery     targeted \
                                        -label_adv          unsolicited \
                                        -label_start 		[lindex $ldpLabelList $routerIndex] \
                                        -intf_ip_addr       [lindex $ipv4AddrList $routerIndex] \
                                        -intf_prefix_length	[lindex $ldpRouterLenList $routerIndex] \
                                        -loopback_ip_addr   [lindex $routerIdList $routerIndex] \
                                        -remote_ip_addr     $dutLoopAddr \
                                        -gateway_ip_addr    [lindex $ipv4GatewayList $routerIndex] \
                                        -lsr_id             [lindex $routerIdList $routerIndex]]
set routerStatus [keylget ret status]
if {!$routerStatus} {
    set passFail FAIL
    puts "\nFailed to create LDP router. Message: $ret"
	return
} else {
    set ldpRouterPE [keylget ret handle]
    puts $ldpRouterPE
    puts "\nSuccessfully to create LDP router."
}

#------------------------------------------------step5. Config LSP IPv4 Prefix---------------------------------------------------
puts "\n-------------------------------------------step5. Config LSP IPv4 Prefix-------------------------------------"
#-Create LSP on PE router(Provide Side)
set routerIndex 1

set ret [sth::emulation_ldp_route_config \
	                                 -mode 			        create \
                                     -handle 				$ldpRouterPE \
                                     -fec_type 			    ipv4_prefix \
                                     -fec_ip_prefix_start 	[lindex $bgpPrefixList $routerIndex] \
                                     -fec_ip_prefix_length 	[lindex $ldpPrefixLenList $routerIndex] \
                                     -num_lsps 			    1]
set lspStatus [keylget ret status]
if {!$lspStatus} {
    set passFail FAIL
    puts "\nFailed to create LDP prefix. Message: $ret"
	return
} else {
    puts "\nSuccessfully to create LDP prefix."
}


#------------------------------------------------step6. Config GRE Tunnel---------------------------------------------------
puts "\n-------------------------------------------step6. Config GRE Tunnel-------------------------------------"
#-Create GRE Tunnel on PE router(Provide Side)
set routerIndex 1

set tunnelStatus [sth::emulation_gre_config \
                                     -gre_tnl_type         4 \
                                     -gre_tnl_addr         2.2.2.4 \
                                     -gre_tnl_addr_step    0.0.0.1 \
                                     -gre_tnl_addr_count   1 \
                                     -gre_src_mode         increment \
                                     -gre_src_addr         13.32.0.11 \
                                     -gre_src_addr_step    0.0.0.1 \
                                     -gre_src_addr_count   1 \
                                     -gre_dst_mode         increment \
                                     -gre_dst_addr         13.32.0.1 \
                                     -gre_dst_addr_step    0.0.0.1 \
                                     -gre_dst_addr_count   1]
if {$tunnelStatus == ""} {
    set passFail FAIL
    puts "\nFailed to create GRE Tunnel. Message: $ret"
	return
} else {
    puts "\nSuccessfully to create GRE Tunnel."
    set greTunnel $tunnelStatus
}

#------------------------------------------------step7. Start LDP router---------------------------------------------------
puts "\n-------------------------------------------step7. Start LDP router-------------------------------------"

set ret [sth::emulation_ldp_control -mode start -handle $ldpRouterPE]
set startStatus [keylget ret status]

#------------------------------------------------step8. Config L2VPN PE---------------------------------------------------
puts "\n-------------------------------------------step8. Config L2VPN PE-------------------------------------"
#-Config PE router(Provide Side)
set portIndex 1
set port2 [lindex $hPortlist $portIndex]


set ret [ sth::emulation_mpls_l2vpn_pe_config \
                                           -mode                 enable \
                                           -port_handle          $port2 \
                                           -vpn_type             martini_pwe \
                                           -igp_session_handle   $ospfRouterPE \
                                           -tunnel_handle        $greTunnel \
                                           -targeted_ldp_session_handle $ldpRouterPE\
                                           -pe_count             1]
set PeStatus [keylget ret status]
if {!$PeStatus} {
    set passFail FAIL
    puts "\nFailed to create PE. Message: $ret"
	return
} else {
    puts "\nSuccessfully to create PE."
    set vpnRouterPE [keylget ret handle]
    puts $vpnRouterPE
}

#------------------------------------------------step9. Create CE site---------------------------------------------------
puts "\n-------------------------------------------step9. Create CE site-------------------------------------"
#-Create CE site on Customer Side
set portIndex 0
set routerIndex 0
set port1 [lindex $hPortlist $portIndex]

set ret [ sth::emulation_mpls_l2vpn_site_config \
                                           -mode                  create \
                                           -port_handle           $port1 \
                                           -pe_loopback_ip_addr   $dutLoopAddr \
                                           -pe_loopback_ip_step   0.0.0.0 \
                                           -pe_loopback_ip_prefix 32 \
                                           -site_count            1 \
                                           -vc_id                 1500 \
                                           -vpn_id                100]
set CeStatus [keylget ret status]
if {!$CeStatus} {
    set passFail FAIL
    puts "\nFailed to create CE on custorm side. Message: $ret"
	return
} else {
    puts "\nSuccessfully to create CE on custorm side."
    set ceCustomSide [keylget ret handle]
}

#-Create CE site on Provide Side
set portIndex 1
set routerIndex 1
set port2 [lindex $hPortlist $portIndex]

set ret [sth::emulation_mpls_l2vpn_site_config \
                                          -mode                  create \
                                          -port_handle           $port2 \
                                          -pe_handle             $vpnRouterPE \
                                          -pe_loopback_ip_addr   [lindex $routerIdList $routerIndex] \
                                          -pe_loopback_ip_step   0.0.0.0 \
                                          -pe_loopback_ip_prefix 32 \
                                          -site_count            1 \
                                          -vpn_type              martini_pwe \
                                          -vc_id                 1500 \
                                          -vpn_id                100 \
                                          -vlan_id               1701]
set CeStatus [keylget ret status]
if {!$CeStatus} {
    set passFail FAIL
    puts "\nFailed to create CE behind provide side PE. Message: $ret"
	return
} else {
    puts "\nSuccessfully to create CE behind provide side PE."
    set ceProvideSide [keylget ret handle]
}

#------------------------------------------------step10. Create L2VPN Traffic---------------------------------------------------
puts "\n-------------------------------------------step10. Create L2VPN Traffic-------------------------------------"
set port1 [lindex $hPortlist 0]
set port2 [lindex $hPortlist 1]

#- Create traffic from ceCustomSide to ceProvideSide
set ret [sth::traffic_config \
                                   -mode                  create \
                                   -port_handle           $port1 \
                                   -length_mode           fixed \
                                   -l3_length             256 \
                                   -emulation_src_handle  $ceCustomSide \
                                   -emulation_dst_handle  $ceProvideSide \
                                   -rate_pps              10]
set TrafficStatus [keylget ret status]
if {!$TrafficStatus} {
    set passFail FAIL
    puts "\nFailed to create traffic. Message: $ret"
	return
} else {
    puts "\nSuccessfully to create traffic."
}

#- Create traffic from ceProvideSide to ceCustomSide
set ret [ sth::traffic_config \
                                   -mode                  create \
                                   -port_handle           $port2 \
                                   -length_mode           fixed \
                                   -l3_length             256 \
                                   -emulation_src_handle  $ceProvideSide \
                                   -emulation_dst_handle  $ceCustomSide \
                                   -rate_pps              10]
set TrafficStatus [keylget ret status]
if {!$TrafficStatus} {
    set passFail FAIL
    puts "\nFailed to create traffic. Message: $ret"
	return
} else {
    puts "\nSuccessfully to create traffic."
}

#config parts are finished

#------------------------------------------------step11. Start OSPF router---------------------------------------------------
puts "\n-------------------------------------------step11. Start OSPF router-------------------------------------"

set ret [sth::emulation_ospf_control -mode start -handle $ospfRouterPE]
set startStatus [keylget ret status]
puts "------------>wait for 20sec..."
after 20000


############################################
# Telnet to DUT to config OSPF protocol
############################################
#EX_TelnetOpen $DUTIP $dutUserName $dutPassWord -timeout 5 -passwordPrompt "Password:" -prompt ">"
#EX_TelnetSendCommand "en" -prompt "Password:"
#EX_TelnetSendCommand $enablePassword -prompt "#"
#EX_TelnetSendCommand "configure terminal"

#EX_TelnetSendCommand "interface gigabitEthernet 13/32"
#EX_TelnetSendCommand "mpls label protocol ldp"
#EX_TelnetSendCommand "mpls ip"

#EX_TelnetClose
############################################

############################################
# Telnet to DUT to config OSPF protocol
############################################
#EX_TelnetOpen $DUTIP $dutUserName $dutPassWord -timeout 5 -passwordPrompt "Password:" -prompt ">"
#EX_TelnetSendCommand "en" -prompt "Password:"
#EX_TelnetSendCommand $enablePassword -prompt "#"
#EX_TelnetSendCommand "configure terminal"

#EX_TelnetSendCommand "interface Tunnel112"
#EX_TelnetSendCommand "ip unnumbered Loopback1"
#EX_TelnetSendCommand "tag-switching ip"
#EX_TelnetSendCommand "tunnel source 13.32.0.1"
#EX_TelnetSendCommand "tunnel destination 13.32.0.11"
#EX_TelnetSendCommand "mpls ip"

#EX_TelnetClose
############################################

############################################
# Telnet to DUT to config OSPF protocol
############################################
#EX_TelnetOpen $DUTIP $dutUserName $dutPassWord -timeout 5 -passwordPrompt "Password:" -prompt ">"
#EX_TelnetSendCommand "en" -prompt "Password:"
#EX_TelnetSendCommand $enablePassword -prompt "#"
#EX_TelnetSendCommand "configure terminal"

#EX_TelnetSendCommand "interface gigabitEthernet 13/31"
#EX_TelnetSendCommand "ip vrf forwarding vpn123"
#EX_TelnetSendCommand "ip address 13.31.0.1 255.255.0.0"

#EX_TelnetClose
############################################

#------------------------------------------------step12. Start/Stop Traffic---------------------------------------------------
puts "\n-------------------------------------------step12. Start/Stop Traffic-------------------------------------"
# - Start Capture
TurnOnCapture $hPortlist "CT"

set ret [ sth::traffic_control -action run -port_handle "all"]
set ret [keylget ret status]
puts "Wait for 10sec..."
after 10000

set ret [sth::traffic_control -action stop -port_handle "all"]
set ret [keylget ret status]
TurnOffCapture $hPortlist


#------------------------------------------------step13. Check the Tx/Rx---------------------------------------------------
puts "\n-------------------------------------------step13. Check the Tx/Rx-------------------------------------"
foreach port $hPortlist {
	set ret [sth::interface_stats	-port_handle	$port]
	set info [keylget ret status]										
	if {! $info} {
			puts "Failed to get interface info on $port"
			set passFail FAIL
			return
	} else {
			puts "Interface info of $port has been got successfully."
			
			set Rx($port) [keylget ret rx_sig_count]
			set Tx($port) [keylget ret tx_generator_sig_frame_count]
			puts "Rx on $port:------------------------$Rx($port)"
			puts "Tx on $port:------------------------$Tx($port)"
	}
}

set port1 [lindex $hPortlist 0]
set port2 [lindex $hPortlist 1]

if {$Rx($port2) >= [expr 0.8 * $Tx($port1)]} {
    puts "\nThe Rx on $port2 is equal to Tx on $port1."
} else {
    set passFail FAIL
    puts "\nPackets lost!"
	return
}


#------------------------------------------------step14. Check the Packets---------------------------------------------------
puts "\n-------------------------------------------step14. Check the Packets-------------------------------------"


puts $passFail

puts "_SAMPLE_SCRIPT_SUCCESS"



