#################################
#
# File Name:         pppoe_dhcpv6pd_traffic.robot
#
# Description:       This script demonstrates the use of Spirent HLTAPI to setup PPPoE server and client,DHCPv6-PD server and 
#                    client,and create/trigger traffic between PPPoE server and client.
#                    
#
# Test Step:         1. Reserve and connect chassis ports
#                    2. Interface config(optional)
#                    3. Create pppoe server 
#                    4. Create dhcpv6-pd server
#                    5. Create pppoe client 
#                    6. Create dhcpv6-pd client
#                    7. Create stream block
#                    8. Connect pppoe server and pppoe client
#                    9. Start dhcpv6 server and bind dhcpv6 client
#                    10. Start and stop traffic
#                    11. Get results
#                    12. Release resources
# DUT configuration:
#           none
#
# Topology
#                        [STC Port1]                                   [STC Port2]                     
#                 dhcpv6pd over pppoe device------------------dhcpv6pd over pppoe device
#                        
#################################
#
# Run sample:
#            c:\>robot pppoe_dhcpv6pd_traffic.robot


*** Settings ***
Documentation  Get libraries
Library           BuiltIn
Library           Collections
Library           sth.py

*** Variables ***

*** Keywords ***
Get Port Handle
    [Arguments]  ${dict}  ${chassis}  @{port_list}
    ${port} =  Set Variable  ${EMPTY}
    :FOR  ${port}  IN  @{port_list}
    \  ${Rstatus} =  Get From Dictionary  ${dict}  port_handle
    \  ${Rstatus} =  Get From Dictionary  ${Rstatus}  ${chassis}
    \  ${Rstatus} =  Get From Dictionary  ${Rstatus}  ${port}
    \  Set Test Variable    ${port${port_index}}    ${Rstatus}
    \  Log To Console  \nreserved ports: ${chassis} ${port} ${Rstatus}
    \  ${port_index}    Evaluate    ${port_index}+1
    \  Set Test Variable  ${port_index}  ${port_index}

*** Test Cases ***
pppoe dhcpv6pd traffic test
    [Documentation]  pppox server test

##############################################################
#config the parameters for the logging
##############################################################

    ${test_sta} =  test config  log=1   logfile=pppoe_dhcpv6pd_traffic_logfile   vendorlogfile=pppoe_dhcpv6pd_traffic_stcExport   vendorlog=1   hltlog=1   hltlogfile=pppoe_dhcpv6pd_traffic_hltExport   hlt2stcmappingfile=pppoe_dhcpv6pd_traffic_hlt2StcMapping   hlt2stcmapping=1   log_level=7

    ${status} =  Get From Dictionary  ${test_sta}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun test config failed\n${test_sta}
    ...  ELSE  Log To Console  \n***** run test config successfully

##############################################################
#config the parameters for optimization and parsing
##############################################################

    ${test_ctrl_sta} =  test control  action=enable

    ${status} =  Get From Dictionary  ${test_ctrl_sta}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun test control failed\n${test_ctrl_sta}
    ...  ELSE  Log To Console  \n***** run test control successfully

########################################
#Step1. Reserve and connect chassis ports
########################################

    Set Test Variable  ${port_index}  1
    ${device} =  Set Variable  10.61.47.130
    @{port_list} =  Create List  1/1  1/2
    ${intStatus} =  connect  device=${device}  port_list=${port_list}  break_locks=1  offline=0
    ${status} =  Get From Dictionary  ${intStatus}  status
    Run Keyword If  ${status} == 1  Get Port Handle  ${intStatus}  ${device}  @{port_list}
    ...  ELSE  log to console  \n<error> Failed to retrieve port handle! Error message: ${intStatus}
    
##############################################################
#get the device info
##############################################################

    ${device_info} =  device info  ports=1  port_handle=${port1} ${port2}   fspec_version=1

    ${status} =  Get From Dictionary  ${device_info}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun device info failed\n${device_info}
    ...  ELSE  Log To Console  \n***** run device info successfully

    
