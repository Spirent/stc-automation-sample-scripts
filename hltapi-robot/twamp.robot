#########################################################################################################################
#
# File Name:           twamp.robot                 
# Description:         This script demonstrates the use of Spirent HLTAPI to setup twamp in B2B mode.
#                      
# Test Steps:          
#                    1. Reserve and connect chassis ports
#                    2. Create devices on port1 and port2
#                    3. Create twamp client on device1 on port1
#                    4. Create twamp server on device2 on port2
#                    5. Create twamp session1 on twamp client 
#                    6. Create twamp session2 on twamp client 
#                    7. Start twamp server and client
#                    8. Get twamp server and client results
#                    9. Stop twamp server and client 
#                    10. Release resources
#                                                                       
# Topology:
#                    STC Port2                      STC Port1                       
#                 [twamp server]------------------[twamp client]
#                                                                         
#  
################################################################################
# 
# Run sample:
#            c:\>robot twamp.robot
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
Twamp Test

##############################################################
#config the parameters for the logging
##############################################################

    ${test_sta} =  test config  log=1   logfile=twamp_logfile   vendorlogfile=twamp_stcExport   vendorlog=1   hltlog=1   hltlogfile=twamp_hltExport   hlt2stcmappingfile=twamp_hlt2StcMapping   hlt2stcmapping=1   log_level=7

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
#Step 2. Create devices on port1 and port2
##############################################################

    #start to create the device: Host 1

    ${device_ret0} =  emulation device config  mode=create   ip_version=ipv4   count=1   router_id=192.0.0.1   enable_ping_response=0   encapsulation=ethernet_ii   port_handle=${port1}   mac_addr=00:10:94:00:00:01   mac_addr_step=00:00:00:00:00:01   intf_ip_addr=192.85.1.3   intf_prefix_len=24   resolve_gateway_mac=true   gateway_ip_addr=192.85.1.1   gateway_ip_addr_step=0.0.0.0   intf_ip_addr_step=0.0.0.1

    ${status} =  Get From Dictionary  ${device_ret0}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun emulation device config failed\n${device_ret0}
    ...  ELSE  Log To Console  \n***** run emulation device config successfully

    ${devicehandle1} =  Get From Dictionary  ${device_ret0}  handle

    #start to create the device: Host 2

    ${device_ret1} =  emulation device config  mode=create   ip_version=ipv4   count=1   router_id=192.0.0.2   enable_ping_response=0   encapsulation=ethernet_ii   port_handle=${port2}   mac_addr=00:10:94:00:00:02   mac_addr_step=00:00:00:00:00:01   intf_ip_addr=192.85.1.1   intf_prefix_len=24   resolve_gateway_mac=true   gateway_ip_addr=192.85.1.3   gateway_ip_addr_step=0.0.0.0   intf_ip_addr_step=0.0.0.1

    ${status} =  Get From Dictionary  ${device_ret1}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun emulation device config failed\n${device_ret1}
    ...  ELSE  Log To Console  \n***** run emulation device config successfully

    ${devicehandle2} =  Get From Dictionary  ${device_ret1}  handle

##############################################################
#Step 3. Create twamp client on device1 on port1
##############################################################

    ${device_cfg_ret0} =  emulation twamp config  mode=create   handle=${devicehandle1}   type=client   peer_ipv4_addr=192.85.1.1   ip_version=ipv4   connection_retry_cnt=200   connection_retry_interval=40   scalability_mode=normal

    ${status} =  Get From Dictionary  ${device_cfg_ret0}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun emulation twamp config failed\n${device_cfg_ret0}
    ...  ELSE  Log To Console  \n***** run emulation twamp config successfully

##############################################################
#Step 4. Create twamp server on device2 on port2
##############################################################   

    ${device_cfg_ret1} =  emulation twamp config  mode=create   handle=${devicehandle2}   type=server   server_ip_version=ipv4   server_willing_to_participate=true   server_mode=unauthenticated

    ${status} =  Get From Dictionary  ${device_cfg_ret1}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun emulation twamp config failed\n${device_cfg_ret1}
    ...  ELSE  Log To Console  \n***** run emulation twamp config successfully

