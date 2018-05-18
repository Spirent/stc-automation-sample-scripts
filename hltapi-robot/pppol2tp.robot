#################################
#
# File Name:         pppol2tp.robot
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
#            c:\>robot pppol2tp.robot

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
pppoe over l2tp test
    [Documentation]  pppoe over l2tp test

##############################################################
#config the parameters for the logging
##############################################################

    ${test_sta} =  test config  log=1   logfile=pppol2tp_logfile   vendorlogfile=pppol2tp_stcExport   vendorlog=1   hltlog=1   hltlogfile=pppol2tp_hltExport   hlt2stcmappingfile=pppol2tp_hlt2StcMapping   hlt2stcmapping=1   log_level=7

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
#Step2. Config Pppoe over l2tp LAC on Port2
##############################################################

    ${device_ret0} =  l2tp config  l2_encap=ethernet_ii   l2tp_src_count=1   l2tp_src_addr=192.85.1.3   l2tp_src_step=0.0.0.1   l2tp_dst_addr=192.85.1.4   l2tp_dst_step=0.0.0.0   port_handle=${port2}   max_outstanding=100   disconnect_rate=1000   mode=lac   attempt_rate=100   ppp_auto_retry=FALSE   max_terminate_req=10   auth_req_timeout=3   username=spirent   ppp_retry_count=65535   max_ipcp_req=10   echo_req_interval=10   password=spirent   config_req_timeout=3   terminate_req_timeout=3   max_echo_acks=0   auth_mode=none   echo_req=FALSE   enable_magic=TRUE   l2tp_mac_addr=00:10:94:00:00:01   l2tp_mac_step=00:00:00:00:00:01   hello_interval=60   hello_req=FALSE   force_lcp_renegotiation=FALSE   tunnel_id_start=1   num_tunnels=1   tun_auth=TRUE   session_id_start=1   redial=FALSE   avp_framing_type=sync   redial_max=1   redial_timeout=1   sessions_per_tunnel=1   avp_hide_list=0   avp_tx_connect_speed=56000   udp_src_port=1701   lcp_proxy_mode=none   secret=spirent   hostname=server.spirent.com   rws=4

    ${status} =  Get From Dictionary  ${device_ret0}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun l2tp config failed\n${device_ret0}
    ...  ELSE  Log To Console  \n***** run l2tp config successfully

    ${device2} =  Get From Dictionary  ${device_ret0}  handle

##############################################################
#Step3. Config Pppoe over l2tp LNS on Port1
##############################################################

    ${device_ret1} =  l2tp config  l2_encap=ethernet_ii   l2tp_dst_count=1   l2tp_src_addr=192.85.1.3   l2tp_src_step=0.0.0.0   l2tp_dst_addr=192.85.1.4   l2tp_dst_step=0.0.0.1   ppp_server_ip=192.85.1.4   ppp_server_step=0.0.0.1   ppp_client_ip=192.0.1.0   ppp_client_step=0.0.0.1   port_handle=${port1}   max_outstanding=100   disconnect_rate=1000   mode=lns   attempt_rate=100   max_terminate_req=10   username=spirent   max_ipcp_req=10   echo_req_interval=10   password=spirent   config_req_timeout=3   terminate_req_timeout=3   max_echo_acks=0   auth_mode=none   echo_req=FALSE   enable_magic=TRUE   l2tp_mac_addr=00:10:94:00:00:02   l2tp_mac_step=00:00:00:00:00:01   hello_interval=60   hello_req=FALSE   force_lcp_renegotiation=FALSE   tunnel_id_start=1   num_tunnels=1   tun_auth=TRUE   session_id_start=1   redial=FALSE   avp_framing_type=sync   redial_max=1   redial_timeout=1   sessions_per_tunnel=1   avp_hide_list=0   avp_tx_connect_speed=56000   udp_src_port=1701   lcp_proxy_mode=none   secret=spirent   hostname=server.spirent.com   rws=4

    ${status} =  Get From Dictionary  ${device_ret1}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun l2tp config failed\n${device_ret1}
    ...  ELSE  Log To Console  \n***** run l2tp config successfully

    ${device1} =  Get From Dictionary  ${device_ret1}  handle

    #config part is finished
    
##############################################################
#Step4. Start LAC-LNS Connect and Pppoe
##############################################################

    ${ctrl_ret1} =  l2tp control  handle=${device1}   action=connect

    ${status} =  Get From Dictionary  ${ctrl_ret1}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun l2tp control failed\n${ctrl_ret1}
    ...  ELSE  Log To Console  \n***** run l2tp control successfully

    ${ctrl_ret3} =  l2tp control  handle=${device2}   action=connect

    ${status} =  Get From Dictionary  ${ctrl_ret3}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun l2tp control failed\n${ctrl_ret3}
    ...  ELSE  Log To Console  \n***** run l2tp control successfully

##############################################################
#Step5. Retrive Statistics
##############################################################

    ${results_ret1} =  l2tp stats  handle=${device1}   mode=aggregate

    ${status} =  Get From Dictionary  ${results_ret1}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun l2tp stats failed\n${results_ret1}
    ...  ELSE  Log To Console  \n***** run l2tp stats successfully, and results is:\n${results_ret1}

    ${results_ret3} =  l2tp stats  handle=${device2}   mode=aggregate

    ${status} =  Get From Dictionary  ${results_ret3}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun l2tp stats failed\n${results_ret3}
    ...  ELSE  Log To Console  \n***** run l2tp stats successfully, and results is:\n${results_ret3}
    
##############################################################
#Step6. Release resources
###############################################################

    ${cleanup_sta} =  cleanup session  port_handle=${port1} ${port2}   clean_dbfile=1

    ${status} =  Get From Dictionary  ${cleanup_sta}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun cleanup session failed\n${cleanup_sta}
    ...  ELSE  Log To Console  \n***** run cleanup session successfully

    
    Log To Console  \n**************Finish***************

