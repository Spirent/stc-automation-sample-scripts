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
# File Name:    HLTAPI_InterfaceConfig_subinterface.tcl
#
# Description:   Allow interface_config to config subinterfaces. The following options have been added:
#           vlan
#           vlan_id
#           vlan_cfi
#           vlan_id_count
#           vlan_id_step
#           vlan_user_priority
#           qinq_incr_mode
#           vlan_outer_id
#           vlan_outer_cfi
#           vlan_outer_count
#           vlan_outer_id_step
#           vlan_outer_user_priority
#           gateway_step
#           ipv6_gateway_step
#           intf_ip_addr_step
#           ipv6_intf_addr_step
#           src_mac_addr_step
#
#Topology
#           10.21.0.2                   10.21.0.1
#           10.22.0.2                   10.22.0.1
#               (STC) -------------------------------(DUT)  11.55.0.1------------11.55.0.2 (STC)
#           10.23.0.2                   10.23.0.1
#           10.24.0.2                   10.24.0.1
#
# Test Step:  1. Config port TGEN1 (with sub-interfaces) and TGEN2
#             2. Create raw streams
#             3. start traffic and check the result
############################################################################

# Run sample:
#            c:>tclsh HLTAPI_InterfaceConfig_subinterface.tcl 10.61.44.2 3/1 3/3
#            c:>tclsh HLTAPI_InterfaceConfig_subinterface.tcl "10.61.44.2 10.61.44.7" 3/1 3/3

package require SpirentHltApi

set device_list      [lindex $argv 0]
set srcPort        [lindex $argv 1]
set dstPort        [lindex $argv 2]
set i 1
foreach device $device_list {
    set device$i $device
    incr i
}
set device$i $device
set port_list "$srcPort $dstPort";

::sth::test_config  -logfile hltLogfile \
                        -log 1\
                        -vendorlogfile stcExport\
                        -vendorlog 1\
                        -hltlog 1\
                        -hltlogfile hltExport\
                        -hlt2stcmappingfile hlt2stcMapping \
                        -hlt2stcmapping 1\
                        -log_level 7