##############################################################
#Step  5. Create twamp session1 on twamp client
##############################################################

    ${device_cfg_ret0_sessionhandle_0} =  emulation twamp session config  mode=create   handle=${devicehandle1}   dscp=2   ttl=254   start_delay=6   session_name=TwampTestSession_1   frame_rate=50   session_src_udp_port=5451   session_dst_udp_port=5450   duration_mode=seconds   padding_pattern=random   padding_len=140   scalability_mode=normal   duration=120   timeout=60

    ${status} =  Get From Dictionary  ${device_cfg_ret0_sessionhandle_0}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun emulation twamp session config failed\n${device_cfg_ret0_sessionhandle_0}
    ...  ELSE  Log To Console  \n***** run emulation twamp session config successfully
    
##############################################################
#Step  6. Create twamp session2 on twamp client
##############################################################   

    ${device_cfg_ret0_sessionhandle_1} =  emulation twamp session config  mode=create   handle=${devicehandle1}   dscp=2   ttl=254   start_delay=6   session_name=TwampTestSession_2   frame_rate=50   session_src_udp_port=5453   session_dst_udp_port=5452   duration_mode=seconds   padding_pattern=random   padding_len=140   scalability_mode=normal   duration=120   timeout=60

    ${status} =  Get From Dictionary  ${device_cfg_ret0_sessionhandle_1}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun emulation twamp session config failed\n${device_cfg_ret0_sessionhandle_1}
    ...  ELSE  Log To Console  \n***** run emulation twamp session config successfully
    
#config part is finished
    
##############################################################
#Step7. Start twamp server and client
##############################################################

    ${ctrl_ret0} =  emulation twamp control  handle=${devicehandle2}   mode=start

    ${status} =  Get From Dictionary  ${ctrl_ret0}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun emulation twamp control failed\n${ctrl_ret0}
    ...  ELSE  Log To Console  \n***** run emulation twamp control successfully

    ${ctrl_ret1} =  emulation twamp control  handle=${devicehandle1}   mode=start

    ${status} =  Get From Dictionary  ${ctrl_ret1}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun emulation twamp control failed\n${ctrl_ret1}
    ...  ELSE  Log To Console  \n***** run emulation twamp control successfully

##############################################################
#Step8. Get twamp server and client results
##############################################################

    ${results_ret0} =  emulation twamp stats  port_handle=${port2}   mode=state_summary

    ${status} =  Get From Dictionary  ${results_ret0}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun emulation twamp stats failed\n${results_ret0}
    ...  ELSE  Log To Console  \n***** run emulation twamp stats successfully, and results is:\n${results_ret0}

    ${results_ret1} =  emulation twamp stats  port_handle=${port1}   mode=state_summary

    ${status} =  Get From Dictionary  ${results_ret1}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun emulation twamp stats failed\n${results_ret1}
    ...  ELSE  Log To Console  \n***** run emulation twamp stats successfully, and results is:\n${results_ret1}
    
##############################################################
#Step9. Stop twamp server and client
##############################################################

    ${ctrl_ret0} =  emulation twamp control  handle=${devicehandle2}   mode=stop

    ${status} =  Get From Dictionary  ${ctrl_ret0}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun emulation twamp control failed\n${ctrl_ret0}
    ...  ELSE  Log To Console  \n***** run emulation twamp control successfully

    ${ctrl_ret1} =  emulation twamp control  handle=${devicehandle1}   mode=stop

    ${status} =  Get From Dictionary  ${ctrl_ret1}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun emulation twamp control failed\n${ctrl_ret1}
    ...  ELSE  Log To Console  \n***** run emulation twamp control successfully
    
##############################################################
#Step10. Release resources
##############################################################

    ${cleanup_sta} =  cleanup session  port_handle=${port1} ${port2}   clean_dbfile=1

    ${status} =  Get From Dictionary  ${cleanup_sta}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun cleanup session failed\n${cleanup_sta}
    ...  ELSE  Log To Console  \n***** run cleanup session successfully

    Log To Console  \n**************Finish***************

