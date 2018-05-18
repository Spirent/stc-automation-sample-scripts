#################################
#
# File Name:         HLTAPI_PPPoE_DHCPV6PD_TRAFFIC_B2B.tcl
#
# Description:       This script demonstrates the use of Spirent HLTAPI to setup STP devices
#
# Test Step:         1. Reserve and connect chassis ports
#                    2. Interface config
#                    3. Create pppoe server 
#                    4. Create dhcpv6-pd server
#                    5. Create pppoe client 
#                    6. Create dhcpv6-pd client
#                    7. Create stream block
#                    8. Connect pppoe server and pppoe client
#                    9. Start dhcpv6 server and bind dhcpv6 client
#                    10. Start and stop traffic
#                    11. Get results
#                    12. Release resources
# DUT configuration:
#           none
#
# Topology
#                 STC Port1                                             STC Port2                       
#                 dhcpv6pd over pppoe device----------------  dhcpv6pd over pppoe device
#                        
#                                         
#
#################################

# Run sample:
#            c:>tclsh HLTAPI_PPPoE_DHCPV6PD_TRAFFIC_B2B.tcl 10.61.44.2 3/1 3/3
#            c:>tclsh HLTAPI_PPPoE_DHCPV6PD_TRAFFIC_B2B.tcl "10.61.44.2 10.61.44.7" 3/1 3/3

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

########################################
# Step1: Reserve and connect chassis ports
########################################
set returnedString  [sth::connect -device $device_list -port_list $port_list];
if {![keylget returnedString status ]} {
    puts $returnedString
    return "Reserve port FAILED"
} else {
    keylget returnedString port_handle.$device1.$port1 port1 
    keylget returnedString port_handle.$device2.$port2 port2
}

########################################
# Step2: Config interface
########################################
set returnedString [sth::interface_config -port_handle $port1 \
                                          -mode config \
                                          -ipv6_intf_addr 1000::1 \
                                          -ipv6_gateway 1000::2 \
                                          -autonegotiation 1 \
                                          -arp_send_req 1 ]

if {![keylget returnedString status ]} {
    puts $returnedString
    return "Interface config FAILED"
} else {
    #get the device handle
    set deviceHdl1 [keylget returnedString handles]
}


set returnedString [sth::interface_config -port_handle $port2 \
                                          -mode config \
                                          -ipv6_intf_addr 1000::2 \
                                          -ipv6_gateway 1000::1 \
                                          -autonegotiation 1 \
                                          -arp_send_req 1 ]

if {![keylget returnedString status ]} {
    puts $returnedString
    return "Interface config FAILED"
} else {
    #get the device handle
    set deviceHdl2 [keylget returnedString handles]
}

########################################
# Step3: create pppoe server 
########################################
set returnedString [sth::pppox_server_config   -mode "create" \
           -port_handle               $port1 \
           -protocol                  pppoe \
           -encap                  ethernet_ii \
           -num_sessions              1 \
           -ip_cp                    "ipv6_cp" \
           -mac_addr                "00:10:94:01:00:01" \
           -intf_ipv6_addr            2000::5 \
           -intf_ipv6_addr_step        0::2 \
           -gateway_ipv6_addr        2000::1 \
           -ipv6_pool_prefix_start     1000:: \
           -ipv6_pool_prefix_step      2:: \
           -ipv6_pool_intf_id_start     ::1 \
           -ipv6_pool_intf_id_step      ::2 \
           -ipv6_pool_prefix_len        64 \
           -ipv6_pool_addr_count        50 ]
if {![keylget returnedString status ]} {
     puts "  FAILED:  $returnedString"
	return
} else {
    #get the device handle
    set deviceHdlServer [keylget returnedString handle]
}


########################################
# Step4: create dhcpv6-pd server
########################################                                        
set returnedString [ sth::emulation_dhcp_server_config  \
                        -mode                            "enable" \
                        -handle                     $deviceHdlServer \
                        -ip_version                      6\
                        -preferred_lifetime              604800\
                        -rebinding_time_percent          80\
                        -prefix_pool_start_addr          "2002::1"]
if {![keylget returnedString status ]} {
    puts "  FAILED:  $returnedString"
	return
}

