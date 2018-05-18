#################################
#
# File Name:         isis_sr.robot
#
# Description:       This script demonstrates the use of Spirent HLTAPI to setup ISIS with Segment Routing.                  
#
# Test Step:
#                    1. Reserve and connect chassis ports                             
#                    2. Config ISIS on port1 & port2 with Segment routing enabled in the routes
#                    3. Config bound stream traffic between ISIS router on port2 to ISIS LSP's configured on port1
#                    4. Start ISIS 
#                    5. Start Traffic
#                    6. Get ISIS Info
#                    7. Get Traffic Stats
#                    8. Release resources
#
#
# Topology:
#
#              STC Port1                      STC Port2           
#             [ISIS Router1]------------------[ISIS Router2]
#                                          
#                           
###################################

# Run sample:
#            c:\>robot isis_sr.robot

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
isis sr test

##############################################################
#config the parameters for the logging
##############################################################
    

    ${test_sta} =  test config  log=1   logfile=isis_sr_logfile   vendorlogfile=isis_sr_stcExport   vendorlog=1   hltlog=1   hltlogfile=isis_sr_hltExport   hlt2stcmappingfile=isis_sr_hlt2StcMapping   hlt2stcmapping=1   log_level=7

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
# Step1. Reserve and connect chassis ports
########################################

    Set Test Variable  ${port_index}  1
    ${device} =  Set Variable  10.61.47.130
    @{port_list} =  Create List  1/1  1/2
    ${intStatus} =  connect  device=${device}  port_list=${port_list}  break_locks=1  offline=0
    ${status} =  Get From Dictionary  ${intStatus}  status
    Run Keyword If  ${status} == 1  Get Port Handle  ${intStatus}  ${device}  @{port_list}
    ...  ELSE  log to console  \n<error> Failed to retrieve port handle! Error message: ${intStatus}
    
###########################
#get the device info
###########################

    ${device_info} =  device info  ports=1  port_handle=${port1} ${port2}   fspec_version=1

    ${status} =  Get From Dictionary  ${device_info}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun device info failed\n${device_info}
    ...  ELSE  Log To Console  \n***** run device info successfully

##################################################################################
# Step2.Config ISIS on port1 & port2 with Segment routing enabled in the routes
##################################################################################

    #start to create the device: Router 1

    ${device_ret0} =  emulation isis config  mode=enable   authentication_mode=none   intf_metric=1   system_id=02000a010101   holding_time=30   port_handle=${port1}   ipv6_router_id=2000::1   router_id=192.0.0.1   mac_address_start=00-10-94-00-00-01   intf_ip_prefix_length=24   intf_ip_addr=10.1.1.1   gateway_ip_addr=10.1.1.2   hello_interval=10   ip_version=4   te_router_id=192.0.0.1   routing_level=L2   graceful_restart_restart_time=3   lsp_refresh_interval=900   psnp_interval=2   intf_type=broadcast   graceful_restart=0   wide_metrics=1   hello_padding=true   area_id=000001

    ${status} =  Get From Dictionary  ${device_ret0}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun emulation isis config failed\n${device_ret0}
    ...  ELSE  Log To Console  \n***** run emulation isis config successfully

    ${isis_hnd1} =  Get From Dictionary  ${device_ret0}  handle

#configure ISIS LSP with segment routing enabled

    ${lspStatus} =  emulation isis lsp generator  mode=create  handle=${isis_hnd1}  type=tree  loopback_adver_enable=true
    ...  tree_if_type=POINT_TO_POINT  ipv4_internal_emulated_routers=NONE  ipv4_internal_simulated_routers=ALL  ipv4_internal_count=0
    ...  tree_max_if_per_router=2  router_id_start=3.0.0.1  ipv4_addr_start=3.0.0.0  system_id_start=100000000001  isis_level=LEVEL2
    ...  segment_routing_enabled=true  sr_algorithms=0  sr_cap_range=100  sr_cap_value=100  sr_cap_value_type=label

    ${status} =  Get From Dictionary  ${lspStatus}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun sth.emulation_isis_lsp_generator failed\n${lspStatus}
    ...  ELSE  Log To Console  \n***** run sth.emulation_isis_lsp_generator successfully\n${lspStatus}

    ${lsp1} =  Get From Dictionary  ${lspStatus}  lsp_handle
    Log To Console  \nlsp_handle is ${lsp1}

#start to create the device: Router 2

     ${device_ret1} =  emulation isis config  mode=enable   authentication_mode=none   intf_metric=1   system_id=02000a010102   holding_time=30   port_handle=${port2}   ipv6_router_id=2000::2   router_id=192.0.0.2   mac_address_start=00-10-94-00-00-02   intf_ip_prefix_length=24   intf_ip_addr=10.1.1.2   gateway_ip_addr=10.1.1.1   hello_interval=10   ip_version=4   te_router_id=192.0.0.1   routing_level=L2   graceful_restart_restart_time=3   lsp_refresh_interval=900   psnp_interval=2   intf_type=broadcast   graceful_restart=0   wide_metrics=1   hello_padding=true   area_id=000001

    ${status} =  Get From Dictionary  ${device_ret1}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun emulation isis config failed\n${device_ret1}
    ...  ELSE  Log To Console  \n***** run emulation isis config successfully

    ${isis_hnd2} =  Get From Dictionary  ${device_ret1}  handle

