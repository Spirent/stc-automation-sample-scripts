################################################################################
#
# File Name:         HLTAPI_Igmp_Querier.tcl
#
# Description:       This script demonstrates the use of Spirent HLTAPI to setup Igmp Router.
#
# Test Step:         # Step 1 : Connect to chassis & reserve port
#                    # Step 2 : Interface Configuration 
#                    # Step 3 : Configure IGMP Querier(router) on port1
#                    # Step 4 : Configure IGMP Host on port2
#                    # Step 5 : Setup Multicast group
#                    # Step 6 : Attach multicast group to IGMP Host
#                    # Step 7 : Save the configuration
#                    # Step 8 : Start capture on all ports
#                    # Step 9 : Join IGMP hosts to multicast group
#                    # Step 10 : Get IGMP hosts Stats
#                    # Step 11 : Start IGMP Querier
#                    # Step 12 : Get the IGMP Querier Stats
#                    # Step 13 : Check and Display IGMP router states
#                    # Step 14 : Stop IGMP Querier
#                    # Step 15 : Leave IGMP Host from the Multicast Group
#                    # Step 16 : Stop the packet capture 
#                    # Step 17 : Delete IGMP Querier 
#                    # Step 18 : Release Resources
#
#
# Topology
#                   STC Port1                      STC Port2                       
#                [IGMP Querier]-------------------[IGMP Host]
#                                              
################################################################################

# Run sample:
#            c:>tclsh HLTAPI_IGMP_Querier.tcl 10.61.44.2 3/1 3/3
#            c:>tclsh HLTAPI_IGMP_Querier.tcl "10.61.44.2 10.61.44.7" 3/1 3/3

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
set portlist "$port1 $port2"

set media "copper"
set speed "ether1000"
set passFail PASS
set groupAddrStart "225.1.0.1"
set hPortlist ""

set captureFlag 0
set enableHltLog 1

if {$enableHltLog} {
    ::sth::test_config  -logfile IGMP_Querier_hltLogfile \
                        -log 1 \
                        -vendorlogfile IGMP_Querier_stcExport\
                        -vendorlog 1\
                        -hltlog 1\
                        -hltlogfile IGMP_Querier_hltExport \                                                                                                                  ort\
                        -hlt2stcmappingfile IGMP_Querier_hlt2StcMapping \
                        -hlt2stcmapping 1 \
                        -log_level 7
}

# Step 1 : Connect to chassis & reserve port
puts "Connecting to $device_list, $portlist"
set intStatus [sth::connect -device $device_list -port_list $portlist -offline 0]
puts $intStatus

set hPort($device1.$port1) [keylget intStatus port_handle.$device1.$port1]
set hPort($device2.$port2) [keylget intStatus port_handle.$device2.$port2]
set hPortlist [concat $hPortlist $hPort($device1.$port1)]
set hPortlist [concat $hPortlist $hPort($device2.$port2)]

# Step 2 : Interface Configuration 
foreach port $portlist {
    set intStatus [::sth::interface_config 	-port_handle        $hPort($device.$port) \
                                            -intf_ip_addr       1.1.1.10 \
                                            -gateway            1.1.1.1 \
                                            -netmask            255.255.0.0 \
                                            -intf_mode          ethernet \
                                            -phy_mode           $media \
                                            -speed              $speed \
                                            -autonegotiation    1 \
                                            -mode               config \
                                            -arp_send_req       0]
        
}


# Step 3 : Configure IGMP Querier(router) on port1 
puts "Create the igmp querier router on port1"
set returnedString [sth::emulation_igmp_querier_config \
                                    -mode                       "create" \
                                    -port_handle                $hPort($device.$port1) \
                                    -count                      7 \
                                    -igmp_version               v2 \
                                    -intf_ip_addr               1.1.1.40 \
                                    -intf_ip_addr_step          "0.0.0.1" \
                                    -neighbor_intf_ip_addr      1.1.1.10 \
                                    -neighbor_intf_ip_addr_step "0.0.0.1" \
                                    -vlan_id                    111\
                                    -vlan_id_count              3 \
                                    -vlan_id_step               2\
                                    -vlan_id_mode               increment\
                                    -vlan_id_outer              101\
                                    -vlan_id_outer_count        5 \
                                    -vlan_id_outer_step         2\
                                    -vlan_id_outer_mode         increment]

keylget returnedString status status
if {!$status} {
    puts "  FAILED:  $returnedString"
	return
} else {
    puts "Created IGMP Querier on port1 successfully"
}

keylget returnedString handle igmpQuerierRouterList


# Step 4 : Configure IGMP Host on port2
puts "Create the igmp host on port2"

set returnedString [sth::emulation_igmp_config \
                        -mode "create" \
                        -port_handle $hPort($device.$port2) \
                        -igmp_version v2 \
                        -robustness 10 \
                        -count 7 \
                        -intf_ip_addr 1.1.1.10 \
                        -intf_ip_addr_step "0.0.0.1" \
                        -neighbor_intf_ip_addr 1.1.1.40 \
                        -neighbor_intf_ip_addr_step "0.0.0.1" \
                        -vlan_id 111\
                        -vlan_id_mode increment\
                        -vlan_id_step 2\
                        -vlan_id_count 3\
                        -vlan_id_outer 101\
                        -vlan_id_outer_step 2\
                        -vlan_id_outer_count 5\
                        -vlan_id_outer_mode increment\
                        -qinq_incr_mode outer\
                        -general_query 1\
                        -group_query 1]

