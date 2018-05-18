
# Run sample:
#            c:>tclsh HLTAPI_ipv6AutoConfig_vlan l 10.61.44.2 3/1 3/3
#            c:>tclsh HLTAPI_ipv6AutoConfig_vlan 10.61.44.2-10.61.44.7 3/1 3/3

package require SpirentHltApi

set device_list      [lindex $argv 0]
set device_list [regsub -all {\-} $device_list " "]
set port1        [lindex $argv 1]
set port2        [lindex $argv 2]
set port_list "$port1 $port2"
set i 1
foreach device $device_list {
    set device$i $device
    incr i
}
set device$i $device

##############################################################
#config the parameters for the logging
##############################################################

set test_sta [sth::test_config\
		-log                                              1\
		-logfile                                          ipv6AutoConfig_logfile\
		-vendorlogfile                                    ipv6AutoConfig_stcExport\
		-vendorlog                                        1\
		-hltlog                                           1\
		-hltlogfile                                       ipv6AutoConfig_hltExport\
		-hlt2stcmappingfile                               ipv6AutoConfig_hlt2StcMapping\
		-hlt2stcmapping                                   1\
		-log_level                                        7]

set status [keylget test_sta status]
if {$status == 0} {
	puts "run sth::test_config failed"
	puts $test_sta
} else {
	puts "***** run sth::test_config successfully"
}

##############################################################
#config the parameters for optimization and parsing
##############################################################

set test_ctrl_sta [sth::test_control\
		-action                                           enable]

set status [keylget test_ctrl_sta status]
if {$status == 0} {
	puts "run sth::test_control failed"
	puts $test_ctrl_sta
} else {
	puts "***** run sth::test_control successfully"
}

##############################################################
#connect to chassis and reserve port list
##############################################################

set i 0

set intStatus [sth::connect -device $device -port_list $port_list -offline 0]

set chassConnect [keylget intStatus status]
if {$chassConnect} {
	foreach port $port_list {
		incr i
		set port$i [keylget intStatus port_handle.$device.$port]
		puts "\n reserved ports : $intStatus"
	}
} else {
	set passFail FAIL
	puts "\nFailed to retrieve port handle! Error message: $intStatus"
}

##############################################################
#get the device info
##############################################################

set device_info [sth::device_info\
		-ports\
		-port_handle                                      $port1 \
		-fspec_version]

set status [keylget device_info status]
if {$status == 0} {
	puts "run sth::device_info failed"
	puts $device_info
} else {
	puts "***** run sth::device_info successfully"
}

##############################################################
#interface config
##############################################################

set int_ret0 [sth::interface_config \
		-mode                                             config \
		-port_handle                                      $port1 \
		-intf_mode                                        ethernet\
		-phy_mode                                         fiber\
		-scheduling_mode                                  RATE_BASED \
		-enable_ping_response                             0 \
		-control_plane_mtu                                1500 \
		-transmit_clock_source                            INTERNAL \
		-flow_control                                     false \
		-deficit_idle_count                               false \
		-speed                                            ether10000 \
		-data_path_mode                                   normal \
		-port_mode                                        LAN \
		-autonegotiation                                  1 \
]

set status [keylget int_ret0 status]
if {$status == 0} {
	puts "run sth::interface_config failed"
	puts $int_ret0
} else {
	puts "***** run sth::interface_config successfully"
}

##############################################################
#create device and config the protocol on it
##############################################################

#start to create the device: Device 1

set device_ret0 [sth::emulation_ipv6_autoconfig\
		-mode                                             create\
		-ip_version                                       6\
		-encap                                            ethernet_vlan\
		-port_handle                                      $port1\
		-local_ipv6_prefix_len                            64 \
		-gateway_ipv6_addr_step                           :: \
		-gateway_ipv6_addr                                2001::1 \
		-local_ipv6_addr                                  2001::2 \
		-local_ipv6_addr_step                             ::1 \
		-count                                            3 \
		-mac_addr                                         00:10:94:00:00:01 \
		-mac_addr_step                                    00:00:00:00:00:01 \
		-router_solicit_retransmit_delay                  3000 \
		-router_solicit_retry                             2 \
		-vlan_id 						4\
		-vlan_id_step 					2\
		-vlan_id_mode					increment\
		-vlan_priority 					2\
]

set status [keylget device_ret0 status]
if {$status == 0} {
	puts "run sth::emulation_ipv6_autoconfig failed"
	puts $device_ret0
} else {
	puts "***** run sth::emulation_ipv6_autoconfig successfully"
}
set device [keylget device_ret0 handle]
#config part is finished
stc::perform SaveAsXml -filename ipv6AutoConfig_vlan.xml
##############################################################
#start devices
##############################################################

set device_ret1 [sth::emulation_ipv6_autoconfig\
		-mode                                             modify\
		-handle                                      $device\
		-local_ipv6_prefix_len                            64 \
		-gateway_ipv6_addr_step                           :: \
		-gateway_ipv6_addr                                2001::1 \
		-local_ipv6_addr                                  2001::2 \
		-local_ipv6_addr_step                             ::1 \
		-mac_addr                                         00:10:94:00:00:01 \
		-mac_addr_step                                    00:00:00:00:00:01 \
		-router_solicit_retransmit_delay                  3000 \
		-router_solicit_retry                             2 \
		-vlan_id 						5\
		-vlan_id_step 					3\
		-vlan_id_mode					increment\
		-vlan_priority 					3\
]

set status [keylget device_ret0 status]
if {$status == 0} {
	puts "run sth::emulation_ipv6_autoconfig failed"
	puts $device_ret1
} else {
	puts "***** run sth::emulation_ipv6_autoconfig successfully"
}
stc::perform SaveAsXml -filename ipv6AutoConfig_vlan_modified.xml
set ctrl_ret1 [sth::emulation_ipv6_autoconfig_control    \
		-port_handle                                      "$port1 "\
		-action                                           start\
]

set status [keylget ctrl_ret1 status]
if {$status == 0} {
	puts "run sth::emulation_ipv6_autoconfig_control failed"
	puts $ctrl_ret1
} else {
	puts "***** run sth::emulation_ipv6_autoconfig_control successfully"
}

##############################################################
#start to get the device results
##############################################################

set results_ret1 [sth::emulation_ipv6_autoconfig_stats    \
		-port_handle                                      "$port1 "\
		-mode                                             aggregate\
		-action                                           collect\
]

set status [keylget results_ret1 status]
if {$status == 0} {
	puts "run sth::emulation_ipv6_autoconfig_stats failed"
	puts $results_ret1
} else {
	puts "***** run sth::emulation_ipv6_autoconfig_stats successfully, and results is:"
	puts "$results_ret1\n"
}



##############################################################
#clean up the session, release the ports reserved and cleanup the dbfile
##############################################################

set cleanup_sta [sth::cleanup_session\
		-port_handle                                      $port1 \
		-clean_dbfile                                     1]

set status [keylget cleanup_sta status]
if {$status == 0} {
	puts "run sth::cleanup_session failed"
	puts $cleanup_sta
} else {
	puts "***** run sth::cleanup_session successfully"
}

puts "**************Finish***************"

