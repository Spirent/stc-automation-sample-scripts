################################################################################
#
# File Name:         HLTAPI_Twamp.tcl
#
# Description:       This script demonstrates .
#
# Test Step:         1. Reserve and connect chassis ports
#                    2. Create two devices using emulation_device_config
#                    3. Creating a twamp client on device1
#                    4. Creating a twamp server on device2
#                    5. Creating two sessions on twamp client
#                    6. Start twamp server
#                    7. Start twamp client
#                    8. Take stats for mode state_summary ,client, server, test_session, port_test_session, aggregated_client and aggregated_server
#
#
#Author :  Manasa M B
#
# HLTAPI_Twamp.tcl 10.62.224.163 1/1 1/2
################################################################################

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

##############################################################
#config the parameters for the logging
##############################################################

set test_sta [sth::test_config\
        -log                                              1\
        -logfile                                          twamp_logfile\
        -vendorlogfile                                    twamp_stcExport\
        -vendorlog                                        1\
        -hltlog                                           1\
        -hltlogfile                                       twamp_hltExport\
        -hlt2stcmappingfile                               twamp_hlt2StcMapping\
        -hlt2stcmapping                                   1\
        -log_level                                        7]

set status [keylget test_sta status]
if {$status == 0} {
    puts "<error>run sth::test_config failed"
    puts $test_sta
} else {
    puts "\n***** run sth::test_config successfully\n"
}

##############################################################
#config the parameters for optimization and parsing
##############################################################

set test_ctrl_sta [sth::test_control\
        -action                                           enable]

set status [keylget test_ctrl_sta status]
if {$status == 0} {
    puts "<error>run sth::test_control failed"
    puts $test_ctrl_sta
} else {
    puts "\n***** run sth::test_control successfully\n"
}

##############################################################
#connect to chassis and reserve port list
##############################################################

set i 0
set intStatus [sth::connect -device $device_list -port_list $port_list];

set chassConnect [keylget intStatus status]
if {$chassConnect} {
    foreach port $port_list {
        incr i
        set port$i [keylget intStatus port_handle.$device.$port]
        puts "\n reserved ports : $intStatus"
    }
} else {
    set passFail FAIL
    puts "\n<error>Failed to retrieve port handle! Error message: $intStatus"
}

set device_ret0 [sth::emulation_device_config\
        -mode                                             create\
        -ip_version                                       ipv4\
        -encapsulation                                    ethernet_ii\
        -port_handle                                      $port1\
        -count                                            1 \
        -enable_ping_response                             0 \
        -router_id                                        192.0.0.1 \
        -mac_addr                                         00:10:94:00:00:01 \
        -mac_addr_step                                    00:00:00:00:00:01 \
        -resolve_gateway_mac                              true \
        -gateway_ip_addr_step                             0.0.0.0 \
        -intf_ip_addr                                     192.85.1.3 \
        -intf_prefix_len                                  24 \
        -gateway_ip_addr                                  192.85.1.1 \
        -intf_ip_addr_step                                0.0.0.1 \
]

set devicehandle1 [keylget device_ret0 handle]

set status [keylget device_ret0 status]
if {$status == 0} {
    puts "\n<error>run sth::emulation_device_config failed"
    puts $device_ret0
} else {
    puts "\n*****run sth::emulation_device_config successfully"
}

set device_ret1 [sth::emulation_device_config\
        -mode                                             create\
        -ip_version                                       ipv4\
        -encapsulation                                    ethernet_ii\
        -port_handle                                      $port2\
        -count                                            1 \
        -enable_ping_response                             0 \
        -router_id                                        192.0.0.2 \
        -mac_addr                                         00:10:94:00:00:02 \
        -mac_addr_step                                    00:00:00:00:00:01 \
        -resolve_gateway_mac                              true \
        -gateway_ip_addr_step                             0.0.0.0 \
        -intf_ip_addr                                     192.85.1.1 \
        -intf_prefix_len                                  24 \
        -gateway_ip_addr                                  192.85.1.3 \
        -intf_ip_addr_step                                0.0.0.1 \
]
set devicehandle2 [keylget device_ret1 handle]

set status [keylget device_ret1 status]
if {$status == 0} {
    puts "\n<error>run sth::emulation_device_config failed"
    puts device_ret1
} else {
    puts "\n***** run sth::emulation_device_config successfully"
}

