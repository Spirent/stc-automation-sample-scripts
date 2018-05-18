#################################
#
# File Name:         pppox_server.robot
#
# Description:       This script demonstrates the use of Spirent HLTAPI to setup PPPox Server devices
#                    and create bound traffic between PPPox servers and clients.                  
#
# Test Step:         1. Reserve and connect chassis ports
#                    2. Interface config(optional)
#                    3. Config PPPox Server
#                    4. Config PPPox Clients
#                    5. Connect PPPoE server & client
#                    6. Check PPPoE server & client Stats
#                    7. Stop PPPoE server & client
#                    8. Release resources
#
#
# Topology
#                 STC Port1                    STC Port2                       
#               [PPPox Servers]----------------[PPPox Clients]
#                                         
#
#################################
# Run sample:
#            c:\>robot pppox_server.robot

*** Settings ***
Documentation  Get libraries
Library           BuiltIn
Library           Collections
Library           sth.py

*** Variables ***
${deviceNum} =  10

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
pppox server test
    [Documentation]  pppox server test
    
##############################################################
#config the parameters for the logging
##############################################################
    

    ${test_sta} =  test config  log=1   logfile=pppox_server_logfile   vendorlogfile=pppox_server_stcExport   vendorlog=1   hltlog=1   hltlogfile=pppox_server_hltExport   hlt2stcmappingfile=pppox_server_hlt2StcMapping   hlt2stcmapping=1   log_level=7

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

########################################
# Step3: Config PPPox Server
########################################   

    ${device_ret0} =  pppox server config  mode=create   encap=ethernet_ii_qinq   protocol=pppoe   ipv4_pool_addr_prefix_len=24   ipv4_pool_addr_count=50   ipv4_pool_addr_step=1   ipv4_pool_addr_start=10.1.0.0   port_handle=${port1}   max_outstanding=100   disconnect_rate=50   attempt_rate=50   enable_osi=false   pap_req_timeout=3   mru_neg_enable=1   max_configure_req=10   term_req_timeout=3   max_terminate_req=10   username=spirent   force_server_connect_mode=false   echo_vendor_spec_tag_in_pado=false   echo_vendor_spec_tag_in_pads=false   max_payload_tag_enable=false   max_ipcp_req=10   echo_req_interval=10   config_req_timeout=3   local_magic=1   password=spirent   chap_reply_timeout=3   max_chap_req_attempt=10   enable_mpls=false   lcp_mru=1492   ip_cp=ipv4_cp   max_echo_acks=1   auth_mode=chap   include_id=1   ipcp_req_timeout=3   server_inactivity_timer=30   unconnected_session_threshold=0   max_payload_bytes=1500   echo_req=false   fsm_max_naks=5   vlan_cfi=0   vlan_id=200   vlan_id_count=2   vlan_user_priority=7   vlan_id_step=0   vlan_id_mode=increment   vlan_id_outer_count=5   vlan_outer_user_priority=7   vlan_outer_cfi=0   vlan_id_outer=300   vlan_id_outer_step=0   vlan_id_outer_mode=increment   mac_addr=00:10:94:01:00:01   mac_addr_step=00:00:00:00:00:01   intf_ip_prefix_length=24   intf_ip_addr=192.0.0.8   gateway_ip_addr=192.0.0.1   intf_ip_addr_step=0.0.0.1   gateway_ip_step=0.0.0.0   num_sessions=${deviceNum}

    ${status} =  Get From Dictionary  ${device_ret0}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun pppox server config failed\n${device_ret0}
    ...  ELSE  Log To Console  \n***** run pppox server config successfully

