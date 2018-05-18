#################################
#
# File Name:         pim_highscale.robot
#
# Description:       This script demonstrates the use of Spirent HLTAPI PIM with 20K Multicast groups.
# 
# Test Step:
#                    1. Reserve and connect chassis ports                             
#                    2. Config multicast groups  
#                    3. Config upstrem PIM router on port1 
#                    4. Config downstrem PIM router on port2
#                    5. Config traffic
#                    6. Start traffic
#                    7. Start PIM Routers
#                    8. Get PIM routers info
#                    9. Get traffic results
#                    10. Release resources
#
# Topology:
#
#              STC Port1                                  STC Port2           
#         [Upstream PIM Router1]-----------------  [Downstream PIM Router2]
#                                          
#                           
###################################
# Run sample:
#            c:\>robot pim_highscale.robot


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
pim highscale test
    [Documentation]  pim highscale test
##############################################################
#config the parameters for the logging
##############################################################

    ${test_sta} =  test config  log=1   logfile=pim_highscale_logfile   vendorlogfile=pim_highscale_stcExport   vendorlog=1   hltlog=1   hltlogfile=pim_highscale_hltExport   hlt2stcmappingfile=pim_highscale_hlt2StcMapping   hlt2stcmapping=1   log_level=7

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
 
##############################################################
#get the device info
##############################################################

    ${device_info} =  device info  ports=1  port_handle=${port1} ${port2}   fspec_version=1

    ${status} =  Get From Dictionary  ${device_info}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun device info failed\n${device_info}
    ...  ELSE  Log To Console  \n***** run device info successfully

##############################################################
# Step2.Config multicast groups  
##############################################################

    ${device_ret0_pim_group0_macstgroup} =  emulation multicast group config  mode=create   ip_prefix_len=32   ip_addr_start=225.18.0.10   ip_addr_step=1   num_groups=10000   pool_name=Ipv4Group_1

    ${status} =  Get From Dictionary  ${device_ret0_pim_group0_macstgroup}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun emulation multicast group config failed\n${device_ret0_pim_group0_macstgroup}
    ...  ELSE  Log To Console  \n***** run emulation multicast group config successfully

    ${device_ret1_pim_group0_macstgroup} =  emulation multicast group config  mode=create   ip_prefix_len=32   ip_addr_start=225.19.0.10   ip_addr_step=1   num_groups=10000   pool_name=Ipv4Group_2

    ${status} =  Get From Dictionary  ${device_ret1_pim_group0_macstgroup}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun emulation multicast group config failed\n${device_ret1_pim_group0_macstgroup}
    ...  ELSE  Log To Console  \n***** run emulation multicast group config successfully

##############################################################
# Step3.Config upstrem PIM router on port1
##############################################################

#start to create the device: Router 1
    ${device_ret0} =  emulation pim config  mode=create   prune_delay=100   hello_max_delay=30   override_interval=1000   prune_delay_enable=1   c_bsr_rp_addr=1.1.1.4   c_bsr_rp_holdtime=130   c_bsr_rp_priority=100   c_bsr_rp_mode=create   port_handle=${port1}   hello_interval=40   ip_version=4   bs_period=160   hello_holdtime=140   dr_priority=1   join_prune_interval=80   bidir_capable=1   pim_mode=sm   join_prune_holdtime=240   type=c_bsr   c_bsr_priority=1   router_id=13.13.0.10   mac_address_start=00:10:94:00:00:04   intf_ip_addr=13.13.0.10   intf_ip_prefix_len=24   neighbor_intf_ip_addr=13.13.0.1

    ${status} =  Get From Dictionary  ${device_ret0}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun emulation pim config failed\n${device_ret0}
    ...  ELSE  Log To Console  \n***** run emulation pim config successfully

#Link the upstream router to multicast group

    ${session_handle} =  Get From Dictionary  ${device_ret0}  handle

    ${group_pool_handle} =  Get From Dictionary  ${device_ret0_pim_group0_macstgroup}  handle

    ${device_ret0_pim_group0} =  emulation pim group config  mode=create   session_handle=${session_handle}   group_pool_handle=${group_pool_handle}   interval=1   rate_control=0   rp_ip_addr=1.1.1.4

    ${pimGroupMemberHandle1} =  Get From Dictionary  ${device_ret0_pim_group0}  handle

    ${status} =  Get From Dictionary  ${device_ret0_pim_group0}  status
    ${lbl} =  Set Variable  PIM Group Member 1
    Run Keyword If  ${status} == 0  Log To Console  \nrun emulation pim group config failed\n${device_ret0_pim_group0}
    ...  ELSE   Log To Console  \n***** run emulation pim group config successfully 

