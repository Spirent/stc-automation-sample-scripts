################################################################################
#
# File Name:                 traffic_qos.robot
#
# Description:               This script demonstrates how to configure traffic QoS and query the result based on 
#                            VLAN priority/DSCP/ToS.  
#                                                 
# Test steps:               
#                            1. Reserve and connect chassis ports
#                            2. Configure streamblock with multiple inner and outer vlan priorities
#                            3. Start taffic and then get real time and EOT results based on outer vlan priority
#                            4. Start taffic again and then get real time results and EOT results based on inner vlan priority
#                            5. Configure streamblock with multiple DSCP values
#                            6. Start taffic and then get real time results based on DSCP value
#                            7. Stop traffic and get EOT results of DSCP value
#                            8. Configure streamblock with multiple ToS values
#                            9. Start taffic and then get real time results based on ToS value
#                            10. Stop traffic and get EOT results of ToS
#                            11. Release resources
#
# Topology:
#                 Generate Traffic             Get Result     
#                   STC port1  ---------------- STC port2 
#                 [Streamblock]
#
################################################################################
# 
# Run sample:
#            c:\>robot traffic_QoS.robot

*** Settings ***
Documentation  Get libraries
Library           BuiltIn
Library           Collections
Library           sth.py


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
Test case name

    
##############################################################
#config the parameters for the logging
##############################################################

    ${test_sta} =  test config  log=1   logfile=traffic_qos_logfile   vendorlogfile=traffic_qos_stcExport   vendorlog=1   hltlog=1   hltlogfile=traffic_qos_hltExport   hlt2stcmappingfile=traffic_qos_hlt2StcMapping   hlt2stcmapping=1   log_level=7

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

##############################################################
#Step1. Reserve and connect chassis ports
##############################################################

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

################################################################################
# Step2. Configure streamblock with multiple inner and outer vlan priorities
################################################################################

    ${streamblock_ret1} =  traffic config  mode=create   port_handle=${port1}   l2_encap=ethernet_ii_vlan   l3_protocol=ipv4   ip_id=0   ip_src_addr=10.0.0.11   ip_dst_addr=10.0.0.1   ip_ttl=255   ip_hdr_length=5   ip_protocol=253   ip_fragment_offset=0   ip_mbz=0   ip_precedence=0   ip_tos_field=0   vlan_id_repeat=0   vlan_id_mode=increment   vlan_id_count=3   vlan_id_step=1   vlan_id_outer_repeat=0   vlan_id_outer_step=1   vlan_id_outer_count=3   vlan_id_outer_mode=increment   mac_src=00:10:94:00:00:02   mac_dst=00:00:01:00:00:01   vlan_outer_cfi=0   vlan_outer_tpid=33024   vlan_outer_user_priority=4   vlan_id_outer=100   vlan_cfi=0   vlan_tpid=33024   vlan_id=1   vlan_user_priority=1   enable_control_plane=0   l3_length=102   name=StreamBlock_1   fill_type=prbs   fcs_error=0   fill_value=0   frame_size=128   traffic_state=0   high_speed_result_analysis=1   length_mode=fixed   tx_port_sending_traffic_to_self_en=false   disable_signature=0   enable_stream_only_gen=1   endpoint_map=one_to_one   pkts_per_burst=1   inter_stream_gap_unit=bytes   burst_loop_count=30   transmit_mode=continuous   inter_stream_gap=12   rate_pps=1000   mac_discovery_gw=192.85.1.1   enable_stream=true

    ${status} =  Get From Dictionary  ${streamblock_ret1}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun traffic config failed\n${streamblock_ret1}
    ...  ELSE  Log To Console  \n***** run traffic config successfully

    ${vlanstreamHandle} =  Get From Dictionary  ${streamblock_ret1}  stream_id

#########################################################################################
# Step3. Start taffic and then get real time and EOT results based on outer vlan priority
#########################################################################################
    Log To Console  \nStart traffic generator for filtering outer vlan priority
    
    ${traffic_ctrl_ret} =  traffic control  port_handle=${port1}  action=run  get=vlan_pri

    ${status} =  Get From Dictionary  ${traffic_ctrl_ret}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun traffic control failed\n${traffic_ctrl_ret}
    ...  ELSE  Log To Console  \n***** run traffic control successfully

    Sleep  1s

    Log To Console  \nGet realtime results of outer vlan priority

    ${traffic_results_ret} =  traffic stats  port_handle=${port1}  mode=aggregate

    ${status} =  Get From Dictionary  ${traffic_results_ret}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun traffic stats failed\n${traffic_results_ret}
    ...  ELSE  Log To Console  \n***** run traffic stats successfully, and results is:\n${traffic_results_ret}

    Sleep  3s

    Log To Console  \nstop traffic

    ${traffic_ctrl_ret} =  traffic control  port_handle=${port1}  action=stop

    ${status} =  Get From Dictionary  ${traffic_ctrl_ret}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun traffic control failed\n${traffic_ctrl_ret}
    ...  ELSE  Log To Console  \n***** run traffic control successfully

    Log To Console  \nGet EOT results of outer vlan priority

    ${traffic_results_ret} =  traffic stats  port_handle=${port2}  mode=aggregate

    ${status} =  Get From Dictionary  ${traffic_results_ret}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun traffic stats failed\n${traffic_results_ret}
    ...  ELSE  Log To Console  \n***** run traffic stats successfully, outer vlan priority and EOT results are:\n${traffic_results_ret}

