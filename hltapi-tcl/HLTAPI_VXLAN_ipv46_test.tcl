package require SpirentHltApi

##############################################################
#config the parameters for the logging
##############################################################

set test_sta [sth::test_config\
		-log                                              1\
		-logfile                                          hlapiGen_vxlan_logfile\
		-vendorlogfile                                    hlapiGen_vxlan_stcExport\
		-vendorlog                                        1\
		-hltlog                                           1\
		-hltlogfile                                       hlapiGen_vxlan_hltExport\
		-hlt2stcmappingfile                               hlapiGen_vxlan_hlt2StcMapping\
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
#connect to chassis and reserve port list
##############################################################

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

set i 0

set returnedString [sth::connect -device $device_list -port_list $port_list]

keylget returnedString status status
if {!$status} {
	puts $returnedString
    puts "  FAILED:  $status"
	return
} 

keylget returnedString port_handle.$device2.$port2 hltDstPort
keylget returnedString port_handle.$device1.$port1 hltSrcPort


#create ipv46 raw device
set device_ret1 [::sth::emulation_device_config\
                -port_handle $hltSrcPort\
                -mode create\
                -count 1\
                -router_id 10.0.0.12\
                -router_id_ipv6 2001::2\
                -ip_version ipv46\
                -intf_ip_addr 10.0.0.2\
                -gateway_ip_addr 10.0.0.1\
                -intf_prefix_len 24\
                -intf_ipv6_addr 2000::2\
                -intf_ipv6_prefix_len 64\
                -gateway_ipv6_addr 2000::1\
                -link_local_ipv6_addr fe80::100\
                -link_local_ipv6_prefix_len 64\
                -mac_addr 00:01:02:03:04:05\
]
set status [keylget device_ret1 status]
if {!$status} {
	puts $device_ret1
        puts "  FAILED:  $device_ret1"
	return
}

set device_ret2 [::sth::emulation_device_config\
                -port_handle $hltDstPort\
                -mode create\
                -count 1\
                -router_id 10.0.1.12\
                -router_id_ipv6 2002::2\
                -ip_version ipv46\
                -intf_ip_addr 10.0.0.1\
                -gateway_ip_addr 10.0.0.2\
                -intf_prefix_len 24\
                -intf_ipv6_addr 2000::1\
                -intf_ipv6_prefix_len 64\
                -gateway_ipv6_addr 2000::2\
                -link_local_ipv6_addr fe80::200\
                -link_local_ipv6_prefix_len 64\
                -mac_addr 00:01:02:03:04:06\
]
set status [keylget device_ret2 status]
if {!$status} {
	puts $device_ret2
        puts "  FAILED:  $device_ret2"
	return
}

set vm1 [keylget device_ret1 handle]
set vm2 [keylget device_ret2 handle]

#create the multicate 
set macstgroup_1 [sth::emulation_multicast_group_config\
		-mode                                             create\
		-ip_prefix_len                                    32 \
		-ip_addr_start                                    225.0.0.1 \
		-ip_addr_step                                     1 \
		-num_groups                                       1 \
		-pool_name                                        Ipv4Group_1 \
]
set macstgroup1 "[keylget macstgroup_1 handle]"

set vtep_ret1 [::sth::emulation_vxlan_config\
                -port_handle $hltSrcPort\
                -mode create\
                -router_id 192.0.0.3\
		-router_id_ipv6 3001::2\
                -ip_version ipv46\
                -intf_ip_addr 10.10.10.10\
                -gateway_ip_addr 20.20.20.20\
                -intf_prefix_len 24\
		-intf_ipv6_addr 3000::1\
                -intf_ipv6_prefix_len 64\
                -gateway_ipv6_addr 3000::2\
                -link_local_ipv6_addr fe80::300\
                -link_local_ipv6_prefix_len 64\
                -mac_addr 30:01:02:03:04:05\
                -mac_addr_step 00:00:00:00:00:01\
		-udp_dst_port 4790\
		-auto_select_udp_src_port true\
		-multicast_type MULTICAST_IGMP\
		-udp_checksum_enabled false\
		-vni 2\
		-communication_type MULTICAST_LEARNING\
		-multicast_group $macstgroup1\
		-vm_hosts $vm1\
]
set status [keylget vtep_ret1 status]
if {!$status} {
	puts $vtep_ret1
        puts "  FAILED:  $vtep_ret1"
	return
}

set vtep_ret2 [::sth::emulation_vxlan_config\
                -port_handle $hltDstPort\
                -mode create\
                -router_id 192.0.0.4\
		-router_id_ipv6 3002::2\
                -ip_version ipv46\
                -intf_ip_addr 20.20.20.20\
                -gateway_ip_addr 10.10.10.10\
                -intf_prefix_len 24\
		-intf_ipv6_addr 3000::2\
                -intf_ipv6_prefix_len 64\
                -gateway_ipv6_addr 3000::1\
                -link_local_ipv6_addr fe80::400\
                -link_local_ipv6_prefix_len 64\
                -mac_addr 40:01:02:03:04:05\
		-udp_dst_port 4790\
		-auto_select_udp_src_port true\
		-multicast_type MULTICAST_IGMP\
		-udp_checksum_enabled false\
		-vni 2\
		-communication_type MULTICAST_LEARNING\
		-multicast_group $macstgroup1\
		-vm_hosts $vm2\
]

set status [keylget vtep_ret2 status]
if {!$status} {
	puts $vtep_ret2
        puts "  FAILED:  $vtep_ret2"
	return
}

set vxlansegmenthandle [keylget vtep_ret1 vxlansegmenthandle]
set vtep_device1 [keylget vtep_ret1 handle]
puts $vtep_device1
set vtep_device2 [keylget vtep_ret2 handle]
puts $vtep_device2

puts "setup the traffic between the vm1 and the vm2"
set traffic_results [sth::traffic_config\
			-mode create\
			-port_handle $hltSrcPort\
			-port_handle2 $hltDstPort\
			-bidirectional 1\
			-emulation_src_handle $vm1\
			-emulation_dst_handle $vm2\
			-l3_protocol ipv4\
			]
set status [keylget traffic_results status]
if {!$status} {
	puts $traffic_results
        puts "  FAILED:  $traffic_results"
	return
}
#config parts are finished
stc::perform saveasxml -filename "vxlan_ipv46.xml"

set ctrl_result [::sth::emulation_vxlan_control -port_handle "$hltSrcPort $hltDstPort" -action start]
set status [keylget ctrl_result status]
if {!$status} {
	puts $ctrl_result
        puts "  FAILED:  $ctrl_result"
	return
}

sleep 10

set results [::sth::emulation_vxlan_stats -port_handle "$hltSrcPort $hltDstPort"]
set status [keylget results status]
if {!$status} {
	puts $results
        puts "  FAILED:  $results"
	return
} else {
        puts $results
}

set ctrl_result [::sth::emulation_vxlan_control -port_handle "$hltSrcPort $hltDstPort" -action stop]
set status [keylget ctrl_result status]
if {!$status} {
	puts $ctrl_result
        puts "  FAILED:  $ctrl_result"
	return
}

set results [::sth::emulation_vxlan_stats -port_handle "$hltSrcPort $hltDstPort"]
set status [keylget results status]
if {!$status} {
	puts $results
        puts "  FAILED:  $results"
	return
} else {
        puts $results
}

puts "END"