##############################################################
# Step2: Config interface
##############################################################

    ${int_ret0} =  interface config  mode=config   port_handle=${port1}   create_host=false   intf_mode=ethernet   phy_mode=copper   scheduling_mode=RATE_BASED   port_loadunit=PERCENT_LINE_RATE   port_load=10   ipv6_prefix_length=64   ipv6_resolve_gateway_mac=true   ipv6_gateway=1000::2   ipv6_gateway_step=::   ipv6_intf_addr=1000::1   ipv6_intf_addr_step=::1   enable_ping_response=0   control_plane_mtu=1500   pfc_negotiate_by_dcbx=0   speed=ether10000   duplex=full   autonegotiation=1   alternate_speeds=0

    ${status} =  Get From Dictionary  ${int_ret0}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun interface config failed\n${int_ret0}
    ...  ELSE  Log To Console  \n***** run interface config successfully

    ${int_ret1} =  interface config  mode=config   port_handle=${port2}   create_host=false   intf_mode=ethernet   phy_mode=copper   scheduling_mode=RATE_BASED   port_loadunit=PERCENT_LINE_RATE   port_load=10   ipv6_prefix_length=64   ipv6_resolve_gateway_mac=true   ipv6_gateway=1000::1   ipv6_gateway_step=::   ipv6_intf_addr=1000::2   ipv6_intf_addr_step=::1   enable_ping_response=0   control_plane_mtu=1500   pfc_negotiate_by_dcbx=0   speed=ether10000   duplex=full   autonegotiation=1   alternate_speeds=0

    ${status} =  Get From Dictionary  ${int_ret1}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun interface config failed\n${int_ret1}
    ...  ELSE  Log To Console  \n***** run interface config successfully

##############################################################
# Step3: create pppoe server 
##############################################################

    ${device_ret0} =  pppox server config  mode=create   encap=ethernet_ii   protocol=pppoe   ipv6_pool_prefix_step=2::   ipv6_pool_intf_id_start=::1   ipv6_pool_intf_id_step=::2   ipv6_pool_addr_count=50   ipv6_pool_prefix_len=64   ipv6_pool_prefix_start=1000::   port_handle=${port1}   max_outstanding=100   disconnect_rate=1000   attempt_rate=100   enable_osi=false   pap_req_timeout=3   mru_neg_enable=1   max_configure_req=10   term_req_timeout=3   max_terminate_req=10   username=spirent   force_server_connect_mode=false   echo_vendor_spec_tag_in_pado=false   echo_vendor_spec_tag_in_pads=false   max_payload_tag_enable=false   max_ipcp_req=10   echo_req_interval=10   config_req_timeout=3   local_magic=1   password=spirent   chap_reply_timeout=3   max_chap_req_attempt=10   enable_mpls=false   lcp_mru=1492   ip_cp=ipv6_cp   max_echo_acks=1   auth_mode=none   include_id=1   ipcp_req_timeout=3   server_inactivity_timer=30   unconnected_session_threshold=0   max_payload_bytes=1500   echo_req=false   fsm_max_naks=5   gateway_ipv6_step=::   intf_ipv6_addr=2000::2   intf_ipv6_addr_step=::2   intf_ipv6_prefix_length=64   gateway_ipv6_addr=2000::1   mac_addr=00:10:94:01:00:01   mac_addr_step=00:00:00:00:00:01   num_sessions=1

    ${status} =  Get From Dictionary  ${device_ret0}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun pppox server config failed\n${device_ret0}
    ...  ELSE  Log To Console  \n***** run pppox server config successfully

    ${deviceHdlServer} =  Get From Dictionary  ${device_ret0}  handle

########################################
# Step4: create dhcpv6-pd server
########################################  

    ${device_cfg_ret0} =  emulation dhcp server config  mode=enable   handle=${deviceHdlServer}   ip_version=6   encapsulation=ethernet_ii   prefix_pool_step=1   prefix_pool_per_server=100   prefix_pool_start_addr=2000::   prefix_pool_step_per_server=0:0:0:1::   prefix_pool_prefix_length=64   preferred_lifetime=604800   enable_delayed_auth=false   valid_lifetime=2592000   dhcp_realm=spirent.com   enable_reconfigure_key=false   reneval_time_percent=50   rebinding_time_percent=80   server_emulation_mode=DHCPV6_PD

    ${status} =  Get From Dictionary  ${device_cfg_ret0}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun emulation dhcp server config failed\n${device_cfg_ret0}
    ...  ELSE  Log To Console  \n***** run emulation dhcp server config successfully

########################################
# Step5: create pppoe client 
########################################

    ${device_ret1} =  pppox config  mode=create   encap=ethernet_ii   protocol=pppoe   ac_select_mode=service_name   circuit_id_suffix_mode=none   port_handle=${port2}   max_outstanding=100   disconnect_rate=1000   attempt_rate=100   pppoe_circuit_id=circuit   mru_neg_enable=1   max_configure_req=10   chap_ack_timeout=3   max_padi_req=10   padi_include_tag=1   padr_req_timeout=3   max_terminate_req=10   term_req_timeout=3   username=spirent   use_partial_block_state=false   max_auto_retry_count=65535   agent_type=2516   max_ipcp_req=10   intermediate_agent=false   echo_req_interval=10   password=spirent   local_magic=1   config_req_timeout=3   active=1   auto_retry=false   padi_req_timeout=3   agent_mac_addr=00:00:00:00:00:00   lcp_mru=1492   ip_cp=ipv6_cp   auto_fill_ipv6=1   max_echo_acks=0   auth_mode=chap   include_id=1   ipcp_req_timeout=3   max_padr_req=10   padr_include_tag=1   echo_req=false   fsm_max_naks=5   local_ipv6_addr=fe80::210:94ff:fe01:45   gateway_ipv6_step=::   intf_ipv6_addr=2000::2   intf_ipv6_addr_step=::1   gateway_ipv6_addr=::   mac_addr=00:10:94:01:00:45   mac_addr_repeat=0   mac_addr_step=00:00:00:00:00:01   num_sessions=1

    ${status} =  Get From Dictionary  ${device_ret1}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun pppox config failed\n${device_ret1}
    ...  ELSE  Log To Console  \n***** run pppox config successfully

    ${deviceHdlClient} =  Get From Dictionary  ${device_ret1}  handle

