#########################################################################################################################
#
# File Name:           sip_proxyserver.robot                 
# Description:         This script demonstrates the use of Spirent HLTAPI to setup SIP in proxy server scenario.
#                      If the DUT doesn't support SIP proxy server,the register will fail.
#                      
# Test Steps:          
#                    1. Reserve and connect chassis ports
#                    2. Configure SIP proxy server
#                    3. Configure SIP caller
#                    4. Register caller and callee
#                    5. Check register state before establishing sip call
#                    6. Establish a call between caller and callee via proxy server, initiated by sip caller
#                    7. Release resources 
#                                                                       
# Topology:
#                    STC Port2                      STC Port1                       
#                  [SIP caller]------------------[SIP proxy server]----------------[SIP callee]
#                                                                         
#  
###########################################################################################################################
# 
# Run sample:
#            c:\>sip_proxyserver.robot
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
SIP Proxy Server Test
    [Documentation]  SIP Proxy Server Test

##############################################################
#config the parameters for the logging
##############################################################

    ${test_sta} =  test config  log=1   logfile=sip_proxyserver_logfile   vendorlogfile=sip_proxyserver_stcExport   vendorlog=1   hltlog=1   hltlogfile=sip_proxyserver_hltExport   hlt2stcmappingfile=sip_proxyserver_hlt2StcMapping   hlt2stcmapping=1   log_level=7

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

########################################
# Step2. Configure SIP proxy server
########################################

    ${device_ret0} =  emulation sip config  mode=create   remote_username_prefix=caller   remote_username_suffix=300   remote_username_suffix_step=3   registrar_address=150.1.0.5   media_port_number=50550   response_delay_interval=0   use_compact_headers=0   video_type=H_263   call_duration=300   video_port_number=50052   call_type=AUDIO_ONLY   desired_expiry_time=100000   media_payload_type=SIP_MEDIA_ITU_G711_64K_160BYTE   proxy_server_port=5060   registration_server_enable=1   vlan_id_mode1=fixed   port_handle=${port1}   vlan_ether_type1=0x8100   vlan_id1=500   vlan_id_step1=0   router_id=192.0.0.1   count=10   local_username_prefix=callee   local_username_suffix_step=3   user_agents_per_device=1   local_port=5060   name=Callee1   local_username_suffix=1000   remote_ip_addr=150.1.0.1   remote_ip_addr_repeat=1   local_ip_addr_step=1   remote_ip_addr_step=0   local_ip_addr=150.1.0.5   local_ip_addr_repeat=1   mac_address_start=00:10:94:00:00:01

    ${status} =  Get From Dictionary  ${device_ret0}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun emulation sip config failed\n${device_ret0}
    ...  ELSE  Log To Console  \n***** run emulation sip config successfully

    ${sipCallee} =  Get From Dictionary  ${device_ret0}  handle

########################################
# Step3. Configure SIP caller
########################################

    ${device_ret1} =  emulation sip config  mode=create   remote_username_prefix=callee   remote_username_suffix=1000   remote_username_suffix_step=3   registrar_address=150.1.0.5   media_port_number=50550   response_delay_interval=0   use_compact_headers=0   video_type=H_263   call_duration=300   video_port_number=50052   call_type=AUDIO_ONLY   desired_expiry_time=100000   media_payload_type=SIP_MEDIA_ITU_G711_64K_160BYTE   proxy_server_port=5060   registration_server_enable=1   vlan_id_mode1=fixed   port_handle=${port2}   vlan_ether_type1=0x8100   vlan_id1=600   vlan_id_step1=0   router_id=192.0.0.1   count=10   local_username_prefix=caller   local_username_suffix_step=3   user_agents_per_device=1   local_port=5060   name=Caller1   local_username_suffix=300   remote_ip_addr=160.1.0.1   remote_ip_addr_repeat=1   local_ip_addr_step=1   remote_ip_addr_step=0   local_ip_addr=160.1.0.2   local_ip_addr_repeat=1   mac_address_start=00:10:94:00:10:03

    ${status} =  Get From Dictionary  ${device_ret1}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun emulation sip config failed\n${device_ret1}
    ...  ELSE  Log To Console  \n***** run emulation sip config successfully

    ${sipCaller} =  Get From Dictionary  ${device_ret1}  handle