##############################################################
# Step4.Config downstrem PIM router on port2
##############################################################   
#start to create the device: Router 2

    ${device_ret1} =  emulation pim config  mode=create   prune_delay=100   hello_max_delay=30   override_interval=1000   prune_delay_enable=1   c_bsr_rp_addr=1.1.1.4   c_bsr_rp_holdtime=30   c_bsr_rp_priority=10   c_bsr_rp_mode=create   port_handle=${port2}   hello_interval=30   ip_version=4   bs_period=60   hello_holdtime=105   dr_priority=1   join_prune_interval=60   bidir_capable=0   pim_mode=sm   join_prune_holdtime=210   type=c_bsr   c_bsr_priority=1   router_id=13.14.0.10   mac_address_start=00:10:94:00:00:05   intf_ip_addr=13.14.0.10   intf_ip_prefix_len=24   neighbor_intf_ip_addr=13.14.0.1

    ${status} =  Get From Dictionary  ${device_ret1}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun emulation pim config failed\n${device_ret1}
    ...  ELSE  Log To Console  \n***** run emulation pim config successfully

#Link the downstream router to multicast group    

    ${session_handle} =  Get From Dictionary  ${device_ret1}  handle

    ${group_pool_handle} =  Get From Dictionary  ${device_ret1_pim_group0_macstgroup}  handle

    ${device_ret1_pim_group0} =  emulation pim group config  mode=create   session_handle=${session_handle}   group_pool_handle=${group_pool_handle}   interval=1   rate_control=0   rp_ip_addr=1.1.1.4

    ${pimGroupMemberHandle2} =  Get From Dictionary  ${device_ret1_pim_group0}  handle

    ${status} =  Get From Dictionary  ${device_ret1_pim_group0}  status
    ${lbl} =  Set Variable  PIM Group Member 2
    Run Keyword If  ${status} == 0  Log To Console  \nrun emulation pim group config failed\n${device_ret1_pim_group0}
    ...  ELSE  Log To Console  \n***** run emulation pim group config successfully 

##############################################################
# Step5. Config traffic
##############################################################

    ${src_hdl} =  Get From Dictionary  ${device_ret0}  handle
    ${dst_hdl} =  Get From Dictionary  ${device_ret1_pim_group0_macstgroup}  handle

    ${streamblock_ret1} =  traffic config  mode=create   port_handle=${port1}   emulation_src_handle=${src_hdl}   emulation_dst_handle=${dst_hdl}   l2_encap=ethernet_ii   l3_protocol=ipv4   ip_id=0   ip_ttl=255   ip_hdr_length=5   ip_protocol=253   ip_fragment_offset=0   ip_mbz=0   ip_precedence=6   ip_tos_field=0   mac_src=00:10:94:00:00:04   mac_dst=01:00:5e:13:00:0a   enable_control_plane=0   l3_length=128   name=StreamBlock_1   fill_type=constant   fcs_error=0   fill_value=0   frame_size=146   traffic_state=1   high_speed_result_analysis=1   length_mode=fixed   tx_port_sending_traffic_to_self_en=false   disable_signature=0   enable_stream_only_gen=1   endpoint_map=one_to_one   pkts_per_burst=1   inter_stream_gap_unit=bytes   burst_loop_count=30   transmit_mode=continuous   inter_stream_gap=12   rate_percent=10   mac_discovery_gw=41.1.0.1

    ${status} =  Get From Dictionary  ${streamblock_ret1}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun traffic config failed\n${streamblock_ret1}
    ...  ELSE  Log To Console  \n***** run traffic config successfully

    ${src_hdl} =  Get From Dictionary  ${device_ret1}  handle
    ${dst_hdl} =  Get From Dictionary  ${device_ret0_pim_group0_macstgroup}  handle

    ${streamblock_ret2} =  traffic config  mode=create   port_handle=${port2}   emulation_src_handle=${src_hdl}   emulation_dst_handle=${dst_hdl}   l2_encap=ethernet_ii   l3_protocol=ipv4   ip_id=0   ip_ttl=255   ip_hdr_length=5   ip_protocol=253   ip_fragment_offset=0   ip_mbz=0   ip_precedence=6   ip_tos_field=0   mac_src=00:10:94:00:00:05   mac_dst=01:00:5e:12:00:0a   enable_control_plane=0   l3_length=128   name=StreamBlock_2   fill_type=constant   fcs_error=0   fill_value=0   frame_size=146   traffic_state=1   high_speed_result_analysis=1   length_mode=fixed   tx_port_sending_traffic_to_self_en=false   disable_signature=0   enable_stream_only_gen=1   endpoint_map=one_to_one   pkts_per_burst=1   inter_stream_gap_unit=bytes   burst_loop_count=30   transmit_mode=continuous   inter_stream_gap=12   rate_percent=10   mac_discovery_gw=42.1.0.1

    ${status} =  Get From Dictionary  ${streamblock_ret2}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun traffic config failed\n${streamblock_ret2}
    ...  ELSE  Log To Console  \n***** run traffic config successfully

    #config part is finished
    
