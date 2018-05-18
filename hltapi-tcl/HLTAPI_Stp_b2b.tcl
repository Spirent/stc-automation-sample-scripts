
#################################
#
# File Name:         HLTAPI_Stp_b2b.tcl
#
# Description:       This script demonstrates the use of Spirent HLTAPI to setup STP devices
#
# Test Step:         1. Reserve and connect chassis ports
#                    2. Interface config
#                    3. Config STP
#                    4. Modify STP
#                    5. Start STP
#                    6. Check STP stats
#                    7. Stop STP
#                    8. Release resources
#
# DUT configuration:
#           none
#
# Topology
#                 STC Port1                    STC Port2                       
#                 stp device----------------  stp device
#                        
#                                         
#
#################################

# Run sample:
#            c:>tclsh HLTAPI_Stp_b2b.tcl 10.61.44.2 3/1 3/3
#            c:>tclsh HLTAPI_Stp_b2b.tcl "10.61.44.2 10.61.44.7" 3/1 3/3

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

set enableHltLog 1
if {$enableHltLog} {
    ::sth::test_config  -logfile hltLogfile \
                        -log 1\
                        -vendorlogfile stcExport\
                        -vendorlog 1\
                        -hltlog 1\
                        -hltlogfile hltExport\
                        -hlt2stcmappingfile hlt2StcMapping \
                        -hlt2stcmapping 1\
                        -log_level 7
}	

set bridgePriority   {8192 4096}
set bridgeMacAddress  {00:00:10:00:00:00 00:00:11:00:00:00}
set portPri            {16 16}
set portNum             {2 3}
set rootbridgeType       {"custom" "self"}
set rootPri        {4096 4096}
set rootMacAddress     {00:00:00:00:00:01 00:00:11:00:00:00}
set rootPathCost       {50 0}
set srcMacAddressList  {00:10:94:00:00:31 00:10:94:00:00:33}
set ipv4AddressList {1.1.1.1 1.1.1.2}
set ipv4GatewayList {1.1.1.2 1.1.1.1}

########################################
#Step1: Reserve and connect chassis ports
########################################

puts "Reserve and connect chassis ports"

set returnedString [sth::connect -device $device_list -port_list $port_list]

keylget returnedString status status
if {!$status} {
puts $returnedString
    return "  FAILED:  $status"
}

keylget returnedString port_handle.$device2.$port2 hltHostPort
keylget returnedString port_handle.$device1.$port1 hltSourcePort

set portList "$hltSourcePort $hltHostPort"

########################################
# Step2: Interface config
########################################

puts "Interface config"
set i 0
foreach port $portList {
    set returnedString [sth::interface_config	-mode config \
                            -port_handle        $port \
                            -intf_mode          "ethernet" \
                            -phy_mode           "copper" \
                            -speed 	        "ether1000" \
                            -autonegotiation	1 \
                            -duplex		"full" \
			    -src_mac_addr       [lindex $srcMacAddressList $i] \
			    -intf_ip_addr       [lindex $ipv4AddressList $i] \
			    -gateway            [lindex $ipv4GatewayList $i] \
			    -netmask            255.255.255.0 \
                            -arp_send_req       1 ]
    
    keylget returnedString status status
    if {!$status} {
	puts $returnedString
        return "  FAILED:  $returnedString"
    }
    incr i
	
}

########################################
# Step3: Config stp 
########################################
set i 0
set stpHdlList ""
foreach port $portList {
    set returnedString [sth::emulation_stp_config  -port_handle      $port \
		    -mode  create\
		    -stp_type                     "stp" \
		    -bridge_priority            [lindex $bridgePriority $i] \
		    -bridge_mac_address         [lindex $bridgeMacAddress $i] \
		    -port_priority              [lindex $portPri $i] \
		    -port_number              [lindex $portNum $i] \
		    -root_bridge_type       [lindex $rootbridgeType $i] \
		    -root_priority           [lindex $rootPri $i] \
		    -root_mac_address     [lindex $rootMacAddress $i] \
		    -root_path_cost       [lindex $rootPathCost $i]]
    
    keylget returnedString status status
    if {!$status} {
	puts $returnedString
        return "  FAILED:  $returnedString"
    } else {
	keylget returnedString handle deviceHdl
    }
    lappend stpHdlList $deviceHdl
    incr i
}

