#########################################################################################################################
#
# File Name:           eoam_topology_itut_y1731_vlan.robot              
# Description:         This script demonstrates the use of Spirent HLTAPI to setup EOAM in B2B connection.
#                      
# Test Steps:          
#                    1. Reserve and connect chassis ports
#                    2. Configure EOAM 
#                    3. Start EOAM 
#                    4. Stop EOAM
#                    5. Get ports info
#                    6. Modify EOAM
#                    7. Start EOAM again
#                    8. Stop EOAM again
#                    9. Get ports info again
#                    10. Reset EOAM 
#                    11. Release resources
#                                                                       
# Topology:
#                      STC Port2                    STC Port1                       
#                     [EOAM port]------------------[EOAM port]
#                                                                         
#  
################################################################################
# 
# Run sample:
#            c:\>robot eoam_topology_itut_y1731_vlan.robot
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
    \  Log To Console  \nreserved ports: ${chass is} ${port} ${Rstatus}
    \  ${port_index}    Evaluate    ${port_index}+1
    \  Set Test Variable  ${port_index}  ${port_index}

*** Test Cases ***
eoam topology itut y1731 vlan test

##############################################################
#config the parameters for the logging
##############################################################

    ${test_sta} =  test config  log=1   logfile=eoam_topology_itut_y1731_vlan_logfile   vendorlogfile=eoam_topology_itut_y1731_vlan_stcExport   vendorlog=1   hltlog=1   hltlogfile=eoam_topology_itut_y1731_vlan_hltExport   hlt2stcmappingfile=eoam_topology_itut_y1731_vlan_hlt2StcMapping   hlt2stcmapping=1   log_level=7

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
# Step2. Configure EOAM 
########################################

    Log To Console  Configure EOAM on port1

    ${device_ret0} =  emulation oam config topology  mode=create   count=1   mip_count=2   mep_count=2   port_handle=${port1}   mac_local=00:94:01:00:02:01   mac_local_incr_mode=increment   mac_local_step=00:00:00:00:00:01   vlan_outer_id=1000   vlan_id=100   sut_ip_address=192.168.1.1   mep_id=1   mac_remote=00:94:01:10:01:01   mep_id_incr_mode=increment   mep_id_step=1   mac_remote_incr_mode=increment   mac_remote_step=00:00:00:00:00:01   continuity_check_mcast_mac_dst=true   continuity_check_burst_size=3   responder_link_trace=true   responder_loopback=true   continuity_check_remote_defect_indication=1   short_ma_name_value=Sh_MA_   md_name=DEFAULT   md_name_format=icc_based   oam_standard=itut_y1731   short_ma_name_format=char_str   continuity_check_interval=100ms   md_level=2   md_integer=4   md_mac=00:94:01:00:03:00   

    ${status} =  Get From Dictionary  ${device_ret0}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun emulation oam config topology failed\n${device_ret0}
    ...  ELSE  Log To Console  \n***** run emulation oam config topology successfully

    ${topHandleList1} =  Get From Dictionary  ${device_ret0}  handle

    Log To Console  Configure EOAM on port2

    ${device_ret1} =  emulation oam config topology  mode=create   count=1   mip_count=2   mep_count=2   port_handle=${port2}   mac_local=00:94:01:10:01:01   mac_local_incr_mode=increment   mac_local_step=00:00:00:00:00:01   vlan_outer_id=1000   vlan_id=100   sut_ip_address=192.168.1.1   mep_id=4   mac_remote=00:94:01:00:02:01   mep_id_incr_mode=increment   mep_id_step=1   mac_remote_incr_mode=increment   mac_remote_step=00:00:00:00:00:01   continuity_check_mcast_mac_dst=true   continuity_check_burst_size=3   responder_link_trace=true   responder_loopback=true   continuity_check_remote_defect_indication=1   short_ma_name_value=Sh_MA_   md_name=DEFAULT   md_name_format=icc_based   oam_standard=itut_y1731   short_ma_name_format=char_str   continuity_check_interval=100ms   md_level=2   md_integer=4   md_mac=00:94:01:00:02:00 

    ${status} =  Get From Dictionary  ${device_ret1}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun emulation oam config topology failed\n${device_ret1}
    ...  ELSE  Log To Console  \n***** run emulation oam config topology successfully

    ${topHandleList2} =  Get From Dictionary  ${device_ret1}  handle

#config part is finished
    
########################################
# Step3. Start EOAM 
########################################

    Log To Console  Start EOAM on port2

    ${ctrl_ret1} =  emulation oam control  handle=${topHandleList2}   action=start

    ${status} =  Get From Dictionary  ${ctrl_ret1}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun emulation oam control failed\n${ctrl_ret1}
    ...  ELSE  Log To Console  \n***** run emulation oam control successfully

    Sleep  10s

