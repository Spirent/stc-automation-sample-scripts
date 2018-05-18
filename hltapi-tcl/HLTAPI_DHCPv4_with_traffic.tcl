#################################
#
# File Name:         HLTAPI_DHCPv4_with_traffic.tcl
#
# Description:       This script demonstrates the use of Spirent HLTAPI to setup DHCPv4 with traffic test.                  
#
# Test Step:         1. Reserve and connect chassis ports
#                    2. Interface config
#                    3. Config dhcpv4 clients
#                    4. Bound dhcp clients
#                    5. Check dhcp stats
#                    6. Config upstream and downstream traffic
#                    7. Start and stop traffic
#                    8. Retrive traffic statistics
#                    9. Stop Dhcpv4 client 
#                    10. Release resources
#
# DUT configuration:
#
#             ip dhcp pool dhcp_pool
#               network 100.1.0.1 255.255.0.0
#             !
#             interface FastEthernet 1/0
#               ip address 100.1.0.1 255.255.255.0
#               duplex full
#
#            interface FastEthernet 2/0
#              ip address 110.0.0.1 255.255.255.0
#              duplex full
#
# Topology
#                 STC Port1              DHCPv4 Server         STC Port2                       
#             [DHCPv4 Client]---------------[DUT]--------------[ipv4 host]
#                           100.1.0.0/24         110.0.0.0/24    
#                                         
#
#################################

# Run sample:
#            c:>tclsh HLTAPI_DHCPv4_traffic.tcl 10.61.44.2 3/1 3/3
#            c:>tclsh HLTAPI_DHCPv4_traffic.tcl "10.61.44.2 10.61.44.7" 3/1 3/3

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
set port_list "$port1 $port2";

set enableLog 1

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
	puts $returnedString
    puts " FAILED:  $status"
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
                        -mode               config \
                        -port_handle        $hltSourcePort \
                        -intf_mode          "ethernet" \
                        -phy_mode           "copper" \
                        -speed              "ether1000" \
                        -autonegotiation    1 \
                        -duplex             "full" \
                        -src_mac_addr       00:10:94:00:00:11 \
                        -intf_ip_addr       100.1.0.2\
                        -gateway            100.1.0.1 \
                        -netmask            255.255.255.0 \
                        -arp_send_req       1]

keylget returnedString status status
if {!$status} {
	puts $returnedString
    puts "  FAILED:  $returnedString"
	return
} 

set returnedString [sth::interface_config \
                        -mode               config \
                        -port_handle        $hltHostPort \
                        -intf_mode          "ethernet" \
                        -phy_mode           "copper" \
                        -speed              "ether1000" \
                        -autonegotiation    1 \
                        -duplex             "full" \
                        -src_mac_addr       00:10:94:00:00:22 \
                        -intf_ip_addr       110.0.0.8 \
                        -gateway            110.0.0.1 \
                        -netmask            255.255.255.0 \
                        -arp_send_req       1]

keylget returnedString status status
if {!$status} {
	puts $returnedString
    puts "  FAILED:  $returnedString"
	return
}

########################################
# Step3: Config dhcpv4 clients
########################################

puts "Config dhcpv4 clients"

set returnedString [ sth::emulation_dhcp_config  \
                        -mode                       create \
                        -port_handle                $hltSourcePort \
                        -retry_count                100 \
                        -request_rate               100 \
                        -outstanding_session_count  500 \
                        -broadcast_bit_flag         1]

keylget returnedString status status
if {!$status} {
	puts $returnedString
    puts "  FAILED:  $returnedString"
	return
}

keylget returnedString handles dhcpPortHandle

set returnedString [ sth::emulation_dhcp_group_config \
                        -handle                     $dhcpPortHandle\
                        -mode                       create \
                        -encap                      ethernet_ii\
                        -protocol                   dhcpoe \
                        -num_sessions               20  \
                        -mac_addr                   00.00.10.95.11.15]

keylget returnedString status status
if {!$status} {
	puts $returnedString
    puts "  FAILED:  $returnedString"
	return
}

keylget returnedString handles dhcpClient

stc::perform saveasxml -filename dhcp.xml
#config parts are finished

########################################
# Step4: Bound dhcp clients
########################################

puts "Bound dhcpv4 clients"

set returnedString [ sth::emulation_dhcp_control \
                        -port_handle    $dhcpPortHandle \
                        -action         bind]