########################################
# Step5: create pppoe client 
########################################
set returnedString [sth::pppox_config   -mode "create" \
                        -port_handle                $port2 \
                        -encap                      ethernet_ii\
                        -protocol                   pppoe \
                        -ip_cp                      ipv6_cp \
                        -num_sessions               1 \
                        -auth_mode                  chap \
                        -username                   spirent \
                        -password                   spirent \
                        -mac_addr                   "00:10:94:01:00:45" \
                        -mac_addr_step              "00.00.00.00.00.01" ]
if {![keylget returnedString status ]} {
     puts "  FAILED:  $returnedString"
	return
} else {
    set deviceHdlClient [keylget returnedString handle]
}
########################################
# Step6: create dhcpv6-pd client
########################################
set returnedString [ sth::emulation_dhcp_config  \
                        -mode                             "enable" \
                        -handle                           $deviceHdlClient \
                        -ip_version                       6 \
                        -dhcp6_outstanding_session_count  1 \
                        -dhcp6_release_rate               100 \
                        -dhcp6_request_rate               100 \
                        -dhcp6_renew_rate                 100 ]
if {![keylget returnedString status ]} {
     puts "  FAILED:  $returnedString"
	return
}

set returnedString [ sth::emulation_dhcp_group_config \
                        -handle                              $deviceHdlClient\
                        -mode                                 "enable" \
                        -dhcp6_client_mode                    DHCPPD \
                        -dhcp_range_ip_type                   6 \
                        -num_sessions                         1 ]
if {![keylget returnedString status ]} {
     puts "  FAILED:  $returnedString"
	return
}

##############################################
#step7: create stream block
#############################################
set returnedString [ ::sth::traffic_config  -mode create\
                    -port_handle $port1\
                    -l2_encap ethernet_ii\
                    -l3_protocol ipv6\
                    -emulation_src_handle $deviceHdlServer\
                    -emulation_dst_handle $deviceHdlClient\
                    -ipv6_src_addr aaaa:1::2\
                    -ipv6_src_mode fixed\
                    -mac_src 00.00.02.00.00.01\
                    -mac_discovery_gw aaaa:1::1]
if {![keylget returnedString status ]} {
     puts "  FAILED:  $returnedString"
	return
}

stc::perform SaveAsXmlCommand -filename  "./dhcpv6pd_over_pppox_traffic.xml"
#config parts are finished

##############################################
#step8: connect pppoe server and pppoe client
#############################################
set returnedString [ sth::pppox_server_control -action connect \
                            -port_handle $port1]
if {![keylget returnedString status ]} {
     puts "  FAILED:  $returnedString"
	return
}

set returnedString [ sth::pppox_control -action    connect \
                            -handle    $deviceHdlClient]
if {![keylget returnedString status ]} {
     puts "  FAILED:  $returnedString"
	return
}

sleep 10

#################################################
#step9: start dhcpv6 server and bind dhcpv6 client
#################################################
set returnedString [ sth::emulation_dhcp_server_control  \
                        -port_handle    $port1 \
                        -action         connect\
                        -ip_version      6]
if {![keylget returnedString status ]} {
     puts "  FAILED:  $returnedString"
	return
}

set returnedString [ sth::emulation_dhcp_control \
                        -port_handle    $port2 \
                        -action         bind \
                        -ip_version     6]
if {![keylget returnedString status ]} {
     puts "  FAILED:  $returnedString"
	return
}

########################################
#step10: start and stop traffic
########################################
set returnedString [sth::traffic_control \
                          -port_handle $port1 \
                          -action run]
if {![keylget returnedString status ]} {
     puts "  FAILED:  $returnedString"
	return
}
sleep 5

set returnedString [sth::traffic_control \
                          -port_handle $port1 \
                          -action stop]
if {![keylget returnedString status ]} {
     puts "  FAILED:  $returnedString"
	return
}
########################################
#step11: get results
########################################
set returnedString  [sth::traffic_stats \
                    -port_handle port1\
                    -mode aggregate]
if {![keylget returnedString status ]} {
     puts "  FAILED:  $returnedString"
	return
}

########################################
#step12: release resources
########################################
set returnedString [::sth::cleanup_session -port_list [list port1 port2]]
if {![keylget returnedString status ]} {
     puts "  FAILED:  $returnedString"
	return
}

########################################
#The End
########################################
puts "_SAMPLE_SCRIPT_SUCCESS"
puts "\n test over"


exit