########################################
# Step4. Stop EOAM
########################################

    Log To Console  Stop EOAM on port2

    ${ctrl_ret1} =  emulation oam control  handle=${topHandleList2}   action=start

    ${status} =  Get From Dictionary  ${ctrl_ret1}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun emulation oam control failed\n${ctrl_ret1}
    ...  ELSE  Log To Console  \n***** run emulation oam control successfully

########################################
# Step5. Get ports info
########################################

    ${results_ret1} =  emulation oam info  port_handle=${port1}   mode=aggregate

    ${status} =  Get From Dictionary  ${results_ret1}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun emulation oam info failed\n${results_ret1}
    ...  ELSE  Log To Console  \n***** run emulation oam info successfully, and results is:\n${results_ret1}
    

    ${results_ret1} =  emulation oam info  port_handle=${port2}   mode=aggregate

    ${status} =  Get From Dictionary  ${results_ret1}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun emulation oam info failed\n${results_ret1}
    ...  ELSE  Log To Console  \n***** run emulation oam info successfully, and results is:\n${results_ret1}

########################################
# Step6. Modify EOAM
########################################
    
    Log To Console  Modify EOAM on port1

    ${device_ret0} =  emulation oam config topology  mode=modify   count=1   mip_count=2   mep_count=2   handle=${topHandleList1}   mac_local=00:94:01:00:02:01   mac_local_incr_mode=increment   mac_local_step=00:00:00:00:00:01   vlan_outer_id=100   vlan_id=1000   sut_ip_address=192.168.1.1   mep_id=10   mac_remote=00:94:01:10:01:01   mep_id_incr_mode=increment   mep_id_step=1   mac_remote_incr_mode=increment   mac_remote_step=00:00:00:00:00:01   continuity_check_mcast_mac_dst=true   continuity_check_burst_size=3   responder_link_trace=true   responder_loopback=true   continuity_check_remote_defect_indication=1   short_ma_name_value=Sh_MA_   md_name=DEFAULT   md_name_format=icc_based   oam_standard=itut_y1731   short_ma_name_format=char_str   continuity_check_interval=100ms   md_level=2

    ${status} =  Get From Dictionary  ${device_ret0}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun emulation oam config topology failed\n${device_ret0}
    ...  ELSE  Log To Console  \n***** run emulation oam config topology successfully

    ${topHandleList3} =  Get From Dictionary  ${device_ret0}  handle

########################################
# Step7. Start EOAM again
########################################

    Log To Console  Start EOAM on port2 again

    ${ctrl_ret1} =  emulation oam control  handle=${topHandleList2}   action=start

    ${status} =  Get From Dictionary  ${ctrl_ret1}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun emulation oam control failed\n${ctrl_ret1}
    ...  ELSE  Log To Console  \n***** run emulation oam control successfully

    Sleep  10s

########################################
# Step8. Stop EOAM again
########################################

    Log To Console  Stop EOAM on port2 again

    ${ctrl_ret1} =  emulation oam control  handle=${topHandleList2}   action=start

    ${status} =  Get From Dictionary  ${ctrl_ret1}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun emulation oam control failed\n${ctrl_ret1}
    ...  ELSE  Log To Console  \n***** run emulation oam control successfully

########################################
# Step9. Get ports info again
########################################

    ${results_ret1} =  emulation oam info  port_handle=${port1}   mode=aggregate

    ${status} =  Get From Dictionary  ${results_ret1}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun emulation oam info failed\n${results_ret1}
    ...  ELSE  Log To Console  \n***** run emulation oam info successfully, and results is:\n${results_ret1}
    

    ${results_ret1} =  emulation oam info  port_handle=${port2}   mode=aggregate

    ${status} =  Get From Dictionary  ${results_ret1}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun emulation oam info failed\n${results_ret1}
    ...  ELSE  Log To Console  \n***** run emulation oam info successfully, and results is:\n${results_ret1}

########################################
# Step10. Reset EOAM 
########################################

    Log To Console  Reset EOAM on port1

    ${ctrl_ret1} =  emulation oam control  handle=${topHandleList1}   action=reset

    ${status} =  Get From Dictionary  ${ctrl_ret1}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun emulation oam control failed\n${ctrl_ret1}
    ...  ELSE  Log To Console  \n***** run emulation oam control successfully

##############################################################
# Step11. Release resources
##############################################################  

    ${cleanup_sta} =  cleanup session  port_handle=${port1} ${port2}   clean_dbfile=1

    ${status} =  Get From Dictionary  ${cleanup_sta}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun cleanup session failed\n${cleanup_sta}
    ...  ELSE  Log To Console  \n***** run cleanup session successfully

    
    Log To Console  \n**************Finish***************

