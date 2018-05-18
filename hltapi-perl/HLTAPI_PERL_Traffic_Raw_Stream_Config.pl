#########################################################################################################################
#
# Title         :  HLTAPI_PERL_Traffic_Raw_Stream_Config.pl                   
# Purpose       :  The purpose of this script is to configure raw traffic stream
# 
#
#
# Body   : Step 1. Connect to a pair of STC ports connected B2B                                
#          Step 2. create 2 raw device on each port, configure raw stream on one port
#          Step 3. Check for traffic Tx and Rx 
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
# To run this script : perl HLTAPI_PERL_Traffic_Raw_Stream_Config.pl 
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
        logfile                                          => 'traffic_logfile',
        vendorlogfile                                    => 'traffic_stcExport',
        vendorlog                                        => '1',
        hltlog                                           => '1',
        hltlogfile                                       => 'traffic_hltExport',
        hlt2stcmappingfile                               => 'traffic_hlt2StcMapping',
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


##############################################################
#create traffic
##############################################################

my %streamblock_ret1 = sth::traffic_config (
        mode                                             => 'create',
        port_handle                                      => "$hport[1]",
        l2_encap                                         => 'ethernet_ii',
        l3_protocol                                      => 'ipv4',
        ip_id                                            => '0',
        ip_src_addr                                      => '192.85.1.2',
        ip_dst_addr                                      => '192.0.0.1',
        ip_ttl                                           => '255',
        ip_hdr_length                                    => '5',
        ip_protocol                                      => '253',
        ip_fragment_offset                               => '0',
        ip_mbz                                           => '0',
        ip_precedence                                    => '0',
        ip_tos_field                                     => '0',
        mac_src                                          => '00:10:94:00:00:02',
        mac_dst                                          => '00:00:01:00:00:01',
        enable_control_plane                             => '0',
        l3_length                                        => '110',
        name                                             => 'StreamBlock_4',
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
        mac_discovery_gw                                 => '192.85.1.1');

$status = $streamblock_ret1{status};
if ($status == 0) {
    print "run sth::traffic_config failed\n";
    print Dumper %streamblock_ret1;
} else {
    print "***** run sth::traffic_config successfully\n";
}
my $strm_id = $streamblock_ret1{stream_id};
#config part is finished
sth::invoke('stc::perform SaveAsXml -filename "traffic.xml"');
##############################################################
#start devices
##############################################################


##############################################################
#start traffic
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
