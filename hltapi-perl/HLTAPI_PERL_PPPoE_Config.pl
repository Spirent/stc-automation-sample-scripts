#########################################################################################################################
#
# Title         :  HLTAPI_PERL_PPPoE_Config.pl                   
# Purpose       :  The purpose of this script is to configure PPPoE client and Server
# 
#
#
# Body   : Step 1. Connect to a pair of STC ports connected B2B                                
#          Step 2. Create PPPoE client and PPPoE server on each STC ports
#          Step 3. Check for PPPoE client and server status
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
# To run this script : perl HLTAPI_PERL_PPPoE_Config.pl 
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
        logfile                                          => 'pppoe_logfile',
        vendorlogfile                                    => 'pppoe_stcExport',
        vendorlog                                        => '1',
        hltlog                                           => '1',
        hltlogfile                                       => 'pppoe_hltExport',
        hlt2stcmappingfile                               => 'pppoe_hlt2StcMapping',
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
my $device = "10.61.39.164";
my $port_list = " 10/1 10/3";
my @port_array = ( "10/1", "10/3");
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
        autonegotiation                                  => '1',
        duplex                                           => 'full');

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
        autonegotiation                                  => '1',
        duplex                                           => 'full');

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

#start to create the device: Device 2
my %device_ret0 = sth::pppox_server_config (
        mode                                             => 'create',
        encap                                            => 'ethernet_ii',
        protocol                                         => 'pppoe',
        ipv4_pool_addr_prefix_len                        => '24',
        ipv4_pool_addr_count                             => '1',
        ipv4_pool_addr_step                              => '1',
        ipv4_pool_addr_start                             => '10.1.1.10',
        port_handle                                      => "$hport[2]",
        max_outstanding                                  => '100',
        disconnect_rate                                  => '1000',
        attempt_rate                                     => '100',
        enable_osi                                       => 'false',
        pap_req_timeout                                  => '3',
        mru_neg_enable                                   => '1',
        max_configure_req                                => '10',
        term_req_timeout                                 => '3',
        max_terminate_req                                => '10',
        username                                         => 'spirent',
        force_server_connect_mode                        => 'false',
        echo_vendor_spec_tag_in_pado                     => 'false',
        echo_vendor_spec_tag_in_pads                     => 'false',
        max_payload_tag_enable                           => 'false',
        max_ipcp_req                                     => '10',
        echo_req_interval                                => '10',
        config_req_timeout                               => '3',
        local_magic                                      => '1',
        password                                         => 'spirent',
        chap_reply_timeout                               => '3',
        max_chap_req_attempt                             => '10',
        enable_mpls                                      => 'false',
        lcp_mru                                          => '1492',
        ip_cp                                            => 'ipv4_cp',
        max_echo_acks                                    => '0',
        auth_mode                                        => 'none',
        include_id                                       => '1',
        ipcp_req_timeout                                 => '3',
        server_inactivity_timer                          => '30',
        unconnected_session_threshold                    => '0',
        max_payload_bytes                                => '1500',
        echo_req                                         => 'false',
        fsm_max_naks                                     => '5',
        num_sessions                                     => '1',
        mac_addr                                         => '00:10:94:00:00:04',
        mac_addr_step                                    => '00:00:00:00:00:01',
        intf_ip_prefix_length                            => '24',
        intf_ip_addr                                     => '10.1.1.2',
        gateway_ip_addr                                  => '10.1.1.1',
        intf_ip_addr_step                                => '0.0.0.1',
        gateway_ip_step                                  => '0.0.0.0');

$status = $device_ret0{status};
if ($status == 0) {
    print "run sth::pppox_server_config failed\n";
    print Dumper %device_ret0;
} else {
    print "***** run sth::pppox_server_config successfully\n";
}