##############################################################
# Step 6. Start traffic
##############################################################

    ${traffic_ctrl_ret} =  traffic control  port_handle=${port1} ${port2}   action=run

    ${status} =  Get From Dictionary  ${traffic_ctrl_ret}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun traffic control failed\n${traffic_ctrl_ret}
    ...  ELSE  Log To Console  \n***** run traffic control successfully

##############################################################
# Step 7. Start PIM Routers
##############################################################

#Start upstream pim router

    ${ctrl_ret1} =  emulation pim control  port_handle=${port1}   mode=start

    ${status} =  Get From Dictionary  ${ctrl_ret1}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun emulation pim control failed\n${ctrl_ret1}
    ...  ELSE  Log To Console  \n***** run emulation pim control successfully

#start downstream pim router

    ${ctrl_ret2} =  emulation pim control  port_handle=${port2}   mode=start

    ${status} =  Get From Dictionary  ${ctrl_ret2}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun emulation pim control failed\n${ctrl_ret2}
    ...  ELSE  Log To Console  \n***** run emulation pim control successfully

    Log To Console  PIM routers started,wait 30 seconds to form neighbor relationship.

    ${i} =  Set Variable  {EMPTY}
    :FOR  ${i}  IN RANGE  11
    \  Log To Console  .
    \  Sleep  1s

##############################################################
# Step 8. Get PIM routers info
##############################################################

    ${device0} =  Get From Dictionary  ${device_ret0}  handle
    ${device1} =  Get From Dictionary  ${device_ret1}  handle

    ${results_ret1} =  emulation pim info  handle=${device0}

    ${status} =  Get From Dictionary  ${results_ret1}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun emulation pim info failed\n${results_ret1}
    ...  ELSE  Log To Console  \n***** run emulation pim info successfully, and results is:\n${results_ret1}

    ${results_ret2} =  emulation pim info  handle=${device1}

    ${status} =  Get From Dictionary  ${results_ret2}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun emulation pim info failed\n${results_ret2}
    ...  ELSE  Log To Console  \n***** run emulation pim info successfully, and results is:\n${results_ret2}
    
##############################################################
# Step 9. Get traffic results
##############################################################

    ${traffic_results_ret} =  traffic stats  port_handle=${port1} ${port2}   mode=aggregate

    ${status} =  Get From Dictionary  ${traffic_results_ret}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun traffic stats failed\n${traffic_results_ret}
    ...  ELSE  Log To Console  \n***** run traffic stats successfully, and results is:\n${traffic_results_ret}
    
##############################################################
# Step 10. Release resources
##############################################################

    ${cleanup_sta} =  cleanup session  port_handle=${port1} ${port2}   clean_dbfile=1

    ${status} =  Get From Dictionary  ${cleanup_sta}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun cleanup session failed\n${cleanup_sta}
    ...  ELSE  Log To Console  \n***** run cleanup session successfully

    
    Log To Console  \n**************Finish***************