########################################
# Step4: Config PPPox Clients
########################################

    ${device_ret1} =  pppox config  mode=create   encap=ethernet_ii_qinq   protocol=pppoe   ac_select_mode=service_name   circuit_id_suffix_mode=none   port_handle=${port2}   max_outstanding=100   disconnect_rate=1000   attempt_rate=100   pppoe_circuit_id=circuit   mru_neg_enable=1   max_configure_req=10   chap_ack_timeout=3   max_padi_req=10   padi_include_tag=1   padr_req_timeout=3   max_terminate_req=10   term_req_timeout=3   username=spirent   use_partial_block_state=false   max_auto_retry_count=65535   agent_type=2516   max_ipcp_req=10   intermediate_agent=false   echo_req_interval=10   password=spirent   local_magic=1   config_req_timeout=3   active=1   auto_retry=false   padi_req_timeout=3   agent_mac_addr=00:00:00:00:00:00   lcp_mru=1492   ip_cp=ipv4_cp   auto_fill_ipv6=1   max_echo_acks=0   auth_mode=chap   include_id=1   ipcp_req_timeout=3   max_padr_req=10   padr_include_tag=1   echo_req=false   fsm_max_naks=5   vlan_cfi=0   vlan_id=200   vlan_tpid=33024   vlan_id_count=2   vlan_user_priority=7   vlan_id_step=0   vlan_id_outer_count=5   vlan_outer_user_priority=7   vlan_outer_cfi=0   vlan_id_outer=300   vlan_tpid_outer=33024   vlan_id_outer_step=0   mac_addr=00:10:94:01:00:45   mac_addr_repeat=0   mac_addr_step=00:00:00:00:00:01   intf_ip_addr=192.85.1.3   gateway_ip_addr=192.85.1.1   intf_ip_addr_step=0.0.0.1   gateway_ip_step=0.0.0.0   num_sessions=${deviceNum}

    ${status} =  Get From Dictionary  ${device_ret1}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun pppox config failed\n${device_ret1}
    ...  ELSE  Log To Console  \n***** run pppox config successfully

    ${clientHandle} =  Get From Dictionary  ${device_ret1}  handle

    #config part is finished
    
########################################
# Step5: Connect PPPoE server & client
########################################    

    ${ctrl_ret1} =  pppox server control  port_handle=${port1}   action=connect

    ${status} =  Get From Dictionary  ${ctrl_ret1}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun pppox server control failed\n${ctrl_ret1}
    ...  ELSE  Log To Console  \n***** run pppox server control successfully

    ${ctrl_ret2} =  pppox control  handle=${clientHandle}   action=connect

    ${status} =  Get From Dictionary  ${ctrl_ret2}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun pppox control failed\n${ctrl_ret2}
    ...  ELSE  Log To Console  \n***** run pppox control successfully

    Sleep  5s

########################################
# Step6: Check PPPoE server & client Stats
########################################

    ${results_ret1} =  pppox server stats  port_handle=${port1}   mode=aggregate

    ${status} =  Get From Dictionary  ${results_ret1}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun pppox server stats failed\n${results_ret1}
    ...  ELSE  Log To Console  \n***** run pppox server stats successfully, and results is:\n${results_ret1}
 
    ${connect} =  evaluate  ${results_ret1}['aggregate']['connected']

    Run Keyword If  ${connect} == 1  Log To Console  \nPPPoE server and clients connected successfully
    ...  ELSE  Log To Console  \nPPPoE server and clients connected unsuccessfully

    ${results_ret2} =  pppox stats  handle=${clientHandle}   mode=session

    ${status} =  Get From Dictionary  ${results_ret2}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun pppox client stats failed\n${results_ret1}
    ...  ELSE  Log To Console  \n***** run pppox client stats successfully, and results is:\n${results_ret1}
 
    Log To Console  \nThe assigned pppoe client ip addresses are:

    :FOR  ${i}  IN RANGE  1  ${deviceNum}+1
    \  ${ip} =  evaluate  ${results_ret2}['session']['${i}']['ip_addr']
    \  Log To Console  \n${ip}

########################################
#step7: Stop PPPoE server & client
########################################

    ${ctrl_ret1} =  pppox control  handle=${clientHandle}   action=disconnect

    ${status} =  Get From Dictionary  ${ctrl_ret1}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun pppox control failed\n${ctrl_ret2}
    ...  ELSE  Log To Console  \n***** run pppox control successfully

   ${ctrl_ret2} =  pppox server control  port_handle=${port1}   action=disconnect

    ${status} =  Get From Dictionary  ${ctrl_ret1}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun pppox server control failed\n${ctrl_ret1}
    ...  ELSE  Log To Console  \n***** run pppox server control successfully

########################################
#step8: Release resources
########################################

    ${cleanup_sta} =  cleanup session  port_handle=${port1} ${port2}   clean_dbfile=1

    ${status} =  Get From Dictionary  ${cleanup_sta}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun cleanup session failed\n${cleanup_sta}
    ...  ELSE  Log To Console  \n***** run cleanup session successfully

    Log To Console  \n**************Finish***************

