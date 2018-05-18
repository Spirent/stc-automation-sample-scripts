################################################################################
#
# File Name:         HLTAPI_DHCPv6_basic.tcl
#
# Description:       This script demonstrates the use of Spirent HLTAPI to setup DHCPv6 Client/Server test.
#                    In this test, DHCP Server and clients are emulated in back-to-back mode.
#
# Test Step:         1. Reserve and connect chassis ports
#                    2. Interface config
#                    3. Config dhcpv6 server host
#                    4. Config dhcpv6 client 
#                    5. Start dhcpv6 server
#                    6. Bound Dhcpv6 clients
#                    7  Retrive Dhcpv6 session results
#                    8. Stop Dhcpv6 server and client
#                    9. Release resources
#
#
# Topology
#                   STC Port1                      STC Port2                       
#                [DHCPv6 Server]------------------[DHCPv6 clients]
#                                              
#                                         
#
################################################################################

# Run sample:
#            c:>tclsh HLTAPI_DHCPv6_basic.tcl 10.61.44.2 3/1 3/3
#            c:>tclsh HLTAPI_DHCPv6_basic.tcl "10.61.44.2 10.61.44.7" 3/1 3/3

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

set enableHltLog 1

if {$enableHltLog} {
::sth::test_config  -logfile DHCPv6_basic_hltLogfile \
                    -log 1 \
                    -vendorlogfile DHCPv6_basic_stcExport\
                    -vendorlog 1\
                    -hltlog 1\
                    -hltlogfile DHCPv6_basic_hltExport \                                                                                                                  ort\
                    -hlt2stcmappingfile DHCPv6_basic_hlt2StcMapping \
                    -hlt2stcmapping 1 \
                    -log_level 7

}

########################################
#Step1: Reserve and connect chassis ports
########################################
puts "Reserve and connect chassis ports"
set returnedString [sth::connect -device $device_list -port_list $port_list -offline 0]

keylget returnedString status status
if {!$status} {
    puts "  FAILED:  $returnedString"
	return
}

keylget returnedString port_handle.$device2.$port2 hltHostPort
keylget returnedString port_handle.$device1.$port1 hltSourcePort

set portList "$hltHostPort $hltSourcePort"

########################################
# Step2: Interface config
########################################
puts "Interface Config.....\n"
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
                            -ipv6_intf_addr     2008::6\
                            -ipv6_gateway       2008::1 \
                            -arp_send_req       0]

    keylget returnedString status status
    if {!$status} {
        puts "  FAILED:  $returnedString"
		return
    }
}

#########################################
## Step3: Config dhcpv6 server host
#########################################
puts "Configuring Dhcpv6 Server...........\n"
set returnedString [ sth::emulation_dhcp_server_config  \
                        -mode                            create \
                        -port_handle                     $hltSourcePort \
                        -ip_version                      6\
                        -encapsulation                   ethernet_ii\
                        -server_emulation_mode           "DHCPV6"\
                        -mac_addr                        00.00.10.10.11.15\
                        -mac_addr_step                   00.00.00.00.00.01 \
                        -local_ipv6_addr                 2012::2\
                        -gateway_ipv6_addr               2012::1\
                        -preferred_lifetime              604800\
                        -rebinding_time_percent          80\
                        -prefix_pool_start_addr          "2002::1"]

keylget returnedString status status
if {!$status} {
    puts "  FAILED:  $returnedString"
	return
}

keylget returnedString handle.dhcpv6_handle dhcpServer

#########################################
## Step4: Config dhcpv6 client
#########################################
puts "Configuring Dhcpv6 Client...........\n"
set returnedString [ sth::emulation_dhcp_config  \
                        -mode                             create \
                        -port_handle                      $hltHostPort \
                        -ip_version                       6 \
                        -dhcp6_outstanding_session_count  1 \
                        -dhcp6_release_rate               100 \
                        -dhcp6_request_rate               100 \
                        -dhcp6_renew_rate                 100 ]

keylget returnedString status status
if {!$status} {
    puts "  FAILED:  $returnedString"
	return
}

keylget returnedString handles dhcpPortHandle

