
#################################
#
# File Name:         HLTAPI_Mstp_b2b.tcl
#
# Description:       This script demonstrates the use of Spirent HLTAPI to setup MSTP devices
#
# Test Step:         1. Reserve and connect chassis ports
#                    2. Interface config
#                    3. Config MSTP
#                    4. Modify MSTP
#                    5. Create MSTP Region
#                    6. Modify Msti
#                    7. Start MSTP
#                    8. Check MSTP stats
#                    9. Stop MSTP
#                    10. Release resources
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
#            c:>tclsh HLTAPI_Mstp_b2b.tcl 10.61.44.2 3/1 3/3
#            c:>tclsh HLTAPI_Mstp_b2b.tcl "10.61.44.2 10.61.44.7" 3/1 3/3

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
set portPri            {16 64}
set portNum             {2 3}
set rootbridgeType       {"self" "self"}
set rootPri        {4096 4096}
set rootMacAddress     {00:00:00:00:00:01 00:00:11:00:00:00}
set rootPathCost       {50 0}
set srcMacAddressList  {00:10:94:00:00:31 00:10:94:00:00:33}
set regionRootBridgeType {"custom" "custom"}
set ipv4AddressList {1.1.1.1 1.1.1.2}
set ipv4GatewayList {1.1.1.2 1.1.1.1}

########################################
#Step1: Reserve and connect chassis ports
########################################

puts "Reserve and connect chassis ports"
set returnedString [sth::connect -device $device_list -port_list $port_list -username currentport ]

keylget returnedString status status
if {!$status} {
	puts $returnedString
    puts "  FAILED:  $status"
	return
}

keylget returnedString port_handle.$device2.$port2 hltHostPort
keylget returnedString port_handle.$device1.$port1 hltSourcePort
set portList "$hltHostPort $hltSourcePort"

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
        puts "  FAILED. "
		return
    }
    incr i	
}

########################################
# Step3: Config mstp 
########################################
set i 0
set stpHdlList ""
foreach port $portList {
    set returnedString [sth::emulation_stp_config  -port_handle      $port \
                                -mode  create\
                                -stp_type                     "mstp"\
                                -bridge_priority            [lindex $bridgePriority $i] \
				-bridge_mac_address         [lindex $bridgeMacAddress $i] \
				-port_priority              [lindex $portPri $i] \
				-port_number              [lindex $portNum $i] \
                                -root_bridge_type         [lindex $rootbridgeType $i] \
                                -region_root_priority         [lindex $rootPri $i] \
                                -region_root_mac_address      [lindex $rootMacAddress $i] \
                                -region_root_path_cost        [lindex $rootPathCost $i]\
                                -region_root_bridge_type      [lindex $regionRootBridgeType $i]]
    keylget returnedString status status
    if {!$status} {
		puts $returnedString
        puts "  FAILED. "
		return
    } else {
        keylget returnedString handle deviceHdl
        puts "PASSED for $port in function emulation_stp_config"
    }
    lappend stpHdlList $deviceHdl
    
    incr i
}

set stpHdl1 [lindex $stpHdlList 0]
set stpHdl2 [lindex $stpHdlList 1]

########################################
# Step4: Modify mstp 
########################################

set returnedString [sth::emulation_stp_config  -handle      $stpHdl2 \
		-mode  modify\
		-port_priority              64\
		-region_root_bridge_type "self"]
keylget returnedString status status
if {!$status} {
puts $returnedString
    puts "  FAILED. "
	return
}

########################################
# Step5: Create mstp region
########################################
set returnedString [sth::emulation_mstp_region_config  -port_handle      $portList\
                                -mode  create\
                                -mstp_region_name           "reg1"\
                                -mstp_instance_count          2\
                                -mstp_instance_num_list       {2 5}\
                                -mstp_instance_vlan_list      {1-2 3-5}]
keylget returnedString status status
if {!$status} {
puts $returnedString
    puts "  FAILED. "
	return
} else {
    keylget returnedString reg_handle mstpRegionHdl
    keylget returnedString msti_handle mstiHdlList
    puts "PASSED for $portList in function emulation_mstp_region_config"
}
        
########################################
# Step6: Modify msti
########################################
set returnedString [sth::emulation_msti_config  -port_handle      port2\
			    -mstp_region_name           "reg1"\
			    -msti_instance_num            5\
			    -msti_port_priority           64\
			    -msti_root_bridge_type        "custom"\
			    -msti_region_root_priority       4096\
			    -msti_remaining_hops           32]
