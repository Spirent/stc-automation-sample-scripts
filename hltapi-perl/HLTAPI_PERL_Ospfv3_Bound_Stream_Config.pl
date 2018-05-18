#########################################################################################################################
#
# Title         :  HLTAPI_PERL_Ospfv3_Bound_Stream_Config.pl                   
# Purpose       :  The purpose of this script is to configure OSPFv3 router with 2 ROUTER/External LSA and send traffic between them
# 
#
#
# Body   : Step 1. Connect to a pair of STC ports connected B2B                                
#          Step 2. Create 2 OSPFv3 routers, configure routers ROUTER and EXTERNAL LSA's
#          Step 3. Create bound stream between EXTERNAL LSA on port1 to router2 on port2
#          Step 4. Check for OSPFv3 state and basic traffic Tx and Rx
#         
#           
#
# Pass/Fail Criteria:  Script passes if
#                                                                             
#            Step 1. Connect and reserve successfully                             
#             
#                                                                                          
# Pre-requisites :  1) A pair of STC ports connected to B2B
#                                                                                          
# Output        :  debug logs                                                 
#                                                                             
# Software Req  :   SpirentTestCenter package, HLTAPI 4.40 GA and above                                   
#                                                                             
# Revison History  :                                                          
# Created: - Bharath 2014/07/09                                               
#                                                                             
# Test Type: Functional, Regression                                           
#                                                                             
# To run this script : perl HLTAPI_PERL_Ospfv3_Bound_Stream_Config.pl 
#
# "Copyright Spirent Communications PLC, All rights reserved" 
#
#########################################################################################################################

use sth;
use strict;
use warnings;
use Data::Dumper;


my $status = 0;


##############################################################
#config the parameters for the logging
##############################################################

my %test_sta = sth::test_config (
        log                                              => '1',
        logfile                                          => 'ospfv3_logfile',
        vendorlogfile                                    => 'ospfv3_stcExport',
        vendorlog                                        => '1',
        hltlog                                           => '1',
        hltlogfile                                       => 'ospfv3_hltExport',
        hlt2stcmappingfile                               => 'ospfv3_hlt2StcMapping',
        hlt2stcmapping                                   => '1',
        log_level                                        => '7');

$status = $test_sta{status};
if ($status == 0) {
    print "run sth::test_config failed\n";
    print Dumper %test_sta;
} else {
    print "***** run sth::test_config successfully\n";
}


##############################################################
#config the parameters for optimization and parsing
##############################################################

my %test_ctrl_sta = sth::test_control (
        action                                           => 'enable');

$status = $test_ctrl_sta{status};
if ($status == 0) {
    print "run sth::test_control failed\n";
    print Dumper %test_ctrl_sta;
} else {
    print "***** run sth::test_control successfully\n";
}


##############################################################
#connect to chassis and reserve port list
##############################################################

my $i = 0;
my $device = "10.62.224.11";
my $port_list = " 1/1 1/2";
my @port_array = ( "1/1", "1/2");
my @hport = ""; 
my %intStatus = sth::connect (
        device                                           => "$device",
        port_list                                        => "$port_list",
        offline                                          => '0' );

$status = $intStatus{status};

if ($status == 1) {
    foreach my $port (@port_array) {
        $i++;
        $hport[$i] = $intStatus{port_handle}{$device}{$port};
        print "\n reserved ports $port: $hport[$i]\n";
    }
} else {
    print "\nFailed to retrieve port handle!\n";
    print Dumper %intStatus;
}



##############################################################
#interface config
##############################################################

my %int_ret0 = sth::interface_config (
        mode                                             => 'config',
        port_handle                                      => "$hport[1]",
        intf_mode                                        => 'ethernet',
        duplex                                           => 'full',
        autonegotiation                                  => '1');

$status = $int_ret0{status};
if ($status == 0) {
    print "run sth::interface_config failed\n";
    print Dumper %int_ret0;
} else {
    print "***** run sth::interface_config successfully\n";
}

my %int_ret1 = sth::interface_config (
        mode                                             => 'config',
        port_handle                                      => "$hport[2]",
        intf_mode                                        => 'ethernet',
        duplex                                           => 'full',
        autonegotiation                                  => '1');

$status = $int_ret1{status};
if ($status == 0) {
    print "run sth::interface_config failed\n";
    print Dumper %int_ret1;
} else {
    print "***** run sth::interface_config successfully\n";
}


##############################################################
#create device and config the protocol on it
##############################################################

