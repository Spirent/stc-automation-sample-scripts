#########################################################################################################################
#
# File Name:           lacp.robot                 
# Description:         This script demonstrates the use of Spirent HLTAPI to setup LACP in B2B connection.
#                      
# Test Steps:          
#                    1. Reserve and connect chassis ports
#                    2. Configure interfaces
#                    3. Enable LACP
#                    4. Start LACP 
#                    5. Get LACP Info
#                    6. Stop LACP
#                    7. Retrive LACP statistics
#                    8. Release resources
#                                                                       
# Topology:
#                      STC Port2                    STC Port1                       
#                     [LACP port]------------------[LACP port]
#                                                                         
#  
################################################################################
# 
# Run sample:
#            c:\>robot lacp.robot
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
lacp test

##############################################################
#config the parameters for the logging
##############################################################
    

    ${test_sta} =  test config  log=1   logfile=lacp_logfile   vendorlogfile=lacp_stcExport   vendorlog=1   hltlog=1   hltlogfile=lacp_hltExport   hlt2stcmappingfile=lacp_hlt2StcMapping   hlt2stcmapping=1   log_level=7

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

############################################
# Step2: Configure interfaces             
############################################

    ${int_ret0} =  interface config  mode=config   port_handle=${port1}   create_host=false   intf_mode=ethernet   phy_mode=fiber   scheduling_mode=RATE_BASED   port_loadunit=PERCENT_LINE_RATE   port_load=10   enable_ping_response=0   control_plane_mtu=1500   flow_control=false   speed=ether1000   data_path_mode=normal   autonegotiation=1

    ${status} =  Get From Dictionary  ${int_ret0}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun interface config failed\n${int_ret0}
    ...  ELSE  Log To Console  \n***** run interface config successfully

    ${int_ret1} =  interface config  mode=config   port_handle=${port2}   create_host=false   intf_mode=ethernet   phy_mode=fiber   scheduling_mode=RATE_BASED   port_loadunit=PERCENT_LINE_RATE   port_load=10   enable_ping_response=0   control_plane_mtu=1500   flow_control=false   speed=ether1000   data_path_mode=normal   autonegotiation=1

    ${status} =  Get From Dictionary  ${int_ret1}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun interface config failed\n${int_ret1}
    ...  ELSE  Log To Console  \n***** run interface config successfully

############################################
# Step3: Enable LACP                       
############################################

    ${device_ret0} =  emulation lacp config  mode=enable   port_handle=${port1}   local_mac_addr=00:94:01:00:00:01   act_system_priority=1000   act_system_id=00:00:00:00:01:01   lacp_activity=active   act_port_number=10   act_lacp_port_priority=101   act_port_key=100   act_lacp_timeout=short

    ${status} =  Get From Dictionary  ${device_ret0}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun emulation lacp config failed\n${device_ret0}
    ...  ELSE  Log To Console  \n***** run emulation lacp config successfully


    ${device_ret1} =  emulation lacp config  mode=enable   port_handle=${port2}   local_mac_addr=00:94:02:00:00:02   act_system_priority=5000   act_system_id=00:00:00:00:01:01   lacp_activity=active   act_port_number=10   act_lacp_port_priority=501   act_port_key=500   act_lacp_timeout=short

    ${status} =  Get From Dictionary  ${device_ret1}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun emulation lacp config failed\n${device_ret1}
    ...  ELSE  Log To Console  \n***** run emulation lacp config successfully

    #config part is finished
    
############################################
#step4: Start LACP                          
############################################

    ${ctrl_ret1} =  emulation lacp control  port_handle=${port1}   action=start

    ${status} =  Get From Dictionary  ${ctrl_ret1}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun emulation lacp control failed\n${ctrl_ret1}
    ...  ELSE  Log To Console  \n***** run emulation lacp control successfully

    ${ctrl_ret2} =  emulation lacp control  port_handle=${port2}   action=start

    ${status} =  Get From Dictionary  ${ctrl_ret2}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun emulation lacp control failed\n${ctrl_ret2}
    ...  ELSE  Log To Console  \n***** run emulation lacp control successfully

    Sleep  10s

############################################
#step5: Get LACP Info                      
############################################

    ${results_ret1} =  emulation lacp info  port_handle=${port1}   mode=state   action=collect

    ${status} =  Get From Dictionary  ${results_ret1}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun emulation lacp info failed\n${results_ret1}
    ...  ELSE  Log To Console  \n***** run emulation lacp info successfully, and results is:\n${results_ret1}
    

    ${results_ret2} =  emulation lacp info  port_handle=${port2}   mode=state   action=collect

    ${status} =  Get From Dictionary  ${results_ret2}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun emulation lacp info failed\n${results_ret2}
    ...  ELSE  Log To Console  \n***** run emulation lacp info successfully, and results is:\n${results_ret2}

############################################
#step6: Stop LACP                           
############################################

    ${ctrl_ret1} =  emulation lacp control  port_handle=${port1}   action=stop

    ${status} =  Get From Dictionary  ${ctrl_ret1}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun emulation lacp control failed\n${ctrl_ret1}
    ...  ELSE  Log To Console  \n***** run emulation lacp control successfully

    ${ctrl_ret2} =  emulation lacp control  port_handle=${port2}   action=stop

    ${status} =  Get From Dictionary  ${ctrl_ret2}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun emulation lacp control failed\n${ctrl_ret2}
    ...  ELSE  Log To Console  \n***** run emulation lacp control successfully
    
############################################
#step7: Retrive LACP statistics             
############################################
    
    Sleep  10s

    ${results_ret1} =  emulation lacp info  port_handle=${port1}   mode=aggregate   action=collect

    ${status} =  Get From Dictionary  ${results_ret1}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun emulation lacp info failed\n${results_ret1}
    ...  ELSE  Log To Console  \n***** run emulation lacp info successfully, and results is:\n${results_ret1}
    

    ${results_ret2} =  emulation lacp info  port_handle=${port2}   mode=aggregate   action=collect

##############################################################
# Step8: Release resources
##############################################################

    ${cleanup_sta} =  cleanup session  port_handle=${port1} ${port2}   clean_dbfile=1

    ${status} =  Get From Dictionary  ${cleanup_sta}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun cleanup session failed\n${cleanup_sta}
    ...  ELSE  Log To Console  \n***** run cleanup session successfully

    
    Log To Console  \n**************Finish***************

