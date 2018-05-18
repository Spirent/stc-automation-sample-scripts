package require SpirentHltApi

##############################################################
#config the parameters for the logging
##############################################################

set test_sta [sth::test_config\
        -log                                              1\
        -logfile                                          HLTAPI_Traffic_Config_dhcp_header_logfile\
        -vendorlogfile                                    HLTAPI_Traffic_Config_dhcp_header_stcExport\
        -vendorlog                                        1\
        -hltlog                                           1\
        -hltlogfile                                       HLTAPI_Traffic_Config_dhcp_header_hltExport\
        -hlt2stcmappingfile                               HLTAPI_Traffic_Config_dhcp_header_hlt2StcMapping\
        -hlt2stcmapping                                   1\
        -log_level                                        7]

set status [keylget test_sta status]
if {$status == 0} {
    puts "<error> run sth::test_config failed"
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
    puts "<error> run sth::test_control failed"
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
        -intf_mode                                        ethernet\
        -phy_mode                                         copper\
        -scheduling_mode                                  PORT_BASED \
        -port_loadunit                                    PERCENT_LINE_RATE \
        -port_load                                        10 \
        -enable_ping_response                             0 \
        -control_plane_mtu                                1500 \
        -speed                                            ether1000 \
        -duplex                                           full \
        -autonegotiation                                  1 \
]

set status [keylget int_ret0 status]
if {$status == 0} {
    puts "<error> run sth::interface_config failed"
    puts $int_ret0
} else {
    puts "***** run sth::interface_config successfully"
}

set int_ret1 [sth::interface_config \
        -mode                                             config \
        -port_handle                                      $port2 \
        -create_host                                      false \
        -intf_mode                                        ethernet\
        -phy_mode                                         copper\
        -scheduling_mode                                  PORT_BASED \
        -port_loadunit                                    PERCENT_LINE_RATE \
        -port_load                                        10 \
        -enable_ping_response                             0 \
        -control_plane_mtu                                1500 \
        -speed                                            ether1000 \
        -duplex                                           full \
        -autonegotiation                                  1 \
]

set status [keylget int_ret1 status]
if {$status == 0} {
    puts "<error> run sth::interface_config failed"
    puts $int_ret1
} else {
    puts "***** run sth::interface_config successfully"
}

##############################################################
#create device and config the protocol on it
##############################################################

#start to create the device: Device 1

set device_ret0 [sth::emulation_device_config\
        -mode                                             create\
        -ip_version                                       ipv4\
        -encapsulation                                    ethernet_ii\
        -port_handle                                      $port1\
        -router_id                                        192.0.0.1 \
        -count                                            1 \
        -enable_ping_response                             0 \
        -mac_addr                                         00:10:94:00:00:01 \
        -mac_addr_step                                    00:00:00:00:00:01 \
        -intf_ip_addr                                     192.85.1.3 \
        -intf_prefix_len                                  24 \
        -resolve_gateway_mac                              true \
        -gateway_ip_addr                                  192.85.1.1 \
        -gateway_ip_addr_step                             0.0.0.0 \
        -intf_ip_addr_step                                0.0.0.1 \
]

set status [keylget device_ret0 status]
if {$status == 0} {
    puts "<error> run sth::emulation_device_config failed"
    puts $device_ret0
} else {
    puts "***** run sth::emulation_device_config successfully"
}

#start to create the device: Device 2

set device_ret1 [sth::emulation_device_config\
        -mode                                             create\
        -ip_version                                       ipv4\
        -encapsulation                                    ethernet_ii\
        -port_handle                                      $port2\
        -router_id                                        192.0.0.2 \
        -count                                            1 \
        -enable_ping_response                             0 \
        -mac_addr                                         00:10:94:00:00:02 \
        -mac_addr_step                                    00:00:00:00:00:01 \
        -intf_ip_addr                                     193.85.1.3 \
        -intf_prefix_len                                  24 \
        -resolve_gateway_mac                              true \
        -gateway_ip_addr                                  193.85.1.1 \
        -gateway_ip_addr_step                             0.0.0.0 \
        -intf_ip_addr_step                                0.0.0.1 \
]