#start to create the device: Device 1
my %device_ret0 = sth::emulation_ospf_config (
        mode                                             => 'create',
        ip_version                                       => '6',
        session_type                                     => 'ospfv3',
        network_type                                     => 'ptop',
        option_bits                                      => '0x13',
        port_handle                                      => "$hport[1]",
        hello_interval                                   => '10',
        lsa_retransmit_delay                             => '5',
        instance_id                                      => '0',
        router_priority                                  => '0',
        dead_interval                                    => '40',
        interface_cost                                   => '1',
        area_id                                          => '0.0.0.0',
        intf_ip_addr                                     => '2001::2',
        gateway_ip_addr                                  => '2001::1',
        intf_prefix_length                               => '64',
        router_id                                        => '192.0.0.1',
        mac_address_start                                => '00:10:94:00:00:01');

$status = $device_ret0{status};
if ($status == 0) {
    print "run sth::emulation_ospf_config failed\n";
    print Dumper %device_ret0;
} else {
    print "***** run sth::emulation_ospf_config successfully\n";
}

my @device_ret0_arr = split( " ", $device_ret0{handle} );
my $ospf_router0 = " $device_ret0_arr[0]";

my %device_ret0_router0 = sth::emulation_ospf_lsa_config (
        type                                             => 'router',
        ls_seq                                           => '2147483649',
        ls_age                                           => '0',
        adv_router_id                                    => '192.0.0.1',
        link_state_id                                    => '0',
        handle                                           => "$ospf_router0",
        router_link_data                                 => '1',
        router_link_id                                   => '1.0.0.1',
        router_link_metric                               => '1',
        router_link_mode                                 => 'create',
        router_link_type                                 => 'ptop',
        mode                                             => 'create');

$status = $device_ret0_router0{status};
if ($status == 0) {
    print "run sth::emulation_ospf_lsa_config failed\n";
    print Dumper %device_ret0_router0;
} else {
    print "***** run sth::emulation_ospf_lsa_config successfully\n";
}

@device_ret0_arr = split( " ", $device_ret0{handle} );
$ospf_router0 = " $device_ret0_arr[0]";

my %device_ret0_router1 = sth::emulation_ospf_lsa_config (
        router_abr                                       => '1',
        router_asbr                                      => '1',
        type                                             => 'router',
        ls_seq                                           => '2147483649',
        ls_age                                           => '0',
        adv_router_id                                    => '1.0.0.1',
        link_state_id                                    => '0',
        handle                                           => "$ospf_router0",
        router_link_data                                 => '1',
        router_link_id                                   => '192.0.0.1',
        router_link_metric                               => '1',
        router_link_mode                                 => 'create',
        router_link_type                                 => 'ptop',
        mode                                             => 'create');

$status = $device_ret0_router1{status};
if ($status == 0) {
    print "run sth::emulation_ospf_lsa_config failed\n";
    print Dumper %device_ret0_router1;
} else {
    print "***** run sth::emulation_ospf_lsa_config successfully\n";
}

@device_ret0_arr = split( " ", $device_ret0{handle} );
$ospf_router0 = " $device_ret0_arr[0]";

my %device_ret0_summary_pool2 = sth::emulation_ospf_lsa_config (
        summary_prefix_length                            => '64',
        summary_prefix_start                             => '2000:0:0:2::',
        summary_prefix_step                              => '1',
        summary_number_of_prefix                         => '2',
        type                                             => 'summary_pool',
        summary_prefix_metric                            => '100',
        adv_router_id                                    => '1.0.0.1',
        handle                                           => "$ospf_router0",
        mode                                             => 'create');

$status = $device_ret0_summary_pool2{status};
if ($status == 0) {
    print "run sth::emulation_ospf_lsa_config failed\n";
    print Dumper %device_ret0_summary_pool2;
} else {
    print "***** run sth::emulation_ospf_lsa_config successfully\n";
}

@device_ret0_arr = split( " ", $device_ret0{handle} );
$ospf_router0 = " $device_ret0_arr[0]";

my %device_ret0_ext_pool3 = sth::emulation_ospf_lsa_config (
        external_prefix_step                             => '1',
        external_number_of_prefix                        => '2',
        external_prefix_start                            => '2000:0:0:4::',
        external_prefix_length                           => '64',
        type                                             => 'ext_pool',
        external_prefix_type                             => '0',
        adv_router_id                                    => '1.0.0.1',
        external_prefix_metric                           => '1000',
        handle                                           => "$ospf_router0",
        mode                                             => 'create');

