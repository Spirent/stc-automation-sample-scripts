package require SpirentHltApi
##############################################################
#config the parameters for the logging
##############################################################

set test_sta [sth::test_config\
        -log                                              1\
        -logfile                                          evpn_wizard_logfile\
        -vendorlogfile                                    evpn_wizard_stcExport\
        -vendorlog                                        1\
        -hltlog                                           1\
        -hltlogfile                                       evpn_wizard_hltExport\
        -hlt2stcmappingfile                               evpn_wizard_hlt2StcMapping\
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
set device [lindex $argv 0]
set port_list {}
set port_list [lrange $argv 1 end]

set intStatus [sth::connect -device $device -port_list $port_list -break_locks 1 -offline 0]

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
#interface config
##############################################################

set int_ret0 [sth::interface_config \
        -mode                                             config \
        -port_handle                                      $port1 \
        -create_host                                      false \
        -scheduling_mode                                  PORT_BASED \
        -port_loadunit                                    PERCENT_LINE_RATE \
        -port_load                                        10 \
        -enable_ping_response                             0 \
        -control_plane_mtu                                1500 \
        -duplex                                           full \
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
#interface config
##############################################################

set int_ret0 [sth::interface_config \
        -mode                                             config \
        -port_handle                                      $port2 \
        -create_host                                      false \
        -scheduling_mode                                  PORT_BASED \
        -port_loadunit                                    PERCENT_LINE_RATE \
        -port_load                                        10 \
        -enable_ping_response                             0 \
        -control_plane_mtu                                1500 \
        -duplex                                           full \
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

# evpn provider port config

set core_port_config_ret1 [sth::emulation_evpn_provider_port_config \
    -port_handle $port1\
    -mode create \
    -dut_interface_ipv4_addr          192.85.1.1 \
    -dut_interface_ipv4_addr_step     0.0.1.0 \
    -dut_interface_ipv4_prefix_length  24 \
    -sub_interface_enable             true \
    -sub_interface_count              10 \
    -vlan_id                          1 \
    -vlan_id_step                     1   \
    ]

set status [keylget core_port_config_ret1 status]
if {$status == 0} {
    puts "run sth::emulation_evpn_provider_port_config failed"
    puts $core_port_config_ret1
} else {
    puts "***** run sth::emulation_evpn_provider_port_config successfully"
}

# evpn customer port config 

set customer_port_config_ret1 [sth::emulation_evpn_cust_port_config \
    -port_handle $port2\
    -mode create \
    -sub_interface_enable             true \
    -sub_interface_count              10 \
    -vlan_id                          1 \
    -vlan_id_step                     1 \
    ]

set status [keylget customer_port_config_ret1 status]
if {$status == 0} {
    puts "run sth::emulation_evpn_cust_port_config failed"
    puts $customer_port_config_ret1
} else {
    puts "***** run sth::emulation_evpn_cust_port_config successfully"
}

# evpn network config ---igp ospf , mpls ospf 
set evpn_config_ospf_ret1 [sth::emulation_evpn_wizard_config \
    -mode create \
    -dut_router_id 110.0.0.1 \
    -dut_as 1 \
    -dut_4byte_as_enable false \
    -dut_4byte_as 1:1 \
    -use_provider_ports true \
    -use_cust_ports true \
    -igp_protocol ospf \
    -mpls_protocol ospf \
    -igp_ospf_area_id 1.0.0.0 \
    -igp_ospf_network_type p2p \
    -igp_ospf_router_priority 1\
    -igp_ospf_interface_cost 2\
    -igp_ospf_options ebit \
    -igp_ospf_auth_mode none \
    -igp_ospf_auth_password abc \
    -igp_ospf_auth_md5_key 2 \
    -igp_ospf_graceful_restart_enable false \
    -igp_ospf_graceful_restart_type ll_signalling \
    -igp_ospf_bfd_enable false \
    -mpls_ospf_sr_algorithms 1\
    -mpls_ospf_sid_base 101 \
    -mpls_ospf_sid_range 120 \
    -mpls_ospf_node_sid_index 1 \
    -mpls_ospf_node_sid_index_step 2 \
    -p_router_enable false \
    -p_router_num_per_subif 1 \
    -p_router_topology_type tree \
    -p_router_id_start 192.1.1.1 \
    -p_router_id_step 0.0.1.0 \
    -p_router_ipv4_addr 2.0.0.1\
    -p_router_ipv4_prefix_len 24 \
    -pe_router_num_per_subif 1 \
    -pe_router_id_start 110.0.0.2 \
    -pe_router_id_step 0.0.0.1 \
    -bgp_route_reflector_enable false \
    -vrf_count  10 \
    -vrf_rd_assignment  use_rt \
    -vrf_route_target_start 1:1 \
    -vrf_route_target_step 1:1 \
    -cust_ce_vrf_assignment sequential\
    -cust_rd_start 1:1 \
    -cust_rd_step_per_vrf_enable false \
    -cust_rd_step_per_vrf 1:1 \
    -cust_rd_step_per_ce_enable false \
    -cust_rd_step_per_ce 1:1 \
    -provider_pe_vrf_assignment pe_per_vpn\
    -provider_pe_vrf_count 1 \
    -provider_ce_bgp_as_enable false \
    -provider_ce_bgp_as 1 \
    -provider_ce_bgp_as_step_per_ce_enable false \
    -provider_ce_bgp_as_step_per_ce 2 \
    -provider_ce_bgp_as_step_per_vrf_enable false \
    -provider_ce_bgp_as_step_per_vrf 2 \
    -provider_ce_bgp_4byte_as_enable false \
    -provider_ce_bgp_4byte_as 1:1 \
    -provider_ce_bgp_4byte_as_step_per_ce_enable false \
    -provider_ce_bgp_4byte_as_step_per_ce 2 \
    -provider_ce_bgp_4byte_as_step_per_vrf_enable false  \
    -provider_ce_bgp_4byte_as_step_per_vrf 2 \
    -provider_rd_start 1:1 \
    -provider_rd_step_per_vrf_enable false \
    -provider_rd_step_per_vrf 1:1 \
    -provider_rd_step_per_ce_enable false \
    -provider_rd_step_per_ce 1:1 \
    -traffic_flow_direction none\
    -traffic_stream_group_method  aggregate \
    -traffic_use_single_stream_per_endpoint_pair false  \
    -traffic_load_percent_provider    11\
    -traffic_load_percent_cust    12 \
]
set status [keylget evpn_config_ospf_ret1 status]
if {$status == 0} {
    puts "run sth::emulation_evpn_wizard_config failed"
    puts $evpn_config_ospf_ret1
} else {
    puts "***** run sth::emulation_evpn_wizard_config successfully"
    set evpn_handle1 [keylget evpn_config_ospf_ret1 handle]
    if {$evpn_handle1 ne ""} {
        puts "***** get evpn network handle successfully"
        set ce_router_handle ""
        set p_router_handle ""
        set rr_router_handle ""
        set pe_router_handle ""
        set ce_router_handle [keylget evpn_handle1 ce_router]
        set p_router_handle [keylget evpn_handle1 p_router]
        set rr_router_handle [keylget evpn_handle1 rr_router]
        set pe_router_handle [keylget evpn_handle1 pe_router]
        set router_handles ""
        set router_handles [concat $router_handles $ce_router_handle]
        set router_handles [concat $router_handles $p_router_handle]
        set router_handles [concat $router_handles $rr_router_handle]
        set router_handles [concat $router_handles $pe_router_handle]
    } else {
        puts "***** get evpn network handle failed"
    }
}

stc::perform SaveAsXml -filename HLTAPI_evpn_wizard_test1.xml

set evpn_control_ret [sth::emulation_evpn_control \
        -port_handle $port1 $port2 \
        -action start]

set status [keylget evpn_control_ret status]
if {$status == 0} {
    puts "run sth::emulation_evpn_control failed"
    puts $evpn_control_ret
} else {
    puts "***** run sth::emulation_evpn_control successfully"
}

after 10000

set evpn_info_ospf_ret1 [sth::emulation_routing_mpls_info \
        -handle $router_handles \
        -mode ospfv2]

set status [keylget evpn_info_ospf_ret1 status]
if {$status == 0} {
    puts "run sth::emulation_routing_mpls_info failed"
    puts $evpn_info_ospf_ret1
} else {
    puts "***** run sth::emulation_routing_mpls_info successfully"
    puts $evpn_info_ospf_ret1
}

set evpn_info_summary_ret1 [sth::emulation_routing_mpls_info \
        -port_handle $port1 $port2 \
        -mode summary]

set status [keylget evpn_info_summary_ret1 status]
if {$status == 0} {
    puts "run sth::emulation_routing_mpls_info failed"
    puts $evpn_info_summary_ret1
} else {
    puts "***** run sth::emulation_routing_mpls_info successfully"
    puts $evpn_info_summary_ret1
}

set evpn_info_bgp_ret1 [sth::emulation_routing_mpls_info \
        -handle $router_handles \
        -mode bgp]

set status [keylget evpn_info_bgp_ret1 status]
if {$status == 0} {
    puts "run sth::emulation_routing_mpls_info failed"
    puts $evpn_info_bgp_ret1
} else {
    puts "***** run sth::emulation_routing_mpls_info successfully"
    puts $evpn_info_bgp_ret1
}

set evpn_info_bfd_ret1 [sth::emulation_routing_mpls_info \
        -handle $router_handles \
        -mode bfd]

set status [keylget evpn_info_bfd_ret1 status]
if {$status == 0} {
    puts "run sth::emulation_routing_mpls_info failed"
    puts $evpn_info_bfd_ret1
} else {
    puts "***** run sth::emulation_routing_mpls_info successfully"
    puts $evpn_info_bfd_ret1
}


set evpn_control_ret [sth::emulation_evpn_control \
        -handle $router_handles\
        -action stop]

set status [keylget evpn_control_ret status]
if {$status == 0} {
    puts "run sth::emulation_evpn_control failed"
    puts $evpn_control_ret
} else {
    puts "***** run sth::emulation_evpn_control successfully"
}

set evpn_config_ospf_del_ret1 [sth::emulation_evpn_wizard_config \
       -mode             delete \
       -handle      $evpn_handle1 \
    ]

#  delete evpn network configuration 

set status [keylget evpn_config_ospf_del_ret1 status]
if {$status == 0} {
    puts "run sth::emulation_evpn_wizard_config failed"
    puts $evpn_config_ospf_del_ret1
} else {
    puts "***** run sth::emulation_evpn_wizard_config successfully"
}

# cleanup the chass and  port

set cleanup_sta [sth::cleanup_session\
        -port_handle                                      $port1 $port2\
        -clean_dbfile                                     1]

set status [keylget cleanup_sta status]
if {$status == 0} {
    puts "run sth::cleanup_session failed"
    puts $cleanup_sta
} else {
    puts "***** run sth::cleanup_session successfully"
}

puts "**************Finish***************"