#configure ISIS LSP with segment routing enabled

    ${lspStatus} =  emulation isis lsp generator  mode=create  handle=${isis_hnd2}  type=tree  loopback_adver_enable=true
    ...  tree_if_type=POINT_TO_POINT  ipv4_internal_emulated_routers=NONE  ipv4_internal_simulated_routers=ALL  ipv4_internal_count=10
    ...  tree_max_if_per_router=2  router_id_start=4.0.0.1  ipv4_addr_start=4.0.0.0  system_id_start=100000000002  isis_level=LEVEL2
    ...  segment_routing_enabled=true  sr_algorithms=0  sr_cap_range=100  sr_cap_value=100  sr_cap_value_type=label

    ${status} =  Get From Dictionary  ${lspStatus}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun sth.emulation_isis_lsp_generator failed\n${lspStatus}
    ...  ELSE  Log To Console  \n***** run sth.emulation_isis_lsp_generator successfully\n${lspStatus}

########################################################################
# Step3. Config bound stream traffic from ISIS router on port2 to port1
########################################################################

    ${streamblock_ret1} =  traffic config  mode=create   port_handle=${port2}   emulation_src_handle=${isis_hnd2}   emulation_dst_handle=${lsp1}   tunnel_bottom_label=${isis_hnd2}   l2_encap=ethernet_ii   l3_protocol=ipv4   ip_id=0   ip_dst_addr=192.0.0.1   ip_ttl=255   ip_hdr_length=5   ip_protocol=253   ip_fragment_offset=0   ip_mbz=0   ip_precedence=6   ip_tos_field=0   mac_src=00-10-94-00-00-02   mac_dst=00:00:01:00:00:01   enable_control_plane=0   l3_length=110   name=StreamBlock_2-2   fill_type=constant   fcs_error=0   fill_value=0   frame_size=128   traffic_state=1   high_speed_result_analysis=1   length_mode=fixed   tx_port_sending_traffic_to_self_en=false   disable_signature=0   enable_stream_only_gen=1   endpoint_map=one_to_one   pkts_per_burst=1   inter_stream_gap_unit=bytes   burst_loop_count=1   transmit_mode=multi_burst   inter_stream_gap=12   rate_percent=10   mac_discovery_gw=10.1.1.1

    ${status} =  Get From Dictionary  ${streamblock_ret1}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun traffic config failed\n${streamblock_ret1}
    ...  ELSE  Log To Console  \n***** run traffic config successfully

#config part is finished

##############################################################
# Step4. Start ISIS
##############################################################

    ${ctrl_ret1} =  emulation isis control  handle=${isis_hnd1}   mode=start

    ${status} =  Get From Dictionary  ${ctrl_ret1}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun emulation isis control failed\n${ctrl_ret1}
    ...  ELSE  Log To Console  \n***** run emulation isis control successfully

    ${ctrl_ret2} =  emulation isis control  handle=${isis_hnd2}   mode=start

    ${status} =  Get From Dictionary  ${ctrl_ret2}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun emulation isis control failed\n${ctrl_ret2}
    ...  ELSE  Log To Console  \n***** run emulation isis control successfully

##############################################################
# Step5. Start Traffic
##############################################################

    ${traffic_ctrl_ret} =  traffic control  port_handle=${port1} ${port2}   action=run

    ${status} =  Get From Dictionary  ${traffic_ctrl_ret}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun traffic control failed\n${traffic_ctrl_ret}
    ...  ELSE  Log To Console  \n***** run traffic control successfully

    Sleep  3s

########################################
# Step6. Get ISIS Info
########################################

    ${results_ret1} =  emulation isis info  handle=${isis_hnd1}   mode=stats

    ${status} =  Get From Dictionary  ${results_ret1}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun emulation isis info failed\n${results_ret1}
    ...  ELSE  Log To Console  \n***** run emulation isis info successfully, and results is:\n${results_ret1}
    

    ${device} =  Get From Dictionary  ${device_ret1}  handle
    ${device} =  Get From List  ${device.split()}  0
    
    

    ${results_ret2} =  emulation isis info  handle=${isis_hnd2}   mode=stats

    ${status} =  Get From Dictionary  ${results_ret2}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun emulation isis info failed\n${results_ret2}
    ...  ELSE  Log To Console  \n***** run emulation isis info successfully, and results is:\n${results_ret2}

    Sleep  3s

##############################################################
# Step 7. Get Traffic Stats
##############################################################
    
    ${traffic_results_ret} =  traffic stats  port_handle=${port1} ${port2}   mode=all

    ${status} =  Get From Dictionary  ${traffic_results_ret}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun traffic stats failed\n${traffic_results_ret}
    ...  ELSE  Log To Console  \n***** run traffic stats successfully, and results is:\n${traffic_results_ret}

##############################################################
# Step 8. Release resources
##############################################################

    ${cleanup_sta} =  cleanup session  port_handle=${port1} ${port2}   clean_dbfile=1

    ${status} =  Get From Dictionary  ${cleanup_sta}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun cleanup session failed\n${cleanup_sta}
    ...  ELSE  Log To Console  \n***** run cleanup session successfully

    
    Log To Console  \n**************Finish***************

