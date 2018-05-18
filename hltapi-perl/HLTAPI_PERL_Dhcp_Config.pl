#########################################################################################################################
#
# Title         :  HLTAPI_PERL_Dhcp_Config.pl                   
# Purpose       :  The purpose of this script is to configure DHCP client and server
# 
#
#
# Body   : Step 1. Connect to a pair of STC ports connected B2B                                
#          Step 2. create DHCP client on STC port and DHCP server on other STC port
#          Step 3. Check for DHCP server and client status
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
# To run this script : perl HLTAPI_PERL_Dhcp_Config.pl 
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
        logfile                                          => 'dhcp_logfile',
        vendorlogfile                                    => 'dhcp_stcExport',
        vendorlog                                        => '1',
        hltlog                                           => '1',
        hltlogfile                                       => 'dhcp_hltExport',
        hlt2stcmappingfile                               => 'dhcp_hlt2StcMapping',
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

#start to create the device: Device 2
my %device_ret0 = sth::emulation_dhcp_server_config (
        mode                                             => 'create',
        ip_version                                       => '4',
        encapsulation                                    => 'ETHERNET_II',
        ipaddress_count                                  => '245',
        ipaddress_pool                                   => '10.1.1.10',
        ipaddress_increment                              => '1',
        port_handle                                      => "$hport[2]",
        count                                            => '1',
        lease_time                                       => '3600',
        local_mac                                        => '00:10:94:00:00:02',
        ip_repeat                                        => '0',
        remote_mac                                       => '00:00:01:00:00:01',
        ip_address                                       => '10.1.1.2',
        ip_prefix_length                                 => '24',
        ip_gateway                                       => '10.1.1.1',
        ip_step                                          => '0.0.0.1');

$status = $device_ret0{status};
if ($status == 0) {
    print "run sth::emulation_dhcp_server_config failed\n";
    print Dumper %device_ret0;
} else {
    print "***** run sth::emulation_dhcp_server_config successfully\n";
}

#start to create the device: Device 1
my %device_ret1port = sth::emulation_dhcp_config (
        mode                                             => 'create',
        ip_version                                       => '4',
        port_handle                                      => "$hport[1]",
        starting_xid                                     => '0',
        lease_time                                       => '60',
        outstanding_session_count                        => '1000',
        request_rate                                     => '100',
        msg_timeout                                      => '60000',
        retry_count                                      => '4',
        max_dhcp_msg_size                                => '576',
        release_rate                                     => '100');

$status = $device_ret1port{status};
if ($status == 0) {
    print "run sth::emulation_dhcp_config failed\n";
    print Dumper %device_ret1port;
} else {
    print "***** run sth::emulation_dhcp_config successfully\n";
}

my $dhcp_handle = " $device_ret1port{handles}";

my %device_ret1 = sth::emulation_dhcp_group_config (
        mode                                             => 'create',
        dhcp_range_ip_type                               => '4',
        encap                                            => 'ethernet_ii',
        handle                                           => "$dhcp_handle",
        num_sessions                                     => '1',
        opt_list                                         => '1 6 15 33 44',
        host_name                                        => 'client_@p-@b-@s',
        mac_addr                                         => '00:10:94:00:00:01',
        mac_addr_step                                    => '00:00:00:00:00:01',
        ipv4_gateway_address                             => '10.1.1.2');

$status = $device_ret1{status};
if ($status == 0) {
    print "run sth::emulation_dhcp_group_config failed\n";
    print Dumper %device_ret1;
} else {
    print "***** run sth::emulation_dhcp_group_config successfully\n";
}

#config part is finished
sth::invoke('stc::perform SaveAsXml -filename "dhcp.xml"');
##############################################################
#start devices
##############################################################

my %ctrl_ret1 = sth::emulation_dhcp_server_control (
        port_handle                                      => "$hport[2]",
        action                                           => 'connect',
        ip_version                                       => '4');

$status = $ctrl_ret1{status};
if ($status == 0) {
    print "run sth::emulation_dhcp_server_control failed\n";
    print Dumper %ctrl_ret1;
} else {
    print "***** run sth::emulation_dhcp_server_control successfully\n";
}

my %ctrl_ret2 = sth::emulation_dhcp_control (
        port_handle                                      => "$hport[1]",
        action                                           => 'bind',
        ip_version                                       => '4');

$status = $ctrl_ret2{status};
if ($status == 0) {
    print "run sth::emulation_dhcp_control failed\n";
    print Dumper %ctrl_ret2;
} else {
    print "***** run sth::emulation_dhcp_control successfully\n";
}

sleep 10;
##############################################################
#start to get the device results
##############################################################

my %results_ret1 = sth::emulation_dhcp_server_stats (
        port_handle                                      => "$hport[2]",
        action                                           => 'COLLECT',
        ip_version                                       => '4');

$status = $results_ret1{status};
if ($status == 0) {
    print "run sth::emulation_dhcp_server_stats failed\n";
    print Dumper %results_ret1;
} else {
    print "***** run sth::emulation_dhcp_server_stats successfully, and results is:\n";
    print Dumper %results_ret1;
}
print "\nDHCP server status: $results_ret1{dhcp_server_state}\n";

my %results_ret2 = sth::emulation_dhcp_stats (
        port_handle                                      => "$hport[1]",
        action                                           => 'collect',
        mode                                             => 'session',
        ip_version                                       => '4');

$status = $results_ret2{status};
if ($status == 0) {
    print "run sth::emulation_dhcp_stats failed\n";
    print Dumper %results_ret2;
} else {
    print "***** run sth::emulation_dhcp_stats successfully, and results is:\n";
    print Dumper %results_ret2;
}
#my $res = \%results_ret2;
my $client_stats = $results_ret2{group}{dhcpv4blockconfig1}{total_bound};
print "\nclients bound : $client_stats\n";

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
