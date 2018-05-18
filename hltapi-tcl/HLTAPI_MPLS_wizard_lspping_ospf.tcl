################################################################################
#
# File Name:         HLTAPI_MPLS_wizard_lspping_ospf.tcl
#
# Description:       This script demonstrates how to create P/PE/CE routers of MPLS/BGP IP VPN and IGP OSPF routers based on MPLS IP VPN wizard   #                    on  GUI,and get results include LSP-Ping results.
#
# Test Step:         1. Reserve and connect chassis ports
#                    2. Create Provider port on port1
#                    3. Create Customer port on port2
#                    4. Create MPLS IP VPN config,including P/PE/CE/BGP/OSPF/LSP-Ping
#                    5. Start devices 
#                    6. Get info of OSPFv2/v3
#                    7. Get info of BGP/BFD
#                    8. Get info of lsp_ping 
#                    9. Stop devices
#                    10. Delete MPLS IP VPN config
#                    11. Clean up session
#
#5.5.50.50/24                 3.3.3.3                               5.5.5.5                  5.5.4.50                5.5.60.50
# (route)                    (router ID)                          (router ID)              (router ID)               (route)
#  -                            -                                    -                        -                         -
#  |                            |                                    |                        |                         |
#  |                            |                                    |                        |                         |
#  |                            |                                    |                        |                         |
# 
# [CE]----------------------[PE/DUT]---------------------------------[P]---------------------[PE]---------------------[CE]
#                 2.2.2.2/24       1.1.1.1/24              1.1.1.2/24   5.5.5.50/24                  
#STC Port2--------------------DUT---------------------------------STC Port1                     
#
################################################################################

# Run sample:
#            c:\>tclsh HLTAPI_MPLS_wizard_lspping_ospf.tcl 10.61.47.129 1/1 1/2

package require SpirentHltApi

##############################################################
#config the parameters for the logging
##############################################################