########################################
# Step6: create dhcpv6-pd client
######################################## 

    ${device_cfg_ret1port} =  emulation dhcp config  mode=create   ip_version=6   port_handle=${port2}   dhcp6_renew_rate=100   dhcp6_request_rate=100   dhcp6_rel_max_rc=5   dhcp6_dec_max_rc=5   dhcp6_indef_rel_rt=false   dhcp6_inforeq_max_rt=120   dhcp6_req_timeout=1   dhcp6_sol_max_rc=10   dhcp6_reb_timeout=10   dhcp6_ren_max_rt=600   dhcp6_cfm_max_rt=4   dhcp6_indef_sol_rt=false   dhcp6_sol_max_rt=120   dhcp6_inforeq_timeout=1   dhcp6_dec_timeout=1   dhcp6_reb_max_rt=600   dhcp6_cfm_timeout=1   dhcp6_release_rate=100   dhcp6_sol_timeout=1   dhcp6_rel_timeout=1   dhcp6_req_max_rc=10   dhcp6_indef_req_rt=false   dhcp6_sequence_type=SEQUENTIAL   dhcp6_req_max_rt=30   dhcp6_cfm_duration=10   dhcp6_outstanding_session_count=1   dhcp6_ren_timeout=10

    ${status} =  Get From Dictionary  ${device_cfg_ret1port}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun emulation dhcp config failed\n${device_cfg_ret1port}
    ...  ELSE  Log To Console  \n***** run emulation dhcp config successfully

    ${device_cfg_ret1} =  emulation dhcp group config  mode=enable   handle=${deviceHdlClient}   dhcp_range_ip_type=6   dhcp6_client_mode=DHCPPD   encap=ethernet_ii   enable_reconfig_accept=false   preferred_lifetime=604800   remote_id=remoteId_@p-@b-@s   use_relay_agent_mac_addr_for_dataplane=true   enable_relay_agent=false   relay_server_ipv6_addr_step=::   dhcp6_range_duid_type=LLT   prefix_length=0   duid_value=1   enable_rebind=false   dhcp6_range_duid_vendor_id_increment=1   prefix_start=::   control_plane_prefix=LINKLOCAL   enable_remote_id=false   valid_lifetime=2592000   client_mac_addr_mask=00:00:00:ff:ff:ff   dhcp6_range_duid_enterprise_id=3456   dhcp6_range_ia_t1=302400   dst_addr_type=ALL_DHCP_RELAY_AGENTS_AND_SERVERS   dhcp6_range_ia_t2=483840   client_mac_addr=00:10:01:00:00:01   enable_renew=true   enable_ldra=false   remote_id_enterprise=3456   client_mac_addr_step=00:00:00:00:00:01   rapid_commit_mode=DISABLE   dhcp6_range_duid_vendor_id=0001

    ${status} =  Get From Dictionary  ${device_cfg_ret1}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun emulation dhcp group config failed\n${device_cfg_ret1}
    ...  ELSE  Log To Console  \n***** run emulation dhcp group config successfully

##############################################
#step7: create stream block
#############################################  

    ${streamblock_ret1} =  traffic config  mode=create   port_handle=${port1}   port_handle2=${port2}  emulation_src_handle=${deviceHdlServer}   emulation_dst_handle=${deviceHdlClient}   l2_encap=ethernet_ii_pppoe   l3_protocol=ipv6   ipv6_traffic_class=0   ipv6_next_header=97   ipv6_length=0   ipv6_flow_label=7   ipv6_hop_limit=255   ppp_session_id=0   mac_src=00:10:94:01:00:01   mac_dst=00:00:01:00:00:01   enable_control_plane=0   l3_length=102   name=StreamBlock_2   fill_type=constant   fcs_error=0   fill_value=0   frame_size=128   traffic_state=1   high_speed_result_analysis=1   length_mode=fixed   tx_port_sending_traffic_to_self_en=false   disable_signature=0   enable_stream_only_gen=1   endpoint_map=one_to_one   pkts_per_burst=1   inter_stream_gap_unit=bytes   burst_loop_count=30   transmit_mode=continuous   inter_stream_gap=12   rate_percent=10   mac_discovery_gw=aaaa:1::1

    ${status} =  Get From Dictionary  ${streamblock_ret1}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun traffic config failed\n${streamblock_ret1}
    ...  ELSE  Log To Console  \n***** run traffic config successfully

    #config part is finished
    
