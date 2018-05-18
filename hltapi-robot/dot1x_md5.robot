################################################################################
#
# File Name:         dot1x_md5.robot
#
# Description:       This script demonstrates the use of Spirent HLTAPI to setup 802.1x devices by MD5 authentication.                  
#                                      
#
# Test Steps:        1. Reserve and connect chassis ports
#                    2. Configure interface (optional)
#                    3. Configure 10 802.1x supplicants
#                    4. Start 802.1x Authentication
#                    5. Check 802.1x Stats
#                    6. Stop 802.1x Authentication
#                    7. Release resources
#
# DUT configuration:omitted
#        
#
# Topology
#                 STC Port1----------------DUT---------------------Radius Server                   
#            [802.1x supplicant]    [Authenticator System]     [Authentication Server]
# 
################################################################################
# 
# Run sample:
#            c:\>robot dot1x_md5.robot

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
dot1x md5 test

##############################################################
#config the parameters for the logging
##############################################################

    ${test_sta} =  test config  log=1   logfile=dot1x_md5_logfile   vendorlogfile=dot1x_md5_stcExport   vendorlog=1   hltlog=1   hltlogfile=dot1x_md5_hltExport   hlt2stcmappingfile=dot1x_md5_hlt2StcMapping   hlt2stcmapping=1   log_level=7

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
# Step2: Configure interface
########################################

    ${int_ret0} =  interface config  mode=config   port_handle=${port1}   create_host=false   intf_mode=ethernet   phy_mode=fiber   scheduling_mode=RATE_BASED   port_loadunit=PERCENT_LINE_RATE   port_load=10   enable_ping_response=0   control_plane_mtu=1500   flow_control=false   speed=ether1000   data_path_mode=normal   autonegotiation=1

    ${status} =  Get From Dictionary  ${int_ret0}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun interface config failed\n${int_ret0}
    ...  ELSE  Log To Console  \n***** run interface config successfully

    ${int_ret1} =  interface config  mode=config   port_handle=${port2}   create_host=false   intf_mode=ethernet   phy_mode=fiber   scheduling_mode=RATE_BASED   port_loadunit=PERCENT_LINE_RATE   port_load=10   enable_ping_response=0   control_plane_mtu=1500   flow_control=false   speed=ether1000   data_path_mode=normal   autonegotiation=1

    ${status} =  Get From Dictionary  ${int_ret1}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun interface config failed\n${int_ret1}
    ...  ELSE  Log To Console  \n***** run interface config successfully

###########################################
# Step3: Configure 10 supplicants of 802.1x
###########################################

    ${device_ret0} =  emulation dot1x config  mode=create   ip_version=ipv4   username=spirent   password=spirent   encapsulation=ethernet_ii   port_handle=${port1}   supplicant_logoff_rate=300   max_authentications=600   supplicant_auth_rate=100   auth_retry_count=10   use_pae_group_mac=1   retransmit_interval=1000   authenticator_mac=00:10:94:00:00:02   eap_auth_method=md5   retransmit_count=300   auth_retry_interval=1000   mac_addr=00:10:94:00:00:04   mac_addr_step=00:00:00:00:00:01   local_ip_prefix_len=24   gateway_ip_addr=192.85.1.1   local_ip_addr_step=0.0.0.1   gateway_ip_addr_step=0.0.0.0   local_ip_addr=192.85.1.3   num_sessions=10   name=Dot1x_1

    ${status} =  Get From Dictionary  ${device_ret0}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun emulation dot1x config failed\n${device_ret0}
    ...  ELSE  Log To Console  \n***** run emulation dot1x config successfully

    ${dot1xHandle} =  Get From Dictionary  ${device_ret0}  handle

#config part is finished

####################
#Start to capture
####################
    Log To Console  \nStart to capture

    ${packet_control} =  packet control  port_handle=all  action=start

    ${status} =  Get From Dictionary  ${packet_control}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun packet control failed\n${packet_control}
    ...  ELSE  Log To Console  \n***** run packet control successfully

    Sleep  2s
    
########################################
# Step4: Start Authentication
########################################

    ${ctrl_ret1} =  emulation dot1x control  handle=${dot1xHandle}   mode=start

    ${status} =  Get From Dictionary  ${ctrl_ret1}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun emulation dot1x control failed\n${ctrl_ret1}
    ...  ELSE  Log To Console  \n***** run emulation dot1x control successfully

    Sleep  10s

###############################
#Stop capture and save packets
###############################
    Log To Console  \nStop capture and save packets

    ${packet_stats1} =  packet stats  port_handle=${port1}  action=filtered  stop=1  format=pcap  filename=port1.pcap

    ${packet_stats2} =  packet stats  port_handle=${port2}  action=filtered  stop=1  format=pcap  filename=port2.pcap

    ${status} =  Get From Dictionary  ${packet_stats1}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun packet control failed\n${packet_stats1}
    ...  ELSE  Log To Console  \n***** run packet control successfully

    ${status} =  Get From Dictionary  ${packet_stats2}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun packet control failed\n${packet_stats2}
    ...  ELSE  Log To Console  \n***** run packet control successfully

########################################
# Step5: Check 802.1x Stats
########################################     
 
    ${results_ret1} =  emulation dot1x stats  handle=${dot1xHandle}   mode=aggregate

    ${status} =  Get From Dictionary  ${results_ret1}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun emulation dot1x stats failed\n${results_ret1}
    ...  ELSE  Log To Console  \n***** run emulation dot1x stats successfully, and results is:\n${results_ret1}

    ${results_ret1} =  emulation dot1x stats  handle=${dot1xHandle}   mode=session

    ${status} =  Get From Dictionary  ${results_ret1}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun emulation dot1x stats failed\n${results_ret1}
    ...  ELSE  Log To Console  \n***** run emulation dot1x stats successfully, and results is:\n${results_ret1}

########################################
# Step6: Stop Authentication
######################################## 

    ${ctrl_ret1} =  emulation dot1x control  handle=${dot1xHandle}   mode=stop

    ${status} =  Get From Dictionary  ${ctrl_ret1}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun emulation dot1x control failed\n${ctrl_ret1}
    ...  ELSE  Log To Console  \n***** run emulation dot1x control successfully

    ${ctrl_ret1} =  emulation dot1x config  handle=${dot1xHandle}   mode=delete

    ${status} =  Get From Dictionary  ${ctrl_ret1}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun emulation dot1x control failed\n${ctrl_ret1}
    ...  ELSE  Log To Console  \n***** run emulation dot1x control successfully

##############################################################
# Step7. Release resources
##############################################################

    ${cleanup_sta} =  cleanup session  port_handle=${port1} ${port2}   clean_dbfile=1

    ${status} =  Get From Dictionary  ${cleanup_sta}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun cleanup session failed\n${cleanup_sta}
    ...  ELSE  Log To Console  \n***** run cleanup session successfully

    
    Log To Console  \n**************Finish***************