set stpHdl1 [lindex $stpHdlList 0]
set stpHdl2 [lindex $stpHdlList 1]

########################################
# Step4: Modify stp 
########################################
set returnedString [sth::emulation_stp_config  -handle      $stpHdl2 \
		-mode  modify\
		-port_priority              64 ]
keylget returnedString status status
if {!$status} {
puts $returnedString
    return "  FAILED:  $returnedString"
} else {
    keylget returnedString handle deviceHdl
}

stc::perform SaveasXml -config system1 -filename    "./HLTAPI_stp.xml"
#config parts are finished

########################################
# Step5: Start stp 
########################################
set returnedString [sth::emulation_stp_control  -port_handle      $portList \
			-action start]
keylget returnedString status status
if {!$status} {
    puts"  FAILED:  $returnedString"
	return
}

after 60000

########################################
# Step6: Check stp stats
########################################
set returnedString [sth::emulation_stp_stats  -port_handle      $portList \
                            -mode  "both"]
keylget returnedString status status
if {!$status} {
puts $returnedString
    return "  FAILED:  $returnedString"
}

# check the rood id
keylget returnedString stp.$stpHdl1.root_id rootId1
keylget returnedString stp.$stpHdl2.root_id rootId2
if { $rootId1 == $rootId2 && $rootId2 != "NA"} {
    puts "$stpHdl1 and $stpHdl2 have the same root id."
} else {
puts "FAILED:  $stpHdl1 and $stpHdl2 don't have the same root id."
    return "  FAILED:  $stpHdl1 and $stpHdl2 don't have the same root id."
}


# check if tx_bpdus equals to rx_bpdus
keylget returnedString stp.$stpHdl1.rx_bpdus rxBpdus1
keylget returnedString stp.$stpHdl1.tx_bpdus txBpdus1
keylget returnedString stp.$stpHdl2.rx_bpdus rxBpdus2
keylget returnedString stp.$stpHdl2.tx_bpdus txBpdus2

if { !($rxBpdus1 > [expr $txBpdus2 - 5] && $rxBpdus1 < [expr $txBpdus2 + 5] && $rxBpdus2 > [expr $txBpdus1 - 5] && $rxBpdus2 < [expr $txBpdus1 + 5])} {
    # because of timing issue, the count of sent and received bpdus may have a smaller difference
	puts "FAILED:  $stpHdl1 and $stpHdl2 don't have the same tx and rx bpdus."
    return "  FAILED:  $stpHdl1 and $stpHdl2 don't have the same tx and rx bpdus."
}

# check designated_bridge_id
keylget returnedString stp.$stpHdl1.designated_bridge_id  designatedBridgeId1
keylget returnedString stp.$stpHdl2.designated_bridge_id  designatedBridgeId2
if { $designatedBridgeId1 == $designatedBridgeId2 && $designatedBridgeId2 != "NA"} {
    puts "$stpHdl1 and $stpHdl2 have the same designated_bridge_id."
} else {
puts "FAILED:  $stpHdl1 and $stpHdl2 don't have the same designated_bridge_id."
    return "  FAILED:  $stpHdl1 and $stpHdl2 don't have the same designated_bridge_id."
}

# check the port role state
keylget returnedString stp.$stpHdl1.tx_port_state txPortState1
keylget returnedString stp.$stpHdl2.tx_port_state txPortState2
if { $txPortState1 == "Forwarding" && $txPortState2 == "Forwarding" } {
    puts "The port on the $stpHdl1 and $stpHdl2 have been in the forwarding stats."
} elseif { $txPortState1 == "NONE" || $txPortState2 == "NONE" } {
puts "FAILED:  The port on the $stpHdl1 and $stpHdl2 have an incorrect stats."
     return "  FAILED:  The port on the $stpHdl1 and $stpHdl2 have an incorrect stats."
}

########################################
# Step7: Stop stp 
########################################
set returnedString [sth::emulation_stp_control  -port_handle      $portList \
			-action stop]
keylget returnedString status status
if {!$status} {
puts $returnedString
    return "  FAILED:  $returnedString"
}


########################################
#step8: Release resources
########################################
set returnedString [::sth::cleanup_session -port_list $portList]

keylget returnedString status status
if {!$status} {
puts $returnedString
    return "  FAILED:  $returnedString"
}

puts "_SAMPLE_SCRIPT_SUCCESS"
puts "\n test over"

exit