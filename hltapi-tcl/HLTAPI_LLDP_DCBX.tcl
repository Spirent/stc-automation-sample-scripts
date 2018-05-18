# Copyright (c) 2007 by Spirent Communications, Inc.
# All Rights Reserved
#
# By accessing or executing this software, you agree to be bound 
# by the terms of this agreement.
# 
# Redistribution and use of this software in source and binary forms,
# with or without modification, are permitted provided that the 
# following conditions are met:
#   1.  Redistribution of source code must contain the above copyright 
#       notice, this list of conditions, and the following disclaimer.
#   2.  Redistribution in binary form must reproduce the above copyright
#       notice, this list of conditions and the following disclaimer
#       in the documentation and/or other materials provided with the
#       distribution.
#   3.  Neither the name Spirent Communications nor the names of its
#       contributors may be used to endorse or promote products derived
#       from this software without specific prior written permission.
#
# This software is provided by the copyright holders and contributors 
# [as is] and any express or implied warranties, including, but not 
# limited to, the implied warranties of merchantability and fitness for
# a particular purpose are disclaimed.  In no event shall Spirent
# Communications, Inc. or its contributors be liable for any direct, 
# indirect, incidental, special, exemplary, or consequential damages
# (including, but not limited to: procurement of substitute goods or
# services; loss of use, data, or profits; or business interruption)
# however caused and on any theory of liability, whether in contract, 
# strict liability, or tort (including negligence or otherwise) arising
# in any way out of the use of this software, even if advised of the
# possibility of such damage.
#
# File Name:         HLTAPI_LLDP_DCBX.tcl
#
# Description:      This script demonstrates the use of Spirent HLTAPI to setup LLDP test
#
# Test Step:         1. Reserve and connect chassis ports
#                    2. Config pos interface
#                    3. Config DCBX TLVs
#                    4. Config LLDP Optional TLVs
#                    5. Config LLDP session (Including LLDP Mandatory TLVs)
#                    6. Start LLDP session
#                    7. Retrive LLDP statistics
#                    8. Stop LLDP session
#                    9. Release resources
#
# Dut Configuration:
#                   1. No DUT in useing
#                   2. Back to Back (B2B) test
#
# Topology
#                LLDP Host                          LLDP Host
#                [STC  2/1]-------------------------[STC 2/2 ]
#
#################################

# Run sample:
#            c:>tclsh HLTAPI_LLDP_DCBX.tcl 10.61.44.2 3/1 3/3
#            c:>tclsh HLTAPI_LLDP_DCBX.tcl "10.61.44.2 10.61.44.7" 3/1 3/3

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

############################################
# Step1: Reserve and connect chassis ports #
############################################
set returnedString [sth::connect -device $device_list -port_list $port_list]
if {![keylget returnedString status ]} {
	puts "FAILED: $returnedString"
    return
}
set portHandle1 [keylget returnedString port_handle.$device1.$port1]
set portHandle2 [keylget returnedString port_handle.$device2.$port2]
set portList "$portHandle1 $portHandle2"

############################################
# Step2: Config pos interface              #
############################################
foreach port $portList {
    set returnedString [sth::interface_config   -port_handle       $port \
                                                -mode              config \
                                                -phy_mode          copper \
                                                -duplex            full \
                                                -intf_mode         ethernet]
    if {![keylget returnedString status ]} {
		puts "FAILED: $returnedString"
        return
    }
}

############################################
# Step3: Config DCBX Optional TLVs         #
############################################