keylget returnedString status status
if {!$status} {
puts $returnedString
    puts "  FAILED. "
	return
} else {
    keylget returnedString handle mstiHdl
    puts "PASSED for port2 in function emulation_msti_config"
}

stc::perform SaveasXml -config system1 -filename    "./HLTAPI_mstp.xml"
#config parts are finished

########################################
# Step7: Start mstp
########################################
set returnedString [sth::emulation_stp_control  -port_handle      $portList \
			-action start]
keylget returnedString status status
if {!$status} {
puts $returnedString
    puts "  FAILED. "
	return
}

stc::sleep 60

########################################
# Step8: Check mstp stats
########################################
set returnedString [sth::emulation_stp_stats  -port_handle      $portList \
                            -mode  "both"]
keylget returnedString status status
if {!$status} {
puts $returnedString
    puts "  FAILED. "
	return
}

#### check stp stats ####
# check the rood id
keylget returnedString stp.$stpHdl1.root_id rootId1
keylget returnedString stp.$stpHdl2.root_id rootId2
if { $rootId1 == $rootId2 && $rootId2 != "00-00-00-00-00-00-00-00"} {
    puts "$stpHdl1 and $stpHdl2 have the same root id."
} else {
	puts "  FAILED:  $stpHdl1 and $stpHdl2 don't have the same root id."
    return
}

# check if tx_bpdus equals to rx_bpdus
keylget returnedString stp.$stpHdl1.rx_bpdus rxBpdus1
keylget returnedString stp.$stpHdl1.tx_bpdus txBpdus1
keylget returnedString stp.$stpHdl2.rx_bpdus rxBpdus2
keylget returnedString stp.$stpHdl2.tx_bpdus txBpdus2

if { !($rxBpdus1 > [expr $txBpdus2 - 5] && $rxBpdus1 < [expr $txBpdus2 + 5] && $rxBpdus2 > [expr $txBpdus1 - 5] && $rxBpdus2 < [expr $txBpdus1 + 5])} {
    # because of timing issue, the count of sent and received bpdus may have a smaller difference
	puts "  FAILED:  $stpHdl1 and $stpHdl2 don't have the same tx and rx bpdus."
    return "  FAILED:  $stpHdl1 and $stpHdl2 don't have the same tx and rx bpdus."
}

# check designated_bridge_id
keylget returnedString stp.$stpHdl1.designated_bridge_id  designatedBridgeId1
keylget returnedString stp.$stpHdl2.designated_bridge_id  designatedBridgeId2
if { $designatedBridgeId1 == $designatedBridgeId2 && $designatedBridgeId2 != "NA"} {
    puts "$stpHdl1 and $stpHdl2 have the same designated_bridge_id."
} else {
	puts "  FAILED:  $stpHdl1 and $stpHdl2 don't have the same designated_bridge_id."
    return
}

# check the port role state
keylget returnedString stp.$stpHdl1.tx_port_state   txPortState1
keylget returnedString stp.$stpHdl2.tx_port_state   txPortState2
if { $txPortState1 == "Forwarding" && $txPortState2 == "Forwarding" } {
    puts "The port on the $stpHdl1 and $stpHdl2 have been in the forwarding stats."
} elseif { $txPortState1 == "NONE" || $txPortState2 == "NONE" } {
	puts "  FAILED:  The port on the $stpHdl1 and $stpHdl2 have an incorrect stats."
    return
}


#### check msti stats ####
# get the result handle for each device handle
set mstiResultsList1 ""
set bridgePortCfg1 [::sth::sthCore::doStcGetNew $stpHdl1 -children-BridgePortConfig]
set mstpBridgePortCfg1 [::sth::sthCore::doStcGetNew $bridgePortCfg1 -children-MstpBridgePortConfig]
set mstiCfgList1 [::sth::sthCore::doStcGetNew $mstpBridgePortCfg1 -children-MstiConfig]
foreach mstiCfg1 $mstiCfgList1 {
    set mstiResults1 [::sth::sthCore::doStcGetNew $mstiCfg1 -children-BridgePortResults]
    lappend mstiResultsList1 $mstiResults1
}

set mstiResult1_1 [lindex $mstiResultsList1 0]
set mstiResult1_2 [lindex $mstiResultsList1 1]