set status [keylget device_ret1 status]
if {$status == 0} {
    puts "<error> run sth::emulation_device_config failed"
    puts $device_ret1
} else {
    puts "***** run sth::emulation_device_config successfully"
}

##############################################################
#create traffic
##############################################################

############################################################
# dhcp_msg_header_type = decline
############################################################
set streamblock_ret1 [::sth::traffic_config    \
        -mode                                             create\
        -port_handle                                      $port1\
        -l2_encap                                         ethernet_ii\
        -l3_protocol                                      ipv4\
        -l4_protocol                                      udp_dhcp_msg\
        -udp_src_port                                     67\
        -udp_dst_port                                     1024\
        -ip_id                                            0\
        -ip_src_addr                                      192.85.1.2\
        -ip_dst_addr                                      192.0.0.1\
        -ip_ttl                                           255\
        -ip_hdr_length                                    5\
        -ip_protocol                                      17\
        -ip_fragment_offset                               0\
        -ip_mbz                                           0\
        -ip_precedence                                    0\
        -ip_tos_field                                     0\
        -mac_src                                          00:10:94:00:00:02\
        -mac_dst                                          00:00:01:00:00:01\
        -enable_control_plane                             0\
        -l3_length                                        110\
        -name                                             StreamBlock_Decline\
        -fill_type                                        constant\
        -fcs_error                                        0\
        -fill_value                                       0\
        -frame_size                                       512\
        -traffic_state                                    1\
        -high_speed_result_analysis                       1\
        -length_mode                                      fixed\
        -tx_port_sending_traffic_to_self_en               false\
        -disable_signature                                0\
        -enable_stream_only_gen                           1\
        -endpoint_map                                     one_to_one\
        -pkts_per_burst                                   1\
        -inter_stream_gap_unit                            bytes\
        -burst_loop_count                                 30\
        -transmit_mode                                    continuous\
        -inter_stream_gap                                 12\
        -rate_percent                                     10\
        -mac_discovery_gw                                 192.85.1.1 \
        -enable_stream                                    false\
        -dhcp_cli_msg_client_addr                         2.2.2.2\
        -dhcp_cli_msg_boot_filename                       "spirent"\
        -dhcp_cli_msg_magic_cookie                        4\
        -dhcp_cli_msg_haddr_len                           5\
        -dhcp_cli_msg_hops                                6\
        -dhcp_cli_msg_next_serv_addr                      10.10.10.10\
        -dhcp_cli_msg_hw_type                             1\
        -dhcp_cli_msg_type                                2\
        -dhcp_cli_msg_elapsed                             0\
        -dhcp_cli_msg_bootpflags                          8000\
        -dhcp_cli_msg_your_addr                           20.20.20.20\
        -dhcp_cli_msg_xid                                 2\
        -dhcp_cli_msg_client_mac                          "00:00:01:00:00:05"\
        -dhcp_cli_msg_hostname                            "dhcp-client-msg"\
        -dhcp_cli_msg_relay_agent_addr                    3.3.3.3\
        -dhcp_msg_header_type                             decline\
        -udp_src_port_count                               10\
        -udp_src_port_repeat_count                        0\
        -udp_src_port_step                                1\
        -udp_src_port_mode                                increment\
        -modifier_option                                  {{dhcp_cli_msg_next_serv_addr}}\
        -modifier_mode                                    {{increment}}\
        -modifier_count                                   {{20}}\
        -modifier_repeat_count                            {{0}}\
        -modifier_step                                    {{0.0.0.1}}\
        -modifier_mask                                    {{255.255.255.255}}\
]                                            

set status [keylget streamblock_ret1 status]
if {$status == 0} {
    puts "<error> run sth::traffic_config failed"
    puts $streamblock_ret1
} else {
    puts "***** run sth::traffic_config successfully"
}

