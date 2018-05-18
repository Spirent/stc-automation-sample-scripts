#################################
#
# File Name:         HLTAPI_Pppol2tp_b2b.tcl
#
# Description:       This script demonstrates the use of Spirent HLTAPI to setup Pppol2tp LAC-LNS test.
#                    In this test, l2tp LNS and LAC are emulated in back-to-back mode.
#
# Test Step:         1. Reserve and connect chassis ports
#                    2. Config Pppoe over l2tp LAC on Port1
#                    3. Config Pppoe over l2tp LNS on Port2
#                    4. Start LAC-LNS Connect and Pppoe
#                    5. Retrive Statistics
#                    6. Release resources
#
# Dut Configuration:
#                            None
#
# Topology
#                   STC Port1                      STC Port2                       
#                [pppol2tp LNS]------------------[pppol2tp LAC]
#                                              
#                                         
#
#################################

# Run sample:
#            c:>tclsh HLTAPI_Pppol2tp_b2b.tcl 10.61.44.2 3/1 3/3
#            c:>tclsh HLTAPI_Pppol2tp_b2b.tcl "10.61.44.2 10.61.44.7" 3/1 3/3

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

########################################
#Step1. Reserve and connect chassis ports
########################################

set returnedString [sth::connect -device $device_list -port_list $port_list]

keylget returnedString status status
if {!$status} {
	puts $returnedString
    puts "  FAILED:  $returnedString"
	return
}

keylget returnedString port_handle.$device2.$port2 hltLACPort
keylget returnedString port_handle.$device1.$port1 hltLNSPort

::sth::test_config  -logfile hlapiGen_pppol2tp_logfile \
                    -log 1\
                    -vendorlogfile hlapiGen_pppol2tp_stcExport\
                    -vendorlog 1\
                    -hltlog 1\
                    -hltlogfile hlapiGen_pppol2tp_hltExport\
                    -hlt2stcmappingfile hlapiGen_pppol2tp_hlt2StcMapping \
                    -hlt2stcmapping 1\
                    -log_level 7

					
					
##############################################################
#Step2. Config Pppoe over l2tp LAC on Port1
##############################################################


set device_ret0 [sth::l2tp_config\
		-l2_encap                                         ethernet_ii\
		-l2tp_src_count                                   1\
		-l2tp_src_addr                                    192.85.1.3\
		-l2tp_src_step                                    0.0.0.1\
		-l2tp_dst_addr                                    192.85.1.4\
		-l2tp_dst_step                                    0.0.0.0\
		-port_handle                                      $hltLACPort\
		-max_outstanding                                  100 \
		-disconnect_rate                                  1000 \
		-mode                                             lac \
		-attempt_rate                                     100 \
		-ppp_auto_retry                                   FALSE \
		-max_terminate_req                                10 \
		-auth_req_timeout                                 3 \
		-username                                         spirent \
		-ppp_retry_count                                  65535 \
		-max_ipcp_req                                     10 \
		-echo_req_interval                                10 \
		-password                                         spirent \
		-config_req_timeout                               3 \
		-terminate_req_timeout                            3 \
		-max_echo_acks                                    0 \
		-auth_mode                                        none \
		-echo_req                                         FALSE \
		-enable_magic                                     TRUE \
		-l2tp_mac_addr                                    00:10:94:00:00:01 \
		-l2tp_mac_step                                    00:00:00:00:00:01 \
		-hello_interval                                   60 \
		-hello_req                                        FALSE \
		-force_lcp_renegotiation                          FALSE \
		-tunnel_id_start                                  1 \
		-num_tunnels                                      1 \
		-tun_auth                                         TRUE \
		-session_id_start                                 1 \
		-redial                                           FALSE \
		-avp_framing_type                                 sync \
		-redial_max                                       1 \
		-redial_timeout                                   1 \
		-sessions_per_tunnel                              1 \
		-avp_tx_connect_speed                             56000 \
		-udp_src_port                                     1701 \
		-lcp_proxy_mode                                   none \
		-secret                                           spirent \
		-hostname                                         server.spirent.com \
		-rws                                              4 \
]

set status [keylget device_ret0 status]
if {$status == 0} {
	puts "run sth::l2tp_config failed"
	puts $device_ret0
	return
} else {
	puts "***** run sth::l2tp_config successfully"
}


##############################################################
#Step3. Config Pppoe over l2tp LNS on Port1
##############################################################