set test_sta [sth::test_config\
        -log                                              1\
        -logfile                                          mpls_wizard_logfile\
        -vendorlogfile                                    mpls_wizard_stcExport\
        -vendorlog                                        1\
        -hltlog                                           1\
        -hltlogfile                                       mpls_wizard_hltExport\
        -hlt2stcmappingfile                               mpls_wizard_hlt2StcMapping\
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

########################################
# Step1: Reserve and connect chassis ports
########################################

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

########################################
# Step2: Create Provider port on port1
########################################

set core_port_config_ret4 [sth::emulation_mpls_ip_vpn_provider_port_config \
    -port_handle $port1\
    -mode create \
    -dut_interface_ipv4_addr          1.1.1.1 \
    -dut_interface_ipv4_addr_step     0.0.0.1 \
    -dut_interface_ipv4_prefix_length  24 \
    -sub_interface_enable             true \
    -sub_interface_count              2 \
    -vlan_id                          11 \
    -vlan_id_step                     1   \
    ]

set status [keylget core_port_config_ret4 status]
if {$status == 0} {
    puts "run sth::emulation_mpls_ip_vpn_provider_port_config failed"
    puts $core_port_config_ret4
} else {
    puts "***** run sth::emulation_mpls_ip_vpn_provider_port_config successfully"
}

########################################
# Step3: Create Customer port on port2
########################################

# mpls ip vpn customer port config 

set customer_port_config_ret4 [sth::emulation_mpls_ip_vpn_cust_port_config \
    -port_handle $port2\
    -mode create \
    -dut_interface_ipv4_addr          2.2.2.2 \
    -dut_interface_ipv4_addr_step     0.0.0.1 \
    -dut_interface_ipv4_prefix_length  24 \
    -sub_interface_enable             true \
    -sub_interface_count              5 \
    -vlan_id                          21 \
    -vlan_id_step                     1   \
    ]

set status [keylget customer_port_config_ret4 status]
if {$status == 0} {
    puts "run sth::emulation_mpls_ip_vpn_cust_port_config failed"
    puts $customer_port_config_ret4
} else {
    puts "***** run sth::emulation_mpls_ip_vpn_cust_port_config successfully"
}

#######################################################################
# Step4:  Create MPLS IP VPN config,including P/PE/CE/BGP/OSPF/LSP-Ping
#######################################################################

# mpls ip vpn network config ---igp ospfv2 , mpls ospfv2 

set mpls_config_ospf_ret1 [sth::emulation_mpls_ip_vpn_config \
    -mode create \
    -dut_router_id 3.3.3.3 \
    -dut_as 10 \
    -dut_4byte_as_enable true \
    -dut_4byte_as 9:9 \
    -use_provider_ports true \
    -use_cust_ports true \
    -igp_protocol ospf \
    -mpls_protocol ldp \
    -igp_ospf_area_id 4.4.4.4 \
    -igp_ospf_network_type native \
    -igp_ospf_router_priority 1\
    -igp_ospf_interface_cost 2\
    -igp_ospf_options 0xff \
    -igp_ospf_auth_mode md5 \
    -igp_ospf_auth_password abc \
    -igp_ospf_auth_md5_key 2 \
    -igp_ospf_graceful_restart_enable true \
    -igp_ospf_graceful_restart_type ll_signalling \
    -igp_ospf_bfd_enable true \
    -mpls_ospf_sr_algorithms 1\
    -mpls_ospf_sid_base 101 \
    -mpls_ospf_sid_range 120 \
    -mpls_ospf_node_sid_index 1 \
    -mpls_ospf_node_sid_index_step 2 \
    -p_router_enable true \
    -p_router_num_per_subif 2 \
    -p_router_topology_type tree \
    -p_router_id_start 5.5.5.5 \
    -p_router_id_step 0.0.1.0 \
    -p_router_ipv4_addr 5.5.5.50\
    -p_router_ipv4_prefix_len 24 \
    -pe_router_num_per_subif 3 \
    -pe_router_id_start 5.5.4.50 \
    -pe_router_id_step 0.0.0.1 \
    -bgp_route_reflector_enable true \
    -bgp_route_reflector_per_subif 1 \
    -bgp_route_reflector_per_pe 1 \
    -bgp_route_reflector_id_start 5.5.3.50 \
    -bgp_route_reflector_id_step 0.0.0.2 \
    -bgp_route_reflector_cluster_id 0.0.0.1 \
    -bgp_route_reflector_cluster_id_step 0.0.0.3 \
    -bgp_bfd_enable true \
    -vrf_count  100 \
    -vrf_rd_assignment  manual \
    -vrf_route_target_start 8:8 \
    -vrf_route_target_step 1:1 \
    -cust_ce_vrf_assignment sequential\
    -cust_ce_routing_protocol mixed \
    -cust_ce_bgp_percent 1 \
    -cust_ce_rip_percent 2 \
    -cust_ce_ospf_percent 3 \
    -cust_ce_isis_percent 4 \
    -cust_ce_bgp_as 1 \
    -cust_ce_bgp_as_step_per_ce_enable true \
    -cust_ce_bgp_as_step_per_ce 2 \
    -cust_ce_bgp_as_step_per_vrf_enable true \
    -cust_ce_bgp_as_step_per_vrf 2 \
    -cust_ce_bgp_4byte_as_enable true \
    -cust_ce_bgp_4byte_as 1:1 \
    -cust_ce_bgp_4byte_as_step_per_ce_enable true \
    -cust_ce_bgp_4byte_as_step_per_ce 2 \
    -cust_ce_bgp_4byte_as_step_per_vrf_enable true \
    -cust_ce_bgp_4byte_as_step_per_vrf 1 \
    -cust_rd_start 1:2 \
    -cust_rd_step_per_vrf_enable true \
    -cust_rd_step_per_vrf 1:2 \
    -cust_rd_step_per_ce_enable true \
    -cust_rd_step_per_ce 1:3 \
    -provider_pe_vrf_assignment pe_per_vpn\
    -provider_pe_vrf_count 1 \
    -provider_ce_bgp_as_enable true \
    -provider_ce_bgp_as 1 \
    -provider_ce_bgp_as_step_per_ce_enable true \
    -provider_ce_bgp_as_step_per_ce 2 \
    -provider_ce_bgp_as_step_per_vrf_enable true \
    -provider_ce_bgp_as_step_per_vrf 2 \
    -provider_ce_bgp_4byte_as_enable true \
    -provider_ce_bgp_4byte_as 1:1 \
    -provider_ce_bgp_4byte_as_step_per_ce_enable true \
    -provider_ce_bgp_4byte_as_step_per_ce 2 \
    -provider_ce_bgp_4byte_as_step_per_vrf_enable true  \
    -provider_ce_bgp_4byte_as_step_per_vrf 2 \
    -provider_rd_start 1:4 \
    -provider_rd_step_per_vrf_enable true \
    -provider_rd_step_per_vrf 1:5 \
    -provider_rd_step_per_ce_enable true \
    -provider_rd_step_per_ce 1:2 \
    -cust_vpn_route_start            5.5.50.50 \
    -cust_vpn_route_overlap          true \
    -cust_vpn_route_prefix_len    24 \
    -cust_vpn_route_step             1 \
    -cust_ce_route_type              external \
    -cust_route_count_per_ce              2 \
    -provider_vpn_route_start            5.5.60.50\
    -provider_vpn_route_overlap          true \
    -provider_vpn_route_prefix_len    24 \
    -provider_vpn_route_step             1 \
    -provider_route_count_per_ce              2\
    -vrf_route_mpls_label_type                label_per_route \
    -vrf_route_mpls_label_start               20 \
    -traffic_flow_direction                   bidirectional\
    -traffic_stream_group_method              aggregate \
    -traffic_use_single_stream_per_endpoint_pair true  \
    -traffic_load_percent_provider     11\
    -traffic_load_percent_cust     12 \
    -enable_core_tunnel_lsp_ping   true \
    -enable_vpn_to_dut_tunnel_lsp_ping true \
    -lsp_ping_core_dst_addr              5.5.5.5 \
    -lsp_ping_vpn_dst_addr               5.5.60.50 \
    -lsp_ping_core_interval              5 \
    -lsp_ping_vpn_interval               6 \
    -lsp_ping_core_timeout               4 \
    -lsp_ping_vpn_timeout                5 \
    -lsp_ping_core_ttl          6 \
    -lsp_ping_vpn_ttl          7 \
    -lsp_ping_core_exp_bits     4 \
    -lsp_ping_vpn_exp_bits     5 \
    -lsp_ping_core_validate_fec_stack   true \
    -lsp_ping_vpn_validate_fec_stack   true \
    -lsp_ping_core_enable_nil_fec_label true \
    -lsp_ping_vpn_enable_nil_fec_label true \
    -lsp_ping_core_pad_mode no_pad_tlv \
    -lsp_ping_vpn_pad_mode request_copy_pad_tlv \
    -lsp_ping_core_pad_data 3 \
    -lsp_ping_vpn_pad_data 4 \
]
#puts "\n $mplsipvpn_config_ospf_ret1\n"
set status [keylget mpls_config_ospf_ret1 status]
if {$status == 0} {
    puts "run sth::emulation_mpls_ip_vpn_config failed"
    puts $mpls_config_ospf_ret1
} else {
    puts "***** run sth::emulation_mpls_ip_vpn_config successfully"
    set mpls_handle4 [keylget mpls_config_ospf_ret1 handle]
    if {$mpls_handle4 ne ""} {
        puts "***** get mpls network handle successfully"
        set ce_router_handle ""
        set p_router_handle ""
        set rr_router_handle ""
        set pe_router_handle ""
        set ce_router_handle [keylget mpls_handle4 ce_router]
        set p_router_handle [keylget mpls_handle4 p_router]
        set rr_router_handle [keylget mpls_handle4 rr_router]
        set pe_router_handle [keylget mpls_handle4 pe_router]
        set router_handles ""
        set router_handles [concat $router_handles $ce_router_handle]
        set router_handles [concat $router_handles $p_router_handle]
        set router_handles [concat $router_handles $rr_router_handle]
        set router_handles [concat $router_handles $pe_router_handle]
    } else {
        puts "***** get mpls ip vpn handle failed"
    }
}

stc::perform SaveAsXml -filename HLTAPI_mpls_wizard_lsp.xml

#########################
# Step5:  Start devices
#########################
set mpls_control_ret [sth::emulation_mpls_ip_vpn_control \
        -port_handle $port1 $port2 \
        -action start]

set status [keylget mpls_control_ret status]
if {$status == 0} {
    puts "run sth::emulation_mpls_ip_vpn_control failed"
    puts $mpls_control_ret
} else {
    puts "***** run sth::emulation_mpls_ip_vpn_control successfully"
}

after 1000

###################################
# Step6:  Get info of OSPFv2/v3
###################################
set mpls_info_ospfv2_ret1 [sth::emulation_mpls_ip_vpn_info \
        -handle $router_handles \
        -mode ospfv2]

set status [keylget mpls_info_ospfv2_ret1 status]
if {$status == 0} {
    puts "run sth::emulation_mpls_ip_vpn_info failed"
    puts $mpls_info_ospfv2_ret1
} else {
    puts "***** run sth::emulation_mpls_ip_vpn_info successfully"
    puts $mpls_info_ospfv2_ret1
}

set mpls_info_summayr_ret4 [sth::emulation_mpls_ip_vpn_info \
        -port_handle $port1 $port2 \
        -mode summary]

set status [keylget mpls_info_summayr_ret4 status]
if {$status == 0} {
    puts "run sth::emulation_mpls_ip_vpn_info failed"
    puts $mpls_info_summayr_ret4
} else {
    puts "***** run sth::emulation_mpls_ip_vpn_info successfully"
    puts $mpls_info_summayr_ret4
}


set mpls_info_ospfv3_ret1 [sth::emulation_mpls_ip_vpn_info \
        -port_handle $port1 $port2 \
        -mode ospfv3]

set status [keylget mpls_info_ospfv3_ret1 status]
if {$status == 0} {
    puts "run sth::emulation_mpls_ip_vpn_info failed"
    puts $mpls_info_ospfv3_ret1
} else {
    puts "***** run sth::emulation_mpls_ip_vpn_info successfully"
    puts $mpls_info_ospfv3_ret1
}

###################################
# Step7:  Get info of BGP/BFD
###################################

set mpls_info_bgp_ret4 [sth::emulation_mpls_ip_vpn_info \
        -handle $router_handles \
        -mode bgp]

set status [keylget mpls_info_bgp_ret4 status]
if {$status == 0} {
    puts "run sth::emulation_mpls_ip_vpn_info failed"
    puts $mpls_info_bgp_ret4
} else {
    puts "***** run sth::emulation_mpls_ip_vpn_info successfully"
    puts $mpls_info_bgp_ret4
}

set mpls_info_bfd_ret4 [sth::emulation_mpls_ip_vpn_info \
        -handle $router_handles \
        -mode bfd]

set status [keylget mpls_info_bfd_ret4 status]
if {$status == 0} {
    puts "run sth::emulation_mpls_ip_vpn_info failed"
    puts $mpls_info_bfd_ret4
} else {
    puts "***** run sth::emulation_mpls_ip_vpn_info successfully"
    puts $mpls_info_bfd_ret4
}

###################################
# Step8:  Get info of LSP-Ping
###################################

set lsp_ping_info [sth::emulation_lsp_ping_info \
        -port_handle  $port1 $port2 \
        -mode aggregate]

set status [keylget lsp_ping_info status]
if {$status == 0} {
    puts "run sth::lsp_ping_info failed"
    puts $lsp_ping_info
} else {
    puts "***** run lsp_ping_info_aggregate successfully"
    puts $lsp_ping_info
}


set lsp_ping_info [sth::emulation_lsp_ping_info \
        -port_handle  $port1 $port2 \
        -mode ping]

set status [keylget lsp_ping_info status]
if {$status == 0} {
    puts "run sth::lsp_ping_info failed"
    puts $lsp_ping_info
} else {
    puts "***** run lsp_ping_info_ping successfully"
    puts $lsp_ping_info

}

set lsp_ping_info [sth::emulation_lsp_ping_info \
        -port_handle  $port1 $port2 \
        -mode trace_route]

set status [keylget lsp_ping_info status]
if {$status == 0} {
    puts "run sth::lsp_ping_info failed"
    puts $lsp_ping_info
} else {
    puts "***** run lsp_ping_info_tracert successfully"
    puts $lsp_ping_info
}

#########################
# Step9:  Stop devices
#########################

set mpls_control_ret [sth::emulation_mpls_ip_vpn_control \
        -handle $router_handles\
        -action stop]

set status [keylget mpls_control_ret status]
if {$status == 0} {
    puts "run sth::emulation_mpls_ip_vpn_control failed"
    puts $mpls_control_ret
} else {
    puts "***** run sth::emulation_mpls_ip_vpn_control successfully"
}

set mpls_config_ospf_del_ret1 [sth::emulation_mpls_ip_vpn_config \
       -mode             delete \
       -handle           $mpls_handle4 \
    ]

##################################
# Step10: Delete MPLS IP VPN config
##################################

#  delete mpls ip vpn network configuration 

set status [keylget mpls_config_ospf_del_ret1 status]
if {$status == 0} {
    puts "run sth::emulation_mpls_ip_vpn_config failed"
    puts $mpls_config_ospf_del_ret1
} else {
    puts "***** run sth::emulation_mpls_ip_vpn_config successfully"
}

#########################
# Step11: Clean up session
#########################

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