############################################################
# dhcp_msg_header_type = offer
############################################################
set streamblock_ret1 [::sth::traffic_config    \
        -mode                                             create\
        -port_handle                                      $port1\
        -l2_encap                                         ethernet_ii\
        -l3_protocol                                      ipv4\
        -l4_protocol                                      udp_dhcp_msg\
        -udp_src_port                                     67\
        -udp_dst_port                                     1024\
        -ip_id                                            0\
        -ip_src_addr                                      192.85.1.2\
        -ip_dst_addr                                      192.0.0.1\
        -ip_ttl                                           255\
        -ip_hdr_length                                    5\
        -ip_protocol                                      17\
        -ip_fragment_offset                               0\
        -ip_mbz                                           0\
        -ip_precedence                                    0\
        -ip_tos_field                                     0\
        -mac_src                                          00:10:94:00:00:02\
        -mac_dst                                          00:00:01:00:00:01\
        -enable_control_plane                             0\
        -l3_length                                        110\
        -name                                             StreamBlock_Offer\
        -fill_type                                        constant\
        -fcs_error                                        0\
        -fill_value                                       0\
        -frame_size                                       1000\
        -traffic_state                                    1\
        -high_speed_result_analysis                       1\
        -length_mode                                      fixed\
        -tx_port_sending_traffic_to_self_en               false\
        -disable_signature                                0\
        -enable_stream_only_gen                           1\
        -endpoint_map                                     one_to_one\
        -pkts_per_burst                                   1\
        -inter_stream_gap_unit                            bytes\
        -burst_loop_count                                 30\
        -transmit_mode                                    continuous\
        -inter_stream_gap                                 12\
        -rate_percent                                     10\
        -mac_discovery_gw                                 192.85.1.1 \
        -enable_stream                                    true\
        -dhcp_srv_msg_next_serv_addr                      10.10.10.10\
        -dhcp_srv_msg_hw_type                             1\
        -dhcp_srv_msg_type                                2\
        -dhcp_srv_msg_elapsed                             3\
        -dhcp_srv_msg_bootpflags                          8000\
        -dhcp_srv_msg_your_addr                           20.20.20.20\
        -dhcp_srv_msg_xid                                 2\
        -dhcp_srv_msg_client_mac                          "00:00:01:00:00:05"\
        -dhcp_srv_msg_hostname                            "dhcp-server-msg"\
        -dhcp_srv_msg_client_addr                         5.5.5.5 \
        -dhcp_srv_msg_boot_filename                       111111\
        -dhcp_srv_msg_magic_cookie                        12345\
        -dhcp_srv_msg_haddr_len                           6\
        -dhcp_srv_msg_hops                                1 \
        -dhcp_srv_msg_client_hw_pad                       0 \
        -dhcp_srv_msg_relay_agent_addr                    3.3.3.3\
        -dhcp_msg_header_type                             offer\
        -udp_src_port_count                               10\
        -udp_src_port_repeat_count                        0\
        -udp_src_port_step                                1\
        -udp_src_port_mode                                increment\
        -modifier_option                                  {{dhcp_srv_msg_next_serv_addr}}\
        -modifier_mode                                    {{decrement}}\
        -modifier_count                                   {{10}}\
        -modifier_repeat_count                            {{0}}\
        -modifier_step                                    {{0.0.0.1}}\
        -modifier_mask                                    {{255.255.255.255}}\
]

set status [keylget streamblock_ret1 status]
if {$status == 0} {
    puts "<error> run sth::traffic_config failed"
    puts $streamblock_ret1
} else {
    puts "***** run sth::traffic_config successfully"
}


