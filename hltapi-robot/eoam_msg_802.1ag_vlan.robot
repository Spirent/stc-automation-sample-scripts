#########################################################################################################################
#
# File Name:           eoam_msg_802.1ag_vlan.robot                 
# Description:         This script demonstrates the use of Spirent HLTAPI to setup EOAM and 802.1ag in B2B connection.
#                      
# Test Steps:          
#                    1. Reserve and connect chassis ports
#                    2. Configure EOAM 
#                    3. Start EOAM 
#                    4. Stop EOAM
#                    5. Get ports info
#                    6. Release resources
#
#                                                                       
# Topology:
#                      STC Port2                    STC Port1                       
#                     [EOAM port]------------------[EOAM port]
#                                                                         
#  
################################################################################
# 
# Run sample:
#            c:\>robot eoam_msg_802.1ag_vlan.robot
#

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
EOAM Test
##############################################################
#config the parameters for the logging
##############################################################

    ${test_sta} =  test config  log=1   logfile=eoam_msg_802_logfile   vendorlogfile=eoam_msg_802_stcExport   vendorlog=1   hltlog=1   hltlogfile=eoam_msg_802_hltExport   hlt2stcmappingfile=eoam_msg_802_hlt2StcMapping   hlt2stcmapping=1   log_level=7

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
#Step 1. Reserve and connect chassis ports
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

##############################################################
#Step 2. Configure EOAM 
##############################################################
    Log To Console  \nConfigure EOAM on port1

    ${device_ret0} =  emulation oam config msg  mode=create   slm_tx_fc_fwd_offset=0   initial_cc_seq_num=1   slr_tx_fc_bck_step=1   lmr_rx_fc_fwd_start=1   ais_rx=true   lmr_rx_fc_fwd_step=1   loss_measurement_response=true   lmr_tx_fc_bck_offset=0   link_trace_response=true   slm_response=true   override_cont_chk_period=none   lmm_tx_fc_fwd_offset=0   mp_name=MP_1   override_me_level=none   delay_measurement_response=true   dmr_delay=0   override_lck_period=none   meg_end_point_id=1   lmr_tx_fc_bck_start=1   lmr_rx_fc_fwd_offset=0   override_ais_period=none   slr_tx_fc_bck_start=1   loopback_response=true   slr_tx_fc_bck_offset=0   lck_rx=true   dmm_delay=0   lmr_tx_fc_bck_step=1   rdi=auto   md_level=1   oam_standard=ieee_802.1ag   lb_loopback_tx_rate=lbrate_1_per_sec   lb_loopback_tx_type=continuous   lb_operation_mode=itu_t   mac_dst=00:94:01:00:01:01   lb_enable_multicast_target=false   lb_initial_transaction_id=100   transmit_mode=continuous   lb_loopback_tx_count=1   dst_addr_type=unicast   lb_unicast_target_list=00:94:01:00:01:01   trans_id=100   tlv_sender_length=10   tlv_sender_chassis_id_length=10   tlv_sender_chassis_id_subtype=5   tlv_sender_chassis_id=21   tlv_org_length=10   tlv_org_oui=22   tlv_org_subtype=11   tlv_org_value=FF   tlv_data_length=10   tlv_data_pattern=0xAA   tlv_test_length=30   tlv_test_pattern=null_with_crc   mac_remote=00:94:01:00:01:01   msg_type=test   port_handle=${port1}   vlan_ether_type=37120   vlan_id=100   vlan_id_step=1   vlan_outer_ether_type=34984   vlan_outer_id=1000   vlan_id_outer_step=1   mac_local=00:94:01:00:00:01

    ${status} =  Get From Dictionary  ${device_ret0}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun emulation oam config msg failed\n${device_ret0}
    ...  ELSE  Log To Console  \n***** run emulation oam config msg successfully

    ${msgHandleList1} =  Get From Dictionary  ${device_ret0}  handle

    Log To Console  \nConfigure EOAM on port2

    ${device_ret1} =  emulation oam config msg  mode=create   slm_tx_fc_fwd_offset=0   initial_cc_seq_num=1   slr_tx_fc_bck_step=1   lmr_rx_fc_fwd_start=1   ais_rx=true   lmr_rx_fc_fwd_step=1   loss_measurement_response=true   lmr_tx_fc_bck_offset=0   link_trace_response=true   slm_response=true   override_cont_chk_period=none   lmm_tx_fc_fwd_offset=0   mp_name=MP_2   override_me_level=none   delay_measurement_response=true   dmr_delay=0   override_lck_period=none   meg_end_point_id=2   lmr_tx_fc_bck_start=1   lmr_rx_fc_fwd_offset=0   override_ais_period=none   slr_tx_fc_bck_start=1   loopback_response=true   slr_tx_fc_bck_offset=0   lck_rx=true   dmm_delay=0   lmr_tx_fc_bck_step=1   rdi=auto   md_level=1   oam_standard=ieee_802.1ag   lb_loopback_tx_rate=lbrate_1_per_sec   lb_loopback_tx_type=continuous   lb_operation_mode=itu_t   mac_dst=00:94:01:00:01:01   lb_enable_multicast_target=false   lb_initial_transaction_id=100   transmit_mode=continuous   lb_loopback_tx_count=1   dst_addr_type=unicast   lb_unicast_target_list=00:94:01:00:01:01   trans_id=100   tlv_sender_length=10   tlv_sender_chassis_id_length=10   tlv_sender_chassis_id_subtype=5   tlv_sender_chassis_id=21   tlv_org_length=10   tlv_org_oui=22   tlv_org_subtype=11   tlv_org_value=FF   tlv_data_length=10   tlv_data_pattern=0xAA   tlv_test_length=30   tlv_test_pattern=null_with_crc   mac_remote=00:94:01:00:00:01   msg_type=test   port_handle=${port2}   vlan_ether_type=37120   vlan_id=100   vlan_id_step=1   vlan_outer_ether_type=34984   vlan_outer_id=1000   vlan_id_outer_step=1   mac_local=00:94:01:00:01:01

    ${status} =  Get From Dictionary  ${device_ret1}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun emulation oam config msg failed\n${device_ret1}
    ...  ELSE  Log To Console  \n***** run emulation oam config msg successfully

    ${msgHandleList2} =  Get From Dictionary  ${device_ret0}  handle

    #config part is finished
    