keylget returnedString status status
if {!$status} {
    puts "  FAILED:  $returnedString"
	return
} else {
    puts "Created IGMP Host on port2 successfully"
}

set igmpHostHandle [keylget returnedString handle]

# Step 5 : Setup Multicast group
set groupStatus [sth::emulation_multicast_group_config \
                            -ip_addr_start $groupAddrStart \
                            -mode "create" \
                            -num_groups 1]

keylget groupStatus status status
if {!$status} {
    puts "  FAILED:  $returnedString"
	return
} else {
    puts "Created Multicast Group successfully"
}

set mcGroupHandle [keylget groupStatus handle]

# Step 6 : Attach multicast group to IGMP Host
set membershipStatus [sth::emulation_igmp_group_config \
                            -mode "create" \
                            -group_pool_handle $mcGroupHandle \
                            -session_handle $igmpHostHandle]

keylget membershipStatus status status
if {!$status} {
    puts "  FAILED:  $returnedString"
	return
} else {
    puts "Attached Multicast Group to Host successfully"
}

# Step 7 : Save the configuration 
stc::perform SaveAsXml -filename "./HLTAPI_Igmp_Querier.xml"
#config parts are finished

# Step 8 : Start capture on all ports
if { $captureFlag } {
    puts "starting the capture on all ports"
    sth::packet_control -port_handle port1 -action start
    sth::packet_control -port_handle port2 -action start
}

# Step 9 : Join IGMP hosts to multicast group
puts " IGMP Host Join the Multicast Group"
set returnedString [sth:::emulation_igmp_control \
				-handle 		$igmpHostHandle  \
				-mode 			join]
keylget returnedString status status
if {!$status} {
    puts "  FAILED:  $returnedString"
	return
} else {
    puts "Started(Join) IGMP Host successfully"
}

sleep 10

# Step 10 : Get IGMP hosts Stats
set returnedString [sth:::emulation_igmp_info -handle $igmpHostHandle]
keylget returnedString status status
if {!$status} {
    puts " emulation_igmp_info FAILED:  $returnedString"
	return
}

puts " IGMP Host result: $returnedString \n"

# Step 11 : Start IGMP Querier
puts "start the igmp querier"
set querierStartStatus [::sth::emulation_igmp_querier_control\
                                        -mode           start\
                                        -port_handle    $hPort($device.$port1)]

keylget querierStartStatus status status
if {!$status} {
    puts "  FAILED:  $querierStartStatus"
	return
} else {
    puts "Started IGMP Querier successfully"
}

sleep 100;

# Step 12 : Get the IGMP Querier Stats
set igmpQuerierInfo [::sth::emulation_igmp_querier_info \
                            -port_handle $hPort($device.$port1)]

keylget igmpQuerierInfo status status
if {!$status} {
    puts " emulation_igmp_querier_info FAILED:  $igmpQuerierInfo"
}

#puts "IGMP Querier Result: $igmpQuerierInfo"

# Step 13 : Check and Display IGMP router states
foreach router $igmpQuerierRouterList {
    keylget igmpQuerierInfo results.$router.router_state routerState
    puts " Router: $router Router State: $routerState"
    if {$routerState != "UP"} {
        puts " IGMP Querier $router not UP "
    }
}

# Step 14 : Stop IGMP Querier
puts "stop the igmp querier"
set querierStopStatus [::sth::emulation_igmp_querier_control\
                                        -mode           stop\
                                        -port_handle    $hPort($device.$port1)]

keylget querierStopStatus status status
if {!$status} {
    puts "  FAILED:  $returnedString"
	return
} else {
    puts "Stop IGMP Querier successfully"
}

# Step 15 : Leave IGMP Host from the Multicast Group
puts " Leave IGMP Host from the Multicast Group"
set returnedString [sth:::emulation_igmp_control \
				-handle 		$igmpHostHandle  \
				-mode 			leave]

keylget returnedString status status
if {!$status} {
    puts " emulation_igmp_control FAILED:  $returnedString"
	return
} else {
    puts "Leave IGMP Host successfully"
}

# Step 16 : Stop the packet capture 
if { $captureFlag } {
    puts "stop the capture on all the ports"
    sth::packet_control -port_handle port1 -action stop
    sth::packet_control -port_handle port2 -action stop
    
    # Step : Save the packet capture
    puts "Saving the packat captured"
    sth::packet_stats -port_handle port1 -action filtered -format pcap -filename "igmp_querier_p1.pcap"
    sth::packet_stats -port_handle port2 -action filtered -format pcap -filename "igmp_querier_p2.pcap"
}

# Step 17 : Delete IGMP Querier 
set igmpQuerierDeleteStatus [sth::emulation_igmp_querier_config \
                                                    -mode delete\
                                                    -handle $igmpQuerierRouterList]

keylget igmpQuerierDeleteStatus status status
if {!$status} {
    puts "  FAILED:  $returnedString"
	return
} else {
    puts "Deleted IGMP Querier successfully"
}


# Step 18 : Release Resources
set returnedString [::sth::cleanup_session -port_list $hPortlist]

keylget returnedString status status
if {!$status} {
    puts "  FAILED:  $returnedString"
	return
}

puts "_SAMPLE_SCRIPT_SUCCESS"
