package require SpirentHltApi

##############################################################
#config the parameters for the logging
##############################################################

set test_sta [sth::test_config\
		-log                                              1\
		-logfile                                          HLTAPI_PCEP_TEST_logfile\
		-vendorlogfile                                    HLTAPI_PCEP_TEST_stcExport\
		-vendorlog                                        1\
		-hltlog                                           1\
		-hltlogfile                                       HLTAPI_PCEP_TEST_hltExport\
		-hlt2stcmappingfile                               HLTAPI_PCEP_TEST_hlt2StcMapping\
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
#Step1: Reserve and connect chassis ports
########################################

set returnedString [sth::connect -device $device_list -port_list $port_list -offline 1]

keylget returnedString status status
if {!$status} {
	puts $returnedString
    puts "  FAILED:  $status"
	return
} 

keylget returnedString port_handle.$device2.$port2 port2
keylget returnedString port_handle.$device1.$port1 port1

set portList "$port1 $port2"

puts "\n Step1: Configure two Raw devices on two back to back ports \n "
set device_ret1 [::sth::emulation_device_config\
                -port_handle $port1\
                -mode create\
                -count 1\
                -router_id 192.0.0.1\
                -ip_version ipv4\
                -intf_ip_addr 11.11.11.11\
                -intf_ip_addr_step 0.0.0.1\
                -gateway_ip_addr 11.11.11.12\
                -gateway_ip_addr_step 0.0.0.1\
                -intf_prefix_len 24\
                -mac_addr 00:01:02:03:04:05\
                -mac_addr_step 00:00:00:00:00:01\
]
puts "\n Raw device1 : $device_ret1 \n "
set device_ret2 [::sth::emulation_device_config\
                -port_handle $port2\
                -mode create\
                -count 1\
                -router_id 193.0.0.1\
                -ip_version ipv4\
                -intf_ip_addr 11.11.11.12\
                -intf_ip_addr_step 0.0.0.1\
                -gateway_ip_addr 11.11.11.11\
                -gateway_ip_addr_step 0.0.0.1\
                -intf_prefix_len 24\
                -mac_addr 00:01:02:03:04:06\
                -mac_addr_step 00:00:00:00:00:01\
]
puts "\n Raw Device2 : $device_ret2 \n"

set dev_handle1 [keylget device_ret1 handle]
set dev_handle2 [keylget device_ret2 handle]

puts "\n Step2: Enable the PCE on RAW Device 1 \n "
set device_ret_pcep1 [::sth::emulation_pcep_config \
			-mode 								create \
			-handle 							$dev_handle1 \
			-pcep_device_role  					PCE \
			-ip_version            				IPV4 \
			-peer_ipv4_addr        				null \
			-peer_ipv4_addr_step   				0.0.0.1 \
			-pcep_session_ip_address 			INTERFACE_IP \
			-is_session_initiator     			true \
			-is_fixed_src_port       			false \
			-keep_alive_timer      				40 \
			-dead_timer          				150 \
			-enable_pc_results     				false \
			-authentication          			MD5 \
			-password                			Spirent \
			-enable_init_lsp          			true \
			-enable_segment_routing    			true \
			-session_out_standing      			500 \
			-session_retry_count     			50 \
			-session_retry_interval 			50 \
			-lsp_per_message					500 \
			-tcp_interval               		600 \
			-packet_align_to_mtu        		true \
			]
			
keylget device_ret_pcep1 pcep_handle pcep_hnd1

puts "\n PCE enable : $device_ret_pcep1 \n"

puts "\n Step3: Add the LSP with all supported objects on PCE enabled device \n "
			
set pce_lsp1 [::sth::emulation_pcep_config \
						-mode 								create \
						-handle 							$pcep_hnd1 \
						-pce_lspcount               		1  \
						-pce_symbolic_name          		PLSP_report_@b  \
						-pce_characteristic         		ENABLE_UPDATE  \
						-enable_update              		true  \
						-pce_src_ipv4_addr          		1.1.1.1  \
						-pce_src_ipv4_addr_step     		0.0.0.1  \
						-pce_dst_ipv4_addr          		2.2.2.2  \
						-pce_dst_ipv4_addr_step     		0.0.0.1  \
						-enable_no_path             		false  \
						-srp_auto_gen_id    				false \
						-srp_id             				10 \
						-srp_id_step        				2 \
						-ipv4_update_ero_pflag 				"false false"\
						-ipv4_update_ero_iflag 				"false true"\
						-ipv4_explicit_start_ip_list 		"192.85.0.1 192.85.1.1 192.85.2.1"\
						-ipv4_explicit_prefix_length 		"16 24 32" \
						-sr_ero_pflag                		true \
						-sr_ero_iflag                 	    true \
						-sr_route_type                 		PCEP_ERO_ROUTE_TYPE_STRICT \
						-explicit_sid_type                  IPV4_ADJACENCY \
						-explicit_mflag                 	true \
						-explicit_cflag                 	true \
						-explicit_sflag                 	true \
						-explicit_fflag                 	true \
						-explicit_sid_label                 16 \
						-explicit_sid_tc                    0 \
						-explicit_sid_sflag                 true \
						-explicit_sid_ttl                   255 \
						-explicit_ipv4_address              1.1.1.1 \
						-explicit_local_ipv4_address        1.1.1.1 \
						-explicit_remote_ipv4_address       2.2.2.2 \
						-explicit_local_node_id             1.1.1.0 \
						-explicit_local_interface_id        0 \
						-explicit_remote_node_id            1.1.1.0 \
						-explicit_remote_interface_id       0 \
						-bw_update_pflag               		true \
						-bw_update_iflag                	false \
						-bw_update_bandwidth                0 \
						-metric_cflag			            true \
						-metric_bflag			            true  \
						-metric_type                        HOP_COUNTS \
						-metric_value                       10 \
						-metriclist_update_pflag            true  \
						-metriclist_update_iflag            true  \
						-lspa_update_pflag               	true \
						-lspa_update_iflag                  true \
						-lspa_update_exclude_any           	1 \
						-lspa_update_include_any            1 \
						-lspa_update_include_all            1 \
						-lspa_update_setup_prio             1 \
						-lspa_update_holding_prio           1 \
						-lspa_update_lflag                  true \
						-lspa_update_affinities_flag        true \
						]

puts "\n PCE LSP : $pce_lsp1 \n"
keylget pce_lsp1 pce_lsp_hnd lsp_handle_pce1
stc::perform SaveasXml -config system1 -filename    "./HLTAPI_pcep_test.xml"

keylget pce_lsp1 lspa_hnd lspa_handle
puts "\n Step4: Modify the LSP configurations using lsp handle \n "
set pce_lsp_modify [::sth::emulation_pcep_config \
			-mode 								create\
			-handle 							$lsp_handle_pce1 \
			-enable_update              		false  \
			-bw_update_pflag               		true \
			-bw_update_iflag                	false \
			-bw_update_bandwidth                0 \
			-metric_cflag			            false \
			-metric_bflag			            false  \
			-metric_type                        IGP_METRIC \
			-metric_value                       10 \
			-metriclist_update_pflag            false  \
			-metriclist_update_iflag            false  \
			-lspa_update_pflag               	false \
			-lspa_update_iflag                  false \
			-lspa_update_exclude_any           	0 \
			-lspa_update_include_any            0 \
			-lspa_update_include_all            0 \
			-lspa_update_setup_prio             0 \
			-lspa_update_holding_prio           0 \
			-lspa_update_lflag                  false \
			-lspa_update_affinities_flag        false \
			]
puts "\n PCE LSP Modify : $pce_lsp_modify \n"
#keylget pce_lsp_modify lspa_hnd lspa_handle

puts "\n Step5: Configure the Custom tlv  \n "

set customer_tlv [::sth::emulation_pcep_config \
						-tlv_type "0x102 0x2 0x5 0x9"\
						-tlv_value "0x55 0xff 0x4 0x44"]
						
puts "\n Custom tlv Config : $customer_tlv \n "
keylget customer_tlv customtlv_hnd customtlv_handle

puts "\n Step6: Enable the custom tlv on lspa object  \n "
set customtlv_lspa [::sth::emulation_pcep_config \
			-mode modify \
			-handle [lindex $lspa_handle 0] \
            -customtlv_handle [lindex $customtlv_handle 1]]
			
puts $customtlv_lspa	
		
puts "\n Step7: Enable the PCC on RAW Device 2 \n "
set device_ret_pcep2 [::sth::emulation_pcep_config \
			-mode 						create \
			-handle 					$dev_handle2 \
			-pcep_device_role  			PCC \
			-state                 		NONE \
			-pcep_mode             		ACTIVE \
			-ip_version            		IPV4 \
			-peer_ipv4_addr        		null \
			-peer_ipv4_addr_step   		0.0.0.1 \
			-peer_ipv6_addr        		null \
			-peer_ipv6_addr_step   		0000::1 \
			-pcep_session_ip_address 	INTERFACE_IP \
			-is_session_initiator     	true \
			-is_fixed_src_port       	false \
			-keep_alive_timer      		30 \
			-dead_timer          		130 \
			-enable_pc_results     		false \
			-authentication          	MD5 \
			-password                	Spirent \
			-sync_timer               	60 \
			-enable_init_lsp          	true \
			-enable_segment_routing    	true \
			-max_sid_depth             	1 \
			-session_out_standing      	400 \
			-session_retry_count     	20 \
			-session_retry_interval 	20 \
			-lsp_per_message			200 \
			-tcp_interval               300 \
			-packet_align_to_mtu        true \				
			]
puts "\n PCC enable : $device_ret_pcep2 \n"
keylget device_ret_pcep2 pcep_handle pcep_hnd2

puts "\n Step8: Add the LSP with all supported objects on PCC enabled device \n "
set device_ret_pcep2 [::sth::emulation_pcep_config \
			-mode 								create \
			-handle 							$pcep_hnd2 \
			-pcc_lspcount          				1 \
			-pcc_symbolic_name     				PLSP_report_@b \
			-pcc_characteristic    				ENABLE_SYNCHRONIZATION \
			-enable_delegate       				true \
			-pcc_src_ipv4_addr     				1.1.1.1 \
			-pcc_src_ipv4_addr_step  			0.0.0.1 \
			-pcc_dst_ipv4_addr       			2.2.2.2 \
			-pcc_dst_ipv4_addr_step  			0.0.0.1 \
			-lsp_auto_gen_id    				true \
			-plsp_id             				1 \
			-plsp_id_step       				1 \
			-aflag               				true \
			-init_lsp_state      				UP \
			-ipv4_tunnel_addr    				1.1.1.1 \
			-ipv4_tunnel_addr_step  			0.0.0.1 \
			-ipv4_explicit_start_ip_list		192.0.1.0 \
			-ipv4_explicit_prefix_length 		24 \
			-ipv4_ero_pflag       				true  \
			-ipv4_ero_iflag       				true  \
			-ipv4_explicit_route_type       	PCEP_ERO_ROUTE_TYPE_LOOSE \
			-lsp_id                 			1 \
			-lsp_id_step             			1 \
			-tunnel_id               			1 \
			-tunnel_id_step           			1 \
			-ipv4_ex_tunnel_id        			10.0.0.1 \
			-ipv4_ex_tunnel_id_step     		0.0.0.1 \
			-ipv4_tunnel_end_addr       		2.2.2.2 \
			-ipv4_tunnel_end_addr_step  		0.0.0.1 \
			-rro_flags                 			PCEP_RRO_FLAG_LOCAL_PROTECTION_IN_USE  \
			-ipv4_rro_pflag                		true  \
			-ipv4_rro_iflag                 	true  \
			-ipv4_reported_start_ip_list		192.0.1.0  \
			-ipv4_reported_prefix_length 		24  \
			-sr_rro_pflag                		true  \
			-sr_rro_iflag                 		true  \
			-reported_sid_type                 	IPV4_ADJACENCY  \
			-reported_sflag                 	true  \
			-reported_fflag                 	true  \
			-reported_sid_label                 16  \
			-reported_sid_tc                  	0  \
			-reported_sid_s_flag                true  \
			-reported_sid_ttl                 	255  \
			-reported_ipv4_address             	1.1.1.1 \
			-reported_local_ipv4_address        1.1.1.1  \
			-reported_remote_ipv4_address       2.2.2.2  \
			-reported_local_node_id             1.1.1.0  \
			-reported_local_interface_id        0  \
			-reported_remote_node_id            1.1.1.0  \
			-reported_remote_interface_id       0  \
			-bw_pflag               			true \
			-bw_iflag               			true \
    		-bw_bandwidth                       0 \
			-metric_cflag                		true \
			-metric_bflag                		true \
			-metric_type                 		HOP_COUNTS \
			-metric_value                       10 \
			-metriclist_pflag                	true \
			-metriclist_iflag                	true \
			-lspa_pflag               			true \
			-lspa_iflag                         true \
			-lspa_exclude_any           		1 \
			-lspa_include_any                 	1 \
			-lspa_include_all                 	1 \
    		-lspa_setup_prio                	1 \
			-lspa_holding_prio                	1 \
			-lspa_lflag                         true \
			-lspa_affinities_flag               true \
			]
puts "\n PCC LSP : $pce_lsp1 \n"

keylget device_ret_pcep2 pcep_handle pcep_hnd2
keylget device_ret_pcep2 pcc_lsp_hnd lsp_handle_pcc1

puts "\n Step9: start the session on pcep devices \n "
set ret [::sth::emulation_pcep_control -handle "$pcep_hnd1 $pcep_hnd2" -action start_sessions]
puts $ret
sleep 10

puts "\n Step10: Get the PCEP device and lsp results by using drv_stats API \n "

set drv_stats [::sth::drv_stats    \
		-query_from 	  "$port1 $port2" \
		-drv_name         "drv2"\
		-where 			  "PcepProtocolConfig.BlockRole = 0" \
		-properties  "EmulatedDevice.PortName EmulatedDevice.Name PcepProtocolConfig.BlockState PcepProtocolConfig.BlockSessionCount PcepProtocolConfig.BlockSessionUpCount PcepProtocolConfig.BlockSessionIdleCount PcepProtocolConfig.BlockSessionPendingCount PcepProtocolConfig.BlockTxOpenCount PcepProtocolConfig.BlockRxOpenCount PcepProtocolConfig.BlockTxKeepAliveCount PcepProtocolConfig.BlockRxKeepAliveCount PcepProtocolConfig.BlockTxPCRptCount PcepProtocolConfig.BlockRxPCUpdCount PcepProtocolConfig.BlockTxPCReqCount PcepProtocolConfig.BlockRxPCRepCount PcepProtocolConfig.BlockTxNotifyCount PcepProtocolConfig.BlockRxNotifyCount PcepProtocolConfig.BlockTxErrorCount PcepProtocolConfig.BlockRxErrorCount PcepProtocolConfig.BlockTxCloseCount PcepProtocolConfig.BlockRxCloseCount PcepProtocolConfig.BlockRxPCInitCount PcepProtocolConfig.BlockFlapCount PcepProtocolConfig.BlockRole"\
]
puts "\n PCEP Results using properties: $drv_stats \n"

set drvxml_dir [pwd]
puts $drvxml_dir

puts "\n Step11: Get the PCEP device and lsp results by using XML(save drv view as xml from GUI and provide same xml here) \n "
set drv_stats1 [::sth::drv_stats    \
		-drv_xml "$drvxml_dir/pcclsp_results.xml" \
		 ]
puts "\n PCEP Results using drv xml : $drv_stats1 \n"

set drv_stats2 [::sth::drv_stats    \
		-drv_xml "$drvxml_dir/pcelsp_results.xml" \
		 ]
puts "\n PCEP Results using drv xml : $drv_stats2 \n"

puts "\n Step12: Release the ports \n "
set cleanup [::sth::cleanup_session -port_list "$port1 $port2"]