# config DCBX TLV of version 1.00
set returnedString [sth::emulation_lldp_dcbx_tlv_config     -version_num                                    "ver_100"\
                                                            -control_tlv_oper_version                       1\
                                                            -control_tlv_max_version                        1\
                                                            -pg_feature_tlv1_enable                         1\
                                                            -pg_feature_tlv1_oper_version                   1\
                                                            -pg_feature_tlv1_max_version                    1\
                                                            -pg_feature_tlv1_enabled_flag                   1\
                                                            -pg_feature_tlv1_willing_flag                   1\
                                                            -pg_feature_tlv1_error_flag                     1\
                                                            -pg_feature_tlv1_subtype                        1\
                                                            -pg_feature_tlv1_bwg_percentage_list            "10 10 10 10 10 10 10 10"\
                                                            -pg_feature_tlv1_prio_alloc_bwg_id_list         "0 1 2 3 4 5 6 7"\
                                                            -pg_feature_tlv1_prio_alloc_strict_prio_list    "0 1 2 3 0 1 2 3"\
                                                            -pg_feature_tlv1_prio_alloc_bw_percentage_list  "10 10 10 10 10 10 10 10"\
                                                            -pfc_feature_tlv1_enable                        1\
                                                            -pfc_feature_tlv1_oper_version                  1\
                                                            -pfc_feature_tlv1_max_version                   1\
                                                            -pfc_feature_tlv1_enabled_flag                  1\
                                                            -pfc_feature_tlv1_willing_flag                  1\
                                                            -pfc_feature_tlv1_error_flag                    1\
                                                            -pfc_feature_tlv1_subtype                       1\
                                                            -pfc_feature_tlv1_admin_mode_bits               "11111111"\
                                                            -application_feature_tlv1_enable                1\
                                                            -application_feature_tlv1_oper_version          1\
                                                            -application_feature_tlv1_max_version           1\
                                                            -application_feature_tlv1_enabled_flag          1\
                                                            -application_feature_tlv1_error_flag            1\
                                                            -application_feature_tlv1_subtype               1\
                                                            -application_feature_tlv1_prio_map              "11111111"\
                                                            -bcn_feature_tlv1_enable                        1\
                                                            -bcn_feature_tlv1_oper_version                  1\
                                                            -bcn_feature_tlv1_max_version                   1\
                                                            -bcn_feature_tlv1_enabled_flag                  1\
                                                            -bcn_feature_tlv1_willing_flag                  1\
                                                            -bcn_feature_tlv1_error_flag                    1\
                                                            -bcn_feature_tlv1_subtype                       1\
                                                            -bcn_feature_tlv1_bcna_value                    "1"\
                                                            -bcn_feature_tlv1_cp_admin_mode_list            "1 1 1 1 1 1 1 1"\
                                                            -bcn_feature_tlv1_rp_admin_mode_list            "1 1 1 1 1 1 1 1"\
                                                            -bcn_feature_tlv1_rp_oper_mode_list             "1 1 1 1 1 1 1 1"\
                                                            -bcn_feature_tlv1_rem_tag_oper_mode_list        "1 1 1 1 1 1 1 1"\
                                                            -bcn_feature_tlv1_rp_w                          1\
                                                            -bcn_feature_tlv1_rp_tmax                       1\
                                                            -bcn_feature_tlv1_rp_rmin                       1\
                                                            -bcn_feature_tlv1_rp_td                         1\
                                                            -bcn_feature_tlv1_rp_rd                         1\
                                                            -bcn_feature_tlv1_cp_sf                         1\
                                                            -lld_feature_tlv1_enable                        1\
                                                            -lld_feature_tlv1_oper_version                  1\
                                                            -lld_feature_tlv1_max_version                   1\
                                                            -lld_feature_tlv1_enabled_flag                  1\
                                                            -lld_feature_tlv1_willing_flag                  1\
                                                            -lld_feature_tlv1_error_flag                    1\
                                                            -lld_feature_tlv1_subtype                       1\
                                                            -lld_feature_tlv1_status_value                  1\
                                                            -customized_feature_tlv1_enable                 1\
                                                            -customized_feature_tlv1_oper_version           1\
                                                            -customized_feature_tlv1_max_version            1\
                                                            -customized_feature_tlv1_enabled_flag           1\
                                                            -customized_feature_tlv1_willing_flag           1\
                                                            -customized_feature_tlv1_error_flag             1\
                                                            -customized_feature_tlv1_subtype                1\
                                                            -customized_feature_tlv1_type                   11\
                                                            -customized_feature_tlv1_value                  "0e0e"]

if {![keylget returnedString status ]} {
	puts "FAILED: $returnedString"
    return
} else {
    keylget returnedString handle dcbx_tlv_handle1
}

