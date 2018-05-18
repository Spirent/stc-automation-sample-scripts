#########################################################################################################################
#
# File Name:           fcoe_traffic.robot                 
# Description:         This script demonstrates the use of Spirent HLTAPI to setup FCoE_Traffic in B2B mode.
#                      
# Test Steps:          
#                    1. Reserve and connect chassis ports
#                    2. Genearte L2 Traffic on Port1 and Port2
#                    3. Create FCoE and FIP Raw Traffic 
#                    4. Run the Traffic
#                    5. Release resources
#                                                                       
# Topology:
#                                      
#                [STC  port1]---------[DUT]---------[STC  port2]
#                                                                         
#  
################################################################################
# 
# Run sample:
#            c:\>robot fcoe_traffic.robot
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
fcoe traffic test
    
##############################################################
#config the parameters for the logging
##############################################################

    ${test_sta} =  test config  log=1   logfile=fcoe_traffic_logfile   vendorlogfile=fcoe_traffic_stcExport   vendorlog=1   hltlog=1   hltlogfile=fcoe_traffic_hltExport   hlt2stcmappingfile=fcoe_traffic_hlt2StcMapping   hlt2stcmapping=1   log_level=7

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

#################################################
# Step2. Generate L2 Traffic on Port1 and Port2
#################################################

    ${streamblock_ret1} =  traffic config  mode=create   port_handle=${port1}   l2_encap=ethernet_ii   
    ...  transmit_mode=continuous   length_mode=fixed   l3_length=1002   rate_pps=1000

    ${status} =  Get From Dictionary  ${streamblock_ret1}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun traffic config failed\n${streamblock_ret1}
    ...  ELSE  Log To Console  \n***** run traffic config successfully

    ${sb1} =  Get From Dictionary  ${streamblock_ret1}  stream_id
    
    ${streamblock_ret2} =  traffic config  mode=create   port_handle=${port2}   l2_encap=ethernet_ii   
    ...  transmit_mode=continuous   length_mode=fixed   l3_length=1002   rate_pps=1000

    ${status} =  Get From Dictionary  ${streamblock_ret2}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun traffic config failed\n${streamblock_ret2}
    ...  ELSE  Log To Console  \n***** run traffic config successfully

    ${sb2} =  Get From Dictionary  ${streamblock_ret2}  stream_id

########################################
# Step3. Create FCoE and FIP Raw Traffic 
########################################

    ${stream_fcoe_ret} =  fcoe traffic config  handle=${sb1}   mode=create   sof=sofn3   eof=eofn   h_did=000000000   h_sid=000000
    ...  h_type=00   h_framecontrol=000000   h_seqid=00   h_dfctl=00   h_seqcnt=0000   h_origexchangeid=0000   pl_id=flogireq
    ...  pl_nodename=10:00:10:94:00:00:00:01

    ${status} =  Get From Dictionary  ${stream_fcoe_ret}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun fcoe traffic config failed\n${stream_fcoe_ret}
    ...  ELSE  Log To Console  \n***** run fcoe traffic config successfully

    ${streamblock_fip_ret} =  fip traffic config  mode=create   handle=${sb2}   fp=1   sp=0   a=0   f=0   s=0
    ...  dl_id=priority macaddr nameid fabricname fka_adv_period   priority=64   macaddr=00:10:94:00:00:01
    ...  nameid=10:00:10:94:00:00:00:01   fabricname=20:00:10:94:00:00:00:01 

    ${status} =  Get From Dictionary  ${streamblock_fip_ret}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun fip traffic config failed\n${streamblock_fip_ret}
    ...  ELSE  Log To Console  \n***** run fip traffic config successfully

#config part is finished
    
########################################
# Step4. Run the Traffic
########################################

    ${traffic_ctrl_ret} =  traffic control  port_handle=${port1} ${port2}   action=run

    ${status} =  Get From Dictionary  ${traffic_ctrl_ret}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun traffic control failed\n${traffic_ctrl_ret}
    ...  ELSE  Log To Console  \n***** run traffic control successfully

##############################################################
# Step5. Release resources
##############################################################

    ${cleanup_sta} =  cleanup session  port_handle=${port1} ${port2}   clean_dbfile=1

    ${status} =  Get From Dictionary  ${cleanup_sta}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun cleanup session failed\n${cleanup_sta}
    ...  ELSE  Log To Console  \n***** run cleanup session successfully

    
    Log To Console  \n**************Finish***************