set mstiResultsList2 ""
set bridgePortCfg2 [::sth::sthCore::doStcGetNew $stpHdl2 -children-BridgePortConfig]
set mstpBridgePortCfg2 [::sth::sthCore::doStcGetNew $bridgePortCfg2 -children-MstpBridgePortConfig]
set mstiCfgList2 [::sth::sthCore::doStcGetNew $mstpBridgePortCfg2 -children-MstiConfig]
foreach mstiCfg2 $mstiCfgList2 {
    set mstiResults2 [::sth::sthCore::doStcGetNew $mstiCfg2 -children-BridgePortResults]
    lappend mstiResultsList2 $mstiResults2
}

set mstiResult2_1 [lindex $mstiResultsList2 0]
set mstiResult2_2 [lindex $mstiResultsList2 1]

# check the instance number
keylget returnedString msti.$stpHdl1.$mstiResult1_1.instance_num instanceNum1_1
keylget returnedString msti.$stpHdl1.$mstiResult1_2.instance_num instanceNum1_2
keylget returnedString msti.$stpHdl2.$mstiResult2_1.instance_num instanceNum2_1
keylget returnedString msti.$stpHdl2.$mstiResult2_2.instance_num instanceNum2_2

set instanceList "$instanceNum1_1 $instanceNum1_2 $instanceNum2_1 $instanceNum2_2"
foreach instanceNum $instanceList {
    if { $instanceNum == 2 || $instanceNum == 5 } {
	continue
    } else {
	puts "  FAILED:  $stpHdl1 and $stpHdl2 have incorrect inistance number for msti."
	return
    }
}

# check the region root id if the msti handles have the same instance number
keylget returnedString msti.$stpHdl1.$mstiResult1_1.regional_root_id   regionRootId1_1
keylget returnedString msti.$stpHdl1.$mstiResult1_2.regional_root_id   regionRootId1_2
keylget returnedString msti.$stpHdl2.$mstiResult2_1.regional_root_id   regionRootId2_1
keylget returnedString msti.$stpHdl2.$mstiResult2_2.regional_root_id   regionRootId2_2
if { $regionRootId1_1 != $regionRootId2_1 && $regionRootId1_1 != $regionRootId2_2 } {
	puts "  FAILED:  $stpHdl1 and $stpHdl2 have incorrect region root id for msti."
    return
}
if { $regionRootId1_2 != $regionRootId2_1 && $regionRootId1_2 != $regionRootId2_2 } {
	puts "  FAILED:  $stpHdl1 and $stpHdl2 have incorrect region root id for msti."
    return
}

# check the port state
keylget returnedString msti.$stpHdl1.$mstiResult1_1.tx_port_state   txPortState1_1
keylget returnedString msti.$stpHdl1.$mstiResult1_2.tx_port_state   txPortState1_2
keylget returnedString msti.$stpHdl2.$mstiResult2_1.tx_port_state   txPortState2_1
keylget returnedString msti.$stpHdl2.$mstiResult2_2.tx_port_state   txPortState2_2
keylget returnedString msti.$stpHdl1.$mstiResult1_1.rx_port_state   rxPortState1_1
keylget returnedString msti.$stpHdl1.$mstiResult1_2.rx_port_state   rxPortState1_2
keylget returnedString msti.$stpHdl2.$mstiResult2_1.rx_port_state   rxPortState2_1
keylget returnedString msti.$stpHdl2.$mstiResult2_2.rx_port_state   rxPortState2_2
set portStateList "$txPortState1_1 $txPortState1_2 $txPortState2_1 $txPortState2_2 $rxPortState1_1 $rxPortState1_2 $rxPortState2_1 $rxPortState2_2"
foreach portState $portStateList {
    if { $portState == "Forwarding" } {
	continue
    } elseif { $portState == "NONE" } {
	puts "  FAILED:  The msti has been in an incorrect stats."
	return
    }	
}

########################################
# Step9: Stop mstp 
########################################
set returnedString [sth::emulation_stp_control  -port_handle $portList \
			-action stop]
keylget returnedString status status
if {!$status} {
puts $returnedString
    puts "  FAILED. "
	return
}

########################################
#step10: Release resources
########################################
set returnedString [::sth::cleanup_session -port_list $portList]

keylget returnedString status status
if {!$status} {
puts $returnedString
    puts "  FAILED. "
	return
}

puts "\n test over"
puts "_SAMPLE_SCRIPT_SUCCESS"

exit