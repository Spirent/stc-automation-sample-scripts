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

set port_list "$port1 $port2"

set i 1
foreach device $device_list {
    set device$i $device
    incr i
}
set device$i $device
set port_list "$port1 $port2";

set i 0

set returnedString [sth::connect -device $device_list -port_list $port_list -offline 0]

keylget returnedString status status
if {!$status} {
	puts $returnedString
    puts "  FAILED:  $status"
	return
} 

keylget returnedString port_handle.$device2.$port2 hltDstPort
keylget returnedString port_handle.$device1.$port1 hltSrcPort


#create ipv4 raw device on the port1
set device_ret1 [::sth::emulation_device_config\
                -port_handle $hltSrcPort\
                -mode create\
                -count 1\
                -router_id 192.0.0.1\
                -ip_version ipv4\
                -intf_ip_addr 11.11.11.11\
                -intf_ip_addr_step 0.0.0.1\
                -gateway_ip_addr 11.11.11.12\
                -gateway_ip_addr_step 0.0.0.1\
                -intf_prefix_len 24\
                -mac_addr 00:01:02:03:04:05\
                -mac_addr_step 00:00:00:00:00:01\
                -encapsulation ethernet_ii_qinq\
                -vlan_id 10\
                -vlan_outer_id 20\
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
                -router_id 192.0.0.2\
                -ip_version ipv4\
                -intf_ip_addr 11.11.11.12\
                -intf_ip_addr_step 0.0.0.1\
                -gateway_ip_addr 11.11.11.11\
                -gateway_ip_addr_step 0.0.0.1\
                -intf_prefix_len 24\
                -mac_addr 00:01:02:03:04:06\
                -mac_addr_step 00:00:00:00:00:01\
                -encapsulation ethernet_ii_qinq\
                -vlan_id 10\
                -vlan_outer_id 20\
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
                -ip_version ipv4\
                -intf_ip_addr 10.10.10.10\
                -intf_ip_addr_step 0.0.0.1\
                -gateway_ip_addr 10.10.10.11\
                -gateway_ip_addr_step 0.0.0.1\
                -intf_prefix_len 24\
                -mac_addr 30:01:02:03:04:05\
                -mac_addr_step 00:00:00:00:00:01\
		-udp_dst_port 4789\
		-auto_select_udp_src_port true\
		-multicast_type MULTICAST_IGMP\
		-udp_checksum_enabled false\
		-vni 2\
		-communication_type MULTICAST_LEARNING\
		-vm_hosts $vm1\
                -encapsulation ethernet_ii_qinq\
                -vlan_id 11\
                -vlan_outer_id 21\
                -multicast_group $macstgroup1\
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
                -ip_version ipv4\
                -intf_ip_addr 10.10.10.11\
                -intf_ip_addr_step 0.0.0.1\
                -gateway_ip_addr 10.10.10.10\
                -gateway_ip_addr_step 0.0.0.1\
                -intf_prefix_len 24\
                -mac_addr 40:01:02:03:04:05\
                -mac_addr_step 00:00:00:00:00:01\
		-udp_dst_port 4789\
		-auto_select_udp_src_port true\
		-multicast_type MULTICAST_IGMP\
		-udp_checksum_enabled false\
		-vni 2\
		-communication_type MULTICAST_LEARNING\
		-vm_hosts $vm2\
                -encapsulation ethernet_ii_qinq\
                -vlan_id 11\
                -vlan_outer_id 21\
                -multicast_group $macstgroup1\
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

set traffic_results [sth::traffic_config\
			-mode create\
			-port_handle $hltDstPort\
			-bidirectional 0\
			-l3_protocol ipv4\
                        -l3_length 150\
                        -length_mode fixed\
                        -inner_l3_protocol ipv4\
                        -ip_src_addr  10.10.10.11\
                        -ip_dst_addr  10.10.10.10\
                        -inner_ip_src_addr 11.11.11.12 \
                        -inner_ip_dst_addr 11.11.11.11\
                        -inner_ip_gw 11.11.11.11\
                        -l4_protocol udp\
                        -udp_src_port 456\
                        -udp_dst_port 4789\
                        -mac_src 40:01:02:03:04:05 \
                        -mac_dst 30:01:02:03:04:05\
                        -inner_mac_src 00:01:02:03:04:06\
                        -inner_mac_dst 00:01:02:03:04:05 \
                        -l2_encap ethernet_ii_vlan \
                        -vlan_id 11\
                        -vlan_id_outer 21\
                        -inner_vlan_id 10\
                        -inner_vlan_id_outer 20\
                        -inner_l2_encap ethernet_ii_vlan\
			-vxlan    1\
                        -vni 2\
                        -ipv4_multicast_group_addr 225.0.0.1\
                        -qinq_incr_mode inner \
                        -vlan_id_mode increment\
                        -vlan_id_step 2\
                        -vlan_id_count 5\
                        -vlan_id_outer_mode increment\
                        -vlan_id_outer_count 5\
                        -vlan_id_outer_step 3\
                        -vlan_user_priority 2\
                        -vlan_priority_mode increment\
                        -vlan_priority_count 2\
                        -vlan_outer_user_priority 3\
                        -vlan_cfi 1\
                        -vlan_outer_cfi 0\
                        -inner_qinq_incr_mode inner\
                        -inner_vlan_id_mode increment\
                        -inner_vlan_id_step 2\
                        -inner_vlan_id_count 5\
                        -inner_vlan_id_outer_mode increment\
                        -inner_vlan_id_outer_count 5\
                        -inner_vlan_id_outer_step 3\
                        -inner_vlan_user_priority 4\
                        -inner_vlan_priority_mode increment\
                        -inner_vlan_priority_count 2\
                        -inner_vlan_outer_user_priority 5\
                        -inner_vlan_cfi 1\
                        -inner_vlan_outer_cfi 0\
                        ]

puts $traffic_results
set streamblock [keylget traffic_results stream_id]
set traffic_results [sth::traffic_config\
			-mode modify\
			-stream_id $streamblock\
			-bidirectional 0\
			-l3_protocol ipv4\
                        -l3_length 150\
                        -length_mode fixed\
                        -inner_l3_protocol ipv4\
                        -ip_src_addr  20.10.10.11\
                        -ip_dst_addr  20.10.10.10\
                        -inner_ip_src_addr 21.11.11.12 \
                        -inner_ip_dst_addr 21.11.11.11\
                        -inner_ip_gw 21.11.11.11\
                        -l4_protocol udp\
                        -udp_src_port 456\
                        -udp_dst_port 4789\
                        -mac_src 50:01:02:03:04:05 \
                        -mac_dst 60:01:02:03:04:05\
                        -inner_mac_src 10:01:02:03:04:06\
                        -inner_mac_dst 10:01:02:03:04:05 \
                        -l2_encap ethernet_ii_vlan \
                        -vlan_id 16\
                        -vlan_id_outer 26\
                        -inner_vlan_id 15\
                        -inner_vlan_id_outer 25\
                        -inner_l2_encap ethernet_ii_vlan\
			-vxlan    1\
                        -vni 4\
                        -ipv4_multicast_group_addr 225.0.0.10\
                        -qinq_incr_mode inner \
                        -vlan_id_mode increment\
                        -vlan_id_step 3\
                        -vlan_id_count 4\
                        -vlan_id_outer_mode increment\
                        -vlan_id_outer_count 5\
                        -vlan_id_outer_step 4\
                        -vlan_user_priority 2\
                        -vlan_priority_mode increment\
                        -vlan_priority_count 3\
                        -vlan_outer_user_priority 3\
                        -vlan_cfi 1\
                        -vlan_outer_cfi 0\
                        -inner_qinq_incr_mode inner\
                        -inner_vlan_id_mode increment\
                        -inner_vlan_id_step 3\
                        -inner_vlan_id_count 4\
                        -inner_vlan_id_outer_mode increment\
                        -inner_vlan_id_outer_count 4\
                        -inner_vlan_id_outer_step 4\
                        -inner_vlan_user_priority 4\
                        -inner_vlan_priority_mode increment\
                        -inner_vlan_priority_count 3\
                        -inner_vlan_outer_user_priority 3\
                        -inner_vlan_cfi 1\
                        -inner_vlan_outer_cfi 0\
                        ]
puts $traffic_results
stc::perform saveasxml -filename "vxlan_rawstream.xml"
#config parts are finished

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