keylget returnedString status status
if {!$status} {
	puts $returnedString
    puts "  FAILED:  $returnedString"
	return
}

after 2000

########################################
# Step5: Check dhcp stats
########################################
puts "Check dhcpv4 stats"

set returnedString [ sth::emulation_dhcp_stats \
                        -handle         $dhcpClient \
                        -action         collect \
                        -mode           session]

keylget returnedString status status
if {!$status} {
	puts $returnedString
    puts "  FAILED:  $returnedString"
	return
}

keylget returnedString group.$dhcpClient.total_attempted attempted
keylget returnedString group.$dhcpClient.total_bound bound

if {$bound == $attempted} {
    puts "All $bound dhcp client sessions are bound with dhcp server."
} else {
    puts "Not all dhcp client sessions are bound with dhcp server."
}

########################################
# Step6: Config upstream and downstream traffic
########################################
puts "Config upstream traffic"
set returnedString [sth::traffic_config \
                        -mode                   create \
                        -port_handle            $hltSourcePort \
                        -rate_pps               1000 \
                        -l2_encap               ethernet_ii \
                        -l3_protocol            ipv4 \
                        -l3_length              108\
                        -transmit_mode          continuous \
                        -length_mode            fixed \
                        -emulation_src_handle   $dhcpClient \
                        -ip_dst_addr            110.0.0.8 \
                        -l4_protocol            udp  \
                        -udp_src_port           1024 \
                        -udp_dst_port           1024 ]

keylget returnedString status status
if {!$status} {
	puts $returnedString
    puts "  FAILED:  $returnedString"
	return
}
keylget returnedString stream_id streamblock1

puts "Config downstream  traffic"
set returnedString [sth::traffic_config \
                        -mode                   create \
                        -port_handle            $hltHostPort \
                        -rate_pps               1000 \
                        -l2_encap               ethernet_ii \
                        -l3_protocol            ipv4 \
                        -l3_length              108\
                        -transmit_mode          continuous \
                        -length_mode            fixed \
                        -ip_src_addr            110.0.0.8 \
                        -emulation_dst_handle   $dhcpClient \
                        -ip_src_mode            fixed \
                        -mac_src                00:10:94:00:00:22  \
                        -mac_discovery_gw       110.0.0.1 \
                        -l4_protocol            udp  \
                        -udp_src_port           1024 \
                        -udp_dst_port           1024 ]

keylget returnedString status status
if {!$status} {
	puts $returnedString
    puts "  FAILED:  $returnedString"
	return
}

keylget returnedString stream_id streamblock2

########################################
# Step7: Start and stop traffic
########################################
puts "Start and stop traffic"

set returnedString [sth::traffic_control \
                        -port_handle    all \
                        -action         run]

keylget returnedString status status
if {!$status} {
	puts $returnedString
    puts "  FAILED:  $returnedString"
	return
}

after 2000

set returnedString [sth::traffic_control \
                        -port_handle    $portList \
                        -action         stop]

keylget returnedString status status
if {!$status} {
	puts $returnedString
    puts "  FAILED:  $returnedString"
	return
}

########################################
# Step8: Retrive traffic statistics
########################################
puts "Retrive traffic statistics"

set returnedString [sth::traffic_stats \
                    -mode           streams \
                    -port_handle    $portList ]


keylget returnedString status status
if {!$status} {
	puts $returnedString
    puts "  FAILED:  $returnedString"
	return
}

puts "Upstream traffic"
foreach item {tx.total_pkts rx.total_pkts} {
    keylget returnedString $hltSourcePort.stream.$streamblock1.$item frames
    puts "$item $frames"
}

puts "Downstream traffic"
foreach item {tx.total_pkts rx.total_pkts} {
    keylget returnedString $hltSourcePort.stream.$streamblock2.$item frames
    puts "$item $frames"
}

########################################
# Step9: Stop Dhcpv4 client 
########################################

set returnedString [sth::emulation_dhcp_control \
                        -handle         $dhcpClient \
                        -action         release]

keylget returnedString status status
if {!$status} {
	puts $returnedString
    puts "  FAILED:  $returnedString"
	return
}

########################################
#step10: Release resources
########################################
set returnedString [::sth::cleanup_session -port_list $portList]

keylget returnedString status status
if {!$status} {
	puts $returnedString
    puts "  FAILED:  $returnedString"
	return
}

puts "_SAMPLE_SCRIPT_SUCCESS"