########################################################################################################################
# Step4. Start taffic again and then get real time results and EOT results based on inner vlan priority
########################################################################################################################

    Log To Console  Start traffic generator again for filtering innner vlan priority
    
    ${traffic_ctrl_ret} =  traffic control  port_handle=${port1}  action=run  get=vlan_pri_inner

    ${status} =  Get From Dictionary  ${traffic_ctrl_ret}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun traffic control failed\n${traffic_ctrl_ret}
    ...  ELSE  Log To Console  \n***** run traffic control successfully

    Sleep  1s

    Log To Console  \nGet realtime results of inner vlan priority

    ${traffic_results_ret} =  traffic stats  port_handle=${port1}  mode=aggregate

    ${status} =  Get From Dictionary  ${traffic_results_ret}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun traffic stats failed\n${traffic_results_ret}
    ...  ELSE  Log To Console  \n***** run traffic stats successfully,inner vlan priority and realtime results are:\n${traffic_results_ret}

    Sleep  3s

    Log To Console  \nstop traffic

    ${traffic_ctrl_ret} =  traffic control  port_handle=${port1}  action=stop

    ${status} =  Get From Dictionary  ${traffic_ctrl_ret}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun traffic control failed\n${traffic_ctrl_ret}
    ...  ELSE  Log To Console  \n***** run traffic control successfully

    Sleep  3s

    Log To Console  \nGet EOT results of inner vlan priority

    ${traffic_results_ret} =  traffic stats  port_handle=${port2}  mode=aggregate

    ${status} =  Get From Dictionary  ${traffic_results_ret}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun traffic stats failed\n${traffic_results_ret}
    ...  ELSE  Log To Console  \n***** run traffic stats successfully,inner vlan priority and EOT results are:\n${traffic_results_ret}

    Log To Console  \nDisable streamblock of vlan priority

    ${disable_sb} =  traffic config  mode=disable  stream_id=${vlanstreamHandle}

    ${status} =  Get From Dictionary  ${disable_sb}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun traffic config failed\n${disable_sb}
    ...  ELSE  Log To Console  \n***** Disable streamblock successfully

########################################################
# Step5. Configure streamblock with multiple DSCP values
########################################################

    Log To Console  \ncreate DSCP streamblock

    ${streamblock_ret2} =  traffic config  mode=create   port_handle=${port1}   l2_encap=ethernet_ii   l3_protocol=ipv4   l4_protocol=tcp   tcp_ack_num=234567   tcp_seq_num=123456   tcp_urg_flag=0   tcp_fin_flag=0   tcp_ack_flag=1   tcp_data_offset=5   tcp_rst_flag=0   tcp_window=4096   tcp_urgent_ptr=0   tcp_psh_flag=0   tcp_syn_flag=0   tcp_checksum=0   tcp_src_port=1000   tcp_reserved=0   tcp_dst_port=2000   ip_id=0   ip_src_addr=10.0.0.11   ip_dst_addr=10.0.0.1   ip_ttl=255   ip_hdr_length=5   ip_protocol=253   ip_fragment_offset=0   ip_dscp=26   ip_dscp_count=3   ip_dscp_step=1   mac_src=00:10:94:00:00:02   mac_dst=00:00:01:00:00:01   enable_control_plane=0   l3_length=110   name=StreamBlock_2   fill_type=constant   fcs_error=0   fill_value=0   frame_size=128   traffic_state=1   high_speed_result_analysis=1   length_mode=fixed   tx_port_sending_traffic_to_self_en=false   disable_signature=0   enable_stream_only_gen=1   endpoint_map=one_to_one   pkts_per_burst=1   inter_stream_gap_unit=bytes   burst_loop_count=30   transmit_mode=continuous   inter_stream_gap=12   rate_pps=10000   mac_discovery_gw=192.85.1.1   enable_stream=true

    ${status} =  Get From Dictionary  ${streamblock_ret2}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun traffic config failed\n${streamblock_ret2}
    ...  ELSE  Log To Console  \n***** run traffic config successfully

    ${dscpstreamHandle} =  Get From Dictionary  ${streamblock_ret2}  stream_id

################################################################################
# Step6. Start taffic and then get real time results based on DSCP value
################################################################################

    Log To Console  \nStart traffic generator for filtering DSCP value
    
    ${traffic_ctrl_ret} =  traffic control  port_handle=${port1}  action=run  get=dscp

    ${status} =  Get From Dictionary  ${traffic_ctrl_ret}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun traffic control failed\n${traffic_ctrl_ret}
    ...  ELSE  Log To Console  \n***** run traffic control successfully

    Sleep  1s

    Log To Console  \nGet realtime results of dscp

    ${traffic_results_ret} =  traffic stats  port_handle=${port2}  mode=aggregate

    ${status} =  Get From Dictionary  ${traffic_results_ret}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun traffic stats failed\n${traffic_results_ret}
    ...  ELSE  Log To Console  \n***** run traffic stats successfully,DSCP value and realtime results are:\n${traffic_results_ret}

    Sleep  1s