#IPV4
#creating a twamp client on device1
set device_ret2 [sth::emulation_twamp_config\
        -mode                                               create\
        -handle                                             $devicehandle1\
        -type                                               client\
        -connection_retry_cnt                               200\
        -ip_version                                         ipv4\
        -peer_ipv4_addr                                     192.85.1.1\
        -scalability_mode                                   normal \
        -connection_retry_interval                          40 \
]
set status [keylget device_ret2 status]
if {$status == 0} {
    puts "<error>run sth::emulation_twamp_config client failed"
    puts $device_ret2
} else {
    puts "\n*****run sth::emulation_twamp_config client successfully"
}

#creating a twamp server on device2
set device_ret3 [sth::emulation_twamp_config\
        -mode                                             create\
        -handle                                           $devicehandle2\
        -type                                             server\
        -server_ip_version                                ipv4 \
        -server_mode                                      unauthenticated \
        -server_willing_to_participate                    true\
]
set status [keylget device_ret3 status]
if {$status == 0} {
    puts "\n<error>run sth::emulation_device_config failed"
    puts $device_ret3
} else {
    puts "\n*****run sth::emulation_device_config successfully"
}


#To create session1 on twamp client1
set device_ret4 [sth::emulation_twamp_session_config\
                 -mode                                             create\
                 -handle                                           $devicehandle1\
                 -dscp                                             2\
                 -duration                                         120\
                 -duration_mode                                    seconds\
                 -frame_rate                                       50\
                 -pck_cnt                                          200\
                 -padding_len                                      140\
                 -session_dst_udp_port                             5450\
                 -session_src_udp_port                             5451\
                 -start_delay                                      6\
                 -timeout                                          60\
                 -ttl                                              254\
                 -padding_pattern                                  random\
                 -scalability_mode                                 normal\   ]
set status [keylget device_ret4 status]
if {$status == 0} {
    puts "\n<error>run sth::emulation_twamp_session_config failed"
    puts $device_ret4
} else {
    puts "\n*****run sth::emulation_twamp_session_config successfully"
}

#To create session2 on twamp client1
set device_ret5 [sth::emulation_twamp_session_config \
                 -mode                                             create\
                 -handle                                           $devicehandle1\
                 -dscp                                             2\
                 -duration                                         120\
                 -duration_mode                                    seconds\
                 -frame_rate                                       50\
                 -pck_cnt                                          200\
                 -padding_len                                      140\
                 -padding_pattern                                  random\
                 -scalability_mode                                 normal\
                 -session_dst_udp_port                             5452\
                 -session_src_udp_port                             5453\
                 -start_delay                                      6\
                 -timeout                                          60\
                 -ttl                                              254\ ]
set sessionhandle1 [keylget device_ret5 handle]
set status [keylget device_ret5 status]
if {$status == 0} {
    puts "\n<error>run sth::emulation_twamp_session_config failed"
    puts $device_ret5
} else {
    puts "\n*****run sth::emulation_twamp_session_config successfully"
}

#config part is finished
stc::perform saveasxml -filename "hltapi_twamp_script.xml"

####Start twamp server and client#######

#start server
set server_start [sth::emulation_twamp_control\
        -handle     $devicehandle2\
        -mode       start\ ]
set status [keylget server_start status]
if {$status == 0} {
    puts "<error>run sth::emulation_twamp_control failed"
    puts $server_start
} else {
    puts "\n*****run sth::emulation_twamp_control successfully"
}

#start client
set client_start [sth::emulation_twamp_control\
        -handle     $devicehandle1\
        -mode       start\ ]
set status [keylget client_start status]
if {$status == 0} {
    puts "<error>run sth::emulation_twamp_control failed"
    puts $client_start
} else {
    puts "\n*****run sth::emulation_twamp_control successfully"
}
        
###############Stats part############################
#server results
set result_server_state [sth::emulation_twamp_stats\
        -handle     $devicehandle2\
        -mode       server\ ]
set state [keylget result_server_state $devicehandle2.state]
while { $state != "STARTED" } {
    set result_server_state [sth::emulation_twamp_stats\
        -handle     $devicehandle2\
        -mode       server\ ]
    set state [keylget result_server_state $devicehandle2.state]
}
    
set result_server [sth::emulation_twamp_stats\
        -handle     $devicehandle2\
        -mode       server\ ]