##############################################################
#Step 3. Start EOAM 
##############################################################

    Log To Console  \nStart EOAM on port1   

    ${ctrl_ret1} =  emulation oam control  handle=${msgHandleList1}   action=start

    ${status} =  Get From Dictionary  ${ctrl_ret1}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun emulation oam control failed\n${ctrl_ret1}
    ...  ELSE  Log To Console  \n***** run emulation oam control successfully
    
    Sleep  10s 

##############################################################
#Step 4. Stop EOAM 
##############################################################

    ${ctrl_ret2} =  emulation oam control  handle=${msgHandleList1}   action=stop

    ${status} =  Get From Dictionary  ${ctrl_ret2}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun emulation oam control failed\n${ctrl_ret2}
    ...  ELSE  Log To Console  \n***** run emulation oam control successfully

##############################################################
#Step 5. Get ports info
##############################################################

    ${results_ret0} =  emulation oam info  port_handle=${port1}   mode=aggregate   action=get_topology_stats

    ${status} =  Get From Dictionary  ${results_ret0}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun emulation oam info failed\n${results_ret0}
    ...  ELSE  Log To Console  \n***** run emulation oam info successfully, and results is:\n${results_ret0}
    

    ${results_ret1} =  emulation oam info  port_handle=${port2}   mode=aggregate   action=get_topology_stats

    ${status} =  Get From Dictionary  ${results_ret1}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun emulation oam info failed\n${results_ret1}
    ...  ELSE  Log To Console  \n***** run emulation oam info successfully, and results is:\n${results_ret1}

    ${fm_pkts0} =  Evaluate  ${results_ret0}['aggregate']['tx']['fm_pkts']
    ${fm_pkts1} =  Set Variable  ${results_ret1['aggregate']['rx']['fm_pkts']}
 
    Log To Console  \ntx_fm_pkts on port1 is : ${fm_pkts0}
    Log To Console  \nrx_fm_pkts on port2 is : ${fm_pkts1}

##############################################################
#Step 6. Release resources
##############################################################

    ${cleanup_sta} =  cleanup session  port_handle=${port1} ${port2}   clean_dbfile=1

    ${status} =  Get From Dictionary  ${cleanup_sta}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun cleanup session failed\n${cleanup_sta}
    ...  ELSE  Log To Console  \n***** run cleanup session successfully

    
    Log To Console  \n**************Finish***************