$status = $device_ret0_ext_pool3{status};
if ($status == 0) {
    print "run sth::emulation_ospf_lsa_config failed\n";
    print Dumper %device_ret0_ext_pool3;
} else {
    print "***** run sth::emulation_ospf_lsa_config successfully\n";
}

#start to create the device: Device 2
my %device_ret1 = sth::emulation_ospf_config (
        mode                                             => 'create',
        ip_version                                       => '6',
        session_type                                     => 'ospfv3',
        network_type                                     => 'ptop',
        option_bits                                      => '0x13',
        port_handle                                      => "$hport[2]",
        hello_interval                                   => '10',
        lsa_retransmit_delay                             => '5',
        instance_id                                      => '0',
        router_priority                                  => '0',
        dead_interval                                    => '40',
        interface_cost                                   => '1',
        area_id                                          => '0.0.0.0',
        intf_ip_addr                                     => '2001::1',
        gateway_ip_addr                                  => '2001::2',
        intf_prefix_length                               => '64',
        router_id                                        => '192.0.0.2',
        mac_address_start                                => '00:10:94:00:00:02');

$status = $device_ret1{status};
if ($status == 0) {
    print "run sth::emulation_ospf_config failed\n";
    print Dumper %device_ret1;
} else {
    print "***** run sth::emulation_ospf_config successfully\n";
}

my @device_ret1_arr = split( " ", $device_ret1{handle} );
$ospf_router0 = " $device_ret1_arr[0]";

my %device_ret1_router0 = sth::emulation_ospf_lsa_config (
        type                                             => 'router',
        ls_seq                                           => '2147483649',
        ls_age                                           => '0',
        adv_router_id                                    => '192.0.0.2',
        link_state_id                                    => '0',
        handle                                           => "$ospf_router0",
        mode                                             => 'create');

$status = $device_ret1_router0{status};
if ($status == 0) {
    print "run sth::emulation_ospf_lsa_config failed\n";
    print Dumper %device_ret1_router0;
} else {
    print "***** run sth::emulation_ospf_lsa_config successfully\n";
}


##############################################################
#create traffic
##############################################################

my @device_ret0_summary_pool2_arr = split( " ", $device_ret0_summary_pool2{lsa_handle} );
my $src_hdl = " $device_ret0_summary_pool2_arr[0]";

@device_ret1_arr = split( " ", $device_ret1{handle} );
my $dst_hdl = " $device_ret1_arr[0]";

my %streamblock_ret1 = sth::traffic_config (
        mode                                             => 'create',
        port_handle                                      => "$hport[1]",
        emulation_src_handle                             => "$src_hdl",
        emulation_dst_handle                             => "$dst_hdl",
        l3_protocol                                      => 'ipv6',
        ipv6_traffic_class                               => '0',
        ipv6_next_header                                 => '59',
        ipv6_length                                      => '0',
        ipv6_flow_label                                  => '7',
        ipv6_hop_limit                                   => '255',
        enable_control_plane                             => '0',
        l3_length                                        => '128',
        name                                             => 'StreamBlock_1-2',
        fill_type                                        => 'constant',
        fcs_error                                        => '0',
        fill_value                                       => '0',
        frame_size                                       => '128',
        traffic_state                                    => '1',
        high_speed_result_analysis                       => '1',
        length_mode                                      => 'fixed',
        disable_signature                                => '0',
        enable_stream_only_gen                           => '1',
        pkts_per_burst                                   => '1',
        inter_stream_gap_unit                            => 'bytes',
        burst_loop_count                                 => '30',
        transmit_mode                                    => 'continuous',
        inter_stream_gap                                 => '12',
        rate_percent                                     => '10',
        mac_discovery_gw                                 => '2001::1');

$status = $streamblock_ret1{status};
if ($status == 0) {
    print "run sth::traffic_config failed\n";
    print Dumper %streamblock_ret1;
} else {
    print "***** run sth::traffic_config successfully\n";
}
my $strm_id = $streamblock_ret1{stream_id};
#config part is finished
sth::invoke('stc::perform SaveAsXml -filename "ospfv3.xml"');
##############################################################
#start devices
##############################################################

@device_ret0_arr = split( " ", $device_ret0{handle} );
my $device_list = " $device_ret0_arr[0]";

my %ctrl_ret1 = sth::emulation_ospf_control (
        handle                                           => "$device_list",
        mode                                             => 'start');