set mac_addr_tgen       {"00:10:94:00:00:11"  "00:10:94:00:00:22"}
set dut_ip               {"10.21.0.1"  "11.55.0.1"}
set tgen_ip              {"10.21.0.2"  "11.55.0.2"}
set vlan_id               4
set vlan_id_count         4
set vlan_id_step          1

   set returnedString [sth::connect -device $device_list -port_list $port_list ]
   keylget returnedString port_handle.$device1.$srcPort tgen1_port
   keylget returnedString port_handle.$device2.$dstPort tgen2_port
   puts "###    Reserve the Ports $tgen1_port and $tgen2_port "

    puts "###    Config TGEN1 and TGEN2"
    set returnedString [sth::interface_config \
                                        -port_handle            $tgen1_port \
                                        -mode                        config \
                                        -intf_ip_addr              [lindex $tgen_ip 0]\
                                        -intf_ip_addr_step      0.1.0.0 \
                                        -gateway                       [lindex $dut_ip 0]\
                                        -gateway_step              0.1.0.0 \
                                        -autonegotiation            1 \
                                        -arp_send_req               1 \
                                        -arp_req_retries            10 \
                                        -phy_mode                    copper \
                                        -vlan_id                        $vlan_id\
                                        -vlan_id_count              $vlan_id_count \
                                        -vlan                               0]
    puts "       TGEN1: $returnedString"

    set returnedString [sth::interface_config \
                                        -port_handle                    $tgen2_port \
                                        -mode                               config \
                                        -intf_ip_addr                    [lindex $tgen_ip 1]\
                                        -gateway                           [lindex $dut_ip 1]\
                                        -autonegotiation             1 \
                                        -arp_send_req                 1 \
                                        -arp_req_retries              10 \
                                        -phy_mode                       copper ]
    puts "       TGEN2: $returnedString\n"

    puts "###    Config the Downstream and UpstreamTraffic"
    set returnedString [sth::traffic_config \
                                -mode                           create \
                                -port_handle                $tgen2_port \
                                -rate_pps                       1000 \
                                -l2_encap                       ethernet_ii \
                                -l3_protocol                ipv4 \
                                -l3_length                      108\
                                -transmit_mode          continuous \
                                -length_mode                fixed \
                                -ip_src_addr                 [lindex $tgen_ip 1]\
                                -ip_dst_step                0.1.0.0     \
                                -ip_dst_count               $vlan_id_count \
                                -ip_src_count               2\
                                -ip_dst_addr                [lindex $tgen_ip 0] \
                                -mac_discovery_gw   [lindex $dut_ip 1] \
                                ]
    puts  "       TGEN2----->TGEN1: $returnedString"

    set returnedString [sth::traffic_config \
                                -mode                                              create \
                                -port_handle                                   $tgen1_port \
                                -rate_pps                                        1000 \
                                -l2_encap                                         ethernet_ii_vlan \
                                -vlan_id                                            $vlan_id\
                                -vlan_id_count                               $vlan_id_count \
                                -l3_protocol                                    ipv4 \
                                -l3_length                                        108\
                                -transmit_mode                              continuous \
                                -length_mode                                  fixed \
                                -ip_src_addr                                    [lindex $tgen_ip 0]\
                                -ip_dst_addr                                    [lindex $tgen_ip 1]\
                                -mac_discovery_gw                        [lindex $dut_ip 0] \
                                -mac_discovery_gw_step              0.1.0.0 \
                                -mac_discovery_gw_count             $vlan_id_count \
                                -ip_src_step                                    0.1.0.0     \
                                -ip_src_count                                   $vlan_id_count \
                                -ip_dst_count                                   2]
    puts  "       TGEN1----->TGEN2: $returnedString\n"

	#config parts are finished
	
    puts "###    Start the Capture"
    sth::packet_control -port_handle $tgen1_port -action start
    sth::packet_control -port_handle $tgen2_port -action start

    puts "###    Start/Stop the Traffic"
    set returnedString [sth::traffic_control  -port_handle all  -action run]
    puts "       Start: $returnedString \n"
    set returnedString [sth::traffic_control     -port_handle all -action stop]
    puts "       Stop: $returnedString \n"

    puts "###    Stop/Save the Capture"
    sth::packet_control -port_handle $tgen1_port -action stop
    sth::packet_control -port_handle $tgen2_port -action stop
    sth::packet_stats -port_handle $tgen1_port -action filtered -format pcap -filename "subInt1.pcap"
    sth::packet_stats -port_handle $tgen2_port -action filtered -format pcap -filename "subInt2.pcap"

    puts "###    Verify the Result"
    set src_traffic [sth::interface_stats -port_handle $tgen2_port]
    #puts "$src_traffic \n"
    set Src_Tx [keylget src_traffic tx_generator_ipv4_frame_count]
    set Src_Rx [keylget src_traffic rx_sig_count]

    set dst_traffic [sth::interface_stats -port_handle $tgen1_port]
    #puts "$dst_traffic \n"
    set Dst_Tx [keylget dst_traffic tx_generator_ipv4_frame_count]
    set Dst_Rx [keylget dst_traffic rx_sig_count]

    if {$Src_Tx == $Dst_Rx} {puts "       UpStream   Traffic Pass"} else  {puts "       $tgen1_port Tx: $Src_Tx, while Rx: $Dst_Rx"}
    if {$Dst_Tx == $Src_Rx} {puts "       DownStream Traffic Pass"}  else {puts "       $tgen2_port Tx: $Dst_Tx, while Rx: $Src_Rx \n"}

    puts "###    Disconnect the Chassis and Part1 Finish\n"
    sth::cleanup_session -maintain_lock 0 -port_list  [list $tgen1_port $tgen2_port]

puts "Script End"
puts "_SAMPLE_SCRIPT_SUCCESS"