# config DCBX TLV of version 1.03
set returnedString [sth::emulation_lldp_dcbx_tlv_config     -version_num                                    "ver_103"\
                                                            -control_tlv_oper_version                       1\
                                                            -control_tlv_max_version                        1\
                                                            -pg_feature_tlv2_enable                         1\
                                                            -pg_feature_tlv2_oper_version                   1\
                                                            -pg_feature_tlv2_max_version                    1\
                                                            -pg_feature_tlv2_enabled_flag                   1\
                                                            -pg_feature_tlv2_willing_flag                   1\
                                                            -pg_feature_tlv2_error_flag                     1\
                                                            -pg_feature_tlv2_subtype                        1\
                                                            -pg_feature_tlv2_prio_alloc_pgid_list           "0 1 2 3 0 1 2 3"\
                                                            -pg_feature_tlv2_pg_alloc_bw_percentage_list    "0 1 2 3 0 1 2 3"\
                                                            -pg_feature_tlv2_num_tcs_supported              1\
                                                            -pfc_feature_tlv2_num_tcpfcs_supported          1\
                                                            -pfc_feature_tlv2_enable                        1\
                                                            -pfc_feature_tlv2_oper_version                  1\
                                                            -pfc_feature_tlv2_max_version                   1\
                                                            -pfc_feature_tlv2_enabled_flag                  1\
                                                            -pfc_feature_tlv2_willing_flag                  1\
                                                            -pfc_feature_tlv2_error_flag                    1\
                                                            -pfc_feature_tlv2_subtype                       1\
                                                            -pfc_feature_tlv2_admin_mode_bits               "11111111"\
                                                            -app_protocol_tlv2_enable                       1\
                                                            -app_protocol_tlv2_oper_version                 1\
                                                            -app_protocol_tlv2_max_version                  1\
                                                            -app_protocol_tlv2_enabled_flag                 1\
                                                            -app_protocol_tlv2_willing_flag                 1\
                                                            -app_protocol_tlv2_error_flag                   1\
                                                            -app_protocol_tlv2_subtype                      1\
                                                            -app_protocol_tlv2_protocol_count               2\
                                                            -app_protocol_tlv2_app_id_list                  "1 2"\
                                                            -app_protocol_tlv2_oui_upper_6_bits_list        "111111 111111"\
                                                            -app_protocol_tlv2_sf_list                      "01 10"\
                                                            -app_protocol_tlv2_oui_lower_2_bytes_list        "01 10"\
                                                            -app_protocol_tlv2_prio_map_list                "01010101 10101010"\
                                                            -customized_feature_tlv2_enable                 1\
                                                            -customized_feature_tlv2_oper_version           1\
                                                            -customized_feature_tlv2_max_version            1\
                                                            -customized_feature_tlv2_enabled_flag           1\
                                                            -customized_feature_tlv2_willing_flag           1\
                                                            -customized_feature_tlv2_error_flag             1\
                                                            -customized_feature_tlv2_subtype                1\
                                                            -customized_feature_tlv2_type                   11\
                                                            -customized_feature_tlv2_value                  "0e0e"]

if {![keylget returnedString status ]} {
	puts "FAILED: $returnedString"
    return
} else {
    keylget returnedString handle dcbx_tlv_handle2
}

############################################
#step4 config LLDP Optional TLVs           #
############################################