set streamblock_ret1 [::sth::traffic_config    \
        -mode                                             create\
        -port_handle                                      $port1\
        -l2_encap                                         ethernet_ii\
        -l3_protocol                                      ipv4\
        -l4_protocol                                      udp_dhcp_msg\
        -udp_src_port                                     67\
        -udp_dst_port                                     1024\
        -ip_id                                            0\
        -ip_src_addr                                      192.85.1.2\
        -ip_dst_addr                                      192.0.0.1\
        -ip_ttl                                           255\
        -ip_hdr_length                                    5\
        -ip_protocol                                      17\
        -ip_fragment_offset                               0\
        -ip_mbz                                           0\
        -ip_precedence                                    0\
        -ip_tos_field                                     0\
        -mac_src                                          00:10:94:00:00:02\
        -mac_dst                                          00:00:01:00:00:01\
        -enable_control_plane                             0\
        -l3_length                                        110\
        -name                                             StreamBlock_Test\
        -fill_type                                        constant\
        -fcs_error                                        0\
        -fill_value                                       0\
        -frame_size                                       512\
        -traffic_state                                    1\
        -high_speed_result_analysis                       1\
        -length_mode                                      fixed\
        -tx_port_sending_traffic_to_self_en               false\
        -disable_signature                                0\
        -enable_stream_only_gen                           1\
        -endpoint_map                                     one_to_one\
        -pkts_per_burst                                   1\
        -inter_stream_gap_unit                            bytes\
        -burst_loop_count                                 30\
        -transmit_mode                                    continuous\
        -inter_stream_gap                                 12\
        -rate_percent                                     10\
        -mac_discovery_gw                                 192.85.1.1 \
        -enable_stream                                    false\
        -dhcp_srv_msg_client_addr                         2.2.2.2\
        -dhcp_srv_msg_boot_filename                       "spirent"\
        -dhcp_srv_msg_magic_cookie                        4\
        -dhcp_srv_msg_haddr_len                           5\
        -dhcp_srv_msg_hops                                6\
        -dhcp_srv_msg_next_serv_addr                      10.10.10.10\
        -dhcp_srv_msg_hw_type                             1\
        -dhcp_srv_msg_type                                2\
        -dhcp_srv_msg_elapsed                             3\
        -dhcp_srv_msg_bootpflags                          8000\
        -dhcp_srv_msg_your_addr                           20.20.20.20\
        -dhcp_srv_msg_xid                                 2\
        -dhcp_srv_msg_client_mac                          "00:00:01:00:00:05"\
        -dhcp_srv_msg_hostname                            "dhcp-server-msg"\
        -dhcp_srv_msg_relay_agent_addr                    3.3.3.3\
        -dhcp_srv_msg_cli_hw_id_type                      01\
        -dhcp_srv_msg_cli_hw_type                         3d\
        -dhcp_srv_msg_cli_hw_client_hwa                   "00:00:01:00:00:02"\
        -dhcp_srv_msg_cli_hw_option_length                07\
        -dhcp_srv_msg_custom_length                       01\
        -dhcp_srv_msg_custom_type                         fe\
        -dhcp_srv_msg_custom_value                        00\
        -dhcp_srv_msg_host_length                         06\
        -dhcp_srv_msg_host_type                           0c\
        -dhcp_srv_msg_host_value                          636c69656e74\
        -dhcp_srv_msg_lease_type                          33\
        -dhcp_srv_msg_lease_length                        04\
        -dhcp_srv_msg_lease_time                          0 \
        -dhcp_srv_msg_msg_length                          01\
        -dhcp_srv_msg_msg_type                            38\
        -dhcp_srv_msg_msg_value                           00\
        -dhcp_srv_msg_size_length                         02\
        -dhcp_srv_msg_size_type                           39\
        -dhcp_srv_msg_size_value                          0240\
        -dhcp_srv_msg_type_length                         01\
        -dhcp_srv_msg_type_code                           ack\
        -dhcp_srv_msg_msgtype_type                        35\
        -dhcp_srv_msg_overload_length                     01\
        -dhcp_srv_msg_overload_type                       34\
        -dhcp_srv_msg_overload                            file\
        -dhcp_srv_msg_req_list_length                     04\
        -dhcp_srv_msg_req_list_type                       37\
        -dhcp_srv_msg_req_list_value                      01060f21\
        -dhcp_srv_msg_req_addr_length                     04\
        -dhcp_srv_msg_req_addr_type                       2 \
        -dhcp_srv_msg_req_addr                            2.0.0.0\
        -dhcp_srv_msg_srv_id_length                       04\
        -dhcp_srv_msg_srv_id_type                         36\
        -dhcp_srv_msg_srv_id_req_addr                     0.0.0.0 \
        -dhcp_srv_msg_end_type                            ff\
        -dhcp_srv_msg_options_hdr_seq                     "cli_hw custom hostname lease msg msg_type msg_size overload req_list req_addr server_id end"\
        -udp_src_port_count                               10\
        -udp_src_port_repeat_count                        0\
        -udp_src_port_step                                1\
        -udp_src_port_mode                                increment\
        -modifier_option                                  {{dhcp_srv_msg_srv_id_length} {dhcp_srv_msg_cli_hw_id_type} {dhcp_srv_msg_lease_length}}\
        -modifier_mode                                    {{increment} {decrement} {list}}\
        -modifier_count                                   {{10} {20} {}}\
        -modifier_repeat_count                            {{0} {0} {}}\
        -modifier_step                                    {{1} {1} {}}\
        -modifier_mask                                    {{FF} {FF} {}}\
        -modifier_list_value                              {{} {} {2 4 5}}\
]

