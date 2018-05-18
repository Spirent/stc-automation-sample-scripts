#################################
#
# File Name:         HLTAPI_BGPv4_BFD.tcl
#
# Description:       This script demonstrates the use of Spirent HLTAPI to config BFD support for BGP test.                  
#
# Test Step:         1. Reserve and connect chassis ports
#                    2. Interface config
#                    3. Config BGP router with BFD enabled
#                    4. Start BGP router
#                    5. Check BGP status
#                    6. Disable BFD 
#                    7. Telnet the DUT to check the neighbor status of BFD
#                    8. Release resources
#
# DUT configuration:
#
#           router bgp 123
#             bgp router-id 220.1.1.1
#             neighbor 100.1.0.8 remote-as 1
#             neighbor 100.1.0.8 fall-over bfd
#           !
#          interface FastEthernet1/0
#            ip address 100.1.0.1 255.255.255.0
#            duplex full
#            bfd interval 500 min_rx 500 multiplier 3
#          !
#
# Topology:
#
#              STC Port1                      Cisco DUT           
#             [BGP Router]-------------------[BGP Router]
#                                           [BFD enabled]
#                           100.1.0.0/24        
#                                         
#
#################################

# Run sample:
#            c:>tclsh HLTAPI_BGPv4_BFD.tcl 10.61.44.2 3/1 3/3
#            c:>tclsh HLTAPI_BGPv4_BFD.tcl "10.61.44.2 10.61.44.7" 3/1 3/3

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
    puts "  FAILED:  $status"
	return
} 

keylget returnedString port_handle.$device2.$port2 hltHostPort
keylget returnedString port_handle.$device1.$port1 hltSourcePort

set portList "$hltHostPort $hltSourcePort"

########################################
# Step2: Interface config
########################################

set returnedString [sth::interface_config \
                        -mode               config \
                        -port_handle        $hltSourcePort \
                        -intf_mode          "ethernet" \
                        -phy_mode           "copper" \
                        -speed              "ether1000" \
                        -autonegotiation    1 \
                        -duplex             "full" \
                        -src_mac_addr       00:10:94:00:00:11 \
                        -intf_ip_addr       192.168.1.8 \
                        -gateway            192.168.1.1 \
                        -netmask            255.255.255.0 \
                        -arp_send_req       1]

set returnedString [sth::interface_config \
                        -mode               config \
                        -port_handle        $hltHostPort \
                        -intf_mode          "ethernet" \
                        -phy_mode           "copper" \
                        -speed              "ether1000" \
                        -autonegotiation    1 \
                        -duplex             "full" \
                        -src_mac_addr       00:10:94:00:00:22 \
                        -intf_ip_addr       192.168.1.10 \
                        -gateway            192.168.1.1 \
                        -netmask            255.255.255.0 \
                        -arp_send_req       1]

########################################
# Step3: Config BGP router with BFD enabled
########################################

set returnedString [sth::emulation_bgp_config \
                        -mode 		        enable \
                        -port_handle 	        $hltSourcePort \
                        -count 		        1  \
                        -active_connect_enable  1  \
                        -local_as 	        1  \
                        -local_as_mode 	        fixed  \
                        -remote_as 	        123  \
                        -ip_version 	        4  \
                        -local_ip_addr 	        100.1.0.8  \
                        -remote_ip_addr 	100.1.0.1  \
                        -next_hop_ip 	        100.1.0.1  \
                        -netmask 	        24 \
                        -local_router_id 	22.1.1.2  \
                        -hold_time 	        90  \
                        -update_interval        30 \
                        -routes_per_msg         2000  \
                        -ipv4_unicast_nlri      1 \
                        -bfd_registration       1 \
]

keylget returnedString status status
if {!$status} {
	puts $returnedString
    puts "  FAILED:  $returnedString"
	return
}

#config parts are finished

keylget returnedString handles bgpHandle

########################################
# Step4: Start BGP router
########################################

set returnedString [sth::emulation_bgp_control \
                        -mode           start \
                        -handle         $bgpHandle \
]

keylget returnedString status status
if {!$status} {
	puts $returnedString
    puts "  FAILED:  $returnedString"
	return
}

after 2000

########################################
# Step5: Check BGP status
########################################

set returnedString [sth::emulation_bgp_info \
                        -mode           stats \
                        -handle         $bgpHandle
]

keylget returnedString status status
if {!$status} {
	puts $returnedString
    puts "  FAILED:  $returnedString"
	return
}

########################################
# Step6: Disable BFD 
########################################

set returnedString [sth::emulation_bgp_config \
                        -mode 		    modify \
                        -handle             $bgpHandle \
                        -bfd_registration   0 \
]

keylget returnedString status status
if {!$status} {
	puts $returnedString
    puts "  FAILED:  $returnedString"
	return
}

# Step7: Telnet the DUT to check the neighbor status of BFD

########################################
#step8: Release resources
########################################
set returnedString [::sth::cleanup_session -port_list $portList]

keylget returnedString status status
if {!$status} {
	puts $returnedString
    puts "  FAILED:  $returnedString"
	return
}


puts "_SAMPLE_SCRIPT_SUCCESS"

