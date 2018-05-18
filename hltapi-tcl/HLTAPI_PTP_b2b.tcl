#################################
#
# File Name:         HLTAPI_PTP_b2b.tcl
#
# Description:       This script demonstrates the use of Spirent HLTAPI to setup PTP device in back to back environment.                  
#
# Test Step:         1. Reserve and connect chassis ports
#                    2. Interface config
#                    3. Config PTP Master device
#                    4. Start PTP devices
#                    5. Check PTP stats
#                    6. Stop PTP device
#                    7. Release resources
#
# DUT configuration:
#           none
#
# Topology
#                 STC Port1                    STC Port2                       
#               [PTP device1]----------------[PTP device2]
#                                            [PTP device3]
#                 Master                       Slave
#                           
#                                         
#
#################################

# Run sample:
#            c:>tclsh HLTAPI_PTP_B2B.tcl 10.61.44.2 3/1 3/3
#            c:>tclsh HLTAPI_PTP_B2B.tcl "10.61.44.2 10.61.44.7" 3/1 3/3

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

set enableLog 1
set deviceNum 2

if {$enableLog} {
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


########################################
#Step1: Reserve and connect chassis ports
########################################

puts "Reserve and connect chassis ports"

set returnedString [sth::connect -device $device_list -port_list $port_list]

keylget returnedString status status
if {!$status} {
	puts "FAILED $returnedString"	
    return
} 

keylget returnedString port_handle.$device2.$port2 hltHostPort
keylget returnedString port_handle.$device1.$port1 hltSourcePort

set portList "$hltHostPort $hltSourcePort"

########################################
# Step2: Interface config
########################################

puts "Ethernet interface config"

set returnedString [sth::interface_config \
                        -mode                   config \
                        -port_handle            $hltSourcePort \
                        -intf_mode              "ethernet" \
                        -phy_mode               "copper" \
                        -speed                  "ether1000" \
                        -autonegotiation        1 \
                        -duplex                 "full" \
                        -src_mac_addr           00:10:94:00:00:11 \
                        -intf_ip_addr           100.0.0.2\
                        -gateway                100.0.0.1 \
                        -netmask                255.255.255.0 \
                        -arp_send_req           1]

keylget returnedString status status
if {!$status} {
puts $returnedString
    return "  FAILED:  $returnedString"
} 

set returnedString [sth::interface_config \
                        -mode                   config \
                        -port_handle            $hltHostPort \
                        -intf_mode              "ethernet" \
                        -phy_mode               "copper" \
                        -speed                  "ether1000" \
                        -autonegotiation        1 \
                        -duplex                 "full" \
                        -src_mac_addr           00:10:94:00:00:22 \
                        -intf_ip_addr           100.0.1.8 \
                        -gateway                100.0.1.1 \
                        -netmask                255.255.255.0 \
                        -arp_send_req           1]

keylget returnedString status status
if {!$status} {
puts $returnedString
    return "  FAILED:  $returnedString"
}


########################################
# Step3: Config PTP Master device
########################################
    
puts "Configuring a PTP Master device on $hltSourcePort with the best priority"
    
set returnedString [sth::emulation_ptp_config   -mode               "create" \
                            -port_handle                    $hltSourcePort \
                            -count                          1 \
                            -name                           PTP_1 \
                            -encapsulation                  ETHERNETII \
                            -device_type                    ptpMaster \
                            -transport_type                 ipv4 \
                            -local_mac_addr                 00:33:00:00:00:01 \
                            -local_ip_addr                  10.0.0.5 \
                            -remote_ip_addr                 10.0.0.1  \
                            -vlan_id1                       100 \
                            -vlan_id2                       200 \
                            -ptp_session_mode               multicast \
                            -ptp_domain_number              10 \
                            -ptp_port_number                1 \
                            -ptp_clock_id                   0xAAAA480000000000 \
                            -master_clock_class             200 \
                            -master_clock_priority1         2 \
                            -master_clock_priority2         2 \
                            -time_source                    ptp-profile \
                            -announce_message_enable        0 \
                            -log_announce_message_interval  4 \
                            -announce_receipt_timeout       20 \
                            -sync_enable                    1 \
                            -sync_two_step_flag             on \
                            -log_sync_message_interval      {"-5"} \
                            -path_delay_mechanism           end-to-end \
]
    
keylget returnedString status status
if {!$status} {
puts $returnedString
    return "  FAILED:  $returnedString"
}

keylget returnedString handle ptpHandle1

puts "Configuring $deviceNum PTP Master devices on $hltHostPort"
    
set returnedString [sth::emulation_ptp_config   -mode               "create" \
                            -port_handle                    $hltHostPort \
                            -count                          $deviceNum \
                            -encapsulation                  ETHERNETII \
                            -device_type                    ptpMaster\
                            -transport_type                 ipv4 \
                            -local_mac_addr                 00:99:00:00:00:01 \
                            -local_ip_addr                  10.0.0.1 \
                            -local_ip_addr_step             0.0.0.1 \
                            -remote_ip_addr                 10.0.0.5 \
                            -vlan_id1                       100 \
                            -vlan_id2                       200 \
                            -ptp_session_mode               multicast \
                            -ptp_domain_number              10 \
                            -ptp_port_number                1 \
                            -ptp_clock_id                   0xBCDE480000000000 \
                            -ptp_clock_id_step              0x0000000000000001 \
                            -master_clock_class             200 \
                            -master_clock_priority1         8 \
                            -master_clock_priority2         2 \
                            ]
    
keylget returnedString status status
if {!$status} {
puts $returnedString
    return "  FAILED:  $returnedString"
}

keylget returnedString handle ptpHandle

set ptpHandle2 [lindex $ptpHandle 0]
set ptpHandle3 [lindex $ptpHandle 1]                            
                            
stc::perform saveasxml -FileName "ptp_test.xml"  
#config parts are finished
 
########################################
# Step4: Start PTP devices
########################################

puts "Start PTP devices"

set returnedString [sth::emulation_ptp_control  \
                            -action_control  start \
                            -port_handle     $portList \
           ]

keylget returnedString status status
if {!$status} {
puts $returnedString
    return "  FAILED:  $returnedString"
}

after 2000

########################################
# Step5: Get PTP stats
########################################
    
set returnedString [sth::emulation_ptp_stats  -mode  device \
                           -handle    $ptpHandle1 \
           ]

keylget returnedString status status
if {!$status} {
puts $returnedString
    return "  FAILED:  $returnedString"
}

puts $returnedString

keylget returnedString $ptpHandle1.clock_state clockState1

if {$clockState1 == "master"} {
    puts "$ptpHandle1 is selected to be master PTP"
} else {
    puts "$ptpHandle1 is a $clockState1 PTP"
}

set returnedString [sth::emulation_ptp_stats  -mode  device \
                           -port_handle    $hltHostPort \
           ]

puts $returnedString

keylget returnedString status status
if {!$status} {
puts $returnedString
    return "  FAILED:  $returnedString"
}

keylget returnedString $ptpHandle2.clock_state clockState2
keylget returnedString $ptpHandle3.clock_state clockState3
keylget returnedString $ptpHandle2.bmc_source_port_clock_id grandmasterId2
keylget returnedString $ptpHandle3.bmc_source_port_clock_id grandmasterId3

if {$clockState2 == "slave"} {
    puts "$ptpHandle2 is selected to be slave PTP"
} else {
    puts "$ptpHandle2 is a $clockState2 PTP"
}
if {$clockState3 == "slave"} {
    puts "$ptpHandle3 is selected to be slave PTP"
} else {
    puts "$ptpHandle3 is a $clockState3 PTP"
}


########################################
# Step6: Stop PTP device 
########################################

set returnedString [sth::emulation_ptp_control \
                        -port_handle         $portList \
                        -action_control      stop]

keylget returnedString status status
if {!$status} {
puts $returnedString
    return "  FAILED:  $returnedString"
}

########################################
#step10: Release resources
########################################
set returnedString [::sth::cleanup_session -port_list $portList]

keylget returnedString status status
if {!$status} {
puts $returnedString
    return "  FAILED:  $returnedString"
}
puts "_SAMPLE_SCRIPT_SUCCESS"
puts "\n test over"