set status [keylget streamblock_ret1 status]
if {$status == 0} {
    puts "<error> run sth::traffic_config failed"
    puts $streamblock_ret1
} else {
    puts "***** run sth::traffic_config successfully"
}
set sbHnd [keylget streamblock_ret1 stream_id]

set streamblock_ret1 [::sth::traffic_config    \
        -mode                                             modify\
        -stream_id                                        $sbHnd\
        -l2_encap                                         ethernet_ii\
        -l3_protocol                                      ipv4\
        -l4_protocol                                      udp_dhcp_msg\
        -modifier_option                                  {{dhcp_srv_msg_type}}\
        -modifier_mode                                    {{list}}\
        -modifier_list_value                              {{2 4 5 6}}\
]

set status [keylget streamblock_ret1 status]
if {$status == 0} {
    puts "<error> run sth::traffic_config failed"
    puts $streamblock_ret1
} else {
    puts "***** run sth::traffic_config successfully"
}


set streamblock_ret1 [::sth::traffic_config    \
        -mode                                             modify\
        -stream_id                                        $sbHnd\
        -l2_encap                                         ethernet_ii\
        -l3_protocol                                      ipv4\
        -l4_protocol                                      udp_dhcp_msg\
        -modifier_option                                  {{dhcp_srv_msg_elapsed}}\
        -modifier_mode                                    {{decrement}}\
        -modifier_count                                   {{10}}\
        -modifier_repeat_count                            {{0}}\
        -modifier_step                                    {{1}}\
        -modifier_mask                                    {{255}}\
]

set status [keylget streamblock_ret1 status]
if {$status == 0} {
    puts "<error> run sth::traffic_config failed"
    puts $streamblock_ret1
} else {
    puts "***** run sth::traffic_config successfully"
}


