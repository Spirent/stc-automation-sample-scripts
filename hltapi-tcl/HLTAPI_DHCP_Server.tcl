#################################
#
# File Name:         HLTAPI_DHCP_Server.tcl
#
# Description:       This script demonstrates the use of Spirent HLTAPI to setup DHCP Server test.
#                    In this test, DHCP Server and clients are emulated in back-to-back mode.
#
# Test Step:         1. Reserve and connect chassis ports
#                    2. Interface config
#                    3. Config dhcp server host
#                    4. Config dhcpv4 client 
#                    5. Start dhcp server
#                    6. Bound Dhcp clients
#                    7  Retrive Dhcp session results
#                    8. Stop Dhcp server and client
#                    8. Release resources
#
#
# Topology
#                   STC Port1                      STC Port2                       
#                [DHCP Server]------------------[DHCP clients]
#                                              
#                                         
#
#################################

# Run sample:
#            c:>tclsh HLTAPI_DHCP_Server.tcl 10.61.44.2 3/1 3/3
#            c:>tclsh HLTAPI_DHCP_Server.tcl "10.61.44.2 10.61.44.7" 3/1 3/3

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

########################################
#Step1: Reserve and connect chassis ports
########################################

set returnedString [sth::connect -device $device_list -port_list $port_list]

keylget returnedString status status
if {!$status} {
	puts $returnedString
    puts "  FAILED:  $returnedString"
	return
}

keylget returnedString port_handle.$device2.$port2 hltHostPort
keylget returnedString port_handle.$device1.$port1 hltSourcePort

set portList "$hltHostPort $hltSourcePort"

########################################
# Step2: Interface config
########################################

foreach port $portList {
    set returnedString [sth::interface_config \
                            -mode               config \
                            -port_handle        $port\
                            -intf_mode          "ethernet" \
                            -phy_mode           "copper" \
                            -speed              "ether1000" \
                            -autonegotiation    1 \
                            -duplex             "full" \
                            -src_mac_addr       00:10:94:00:00:31 \
                            -intf_ip_addr       100.1.1.2 \
                            -gateway            100.1.1.1 \
                            -netmask            255.255.255.0 \
                            -arp_send_req       1]
    
    keylget returnedString status status
    if {!$status} {
		puts $returnedString
        puts "  FAILED:  $returnedString"
		return
    }
}

########################################
# Step3: Config dhcp server host
########################################

set returnedString [ sth::emulation_dhcp_server_config  \
                        -mode                       create \
                        -count                      1 \
                        -port_handle                $hltSourcePort \
                        -local_mac                  00:10:94:00:00:03 \
                        -ip_address                 192.0.1.4 \
                        -ip_step                    0.0.0.1 \
                        -ip_gateway                 192.0.1.1 \
                        -ipaddress_pool             192.0.1.5 \
                        -ipaddress_increment        2 \
                        -ipaddress_count            30 \
                        -lease_time                 60]

keylget returnedString status status
if {!$status} {
	puts $returnedString
    puts "  FAILED:  $returnedString"
	return
}

keylget returnedString handle.dhcp_handle dhcpServer
########################################
# Step4: Config dhcpv4 client
########################################

set returnedString [ sth::emulation_dhcp_config  \
                        -mode                       create \
                        -port_handle                $hltHostPort \
                        -retry_count                20 \
                        -request_rate               1000 \
                        -outstanding_session_count  5 \
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

#config parts are finished

keylget returnedString handles dhcpClient

########################################
# Step5: Start Dhcp Server 
########################################

set returnedString [ sth::emulation_dhcp_server_control  \
                        -port_handle    $hltSourcePort \
                        -action         connect]

keylget returnedString status status
if {!$status} {
	puts $returnedString
    puts "  FAILED:  $returnedString"
	return
}

########################################
# Step6: Bound Dhcp clients
########################################

set returnedString [ sth::emulation_dhcp_control \
                        -port_handle    $dhcpPortHandle \
                        -action         bind]

keylget returnedString status status
if {!$status} {
	puts $returnedString
    puts "  FAILED:  $returnedString"
	return
}

after 1000
########################################
# Step7: Retrive Dhcp session results
########################################

set returnedString [ sth::emulation_dhcp_server_stats \
                        -port_handle    $hltSourcePort \
                        -action         COLLECT]


keylget returnedString status status
if {!$status} {
	puts $returnedString
    puts "  FAILED:  $returnedString"
	return
}

set returnedString [ sth::emulation_dhcp_stats \
                        -port_handle    $dhcpPortHandle \
                        -action         collect]

keylget returnedString status status
if {!$status} {
	puts $returnedString
    puts "  FAILED:  $returnedString"
	return
}

########################################
# Step8: Stop Dhcp server and client
########################################

set returnedString [ sth::emulation_dhcp_server_control  \
                        -dhcp_handle    $dhcpServer \
                        -action         reset]

keylget returnedString status status
if {!$status} {
	puts $returnedString
    puts "  FAILED:  $returnedString"
	return
}

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
#step9: Release resources
########################################
set returnedString [::sth::cleanup_session -port_list $portList]

keylget returnedString status status
if {!$status} {
	puts $returnedString
    puts "  FAILED:  $returnedString"
	return
}

puts "_SAMPLE_SCRIPT_SUCCESS"