#########################################################
# Step7. Stop traffic and get EOT results of DSCP value
#########################################################
    
    Log To Console  \nStop traffic
    
    ${traffic_ctrl_ret} =  traffic control  port_handle=${port1}  action=stop

    ${status} =  Get From Dictionary  ${traffic_ctrl_ret}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun traffic control failed\n${traffic_ctrl_ret}
    ...  ELSE  Log To Console  \n***** run traffic control successfully

    Sleep  3s

    Log To Console  \nGet EOT results of DSCP

    ${traffic_results_ret} =  traffic stats  port_handle=${port1}  mode=aggregate

    ${status} =  Get From Dictionary  ${traffic_results_ret}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun traffic stats failed\n${traffic_results_ret}
    ...  ELSE  Log To Console  \n***** run traffic stats successfully,DSCP and EOT results are:\n${traffic_results_ret}

    Log To Console  \nDisable streamblock of DSCP

    ${disable_sb} =  traffic config  mode=disable  stream_id=${dscpstreamHandle}

    ${status} =  Get From Dictionary  ${disable_sb}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun traffic config failed\n${disable_sb}
    ...  ELSE  Log To Console  \n***** Disable streamblock successfully

########################################################
# Step8. Configure streamblock with multiple ToS values
########################################################

    Log To Console  \ncreate ToS streamblock

    ${streamblock_ret3} =  traffic config  mode=create   port_handle=${port1}   l2_encap=ethernet_ii   l3_protocol=ipv4   l4_protocol=tcp
    ...   ip_tos_count=3   ip_tos_step=1   ip_tos_field=2   ip_precedence=2   ip_mbz=1   transmit_mode=continuous   rate_pps=1000
    ...   ip_src_addr=10.0.0.11   ip_dst_addr=10.0.0.1   tcp_src_port=1000   tcp_dst_port=2000

    ${status} =  Get From Dictionary  ${streamblock_ret3}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun traffic config failed\n${streamblock_ret3}
    ...  ELSE  Log To Console  \n***** run traffic config successfully

    ${tosstreamHandle} =  Get From Dictionary  ${streamblock_ret3}  stream_id
    
    #config part is finished  
    
#######################################################################
# Step9. Start taffic and then get real time results based on ToS value
#######################################################################

    Log To Console  \nStart traffic generator for filtering ToS value
    
    ${traffic_ctrl_ret} =  traffic control  port_handle=${port1}  action=run  get=tos

    ${status} =  Get From Dictionary  ${traffic_ctrl_ret}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun traffic control failed\n${traffic_ctrl_ret}
    ...  ELSE  Log To Console  \n***** run traffic control successfully

    Sleep  1s

    Log To Console  \nGet realtime results of ToS

    ${traffic_results_ret} =  traffic stats  port_handle=${port2}  mode=aggregate

    ${status} =  Get From Dictionary  ${traffic_results_ret}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun traffic stats failed\n${traffic_results_ret}
    ...  ELSE  Log To Console  \n***** run traffic stats successfully,ToS value and realtime results are:\n${traffic_results_ret}
    
    Sleep  1s
    
#####################################################
# Step10. Stop traffic and get EOT results of ToS
#####################################################

    Log To Console  \nStop traffic
    
    ${traffic_ctrl_ret} =  traffic control  port_handle=${port1}  action=stop

    ${status} =  Get From Dictionary  ${traffic_ctrl_ret}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun traffic control failed\n${traffic_ctrl_ret}
    ...  ELSE  Log To Console  \n***** run traffic control successfully

    Sleep  3s

    Log To Console  \nGet EOT results of ToS

    ${traffic_results_ret} =  traffic stats  port_handle=${port2}  mode=aggregate

    ${status} =  Get From Dictionary  ${traffic_results_ret}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun traffic stats failed\n${traffic_results_ret}
    ...  ELSE  Log To Console  \n***** run traffic stats successfully,ToS and EOT results are:\n${traffic_results_ret}

    Log To Console  \nDisable streamblock of ToS

    ${disable_sb} =  traffic config  mode=disable  stream_id=${tosstreamHandle}

    ${status} =  Get From Dictionary  ${disable_sb}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun traffic config failed\n${disable_sb}
    ...  ELSE  Log To Console  \n***** Disable streamblock successfully

##############################################################
# Step 11. Release resources
##############################################################
    
    Log To Console  \nRelease resources

    ${cleanup_sta} =  cleanup session  port_handle=${port1} ${port2}   clean_dbfile=1

    ${status} =  Get From Dictionary  ${cleanup_sta}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun cleanup session failed\n${cleanup_sta}
    ...  ELSE  Log To Console  \n***** run cleanup session successfully

    
    Log To Console  \n**************Finish***************

