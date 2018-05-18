
#################################
#
# File Name:         HLTAPI_PPPox_Server_b2b.tcl
#
# Description:       This script demonstrates the use of Spirent HLTAPI to setup PPPox Server devices
#                    and create bound traffic between PPPox servers and clients.                  
#
# Test Step:         1. Reserve and connect chassis ports
#                    2. Interface config
#                    3. Config PPPox Server
#                    4. Config PPPox Clients
#                    5. Connect PPPoE server & client
#                    6. Check PPPoE server & client Stats
#                    7. Stop PPPoE server & client
#                    8. Release resources
#
# DUT configuration:
#           none
#
# Topology
#                 STC Port1                    STC Port2                       
#               [PPPox Servers]----------------[PPPox Clients]
#                       <-----traffic stream----->
#                                         
#
#################################

# Run sample:
#            c:>tclsh HLTAPI_PPPox_Server_b2b.tcl 10.61.44.2 3/1 3/3
#            c:>tclsh HLTAPI_PPPox_Server_b2b.tcl "10.61.44.2 10.61.44.7" 3/1 3/3

package require SpirentHltApi

set device_list      [lindex $argv 0]
set port1        [lindex $argv 1]
set port2        [lindex $argv 2]
set i 0
foreach device $device_list {
    set device$i $device
    incr i
}
set device$i $device
set port_list "$port1 $port2"

set enableLog 1
set deviceNum 10

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
	puts "  FAILED:  $returnedString"
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
                        -phy_mode               "fiber" \
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
    puts "  FAILED:  $returnedString"
	return
} 

set returnedString [sth::interface_config \
                        -mode                   config \
                        -port_handle            $hltHostPort \
                        -intf_mode              "ethernet" \
                        -phy_mode               "fiber" \
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
    puts "  FAILED:  $returnedString"
	return
}


########################################
# Step3: Config PPPox Server
########################################
    
puts "Configuring PPPoE Server on $hltSourcePort"
    
set returnedString [sth::pppox_server_config   -mode "create" \
                        -port_handle                 $hltSourcePort \
                        -num_sessions                $deviceNum \
                        -encap                       ethernet_ii_qinq \
                        -protocol                    pppoe \
                        -attempt_rate                50 \
                        -disconnect_rate             50 \
                        -max_outstanding             100 \
                        -auth_mode                   chap \
                        -username                    spirent \
                        -password                    spirent \
                        -mac_addr                    "00:10:94:01:00:01" \
                        -mac_addr_step               "00.00.00.00.00.01" \
                        -intf_ip_addr                192.0.0.8 \
                        -intf_ip_addr_step           0.0.0.1 \
                        -gateway_ip_addr             192.0.0.1 \
                        -qinq_incr_mode              inner \
                        -vlan_id                     200 \
                        -vlan_id_count               2 \
                        -vlan_id_outer               300 \
                        -vlan_id_outer_count         5 \
                        -ipv4_pool_addr_start        10.1.0.0 \
                        -ipv4_pool_addr_prefix_len   24 \
                        -ipv4_pool_addr_count        50 \
                        -ipv4_pool_addr_step         1 ]


keylget returnedString status status
if {!$status} {
    puts "  FAILED:  $returnedString"
	return
}

keylget returnedString handle serverHandle

########################################
# Step4: Config PPPox Clients
########################################

puts "Configuring PPPoE Client on $hltHostPort"

set returnedString [sth::pppox_config   -mode "create" \
                        -port_handle                $hltHostPort \
                        -encap                      ethernet_ii_qinq \
                        -protocol                   pppoe \
                        -ip_cp                      ipv4_cp \
                        -num_sessions               $deviceNum \
                        -auth_mode                  chap \
                        -username                   spirent \
                        -password                   spirent \
                        -mac_addr                   "00:10:94:01:00:45" \
                        -mac_addr_step              "00.00.00.00.00.01" \
                        -vlan_id                     200 \
                        -vlan_id_count               2 \
                        -vlan_id_outer               300 \
                        -vlan_id_outer_count         5 \
                        ]

keylget returnedString status status
if {!$status} {
    puts "  FAILED:  $returnedString"
	return
}
   
keylget returnedString handle clientHandle

stc::perform saveasxml -filename pppox_server.xml
#config parts are finished

########################################
# Step5: Connect PPPoE server & client
########################################    
    
puts "Connect PPPoE server"

set returnedString [ sth::pppox_server_control -action connect \
                            -port_handle $hltSourcePort]
    
keylget returnedString status status
if {!$status} {
    puts "  FAILED:  $returnedString"
	return
}
    
puts "Bind PPPoE Client"
    
set returnedString [ sth::pppox_control -action    connect \
                            -handle    $clientHandle]
    
    
keylget returnedString status status
if {!$status} {
    puts "  FAILED:  $returnedString"
	return
}

stc::sleep 10
    
########################################
# Step6: Check PPPoE server & client Stats
########################################
puts "Get PPPoE Server Stats"

set returnedString [ sth::pppox_server_stats   -mode aggregate \
                        -port_handle $hltSourcePort]

keylget returnedString status status
if {!$status} {
    puts "  FAILED:  $returnedString"
	return
}

keylget returnedString aggregate.connected connect

if {$connect == 1} {
    puts "PPPoE server and clients are connected successfully"
} else {
    puts "PPPoE server and clients are NOT connected successfully"
	return
}

puts "Get PPPoE Client Stats"

set returnedString [ sth::pppox_stats   -mode session \
                -handle $clientHandle]

keylget returnedString status status
if {!$status} {
    puts "  FAILED:  $returnedString"
	return
}

puts "The assigned pppoe client ipv4 addresses are:"
for {set i 1} {$i <= $deviceNum} {incr i} {
    keylget returnedString session.$i.ip_addr ip
    puts "$ip"
}

########################################
#step7: Stop PPPoE server & client
########################################

puts "------------Stop PPPoE Client------------------"
    
set returnedString [ sth::pppox_control    -action     disconnect \
                                   -handle     $clientHandle]

keylget returnedString status status
if {!$status} {
    puts "  FAILED:  $returnedString"
	return
}
   

puts "------------Stop PPPoE Server------------------"

set returnedString [ sth::pppox_server_control -action disconnect \
                                    -port_handle $hltSourcePort]

keylget returnedString status status
if {!$status} {
    puts "  FAILED:  $returnedString"
	return
}
    
       
########################################
#step8: Release resources
########################################
set returnedString [::sth::cleanup_session -port_list $portList]

keylget returnedString status status
if {!$status} {
    puts "  FAILED:  $returnedString"
	return
}
   
puts "_SAMPLE_SCRIPT_SUCCESS"
puts "\n test over"