#config part is finished

####################
#Start to capture
####################
    Log To Console  Start to capture

    ${packet_control} =  packet control  port_handle=all  action=start

    ${status} =  Get From Dictionary  ${packet_control}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun packet control failed\n${packet_control}
    ...  ELSE  Log To Console  \n***** run packet control successfully

########################################
# Step4. Register caller and callee
########################################

    ${handleList} =  Create List  ${sipCallee}  ${sipCaller}
    
    ${sipHandle} =  Set Variable  ${EMPTY}
    
    :FOR  ${sipHandle}  IN  @{handleList}
    \  ${ctrl_ret1} =  emulation sip control  handle=${sipHandle}  action=register
    \  ${status} =  Get From Dictionary  ${ctrl_ret1}  status
    \  Run Keyword If  ${status} == 0  Log To Console  \nrun emulation sip control failed\n${ctrl_ret1}  ELSE  Log To Console  \n***** run emulation sip control successfully,the return of register is ${ctrl_ret1}
    
    Sleep  10s

#########################################################
# Step5. Check register state before establishing sip call
######################################################### 
    
    ${stateFlag} =  Set Variable  0
    ${sipHandle} =  Set Variable  ${EMPTY}
    :FOR  ${sipHandle}  IN  @{handleList} 
    \  ${results_ret1} =  emulation sip stats  handle=${sipHandle}   mode=device   action=collect
    \  ${status} =  Get From Dictionary  ${results_ret1}  status
    \  Run Keyword If  ${status} == 0  Log To Console  \nrun emulation sip stats failed\n${results_ret1}  ELSE  Log To Console  \n***** run emulation sip stats successfully, and results is:\n${results_ret1}

# Enum: NOT_REGISTERED|REGISTERING|REGISTRATION_SUCCEEDED|REGISTRATION_FAILED|REGISTRATION_CANCELED|UNREGISTERING

    \  ${regState} =  Evaluate  ${results_ret1}['${sipHandle}']['registration_state']
    \  ${regState} =  set variable  ${regState}
    \  Run Keyword If  '${regState}' != 'REGISTRATION_SUCCEEDED'   Log To Console  \nFailed to register ${sipHandle}
       ...  ELSE  Log To Console  \nRegistered Successfully,and the register state is ${regState}

##############################
#Stop capture and save packets
##############################
    Log To Console  Stop capture and save packets

    ${packet_stats1} =  packet stats  port_handle=${port1}  action=filtered  stop=1  format=pcap  filename=port1.pcap

    ${packet_stats2} =  packet stats  port_handle=${port2}  action=filtered  stop=1  format=pcap  filename=port2.pcap

    ${status} =  Get From Dictionary  ${packet_stats1}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun packet control failed\n${packet_stats1}
    ...  ELSE  Log To Console  \n***** run packet control successfully

    ${status} =  Get From Dictionary  ${packet_stats2}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun packet control failed\n${packet_stats2}
    ...  ELSE  Log To Console  \n***** run packet control successfully


###########################################################################################
# Step6. Establish a call between caller and callee via proxy server, initiated by sip caller
###########################################################################################    
    
    ${establish} =  emulation sip control  handle=${sipCaller}   action=establish

    ${status} =  Get From Dictionary  ${establish}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun emulation sip control failed\n${establish}
    ...  ELSE  Log To Console  \n***** run emulation sip control successfully, and results is:\n${establish}
    
##############################################################
# Step7. Release resources
##############################################################

    ${cleanup_sta} =  cleanup session  port_handle=${port1} ${port2}   clean_dbfile=1

    ${status} =  Get From Dictionary  ${cleanup_sta}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun cleanup session failed\n${cleanup_sta}
    ...  ELSE  Log To Console  \n***** run cleanup session successfully

    
    Log To Console  \n**************Finish***************



