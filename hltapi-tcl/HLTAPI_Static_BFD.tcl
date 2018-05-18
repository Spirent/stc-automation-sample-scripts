#################################
#
# File Name:         HLTAPI_BGPv4_BFD.tcl
#
# Description:       This script demonstrates the use of Spirent HLTAPI to setup BFD test for static routing.
#                    In this test, the interface is not used by any dynamic routing protocol.
#
# Test Step:         1. Reserve and connect chassis ports
#                    2. Interface config
#                    3. Config BFD router
#                    4. Start BFD router
#                    5. Retrieve BFD statistics
#                    6. Stop BFD router
#                    7. Release resources
#
# DUT configuration:
#             interface FastEthernet1/0
#               ip address 100.1.0.1 255.255.255.0
#               duplex full
#               bfd interval 500 min_rx 500 multiplier 3
#            !
#            ip route static bfd FastEthernet1/0 100.1.0.6
#            ip route 100.1.0.0 255.255.255.0 FastEthernet1/0 100.1.0.6
#
#
#
# Topology:
#
#              STC Port1                                 
#             [BFD Router]-------------------[Cisco DUT]                                         
#                            100.1.0.0/24        
#                                         
#
#################################

# Run sample:
#            c:>tclsh HLTAPI_Static_BFD.tcl 10.61.44.2 3/1 3/3
#            c:>tclsh HLTAPI_Static_BFD.tcl "10.61.44.2 10.61.44.7" 3/1 3/3

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

########################################
#Step1: Reserve and connect chassis ports
########################################

set returnedString [sth::connect -device $device_list -port_list $port_list]

keylget returnedString status status
if {!$status} {
puts $returnedString
    return "  FAILED:  $status"
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
# Step3: Config BFD router
########################################

set returnedString [sth::emulation_bfd_config \
                        -port_handle            $hltSourcePort \
                        -mode                   create \
                        -count                  1 \
                        -ip_version             IPv4 \
                        -local_mac_addr         00:10:94:00:00:05 \
                        -intf_ip_addr           100.1.0.6 \
                        -remote_ip_addr         100.1.0.1 \
                        -gateway_ip_addr        100.1.0.1 \
                        -detect_multiplier      3 \
                        -echo_rx_interval       10 \
                        -active_mode            active \
                        -session_discriminator  6 \
]

keylget returnedString status status
if {!$status} {
    puts $returnedString
    return "  FAILED:  $returnedString"
}

#config parts are finished

keylget returnedString handle bfdHandle

########################################
# Step4: Start BFD router
########################################

set returnedString [sth::emulation_bfd_control \
                        -mode           start \
                        -handle         $bfdHandle \
]

after 4000

########################################
# Step4: Retrieve BFD statistics
########################################

set returnedString [sth::emulation_bfd_info \
                        -mode           learned_info \
                        -handle         $bfdHandle]

keylget returnedString status status
if {!$status} {
puts $returnedString
    return "  FAILED:  $returnedString"
}

keylget returnedString bfd_session_state bfdState

if {[string match -nocase "UP" $bfdState]} {
    puts "\n BFD session is established successfully."
}

########################################
# Step5: Stop BFD router
########################################

set returnedString [sth::emulation_bfd_control \
                        -mode           stop \
                        -handle         $bfdHandle \
]
keylget returnedString status status
if {!$status} {
puts $returnedString
    return "  FAILED:  $returnedString"
}

########################################
#step6: Release resources
########################################
set returnedString [::sth::cleanup_session -port_list $portList]

keylget returnedString status status
if {!$status} {
puts $returnedString
    return "  FAILED:  $returnedString"
}
puts "_SAMPLE_SCRIPT_SUCCESS"