set device_ret1 [sth::l2tp_config\
		-l2_encap                                         ethernet_ii\
		-l2tp_dst_count                                   1\
		-l2tp_src_addr                                    192.85.1.3\
		-l2tp_src_step                                    0.0.0.0\
		-l2tp_dst_addr                                    192.85.1.4\
		-l2tp_dst_step                                    0.0.0.1\
		-ppp_server_ip                                    192.85.1.4\
		-ppp_server_step                                  0.0.0.1\
		-ppp_client_ip                                    192.0.1.0\
		-ppp_client_step                                  0.0.0.1\
		-port_handle                                      $hltLNSPort\
		-max_outstanding                                  100 \
		-disconnect_rate                                  1000 \
		-mode                                             lns \
		-attempt_rate                                     100 \
		-max_terminate_req                                10 \
		-username                                         spirent \
		-max_ipcp_req                                     10 \
		-echo_req_interval                                10 \
		-password                                         spirent \
		-config_req_timeout                               3 \
		-terminate_req_timeout                            3 \
		-max_echo_acks                                    0 \
		-auth_mode                                        none \
		-echo_req                                         FALSE \
		-enable_magic                                     TRUE \
		-l2tp_mac_addr                                    00:10:94:00:00:02 \
		-l2tp_mac_step                                    00:00:00:00:00:01 \
		-hello_interval                                   60 \
		-hello_req                                        FALSE \
		-force_lcp_renegotiation                          FALSE \
		-tunnel_id_start                                  1 \
		-num_tunnels                                      1 \
		-tun_auth                                         TRUE \
		-session_id_start                                 1 \
		-redial                                           FALSE \
		-avp_framing_type                                 sync \
		-redial_max                                       1 \
		-redial_timeout                                   1 \
		-sessions_per_tunnel                              1 \
		-avp_tx_connect_speed                             56000 \
		-udp_src_port                                     1701 \
		-lcp_proxy_mode                                   none \
		-secret                                           spirent \
		-hostname                                         server.spirent.com \
		-rws                                              4 \
]

set status [keylget device_ret1 status]
if {$status == 0} {
	puts "run sth::l2tp_config failed"
	puts $device_ret1
	return
} else {
	puts "***** run sth::l2tp_config successfully"
}

#config parts are finished

##############################################################
#Step4. Start LAC-LNS Connect and Pppoe
##############################################################

set device1 [keylget device_ret1 handle]
set ctrl_ret1 [sth::l2tp_control    \
		-handle                                           $device1\
		-action                                           connect\
]

set status [keylget ctrl_ret1 status]
if {$status == 0} {
	puts "run sth::l2tp_control failed"
	puts $ctrl_ret1
	return
} else {
	puts "***** run sth::l2tp_control successfully"
}

set device2 [keylget device_ret0 handle]
set ctrl_ret2 [sth::l2tp_control    \
		-handle                                           $device2\
		-action                                           connect\
]

set status [keylget ctrl_ret2 status]
if {$status == 0} {
	puts "run sth::l2tp_control failed"
	puts $ctrl_ret2
	return
} else {
	puts "***** run sth::l2tp_control successfully"
}


##############################################################
#Step5. Retrive Statistics
##############################################################

set results_ret1 [sth::l2tp_stats    \
		-handle                                           $device1\
		-mode                                             aggregate\
]

set status [keylget results_ret1 status]
if {$status == 0} {
	puts "run sth::l2tp_stats failed"
	puts $results_ret1
	return
} else {
	for {set i 0} {$i < 10} {incr i} {
		after 1000
		set results_ret1 [sth::l2tp_stats -handle $device1 -mode aggregate]
		if {[keylget results_ret1 aggregate.sessions_up]  == 1 && [keylget results_ret1 aggregate.connected]  == 1} {
		    puts "***** run sth::l2tp_stats successfully, and results is:"
			puts "$results_ret1\n"
			break
		}
	}
	if {$i == 10} {
		puts "run sth::l2tp_stats failed"
		puts $results_ret1
		return
	}
}

set results_ret2 [sth::l2tp_stats    \
		-handle                                           $device2\
		-mode                                             aggregate\
]

set status [keylget results_ret2 status]
if {$status == 0} {
	puts "run sth::l2tp_stats failed"
	puts $results_ret2
	return
} else {
	for {set i 0} {$i < 10} {incr i} {
		after 1000
		set results_ret2 [sth::l2tp_stats -handle $device2 -mode aggregate]
		if {[keylget results_ret2 aggregate.sessions_up]  == 1 && [keylget results_ret1 aggregate.connected]  == 1} {
		    puts "***** run sth::l2tp_stats successfully, and results is:"
			puts "$results_ret2\n"
			break
		}
	}
	if {$i == 10} {
		puts "run sth::l2tp_stats failed"
		puts $results_ret2
		return
	}
}

##############################################################
#Step6. Release resources
##############################################################

set cleanup_sta [sth::cleanup_session\
		-port_handle                                      $hltLACPort $hltLNSPort \
		-clean_dbfile                                     1]

set status [keylget cleanup_sta status]
if {$status == 0} {
	puts "run sth::cleanup_session failed"
	puts $cleanup_sta
	return
} else {
	puts "***** run sth::cleanup_session successfully"
}

puts "_SAMPLE_SCRIPT_SUCCESS"