set streamblock_ret1 [::sth::traffic_config    \
        -mode                                             create\
        -port_handle                                      $port1\
        -l2_encap                                         ethernet_ii\
        -l3_protocol                                      ipv4\
        -l4_protocol                                      udp_dhcp_msg\
        -udp_src_port                                     67\
        -udp_dst_port                                     1024\
        -ip_id                                            0\
        -ip_src_addr                                      192.85.1.2\
        -ip_dst_addr                                      192.0.0.1\
        -ip_ttl                                           255\
        -ip_hdr_length                                    5\
        -ip_protocol                                      17\
        -ip_fragment_offset                               0\
        -ip_mbz                                           0\
        -ip_precedence                                    0\
        -ip_tos_field                                     0\
        -mac_src                                          00:10:94:00:00:02\
        -mac_dst                                          00:00:01:00:00:01\
        -enable_control_plane                             0\
        -l3_length                                        110\
        -name                                             StreamBlock_Test\
        -fill_type                                        constant\
        -fcs_error                                        0\
        -fill_value                                       0\
        -frame_size                                       512\
        -traffic_state                                    1\
        -high_speed_result_analysis                       1\
        -length_mode                                      fixed\
        -tx_port_sending_traffic_to_self_en               false\
        -disable_signature                                0\
        -enable_stream_only_gen                           1\
        -endpoint_map                                     one_to_one\
        -pkts_per_burst                                   1\
        -inter_stream_gap_unit                            bytes\
        -burst_loop_count                                 30\
        -transmit_mode                                    continuous\
        -inter_stream_gap                                 12\
        -rate_percent                                     10\
        -mac_discovery_gw                                 192.85.1.1 \
        -enable_stream                                    false\
        -dhcp_cli_msg_client_addr                         2.2.2.2\
        -dhcp_cli_msg_boot_filename                       "spirent"\
        -dhcp_cli_msg_magic_cookie                        4\
        -dhcp_cli_msg_haddr_len                           5\
        -dhcp_cli_msg_hops                                6\
        -dhcp_cli_msg_next_serv_addr                      10.10.10.10\
        -dhcp_cli_msg_hw_type                             1\
        -dhcp_cli_msg_type                                2\
        -dhcp_cli_msg_elapsed                             0\
        -dhcp_cli_msg_bootpflags                          8000\
        -dhcp_cli_msg_your_addr                           20.20.20.20\
        -dhcp_cli_msg_xid                                 2\
        -dhcp_cli_msg_client_mac                          "00:00:01:00:00:05"\
        -dhcp_cli_msg_hostname                            "dhcp-client-msg"\
        -dhcp_cli_msg_relay_agent_addr                    3.3.3.3\
        -dhcp_cli_msg_cli_hw_id_type                      01\
        -dhcp_cli_msg_cli_hw_type                         3d\
        -dhcp_cli_msg_cli_hw_client_hwa                   "00:00:01:00:00:02"\
        -dhcp_cli_msg_cli_hw_option_length                07\
        -dhcp_cli_msg_cli_non_hw_id_type                  00\
        -dhcp_cli_msg_cli_non_hw_type                     3d\
        -dhcp_cli_msg_cli_non_hw_value                    010203040506\
        -dhcp_cli_msg_cli_non_hw_option_length            07\
        -dhcp_cli_msg_custom_length                       01\
        -dhcp_cli_msg_custom_type                         fe\
        -dhcp_cli_msg_custom_value                        00\
        -dhcp_cli_msg_host_length                         06\
        -dhcp_cli_msg_host_type                           0c\
        -dhcp_cli_msg_host_value                          636c69656e74\
        -dhcp_cli_msg_lease_type                          33\
        -dhcp_cli_msg_lease_length                        04\
        -dhcp_cli_msg_lease_time                          0\
        -dhcp_cli_msg_msg_length                          01\
        -dhcp_cli_msg_msg_type                            38\
        -dhcp_cli_msg_msg_value                           00\
        -dhcp_cli_msg_size_length                         02\
        -dhcp_cli_msg_size_type                           39\
        -dhcp_cli_msg_size_value                          0240\
        -dhcp_cli_msg_type_length                         01\
        -dhcp_cli_msg_type_code                           discover\
        -dhcp_cli_msg_msgtype_type                        35\
        -dhcp_cli_msg_overload_length                     01\
        -dhcp_cli_msg_overload_type                       34\
        -dhcp_cli_msg_overload                            file\
        -dhcp_cli_msg_req_list_length                     04\
        -dhcp_cli_msg_req_list_type                       37\
        -dhcp_cli_msg_req_list_value                      01060f21\
        -dhcp_cli_msg_req_addr_length                     04\
        -dhcp_cli_msg_req_addr_type                       2\
        -dhcp_cli_msg_req_addr                            2.0.0.0\
        -dhcp_cli_msg_srv_id_length                       04\
        -dhcp_cli_msg_srv_id_type                         36\
        -dhcp_cli_msg_srv_id_req_addr                     0.0.0.0\
        -dhcp_cli_msg_end_type                            ff\
        -dhcp_cli_msg_options_hdr_seq                     "cli_hw cli_non_hw custom hostname lease msg msg_type msg_size overload req_list req_addr server_id end"\
]                                            



set status [keylget streamblock_ret1 status]
if {$status == 0} {
    puts "<error> run sth::traffic_config failed"
    puts $streamblock_ret1
} else {
    puts "***** run sth::traffic_config successfully"
}

set sbHnd [keylget streamblock_ret1 stream_id]
set streamblock_ret1 [::sth::traffic_config    \
        -mode                                             modify\
        -stream_id                                        $sbHnd\
        -l2_encap                                         ethernet_ii\
        -l4_protocol                                      udp_dhcp_msg\
        -udp_src_port_count                               10\
        -udp_src_port_repeat_count                        0\
        -udp_src_port_step                                1\
        -udp_src_port_mode                                increment\
]

set status [keylget streamblock_ret1 status]
if {$status == 0} {
    puts "<error> run sth::traffic_config failed"
    puts $streamblock_ret1
} else {
    puts "***** run sth::traffic_config successfully"
}