set returnedString [sth::emulation_lldp_optional_tlv_config     -tlv_port_description_enable                        1\
                                                                -tlv_port_description_value                         "AT Test Port"\
                                                                -tlv_system_name_enable                             1\
                                                                -tlv_system_name_value                              "AT Test System"\
                                                                -tlv_system_description_enable                      1\
                                                                -tlv_system_description_value                       "AT Test"\
                                                                -tlv_system_capabilities_enable                     1\
                                                                -tlv_system_capabilities_value                      "11111111"\
                                                                -tlv_enabled_capabilities_value                     "11111111"\
                                                                -tlv_management_addr_enable                         1\
                                                                -tlv_management_addr_count                          2\
                                                                -tlv_management_addr_subtype_list                   "ipv4 ipv6"\
                                                                -tlv_management_addr_value_list                     "192.168.1.1 2000::1"\
                                                                -tlv_management_addr_intf_numbering_subtype_list    "01 02"\
                                                                -tlv_management_addr_intf_number_value_list         "100 101"\
                                                                -tlv_management_addr_oid_value_list                 "0e 0a"\
                                                                -tlv_port_vlanid_enable                             1\
                                                                -tlv_port_vlanid_value                              "100"\
                                                                -tlv_port_and_protocol_vlanid_enable                1\
                                                                -tlv_port_and_protocol_vlanid_count                 2\
                                                                -tlv_port_and_protocol_vlanid_value_list            "100 101"\
                                                                -tlv_port_and_protocol_vlanid_enabled_flag_list     "1 1"\
                                                                -tlv_port_and_protocol_vlanid_supported_flag_list   "1 1"\
                                                                -tlv_vlan_name_enable                               1\
                                                                -tlv_vlan_name_count                                2\
                                                                -tlv_vlan_name_vid_list                             "100 101"\
                                                                -tlv_vlan_name_value_list                           "vlan1 vlan2"\
                                                                -tlv_protocol_identity_enable                       1\
                                                                -tlv_protocol_identity_count                        2\
                                                                -tlv_protocol_identity_value_list                   "8906 8824"\
                                                                -tlv_mac_phy_config_status_enable                   1\
                                                                -tlv_mac_phy_config_status_auto_negotiation_supported_flag          1\
                                                                -tlv_mac_phy_config_status_auto_negotiation_status_flag             1\
                                                                -tlv_mac_phy_config_status_auto_negotiation_advertised_capability   "ffff"\
                                                                -tlv_mac_phy_config_status_operational_mau_type     0002\
                                                                -tlv_power_via_mdi_enable                           1\
                                                                -tlv_power_via_mdi_power_support_bits               "1111"\
                                                                -tlv_power_via_mdi_pse_power_pair                   "signal"\
                                                                -tlv_power_via_mdi_pse_power_class                  "class2"\
                                                                -tlv_link_aggregation_enable                        1\
                                                                -tlv_link_aggregation_status_flag                   1\
                                                                -tlv_link_aggregation_capability_flag               1\
                                                                -tlv_link_aggregation_aggregated_port_id            "00000e0e"\
                                                                -tlv_maximum_frame_size_enable                      1\
                                                                -tlv_maximum_frame_size_value                       1518\
                                                                -tlv_customized_enable                              1\
                                                                -tlv_customized_type                                126\
                                                                -tlv_customized_value                               "0e0e"]

if {![keylget returnedString status ]} {
	puts "FAILED: $returnedString"
    return
} else {
    keylget returnedString handle lldp_tlv_handle1
}


############################################
#step5 config LLDP sessions                #
############################################

# Create Lldp session on port 1
set returnedString [sth::emulation_lldp_config  -port_handle            $portHandle1\
                                                -mode                   create\
                                                -count                  1\
                                                -loopback_ip_addr       192.1.0.1\
                                                -loopback_ip_addr_step  0.0.0.1\
                                                -local_mac_addr         00:94:00:00:00:01\
                                                -local_mac_addr_step    00:00:00:00:00:01\
                                                -intf_ip_addr           192.168.1.1\
                                                -intf_ip_addr_step      0.0.1.0\
                                                -intf_ip_prefix_length  24\
                                                -gateway_ip_addr        192.168.1.254\
                                                -gateway_ip_addr_step   0.0.1.0\
                                                -intf_ipv6_addr         2000::1\
                                                -intf_ipv6_addr_step    0000::1\
                                                -intf_ipv6_prefix_length        64\
                                                -gateway_ipv6_addr      2000::100\
                                                -gateway_ipv6_addr_step ::1\
                                                -enable_ipv6_gateway_learning   0\
                                                -intf_ipv6_link_local_addr      FE08::1\
                                                -msg_tx_interval        100\
                                                -msg_tx_hold_mutiplier  4\
                                                -reinitialize_delay     5\
                                                -tx_delay               5\
                                                -tlv_chassis_id_subtype chassis_component\
                                                -tlv_chassis_id_value   "0E35"\
                                                -tlv_port_id_subtype    port_component\
                                                -tlv_port_id_value      "1234"\
                                                -tlv_ttl_value          "10"\
                                                -lldp_optional_tlvs     $lldp_tlv_handle1\
                                                -dcbx_tlvs              $dcbx_tlv_handle1]

