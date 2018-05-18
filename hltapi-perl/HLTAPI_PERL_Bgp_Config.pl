#########################################################################################################################
#
# Title         :  HLTAPI_PERL_Bgp_config.pl                   
# Purpose       :  The purpose of this script is to configure BGP router with 55 routes
# 
#
#
# Body   : Step 1. Connect to a pair of STC ports connected B2B                                
#          Step 2. create 2 BGP routers, configure both routers with 55 routes
#          Step 3. Check for BGP status and routes advertised and received
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
# To run this script : perl HLTAPI_PERL_Bgp_config.pl 
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
        logfile                                          => 'bgp_logfile',
        vendorlogfile                                    => 'bgp_stcExport',
        vendorlog                                        => '1',
        hltlog                                           => '1',
        hltlogfile                                       => 'bgp_hltExport',
        hlt2stcmappingfile                               => 'bgp_hlt2StcMapping',
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
my %device_ret0 = sth::emulation_bgp_config (
        mode                                             => 'enable',
        retries                                          => '100',
        vpls_version                                     => 'VERSION_00',
        routes_per_msg                                   => '2000',
        staggered_start_time                             => '100',
        update_interval                                  => '30',
        retry_time                                       => '30',
        staggered_start_enable                           => '1',
        md5_key_id                                       => '1',
        md5_key                                          => 'Spirent',
        md5_enable                                       => '0',
        ipv4_unicast_nlri                                => '1',
        ip_stack_version                                 => '4',
        port_handle                                      => "$hport[1]",
        bgp_session_ip_addr                              => 'interface_ip',
        remote_ip_addr                                   => '10.1.1.2',
        ip_version                                       => '4',
        remote_as                                        => '1001',
        hold_time                                        => '90',
        restart_time                                     => '90',
        route_refresh                                    => '0',
        local_as                                         => '1',
        active_connect_enable                            => '1',
        stale_time                                       => '90',
        graceful_restart_enable                          => '0',
        local_router_id                                  => '192.0.0.1',
        mac_address_start                                => '00:10:94:00:00:01',
        local_ip_addr                                    => '10.1.1.1',
        next_hop_ip                                      => '10.1.1.2',
        netmask                                          => '24');

$status = $device_ret0{status};
if ($status == 0) {
    print "run sth::emulation_bgp_config failed\n";
    print Dumper %device_ret0;
} else {
    print "***** run sth::emulation_bgp_config successfully\n";
}

my @device_ret0_arr = split( " ", $device_ret0{handle} );
my $bgp_router1 = " $device_ret0_arr[0]";

my %device_ret0_route1 = sth::emulation_bgp_route_config (
        handle                                           => "$bgp_router1",
        mode                                             => 'add',
        ip_version                                       => '4',
        as_path                                          => 'as_seq:1',
        target_type                                      => 'as',
        target                                           => '100',
        target_assign                                    => '1',
        rd_type                                          => '0',
        rd_admin_step                                    => '0',
        rd_admin_value                                   => '100',
        rd_assign_step                                   => '1',
        rd_assign_value                                  => '1',
        next_hop_ip_version                              => '4',
        next_hop_set_mode                                => 'manual',
        ipv4_unicast_nlri                                => '1',
        prefix_step                                      => '1',
        prefix                                           => '1.0.0.0',
        num_routes                                       => '55',
        netmask                                          => '255.255.255.0',
        next_hop                                         => '192.85.1.3',
        atomic_aggregate                                 => '0',
        local_pref                                       => '10',
        origin                                           => 'igp',
        label_incr_mode                                  => 'none');

$status = $device_ret0_route1{status};
if ($status == 0) {
    print "run sth::emulation_bgp_route_config failed\n";
    print Dumper %device_ret0_route1;
} else {
    print "***** run sth::emulation_bgp_route_config successfully\n";
}

#start to create the device: Device 2
my %device_ret1 = sth::emulation_bgp_config (
        mode                                             => 'enable',
        retries                                          => '100',
        vpls_version                                     => 'VERSION_00',
        routes_per_msg                                   => '2000',
        staggered_start_time                             => '100',
        update_interval                                  => '30',
        retry_time                                       => '30',
        staggered_start_enable                           => '1',
        md5_key_id                                       => '1',
        md5_key                                          => 'Spirent',
        md5_enable                                       => '0',
        ipv4_unicast_nlri                                => '1',
        ip_stack_version                                 => '4',
        port_handle                                      => "$hport[2]",
        bgp_session_ip_addr                              => 'interface_ip',
        remote_ip_addr                                   => '10.1.1.1',
        ip_version                                       => '4',
        remote_as                                        => '1',
        hold_time                                        => '90',
        restart_time                                     => '90',
        route_refresh                                    => '0',
        local_as                                         => '1001',
        active_connect_enable                            => '1',
        stale_time                                       => '90',
        graceful_restart_enable                          => '0',
        local_router_id                                  => '192.0.0.2',
        mac_address_start                                => '00:10:94:00:00:02',
        local_ip_addr                                    => '10.1.1.2',
        next_hop_ip                                      => '10.1.1.1',
        netmask                                          => '24');