set streamblock_ret1 [::sth::traffic_config    \
        -mode                                             modify\
        -stream_id                                        $sbHnd\
        -l2_encap                                         ethernet_ii\
        -l3_protocol                                      ipv4\
        -l4_protocol                                      udp_dhcp_msg\
        -enable_stream                                    false\
        -dhcp_cli_msg_next_serv_addr                      10.10.10.10\
        -dhcp_cli_msg_hw_type                             1\
        -dhcp_cli_msg_type                                2\
        -dhcp_cli_msg_elapsed                             0\
        -dhcp_cli_msg_bootpflags                          8000\
        -dhcp_cli_msg_your_addr                           20.20.20.20\
        -dhcp_cli_msg_xid                                 2\
        -dhcp_cli_msg_client_mac                          "00:00:01:00:00:05"\
        -dhcp_cli_msg_hostname                            "dhcp-client-msg"\
        -dhcp_cli_msg_relay_agent_addr                    3.3.3.3\
        -dhcp_cli_msg_cli_hw_id_type                      01\
        -dhcp_cli_msg_cli_hw_type                         3d\
        -dhcp_cli_msg_cli_hw_client_hwa                   "00:00:01:00:00:02"\
        -dhcp_cli_msg_cli_hw_option_length                07\
        -dhcp_cli_msg_cli_non_hw_id_type                  00\
        -dhcp_cli_msg_cli_non_hw_type                     3d\
        -dhcp_cli_msg_cli_non_hw_value                    010203040506\
        -dhcp_cli_msg_cli_non_hw_option_length            07\
        -dhcp_cli_msg_custom_length                       01\
        -dhcp_cli_msg_custom_type                         fe\
        -dhcp_cli_msg_custom_value                        00\
        -dhcp_cli_msg_host_length                         06\
        -dhcp_cli_msg_host_type                           0c\
        -dhcp_cli_msg_host_value                          636c69656e74\
        -dhcp_cli_msg_lease_type                          33\
        -dhcp_cli_msg_lease_length                        04\
        -dhcp_cli_msg_lease_time                          0\
        -dhcp_cli_msg_msg_length                          01\
        -dhcp_cli_msg_msg_type                            38\
        -dhcp_cli_msg_msg_value                           00\
        -dhcp_cli_msg_size_length                         02\
        -dhcp_cli_msg_size_type                           39\
        -dhcp_cli_msg_size_value                          0240\
        -dhcp_cli_msg_type_length                         01\
        -dhcp_cli_msg_type_code                           decline\
        -dhcp_cli_msg_msgtype_type                        35\
        -dhcp_cli_msg_overload_length                     01\
        -dhcp_cli_msg_overload_type                       34\
        -dhcp_cli_msg_overload                            file\
        -dhcp_cli_msg_req_list_length                     04\
        -dhcp_cli_msg_req_list_type                       37\
        -dhcp_cli_msg_req_list_value                      01060f21\
        -dhcp_cli_msg_req_addr_length                     04\
        -dhcp_cli_msg_req_addr_type                       2\
        -dhcp_cli_msg_req_addr                            2.0.0.0\
        -dhcp_cli_msg_srv_id_length                       04\
        -dhcp_cli_msg_srv_id_type                         36\
        -dhcp_cli_msg_srv_id_req_addr                     0.0.0.0\
        -dhcp_cli_msg_end_type                            ff\
]                                            

set status [keylget streamblock_ret1 status]
if {$status == 0} {
    puts "<error> run sth::traffic_config failed"
    puts $streamblock_ret1
} else {
    puts "***** run sth::traffic_config successfully"
}


stc::perform saveasxml -filename HLTAPI_Traffic_Config_dhcp_header.xml
set comp [regression::check_config [info script]]
#config part is finished
##############################################################
#clean up the session, release the ports reserved and cleanup the dbfile
##############################################################

set cleanup_sta [sth::cleanup_session\
        -port_handle                                      $port1 $port2 \
        -clean_dbfile                                     1]

set status [keylget cleanup_sta status]
if {$status == 0} {
    puts "<error> run sth::cleanup_session failed"
    puts $cleanup_sta
} else {
    puts "***** run sth::cleanup_session successfully"
}

puts "**************Finish***************"