if {![keylget returnedString status ]} {
	puts "FAILED: $returnedString"
    return
} else {
    keylget returnedString handle lldp_handle1
}

# Create Lldp session on port 2
set returnedString [sth::emulation_lldp_config      -port_handle                $portHandle2\
                                                    -mode                       create\
                                                    -count                      1\
                                                    -loopback_ip_addr           192.2.0.1\
                                                    -loopback_ip_addr_step      0.0.0.1\
                                                    -local_mac_addr             00:94:01:00:00:01\
                                                    -local_mac_addr_step        00:00:00:00:00:01\
                                                    -vlan_id                    110\
                                                    -vlan_id_step               2\
                                                    -intf_ip_addr               192.168.1.254\
                                                    -intf_ip_addr_step          0.0.1.0\
                                                    -intf_ip_prefix_length      24\
                                                    -gateway_ip_addr            192.168.1.1\
                                                    -gateway_ip_addr_step       0.0.1.0\
                                                    -intf_ipv6_addr             2000::100\
                                                    -intf_ipv6_addr_step        0000::1\
                                                    -intf_ipv6_prefix_length    64\
                                                    -gateway_ipv6_addr          2000::1\
                                                    -gateway_ipv6_addr_step     ::1\
                                                    -enable_ipv6_gateway_learning   0\
                                                    -intf_ipv6_link_local_addr      FE08::1\
                                                    -msg_tx_interval            30\
                                                    -msg_tx_hold_mutiplier      4\
                                                    -reinitialize_delay         2\
                                                    -tx_delay                   2\
                                                    -tlv_chassis_id_subtype     locally_assigned\
                                                    -tlv_chassis_id_value       "0E36"\
                                                    -tlv_port_id_subtype        intf_name\
                                                    -tlv_port_id_value          "1235"\
                                                    -tlv_ttl_value              "10" \
                                                    -lldp_optional_tlvs         $lldp_tlv_handle1\
                                                    -dcbx_tlvs                  $dcbx_tlv_handle2]

if {![keylget returnedString status ]} {
	puts "FAILED: $returnedString"
    return
} else {
    keylget returnedString handle lldp_handle2
}

#config parts are finished

############################################
#step6 Start LLDP session                  #
############################################

set returnedString [sth::emulation_lldp_control     -handle         "$lldp_handle1 $lldp_handle2"\
                                                    -mode           start]

if {![keylget returnedString status ]} {
	puts "FAILED: $returnedString"
    return
}

############################################
#step7 Retrive LLDP statistics             #
############################################

# get all LLDP & DCBX statistics
foreach lldpHandle "$lldp_handle1 $lldp_handle2" {
    set returnedString [sth::emulation_lldp_info    -handle             $lldpHandle\
                                                    -mode               "both"\
                                                    -dcbx_info_type     {basic|feature_basic|prio_alloc|bw_alloc|pfc|fcoe_prio|logic_link|bcn_parameter|bcn_mode}]

    if {![keylget returnedString status ]} {
		puts "FAILED: $returnedString"
        return
    } else {
        if {[keylget returnedString lldp.lldp_session_state] != "LLDP_SESSION_STATE_UP"} {
			puts "FAILED, LLDP SESSION: $lldpHandle hasn't got up"
            return
        }
    }
}


############################################
#step8 Stop LLDP session                   #
############################################

set returnedString [sth::emulation_lldp_control     -handle     "$lldp_handle1 $lldp_handle2"\
                                                    -mode       stop]

if {![keylget returnedString status ]} {
	puts "FAILED: $returnedString"
    return
}

############################################
#step9 Release resources                   #
############################################

set returnedString [::sth::cleanup_session -port_list $portList]
if {![keylget returnedString status ]} {
	puts "FAILED: $returnedString"
    return
}

puts "_SAMPLE_SCRIPT_SUCCESS"
############################################
#The End                                   #
############################################