$status = $device_ret1{status};
if ($status == 0) {
    print "run sth::emulation_bgp_config failed\n";
    print Dumper %device_ret1;
} else {
    print "***** run sth::emulation_bgp_config successfully\n";
}

my @device_ret1_arr = split( " ", $device_ret1{handle} );
$bgp_router1 = " $device_ret1_arr[0]";

my %device_ret1_route1 = sth::emulation_bgp_route_config (
        handle                                           => "$bgp_router1",
        mode                                             => 'add',
        ip_version                                       => '4',
        as_path                                          => 'as_seq:1001',
        target_type                                      => 'as',
        target                                           => '100',
        target_assign                                    => '1',
        rd_type                                          => '0',
        rd_admin_step                                    => '0',
        rd_admin_value                                   => '100',
        rd_assign_step                                   => '1',
        rd_assign_value                                  => '1',
        next_hop_ip_version                              => '4',
        next_hop_set_mode                                => 'manual',
        ipv4_unicast_nlri                                => '1',
        prefix_step                                      => '1',
        prefix                                           => '1.0.55.0',
        num_routes                                       => '55',
        netmask                                          => '255.255.255.0',
        next_hop                                         => '193.85.1.3',
        atomic_aggregate                                 => '0',
        local_pref                                       => '10',
        origin                                           => 'igp',
        label_incr_mode                                  => 'none');

$status = $device_ret1_route1{status};
if ($status == 0) {
    print "run sth::emulation_bgp_route_config failed\n";
    print Dumper %device_ret1_route1;
} else {
    print "***** run sth::emulation_bgp_route_config successfully\n";
}

#config part is finished
sth::invoke('stc::perform SaveAsXml -filename "bgp.xml"');
##############################################################
#start devices
##############################################################

@device_ret0_arr = split( " ", $device_ret0{handle} );
@device_ret1_arr = split( " ", $device_ret1{handle} );
my $device_list = " $device_ret0_arr[0] $device_ret1_arr[0]";

my %ctrl_ret1 = sth::emulation_bgp_control (
        handle                                           => "$device_list",
        mode                                             => 'start');

$status = $ctrl_ret1{status};
if ($status == 0) {
    print "run sth::emulation_bgp_control failed\n";
    print Dumper %ctrl_ret1;
} else {
    print "***** run sth::emulation_bgp_control successfully\n";
}

sleep 10;
##############################################################
#start to get the device results
##############################################################

@device_ret0_arr = split( " ", $device_ret0{handle} );
$device = " $device_ret0_arr[0]";

my %results_ret1 = sth::emulation_bgp_info (
        handle                                           => "$device",
        mode                                             => 'stats');

$status = $results_ret1{status};
if ($status == 0) {
    print "run sth::emulation_bgp_info failed\n";
    print Dumper %results_ret1;
} else {
    print "***** run sth::emulation_bgp_info successfully, and results is:\n";
    print Dumper %results_ret1;
}

@device_ret1_arr = split( " ", $device_ret1{handle} );
$device = " $device_ret1_arr[0]";

my %results_ret2 = sth::emulation_bgp_info (
        handle                                           => "$device",
        mode                                             => 'stats');

$status = $results_ret2{status};
if ($status == 0) {
    print "run sth::emulation_bgp_info failed\n";
    print Dumper %results_ret2;
} else {
    print "***** run sth::emulation_bgp_info successfully, and results is:\n";
    print Dumper %results_ret2;
}

@device_ret0_arr = split( " ", $device_ret0{handle} );
$device = " $device_ret0_arr[0]";

my %results_ret4 = sth::emulation_bgp_route_info (
        handle                                           => "$device",
        mode                                             => 'advertised');

$status = $results_ret4{status};
if ($status == 0) {
    print "run sth::emulation_bgp_route_info failed\n";
    print Dumper %results_ret4;
} else {
    print "***** run sth::emulation_bgp_route_info successfully, and results is:\n";
    print Dumper %results_ret4;
}

@device_ret1_arr = split( " ", $device_ret1{handle} );
$device = " $device_ret1_arr[0]";

my %results_ret5 = sth::emulation_bgp_route_info (
        handle                                           => "$device",
        mode                                             => 'advertised');

$status = $results_ret5{status};
if ($status == 0) {
    print "run sth::emulation_bgp_route_info failed\n";
    print Dumper %results_ret5;
} else {
    print "***** run sth::emulation_bgp_route_info successfully, and results is:\n";
    print Dumper %results_ret5;
}

print "\nBGP sessions established on port1: $results_ret1{sessions_established}\n";
print "\nBGP routes advertised on port1: $results_ret1{routes_advertised_tx}\n";
print "\nBGP sessions established on port2: $results_ret2{sessions_established}\n";
print "\nBGP routes received on port2: $results_ret2{routes_advertised_rx}\n";
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