set returnedString [ sth::emulation_dhcp_group_config \
                        -handle                              $dhcpPortHandle\
                        -mode                                 create \
                        -dhcp6_client_mode                    DHCPV6 \
                        -encap                                ethernet_ii\
                        -dhcp_range_ip_type                   6 \
                        -num_sessions                         20 \
                        -mac_addr                             00.00.10.95.11.15\
                        -mac_addr_step                        00.00.00.00.00.01 \
                        -local_ipv6_addr                      2009::2\
                        -gateway_ipv6_addr                    2005::1]

keylget returnedString status status
if {!$status} {
    puts "  FAILED:  $returnedString"
	return
}
#config parts are finished

keylget returnedString dhcpv6_handle dhcpClient

#########################################
## Step5: Start Dhcp Server 
#########################################
puts "Starting Dhcpv6 Server...........\n"
set returnedString [ sth::emulation_dhcp_server_control  \
                        -port_handle    $hltSourcePort \
                        -action         connect\
                        -ip_version      6]

keylget returnedString status status
if {!$status} {
    puts "  FAILED:  $returnedString"
	return
}


#########################################
## Step6: Bound Dhcp clients
#########################################
puts "Bind Dhcpv6 Clients...........\n"
set returnedString [ sth::emulation_dhcp_control \
                        -port_handle    $hltHostPort \
                        -action         bind \
                        -ip_version     6]

keylget returnedString status status
if {!$status} {
    puts "  FAILED:  $returnedString"
	return
}

set value 30
puts "Wait for $value secs till all the clients are assigned with valid ipv6 addresses...........\n"
set valueInMs [expr $value * 1000]
after $valueInMs

############################################################
## Step7: Retrive Dhcpv6 Client and Server results
############################################################
#
set returnedString [ sth::emulation_dhcp_server_stats \
                        -port_handle    $hltSourcePort \
                        -action         COLLECT\
                        -ip_version      6]

keylget returnedString status status

if {!$status} {
    puts "  FAILED:  $returnedString"
	return
}

keylget returnedString dhcp_server_state serverState
keylget returnedString ipv6.aggregate.$hltSourcePort.total_bound_count totalBoundCount

set returnedString [ sth::emulation_dhcp_stats \
                        -port_handle    $hltHostPort \
                        -action         collect \
                        -ip_version     6]

keylget returnedString status status
if {!$status} {
    puts "  FAILED:  $returnedString"
	return
}

keylget returnedString ipv6.$hltHostPort.aggregate.state State
keylget returnedString ipv6.aggregate.state Block_State
keylget returnedString ipv6.$hltHostPort.aggregate.setup_success aggrTotalBoundCount
keylget returnedString ipv6.aggregate.setup_success blkTotalBoundCount
puts "######################################################################\n"
puts "--------------------------DHCPv6 Server Result----------------------\n"
puts "Server State    ------- $serverState \n"
puts "Total Bound Count------ $totalBoundCount \n"
puts "--------------------------DHCPv6 Client Result----------------------\n"
puts "Port State : $State        Total  Bound: $aggrTotalBoundCount\n"
puts "Block State: $Block_State  Currently Bound: $blkTotalBoundCount\n"
puts "###################################################################### \n"

#All the clients requested for DHCPv6 address must be bounded
if {$State == "BOUND"} {
    puts "All clients are bounded "
} else {
    puts "  FAILED: Some of the clients not bounded "
	return
}


#########################################
## Step8: Stop Dhcpv6 server and client
#########################################

set returnedString [ sth::emulation_dhcp_server_control  \
                        -dhcp_handle    $dhcpServer \
                        -action         reset\
                        -ip_version     6]

keylget returnedString status status
if {!$status} {
    puts "  FAILED:  $returnedString"
	return
}

set returnedString [sth::emulation_dhcp_control \
                        -handle         $dhcpClient \
                        -action         release \
                        -ip_version     6]

keylget returnedString status status
if {!$status} {
    puts "  FAILED:  $returnedString"
	return
}

stc::perform SaveasXml -config system1 -filename    "./HLTAPI_DHCPv6_basic.xml"
puts "Saved XML....\n"

########################################
#step9: Release resources
########################################
set returnedString [::sth::cleanup_session -port_list $portList]

keylget returnedString status status
if {!$status} {
    puts "  FAILED:  $returnedString"
	return
}

puts "_SAMPLE_SCRIPT_SUCCESS"