##############################################################
# step8: connect pppoe server and pppoe client
##############################################################

    ${ctrl_ret1} =  pppox server control  port_handle=${port1}   action=connect

    ${status} =  Get From Dictionary  ${ctrl_ret1}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun pppox server control failed\n${ctrl_ret1}
    ...  ELSE  Log To Console  \n***** run pppox server control successfully

    ${ctrl_ret2} =  pppox control  handle=${deviceHdlClient}   action=connect

    ${status} =  Get From Dictionary  ${ctrl_ret2}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun pppox control failed\n${ctrl_ret2}
    ...  ELSE  Log To Console  \n***** run pppox control successfully

    Sleep  5s

#################################################
#step9: start dhcpv6 server and bind dhcpv6 client
#################################################

    ${ctrl_ret3} =  emulation dhcp server control  port_handle=${port1}   action=connect   ip_version=6

    ${status} =  Get From Dictionary  ${ctrl_ret3}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun emulation dhcp server control failed\n${ctrl_ret3}
    ...  ELSE  Log To Console  \n***** run emulation dhcp server control successfully

    ${ctrl_ret4} =  emulation dhcp control  port_handle=${port2}   action=bind   ip_version=6

    ${status} =  Get From Dictionary  ${ctrl_ret4}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun emulation dhcp control failed\n${ctrl_ret4}
    ...  ELSE  Log To Console  \n***** run emulation dhcp control successfully

########################################
#step10: start and stop traffic
########################################

    ${traffic_ctrl_ret} =  traffic control  port_handle=all   action=run

    ${status} =  Get From Dictionary  ${traffic_ctrl_ret}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun traffic control failed\n${traffic_ctrl_ret}
    ...  ELSE  Log To Console  \n***** run traffic control successfully

    ${traffic_ctrl_ret} =  traffic control  port_handle=all   action=stop

    ${status} =  Get From Dictionary  ${traffic_ctrl_ret}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun traffic control failed\n${traffic_ctrl_ret}
    ...  ELSE  Log To Console  \n***** run traffic control successfully

##############################################################
# step11: get results
##############################################################

    ${results_ret1} =  pppox server stats  port_handle=${port1}   mode=aggregate

    ${status} =  Get From Dictionary  ${results_ret1}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun pppox server stats failed\n${results_ret1}
    ...  ELSE  Log To Console  \n***** run pppox server stats successfully, and results is:\n${results_ret1}

    ${results_ret3} =  pppox stats  handle=${deviceHdlClient}   mode=aggregate

    ${status} =  Get From Dictionary  ${results_ret3}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun pppox stats failed\n${results_ret3}
    ...  ELSE  Log To Console  \n***** run pppox stats successfully, and results is:\n${results_ret3}
    

    ${results_ret5} =  emulation dhcp server stats  port_handle=${port1}   action=COLLECT   ip_version=6

    ${status} =  Get From Dictionary  ${results_ret5}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun emulation dhcp server stats failed\n${results_ret5}
    ...  ELSE  Log To Console  \n***** run emulation dhcp server stats successfully, and results is:\n${results_ret5}
    

    ${results_ret6} =  emulation dhcp stats  port_handle=${port2}   action=collect   mode=detailed_session   ip_version=6

    ${status} =  Get From Dictionary  ${results_ret6}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun emulation dhcp stats failed\n${results_ret6}
    ...  ELSE  Log To Console  \n***** run emulation dhcp stats successfully, and results is:\n${results_ret6}
    
    Sleep  2s

##############################################################
#start to get the traffic results
##############################################################

    ${traffic_results_ret} =  traffic stats  port_handle=${port1} ${port2}   mode=aggregate

    ${status} =  Get From Dictionary  ${traffic_results_ret}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun traffic stats failed\n${traffic_results_ret}
    ...  ELSE  Log To Console  \n***** run traffic stats successfully, and results is:\n${traffic_results_ret}
    
##############################################################
# step12: Release resources
##############################################################

    ${cleanup_sta} =  cleanup session  port_handle=${port1} ${port2}   clean_dbfile=1

    ${status} =  Get From Dictionary  ${cleanup_sta}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun cleanup session failed\n${cleanup_sta}
    ...  ELSE  Log To Console  \n***** run cleanup session successfully

    
    Log To Console  \n**************Finish***************