#start to create the device: Device 1
my %device_ret1 = sth::pppox_config (
        mode                                             => 'create',
        encap                                            => 'ethernet_ii',
        protocol                                         => 'pppoe',
        ac_select_mode                                   => 'service_name',
        circuit_id_suffix_mode                           => 'none',
        remote_id_suffix_mode                            => 'none',
        port_handle                                      => "$hport[1]",
        max_outstanding                                  => '100',
        disconnect_rate                                  => '1000',
        attempt_rate                                     => '100',
        pppoe_circuit_id                                 => 'circuit',
        mru_neg_enable                                   => '1',
        max_configure_req                                => '10',
        chap_ack_timeout                                 => '3',
        max_padi_req                                     => '10',
        padi_include_tag                                 => '1',
        padr_req_timeout                                 => '3',
        max_terminate_req                                => '10',
        term_req_timeout                                 => '3',
        username                                         => 'spirent',
        use_partial_block_state                          => 'false',
        max_auto_retry_count                             => '65535',
        agent_session_id                                 => 'remote',
        agent_type                                       => '2516',
        max_ipcp_req                                     => '10',
        intermediate_agent                               => 'false',
        echo_req_interval                                => '10',
        password                                         => 'spirent',
        local_magic                                      => '1',
        config_req_timeout                               => '3',
        active                                           => '1',
        auto_retry                                       => 'false',
        padi_req_timeout                                 => '3',
        agent_mac_addr                                   => '00:00:00:00:00:00',
        lcp_mru                                          => '1492',
        ip_cp                                            => 'ipv4_cp',
        auto_fill_ipv6                                   => '1',
        max_echo_acks                                    => '0',
        auth_mode                                        => 'none',
        include_id                                       => '1',
        ipcp_req_timeout                                 => '3',
        pppoe_remote_id                                  => 'remote',
        max_padr_req                                     => '10',
        padr_include_tag                                 => '1',
        echo_req                                         => 'false',
        fsm_max_naks                                     => '5',
        num_sessions                                     => '1',
        mac_addr                                         => '00:10:94:00:00:03',
        mac_addr_repeat                                  => '0',
        mac_addr_step                                    => '00:00:00:00:00:01',
        intf_ip_addr                                     => '10.1.1.1',
        gateway_ip_addr                                  => '10.1.1.2',
        intf_ip_addr_step                                => '0.0.0.1',
        gateway_ip_step                                  => '0.0.0.0');

$status = $device_ret1{status};
if ($status == 0) {
    print "run sth::pppox_config failed\n";
    print Dumper %device_ret1;
} else {
    print "***** run sth::pppox_config successfully\n";
}

#config part is finished
sth::invoke('stc::perform SaveAsXml -filename "pppoe.xml"');
##############################################################
#start devices
##############################################################

my @device_ret0_arr = split( " ", $device_ret0{handle} );
my $device_list = " $device_ret0_arr[0]";

my %ctrl_ret1 = sth::pppox_server_control (
        handle                                           => "$device_list",
        action                                           => 'connect');

$status = $ctrl_ret1{status};
if ($status == 0) {
    print "run sth::pppox_server_control failed\n";
    print Dumper %ctrl_ret1;
} else {
    print "***** run sth::pppox_server_control successfully\n";
}

my @device_ret1_arr = split( " ", $device_ret1{handle} );
$device_list = " $device_ret1_arr[0]";

my %ctrl_ret2 = sth::pppox_control (
        handle                                           => "$device_list",
        action                                           => 'connect');

$status = $ctrl_ret2{status};
if ($status == 0) {
    print "run sth::pppox_control failed\n";
    print Dumper %ctrl_ret2;
} else {
    print "***** run sth::pppox_control successfully\n";
}

sleep 10;
##############################################################
#start to get the device results
##############################################################

@device_ret0_arr = split( " ", $device_ret0{handle} );
$device = " $device_ret0_arr[0]";

my %results_ret1 = sth::pppox_server_stats (
        handle                                           => "$device",
        mode                                             => 'aggregate');

$status = $results_ret1{status};
if ($status == 0) {
    print "run sth::pppox_server_stats failed\n";
    print Dumper %results_ret1;
} else {
    print "***** run sth::pppox_server_stats successfully, and results is:\n";
    print Dumper %results_ret1;
}

@device_ret1_arr = split( " ", $device_ret1{handle} );
$device = " $device_ret1_arr[0]";

my %results_ret3 = sth::pppox_stats (
        handle                                           => "$device",
        mode                                             => 'aggregate');

$status = $results_ret3{status};
if ($status == 0) {
    print "run sth::pppox_stats failed\n";
    print Dumper %results_ret3;
} else {
    print "***** run sth::pppox_stats successfully, and results is:\n";
    print Dumper %results_ret3;
}

print "\nNumber of pppoe server sessions configured on port1: $results_ret1{aggregate}{num_sessions}\n";
print "\nNumber of pppoe server sessions up on port1: $results_ret1{aggregate}{sessions_up}\n";
print "\nNumber of pppoe client sessions configured on port2: $results_ret3{aggregate}{sessions_up}\n";
print "\nNumber of pppoe client sessions up on port2: $results_ret3{aggregate}{num_sessions}\n";


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