set status [keylget result_server status]
if {$status == 0} {
    puts "<error>run sth::emulation_twamp_stats server failed"
    puts $result_server
} else {
    puts "server result: $result_server"
    puts "\n*****run sth::emulation_twamp_stats successfully"
}

#client results
set result_client_state [sth::emulation_twamp_stats\
        -handle     $devicehandle1\
        -mode       client\ ]
set state [keylget result_client_state $devicehandle1.state]
while { $state != "SESSIONS_REQUESTED" } {
    set result_client_state [sth::emulation_twamp_stats\
        -handle     $devicehandle1\
        -mode       client\ ]
    set state [keylget result_client_state $devicehandle1.state]
}
    
set result_client [sth::emulation_twamp_stats\
        -handle     $devicehandle1\
        -mode       client\ ]

set status [keylget result_client status]
if {$status == 0} {
    puts "<error>run sth::emulation_twamp_stats client failed"
    puts $result_client
} else {
    puts "client result: $result_client"
    puts "\n*****run sth::emulation_twamp_stats successfully"
}

#test_session
set result_session [sth::emulation_twamp_stats\
        -handle     $devicehandle1\
        -mode       test_session\ ]

set status [keylget result_session status]
if {$status == 0} {
    puts "<error>run sth::emulation_twamp_stats test_session failed"
    puts $result_session
} else {
    puts "test_session result: $result_session"
    puts "\n*****run sth::emulation_twamp_stats successfully"
}

#port_test_session results
set result_sessionport [sth::emulation_twamp_stats\
        -port_handle     $port1\
        -mode       port_test_session\ ]

set status [keylget result_sessionport status]
if {$status == 0} {
    puts "<error>run sth::emulation_twamp_stats result_sessionport failed"
    puts $result_sessionport
} else {
    puts "test_session result: $result_sessionport"
    puts "\n*****run sth::emulation_twamp_stats successfully"
}

#aggregated_client results
set result_aggregated_client [sth::emulation_twamp_stats\
        -port_handle     $port1\
        -mode       aggregated_client\ ]

set status [keylget result_aggregated_client status]
if {$status == 0} {
    puts "<error>run sth::emulation_twamp_stats result_aggregated_client failed"
    puts $result_aggregated_client
} else {
    puts "result_aggregated_client result: $result_aggregated_client"
    puts "\n*****run sth::emulation_twamp_stats successfully"
}

#aggregated_server results
set result_aggregated_server [sth::emulation_twamp_stats\
        -port_handle     $port2\
        -mode       aggregated_server\ ]

set status [keylget result_aggregated_server status]
if {$status == 0} {
    puts "<error>run sth::emulation_twamp_stats result_aggregated_server failed"
    puts $result_aggregated_server
} else {
    puts "result_aggregated_server result: $result_aggregated_server"
    puts "\n*****run sth::emulation_twamp_stats successfully"
}

#state_summary results
set result_state_summary [sth::emulation_twamp_stats\
        -port_handle     $port1\
        -mode       state_summary\ ]

set status [keylget result_state_summary status]
if {$status == 0} {
    puts "<error>run sth::emulation_twamp_stats result_state_summary failed"
    puts $result_state_summary
} else {
    puts "result_state_summary result: $result_state_summary"
    puts "\n*****run sth::emulation_twamp_stats successfully"
}

####Stop twamp server and client#######
#stop server
set server_stop [sth::emulation_twamp_control\
        -handle     $devicehandle2\
        -mode       stop\ ]
set status [keylget server_stop status]
if {$status == 0} {
    puts "<error>run sth::emulation_twamp_control failed"
    puts $server_stop
} else {
    puts "\n*****run sth::emulation_twamp_control successfully"
}

#start client
set client_stop [sth::emulation_twamp_control\
        -handle     $devicehandle1\
        -mode       stop\ ]
        
set status [keylget client_stop status]
if {$status == 0} {
    puts "<error>run sth::emulation_twamp_control failed"
    puts $client_stop
} else {
    puts "\n*****run sth::emulation_twamp_control successfully"
}
##############################################################
#clean up the session, release the ports reserved and cleanup the dbfile
##############################################################

set cleanup_sta [sth::cleanup_session\
        -port_handle                                      $port1 $port2 \
        -clean_dbfile                                     1]

set status [keylget cleanup_sta status]
if {$status == 0} {
    puts "<error>run sth::cleanup_session failed"
    puts $cleanup_sta
} else {
    puts "\n*****run sth::cleanup_session successfully"
}

puts "**************Finish***************"

