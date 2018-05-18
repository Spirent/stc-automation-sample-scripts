package require SpirentHltApi

##############################################################
#config the parameters for the logging
##############################################################

set test_sta [sth::test_config\
        -log                                              1\
        -logfile                                          lacp_logfile\
        -vendorlogfile                                    lacp_stcExport\
        -vendorlog                                        1\
        -hltlog                                           1\
        -hltlogfile                                       lacp_hltExport\
        -hlt2stcmappingfile                               lacp_hlt2StcMapping\
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
#connect to chassis and reserve port list
##############################################################

set i 0
set device 10.62.224.211
set port_list "1/1 1/2"
set intStatus [sth::connect -device $device -port_list $port_list]

set chassConnect [keylget intStatus status]
if {$chassConnect} {
    puts "\n reserved ports : $intStatus"
    foreach port $port_list {
        incr i
        set port$i [keylget intStatus port_handle.$device.$port]
    }
} else {
    set passFail FAIL
    puts "\nFailed to retrieve port handle! Error message: $intStatus"
}

set device 10.62.224.212
set port_list "1/1 1/2"
set intStatus [sth::connect -device $device -port_list $port_list]

set chassConnect [keylget intStatus status]
if {$chassConnect} {
    puts "\n reserved ports : $intStatus"
    foreach port $port_list {
        incr i
        set port$i [keylget intStatus port_handle.$device.$port]
    }
} else {
    set passFail FAIL
    puts "\nFailed to retrieve port handle! Error message: $intStatus"
}


##############################################################
#create lag port
##############################################################
set cmdReturn1 [sth::emulation_lag_config\
        -port_handle "$port1 $port2" \
        -mode create \
        -protocol "lacp"\
        -lacp_port_mac_addr "00:94:01:00:00:02" \
        -lacp_actor_key 100 \
        -lacp_actor_port_priority 101 \
        -lacp_actor_port_number 10 \
        -lacp_timeout short \
        -lacp_activity active \
        -actor_system_priority 1000 \
        -actor_system_id "00:00:00:00:01:01" \
        -lag_name "LAG1" \
        -transmit_algorithm "hashing" \
        -l2_hash_option "ETH_SRC|ETH_DST|VLAN|MPLS"\
        -l3_hash_option "VLAN|MPLS|IPV4_SRC|IPV4_DST|IPV6_SRC|IPV6_DST|UDP|TCP"\
]

set status [keylget cmdReturn1 status]
if {$status == 0} {
    puts "run sth::emulation_lacp_lag_config failed"
    puts $cmdReturn1
} else {
    puts "***** run sth::emulation_lacp_lag_config($port1 $port2 ==> [keylget cmdReturn1 lag_handle]) successfully"
}
set lag1_handle [keylget cmdReturn1 lag_handle]


set cmdReturn2 [sth::emulation_lag_config\
        -port_handle "$port3 $port4" \
        -mode create \
        -protocol "lacp"\
        -lacp_port_mac_addr "00:94:01:00:00:07" \
        -lacp_actor_key 100 \
        -lacp_actor_port_priority 101 \
        -lacp_actor_port_number 10 \
        -lacp_timeout short \
        -lacp_activity active \
        -actor_system_priority 1000 \
        -actor_system_id "00:00:00:00:01:02" \
        -lag_name "LAG2" \
        -transmit_algorithm "hashing" \
        -l2_hash_option "ETH_SRC|ETH_DST|VLAN|MPLS"\
        -l3_hash_option "VLAN|MPLS|IPV4_SRC|IPV4_DST|IPV6_SRC|IPV6_DST|UDP|TCP"\
]

set status [keylget cmdReturn2 status]
if {$status == 0} {
    puts "run sth::emulation_lacp_lag_config failed"
    puts $cmdReturn2
} else {
    puts "***** run sth::emulation_lacp_lag_config($port3 $port4 ==> [keylget cmdReturn2 lag_handle]) successfully"
}
set lag2_handle [keylget cmdReturn2 lag_handle]

##############################################################
#chage LAG1 into rate_based
##############################################################
set intf_ret1 [::sth::interface_config    \
        -mode                                             config\
        -port_handle                                      $lag1_handle\
        -create_host                                      false\
        -scheduling_mode                                  RATE_BASED\
]

set status [keylget intf_ret1 status]
if {$status == 0} {
    puts "run sth::intf_ret1 failed"
    puts $intf_ret1
} else {
    puts "***** run sth::interface_config successfully"
}

##############################################################
#create traffic
##############################################################

set streamblock_ret1 [::sth::traffic_config    \
        -mode                                             create\
        -port_handle                                      $lag1_handle\
        -l2_encap                                         ethernet_ii\
        -l3_protocol                                      ipv4\
        -ip_id                                            0\
        -ip_src_addr                                      192.85.1.2\
        -ip_dst_addr                                      192.0.0.1\
        -ip_ttl                                           255\
        -ip_hdr_length                                    5\
        -ip_protocol                                      253\
        -ip_fragment_offset                               0\
        -ip_mbz                                           0\
        -ip_precedence                                    0\
        -ip_tos_field                                     0\
        -ip_src_count                                     10\
        -ip_src_step                                      0.0.0.1\
        -ip_src_mode                                      increment\
        -mac_src                                          00:10:94:00:00:0A\
        -mac_dst                                          00:10:94:00:00:0B\
        -enable_control_plane                             0\
        -l3_length                                        110\
        -name                                             Lag_Traffic\
        -fill_type                                        constant\
        -fcs_error                                        0\
        -fill_value                                       0\
        -frame_size                                       128\
        -traffic_state                                    1\
        -high_speed_result_analysis                       1\
        -length_mode                                      fixed\
        -tx_port_sending_traffic_to_self_en               false\
        -disable_signature                                0\
        -enable_stream_only_gen                           1\
        -pkts_per_burst                                   1\
        -inter_stream_gap_unit                            bytes\
        -burst_loop_count                                 30\
        -transmit_mode                                    continuous\
        -inter_stream_gap                                 12\
        -rate_pps                                         1000\
        -mac_discovery_gw                                 192.85.1.1 \
        -enable_stream                                    true\
]

set status [keylget streamblock_ret1 status]
if {$status == 0} {
    puts "run sth::traffic_config failed"
    puts $streamblock_ret1
} else {
    puts "***** run sth::traffic_config successfully"
}

#config part is finished
stc::perform saveasxml -filename LACP_Test.xml
##############################################################
#start lacp port
##############################################################
foreach port "$port1 $port2 $port3 $port4" {
	set cmdStatus [sth::emulation_lacp_control\
            -port_handle $port \
			-action start]
    if {[keylget cmdStatus status] == 0} {
        puts "Error Start lacp on $port"     
        puts "Error info from LACP start command was $cmdReturn"
    } else {
        puts "PASS: Start lacp on $port"            
    }                            
}

after 30000
##############################################################
#get lacp result
##############################################################
foreach port "$port1 $port2 $port3 $port4" {
	set cmdStatus [sth::emulation_lacp_info\
            -port_handle $port \
            -action collect \
	    -mode state]
	if {[keylget cmdStatus status] == 0} {
		puts "Error emulation_lacp_info on $port"     
		puts "Error info from emulation_lacp_info command was $cmdReturn"
	} else {
		puts "PASS: info the status of lacp on $port"            
	} 
	
    #Check the status of LACP on ports
	set sessionState [keylget cmdStatus lacp_state]
	if { $sessionState == "UP"} {
		puts "PASS: The status of LACP on $port is UP"
	} else {
		puts "Fail. Lacp session on $port hasn't come up."
	}
}
	
##############################################################
#start traffic
##############################################################
sth::traffic_control -port_handle all -action clear_stats
set traffic_ctrl_ret [::sth::traffic_control    \
        -port_handle                                      "$lag1_handle $lag2_handle "\
        -action                                           run\
        -duration                                         10\
]

set status [keylget traffic_ctrl_ret status]
if {$status == 0} {
    puts "run sth::traffic_control failed"
    puts $traffic_ctrl_ret
} else {
    puts "***** run sth::traffic_control successfully"
}

after 15000


##############################################################
#start to get the traffic results
##############################################################

set traffic_results_ret [::sth::traffic_stats    \
        -port_handle                                      "$lag1_handle $lag2_handle "\
        -mode                                             aggregate\
]

set status [keylget traffic_results_ret status]
if {$status == 0} {
    puts "run sth::traffic_stats failed"
    puts $traffic_results_ret
} else {
    puts "***** run sth::traffic_stats successfully, and results is:"
    puts "Tx: [keylget traffic_results_ret $lag1_handle.aggregate.tx.total_pkts]"
    puts "Rx: [keylget traffic_results_ret $lag2_handle.aggregate.rx.total_pkts]"
    if {[keylget traffic_results_ret $lag1_handle.aggregate.tx.total_pkts] > 10000} {
        puts "***** Lag1 Tx PASSED *****"
    }
    
    if {[keylget traffic_results_ret $lag2_handle.aggregate.rx.total_pkts] > 10000} {
        puts "***** Lag2 Rx PASSED *****"
    }
}

################################################################################
#modify the lacp port config , so we can get the traffic from the membership
################################################################################

set cmdReturn2 [sth::emulation_lag_config\
        -lag_handle $lag1_handle \
        -mode modify \
        -aggregatorresult member \
]
set traffic_ctrl_ret [::sth::traffic_control    \
        -port_handle                                      "$lag1_handle $lag2_handle "\
        -action                                           stop\
        -duration                                         10\
]
after 10000
set traffic_ctrl_ret [::sth::traffic_control    \
        -port_handle                                      "$lag1_handle $lag2_handle "\
        -action                                           run\
        -duration                                         10\
]
after 15000
set traffic_results_ret [::sth::traffic_stats    \
        -port_handle                                      "$port1 $port2 $port3 $port4 "\
        -mode                                             aggregate\
]

set status [keylget traffic_results_ret status]
if {$status == 0} {
    puts "run sth::traffic_stats failed"
    puts $traffic_results_ret
} else {
    puts "***** run sth::traffic_stats successfully, and results is:"
    puts "Tx1: [keylget traffic_results_ret $port1.aggregate.tx.total_pkts]"
    puts "Tx2: [keylget traffic_results_ret $port2.aggregate.tx.total_pkts]"
    puts "Rx1: [keylget traffic_results_ret $port3.aggregate.rx.total_pkts]"
    puts "Rx2: [keylget traffic_results_ret $port4.aggregate.rx.total_pkts]"
    if {[keylget traffic_results_ret $port1.aggregate.tx.total_pkts] > 5000} {
        puts "***** Lag1 Member1 Tx PASSED *****"
    }
    if {[keylget traffic_results_ret $port2.aggregate.tx.total_pkts] > 5000} {
        puts "***** Lag1 Member2 Tx PASSED *****"
    }
    if {[keylget traffic_results_ret $port3.aggregate.rx.total_pkts] > 5000} {
        puts "***** Lag2 Member1 Rx PASSED *****"
    }
    if {[keylget traffic_results_ret $port4.aggregate.rx.total_pkts] > 5000} {
        puts "***** Lag2 Member2 Rx PASSED *****"
    }
}

################################################################################
#modify the lacp port config , so we can get the traffic from the lag port
################################################################################
set cmdReturn2 [sth::emulation_lag_config\
        -lag_handle $lag1_handle \
        -mode modify \
        -aggregatorresult aggregated \
]

sth::traffic_control -port_handle all -action clear_stats
set traffic_ctrl_ret [::sth::traffic_control    \
        -port_handle                                      "$lag1_handle $lag2_handle "\
        -action                                           run\
]

set status [keylget traffic_ctrl_ret status]
if {$status == 0} {
    puts "run sth::traffic_control failed"
    puts $traffic_ctrl_ret
} else {
    puts "***** run sth::traffic_control successfully"
}

after 10000
set interface_control_ret [::sth::interface_control    \
        -port_handle                                      "$port1"\
        -mode                                             break_link\
]

set status [keylget interface_control_ret status]
if {$status == 0} {
    puts "run sth::interface_control failed"
    puts $interface_control_ret
} else {
    puts "***** run sth::interface_control successfully"
}
after 10000
set traffic_ctrl_ret [::sth::traffic_control    \
        -port_handle                                      "$lag1_handle $lag2_handle "\
        -action                                           stop\
]

set status [keylget traffic_ctrl_ret status]
if {$status == 0} {
    puts "run sth::traffic_control failed"
    puts $traffic_ctrl_ret
} else {
    puts "***** run sth::traffic_control successfully"
}
after 1000
set traffic_results_ret [::sth::traffic_stats    \
        -port_handle                                      "$lag1_handle"\
        -mode                                             streams\
]

set status [keylget traffic_results_ret status]
if {$status == 0} {
    puts "run sth::traffic_stats failed"
    puts $traffic_results_ret
} else {
    puts "***** run sth::traffic_stats successfully, and results is:"
    puts "Streamblock Tx: [keylget traffic_results_ret $lag1_handle.stream.streamblock1.tx.total_pkts]"
    puts "Streamblock Rx: [keylget traffic_results_ret $lag1_handle.stream.streamblock1.rx.total_pkts]"
    puts "Streamblock Dropped: [keylget traffic_results_ret $lag1_handle.stream.streamblock1.rx.dropped_pkts]"
    if {[keylget traffic_results_ret $lag1_handle.stream.streamblock1.rx.dropped_pkts] == 0} {
        puts "PASSED, No pkts lost during break off one member link"    
    }
}


##############################################################
#disable and enable the lacp protocol
##############################################################
set cmdReturn3 [sth::emulation_lag_config\
        -lag_handle $lag1_handle \
        -mode disable]

set cmdReturn4 [sth::emulation_lag_config\
        -lag_handle $lag1_handle \
        -mode enable]

##############################################################
#clean up the session, release the ports reserved and cleanup the dbfile
##############################################################
set cleanup_sta [sth::cleanup_session\
        -port_handle                                      $port1 $port2 $port3 $port4\
        -clean_dbfile                                     1]

set status [keylget cleanup_sta status]
if {$status == 0} {
    puts "run sth::cleanup_session failed"
    puts $cleanup_sta
} else {
    puts "***** run sth::cleanup_session successfully"
}

puts "**************Finish***************"

