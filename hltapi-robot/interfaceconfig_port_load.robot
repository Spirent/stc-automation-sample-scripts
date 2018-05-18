################################################################################
#
# File Name:                 interfaceconfig_port_load.robot
#
# Description:               This script demonstrates how to configure interface and check speed of the interface.
#
# Test steps:               
#                            1. Reserve and connect chassis ports
#                            2. Configure interface
#                            3. Check interface stats
#                            4. Release resources
#
# Topology:
#                            STC port1  ---------------- STC port2 
#
################################################################################
# 
# Run sample:
#            c:\>robot interfaceconfig_port_load.robot

*** Settings ***
Documentation  Get libraries
Library           BuiltIn
Library           Collections
Library           sth.py

*** Variables ***
${speed}         ether10000

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
interface config and port load test
    
##############################################################
#config the parameters for the logging
##############################################################

    ${test_sta} =  test config  log=1   logfile=interfaceconfig_port_load_logfile   vendorlogfile=interfaceconfig_port_load_stcExport   vendorlog=1   hltlog=1   hltlogfile=interfaceconfig_port_load_hltExport   hlt2stcmappingfile=interfaceconfig_port_load_hlt2StcMapping   hlt2stcmapping=1   log_level=7

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

##############################################################
#Step2: Configure interface
##############################################################

    ${int_ret0} =  interface config  mode=config   port_handle=${port1}   create_host=false   intf_mode=ethernet   phy_mode=copper   scheduling_mode=PORT_BASED   port_loadunit=PERCENT_LINE_RATE   port_load=100   enable_ping_response=0   control_plane_mtu=1500   pfc_negotiate_by_dcbx=0   speed=${speed}   duplex=full   autonegotiation=1   alternate_speeds=0

    ${status} =  Get From Dictionary  ${int_ret0}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun interface config failed\n${int_ret0}
    ...  ELSE  Log To Console  \n***** run interface config successfully

    ${int_ret1} =  interface config  mode=config   port_handle=${port2}   create_host=false   intf_mode=ethernet   phy_mode=copper   scheduling_mode=RATE_BASED   port_loadunit=PERCENT_LINE_RATE   port_load=10   enable_ping_response=0   control_plane_mtu=1500   pfc_negotiate_by_dcbx=0   speed=${speed}   duplex=full   autonegotiation=1

    ${status} =  Get From Dictionary  ${int_ret1}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun interface config failed\n${int_ret1}
    ...  ELSE  Log To Console  \n***** run interface config successfully

##############################################################
#Step3: Check interface stats
##############################################################

    ${int_stats} =  interface stats  port_handle=${port1}

    ${status} =  Get From Dictionary  ${int_stats}  status
    Run Keyword If  ${status} == 0  Log To Console  \nGet interface stats failed\n${int_stats}
    ...  ELSE  Log To Console  \n***** Get interface stats successfully,the stats are:${int_stats}

    ${validspeed} =  Get From Dictionary  ${int_stats}  intf_speed

    Run Keyword If  ${validspeed} == 10000  Log To Console  \n Set port speed of port1 to 10G successfully
    ...  ELSE  Log To Console  Supported port speed of port1 is : ${validspeed}
    
##############################################################
# Step4. Release resources
##############################################################

    ${cleanup_sta} =  cleanup session  port_handle=${port1} ${port2}   clean_dbfile=1

    ${status} =  Get From Dictionary  ${cleanup_sta}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun cleanup session failed\n${cleanup_sta}
    ...  ELSE  Log To Console  \n***** run cleanup session successfully

    
    Log To Console  \n**************Finish***************

