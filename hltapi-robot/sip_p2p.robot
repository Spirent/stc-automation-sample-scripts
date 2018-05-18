#########################################################################################################################
#
# File Name:           sip_p2p.robot                 
# Description:         This script demonstrates the use of Spirent HLTAPI to setup SIP in Peer-to-Peer scenario.
#                      
# Test Steps:          
#                    1. Reserve and connect chassis ports
#                    2. Configure SIP callees
#                    3. Configure SIP callers
#                    4. Establish a call between callers and callees(no registering in P2P scenario)
#                    5. Retrieve statistics
#                    6. Clear statistics
#                    7. Retrieve statistics again
#                    8. Delete SIP hosts
#                    9. Release resources
#                                                                       
# Topology:
#                    STC Port2                       STC Port1                       
#                  [SIP caller]---------------------[SIP callee]
#                                                                         
#  
################################################################################
# 
# Run sample:
#            c:\>robot sip_p2p.py
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
sip p2p test
    [Documentation]  SIP p2p Test

##############################################################
#config the parameters for the logging
##############################################################

    ${test_sta} =  test config  log=1   logfile=sip_p2p_logfile   vendorlogfile=sip_p2p_stcExport   vendorlog=1   hltlog=1   hltlogfile=sip_p2p_hltExport   hlt2stcmappingfile=sip_p2p_hlt2StcMapping   hlt2stcmapping=1   log_level=7

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
# Step2. Configure SIP callees
######################################## 

    ${device_ret0} =  emulation sip config  mode=create   remote_host=192.1.0.1   remote_host_repeat=0   remote_host_step=1   call_using_aor=1   registrar_address=0.0.0.0   media_port_number=50050   response_delay_interval=0   use_compact_headers=0   video_type=H_263   call_duration=300   video_port_number=50052   call_type=AUDIO_ONLY   desired_expiry_time=3600   media_payload_type=SIP_MEDIA_ITU_G711_64K_160BYTE   proxy_server_port=5060   registration_server_enable=0   port_handle=${port1}   router_id=192.0.0.1   count=2   local_username_prefix=callee   local_username_suffix_step=3   user_agents_per_device=1   local_port=5060   name=Callee1   local_username_suffix=1000   remote_ip_addr=192.1.0.1   remote_ip_addr_repeat=1   local_ip_addr_step=1   remote_ip_addr_step=0   local_ip_addr=192.1.0.15   local_ip_addr_repeat=1   mac_address_start=00:10:94:00:00:01

    ${status} =  Get From Dictionary  ${device_ret0}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun emulation sip config failed\n${device_ret0}
    ...  ELSE  Log To Console  \n***** run emulation sip config successfully

    ${sipCallee} =  Get From Dictionary  ${device_ret0}  handle

########################################
# Step3. Configure SIP callers
########################################

    ${device_ret1} =  emulation sip config  mode=create   remote_host=192.1.0.15   remote_host_repeat=1   remote_host_step=1   call_using_aor=1   registrar_address=0.0.0.0   media_port_number=50050   response_delay_interval=0   use_compact_headers=0   video_type=H_263   call_duration=300   video_port_number=50052   call_type=AUDIO_ONLY   desired_expiry_time=3600   media_payload_type=SIP_MEDIA_ITU_G711_64K_160BYTE   proxy_server_port=5060   registration_server_enable=0   port_handle=${port2}   router_id=192.0.0.1   count=2   local_username_prefix=caller   local_username_suffix_step=3   user_agents_per_device=1   local_port=5060   name=Caller1   local_username_suffix=3000   remote_ip_addr=192.1.0.15   remote_ip_addr_repeat=1   local_ip_addr_step=1   remote_ip_addr_step=0   local_ip_addr=192.1.0.1   local_ip_addr_repeat=1   mac_address_start=00:10:94:00:01:03

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
    
################################################################################
# Step4. Establish a call between callers and callees(no registering in P2P scenario)
################################################################################ 

    ${ctrl_ret1} =  emulation sip control  handle=${sipCaller}   action=register

    ${status} =  Get From Dictionary  ${ctrl_ret1}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun emulation sip control failed\n${ctrl_ret1}
    ...  ELSE  Log To Console  \n***** run emulation sip control successfully

    Sleep  5s

    ${ctrl_ret1} =  emulation sip control  handle=${sipCaller}   action=terminate

    ${status} =  Get From Dictionary  ${ctrl_ret1}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun emulation sip control failed\n${ctrl_ret1}
    ...  ELSE  Log To Console  \n***** run emulation sip control successfully

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

########################################
# Step5. Retrieve statistics
########################################

    ${results_ret1} =  emulation sip stats  handle=${sipCaller} ${sipCallee}   mode=device   action=collect

    ${status} =  Get From Dictionary  ${results_ret1}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun emulation sip stats failed\n${results_ret1}
    ...  ELSE  Log To Console  \n***** run emulation sip stats successfully, and results is:\n${results_ret1}
 
########################################
# Step6. Clear statistics
########################################

    ${results_ret1} =  emulation sip stats  handle=${sipCaller}   mode=device   action=clear

    ${status} =  Get From Dictionary  ${results_ret1}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun emulation sip stats failed\n${results_ret1}
    ...  ELSE  Log To Console  \n***** run emulation sip stats successfully, and results is:\n${results_ret1}

########################################
# Step7. Retrieve statistics again
########################################

    ${results_ret1} =  emulation sip stats  handle=${sipCaller} ${sipCallee}   mode=device   action=collect

    ${status} =  Get From Dictionary  ${results_ret1}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun emulation sip stats failed\n${results_ret1}
    ...  ELSE  Log To Console  \n***** run emulation sip stats successfully, and results is:\n${results_ret1}

########################################
# Step8. Delete SIP hosts
########################################

    ${device_ret1} =  emulation sip config  handle=${sipCaller}   mode=delete

    ${status} =  Get From Dictionary  ${device_ret1}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun emulation sip config failed\n${device_ret1}
    ...  ELSE  Log To Console  \n***** run emulation sip config successfully, and results is:\n${device_ret1}

    ${device_ret1} =  emulation sip config  handle=${sipCallee}   mode=delete

    ${status} =  Get From Dictionary  ${device_ret1}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun emulation sip config failed\n${device_ret1}
    ...  ELSE  Log To Console  \n***** run emulation sip config successfully, and results is:\n${device_ret1}

##############################################################
# Step9. Release resources
##############################################################

    ${cleanup_sta} =  cleanup session  port_handle=${port1} ${port2}   clean_dbfile=1

    ${status} =  Get From Dictionary  ${cleanup_sta}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun cleanup session failed\n${cleanup_sta}
    ...  ELSE  Log To Console  \n***** run cleanup session successfully

    
    Log To Console  \n**************Finish***************
   