$status = $ctrl_ret1{status};
if ($status == 0) {
    print "run sth::emulation_ospf_control failed\n";
    print Dumper %ctrl_ret1;
} else {
    print "***** run sth::emulation_ospf_control successfully\n";
}

@device_ret1_arr = split( " ", $device_ret1{handle} );
$device_list = " $device_ret1_arr[0]";

%ctrl_ret1 = sth::emulation_ospf_control (
        handle                                           => "$device_list",
        mode                                             => 'start');

$status = $ctrl_ret1{status};
if ($status == 0) {
    print "run sth::emulation_ospf_control failed\n";
    print Dumper %ctrl_ret1;
} else {
    print "***** run sth::emulation_ospf_control successfully\n";
}
sleep 10;

##############################################################
#start and stop traffic
##############################################################

my %traffic_ctrl_ret = sth::traffic_control (
        port_handle                                      => "$hport[1] $hport[2]",
        action                                           => 'run');

$status = $traffic_ctrl_ret{status};
if ($status == 0) {
    print "run sth::traffic_control failed\n";
    print Dumper %traffic_ctrl_ret;
} else {
    print "***** run sth::traffic_control successfully\n";
}
sleep 10;



my %traffic_ctrl_ret2 = sth::traffic_control (
        port_handle                                      => "$hport[1] $hport[2]",
        action                                           => 'stop');

$status = $traffic_ctrl_ret2{status};
if ($status == 0) {
    print "run sth::traffic_control failed\n";
    print Dumper %traffic_ctrl_ret2;
} else {
    print "***** run sth::traffic_control successfully\n";
}
##############################################################
#start to get the device results
##############################################################

@device_ret0_arr = split( " ", $device_ret0{handle} );
@device_ret1_arr = split( " ", $device_ret1{handle} );
$device_list = " $device_ret0_arr[0] $device_ret1_arr[0]";

my %results_ret1 = sth::emulation_ospfv3_info (
        handle                                           => "$device_list");

$status = $results_ret1{status};
if ($status == 0) {
    print "run sth::emulation_ospfv3_info failed\n";
    print Dumper %results_ret1;
} else {
    print "***** run sth::emulation_ospfv3_info successfully, and results is:\n";
    print Dumper %results_ret1;
}
print "\nOSPF router status: $results_ret1{adjacency_status}\n";
print "\nOSPF router state: $results_ret1{router_state}\n";
print "\nTotal external lsa received: $results_ret1{rx_asexternal_lsa}\n";
print "\nTotal router lsa received: $results_ret1{rx_router_lsa}\n";

@device_ret0_arr = split( " ", $device_ret0{handle} );
@device_ret1_arr = split( " ", $device_ret1{handle} );
$device_list = " $device_ret0_arr[0] $device_ret1_arr[0]";

my %route_results_ret1 = sth::emulation_ospf_route_info (
        handle                                           => "$device_list");

$status = $route_results_ret1{status};
if ($status == 0) {
    print "run sth::emulation_ospf_route_info failed\n";
    print Dumper %route_results_ret1;
} else {
    print "***** run sth::emulation_ospf_route_info successfully, and results is:\n";
    print Dumper %route_results_ret1;
}

##############################################################
#start to get the traffic results
##############################################################

my %traffic_results_ret = sth::traffic_stats (
        port_handle                                      => "$hport[1]",
        mode                                             => 'streams',
        streams                                          => "$strm_id",
        rx_port_handle                                   =>  "$hport[2]");

$status = $traffic_results_ret{status};
if ($status == 0) {
    print "run sth::traffic_stats failed\n";
    print Dumper %traffic_results_ret;
} else {
    print "***** run sth::traffic_stats successfully, and results is:\n";
    print Dumper %traffic_results_ret;
}

print "\nTotal packets sent on port1: $traffic_results_ret{$hport[1]}{stream}{$strm_id}{tx}{total_pkts}\n";
print "\nTotal packets received on port2: $traffic_results_ret{$hport[2]}{stream}{$strm_id}{rx}{total_pkts}\n";
##############################################################
#clean up the session, release the ports reserved and cleanup the dbfile
##############################################################

my %cleanup_sta = sth::cleanup_session (
        port_handle                                      => "$hport[1] $hport[2]",
        clean_dbfile                                     => '1');

$status = $cleanup_sta{status};
if ($status == 0) {
    print "run sth::cleanup_session failed\n";
    print Dumper %cleanup_sta;
} else {
    print "***** run sth::cleanup_session successfully\n";
}


print "**************Finish***************\n";
