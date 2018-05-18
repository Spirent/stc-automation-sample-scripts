#########################################################################################################################
#
# File Name:           rfc2544.robot                
# Description:         This script demonstrates the use of Spirent HLTAPI to test RFC2544 includes latency, back to back,frame #                      loss,and throughput.
#                      
#                      
# Test Steps:          
#                    1. Reserve and connect chassis ports
#                    2. Configure interfaces
#                    3. Configure streamblock on two ports
#                    4. RFC2544 test                  
#                    5. Release resources
#                                                                       
# Topology:
#                      [STC port1]---------[DUT]---------[STC port2]          
#  
################################################################################
# 
# Run sample:
#            c:\>robot rfc2544.robot
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
rfc2544 test

##############################################################
#config the parameters for the logging
##############################################################

    ${test_sta} =  test config  log=1   logfile=rfc2544_logfile   vendorlogfile=rfc2544_stcExport   vendorlog=1   hltlog=1   hltlogfile=rfc2544_hltExport   hlt2stcmappingfile=rfc2544_hlt2StcMapping   hlt2stcmapping=1   log_level=7

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
#Step2. Configure interfaces
##############################################################

    ${int_ret0} =  interface config  mode=config   port_handle=${port1}   create_host=false   intf_mode=ethernet  scheduling_mode=PORT_BASED   port_loadunit=PERCENT_LINE_RATE   port_load=22   intf_ip_addr=192.168.1.10   resolve_gateway_mac=true   gateway_step=0.0.0.0   gateway=192.168.1.100   dst_mac_addr=00:00:01:00:00:01   intf_ip_addr_step=0.0.0.1   netmask=255.255.255.255   enable_ping_response=0   control_plane_mtu=1500   pfc_negotiate_by_dcbx=0   speed=ether10000   duplex=full   autonegotiation=1   alternate_speeds=0

    ${status} =  Get From Dictionary  ${int_ret0}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun interface config failed\n${int_ret0}
    ...  ELSE  Log To Console  \n***** run interface config successfully

    ${int_ret1} =  interface config  mode=config   port_handle=${port2}   create_host=false   intf_mode=ethernet   scheduling_mode=RATE_BASED   port_loadunit=PERCENT_LINE_RATE   port_load=10   intf_ip_addr=192.168.1.100   resolve_gateway_mac=true   gateway_step=0.0.0.0   gateway=192.168.1.10   dst_mac_addr=00:00:01:00:00:01   intf_ip_addr_step=0.0.0.1   netmask=255.255.255.255   enable_ping_response=0   control_plane_mtu=1500   pfc_negotiate_by_dcbx=0   speed=ether10000   duplex=full   autonegotiation=1   alternate_speeds=0

    ${status} =  Get From Dictionary  ${int_ret1}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun interface config failed\n${int_ret1}
    ...  ELSE  Log To Console  \n***** run interface config successfully

##############################################################
#Step3. Configure streamblock on two ports
##############################################################

    ${streamblock_ret1} =  traffic config  mode=create   port_handle=${port1}   l2_encap=ethernet_ii   l3_protocol=ipv4   
    ...  l3_length=256   length_mode=fixed   ip_src_addr=192.168.1.10   ip_dst_addr=192.168.1.100   mac_discovery_gw=192.168.1.100
    ...  mac_dst=00:10:94:00:00:03   mac_src=00:10:94:00:00:02

    ${status} =  Get From Dictionary  ${streamblock_ret1}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun traffic config failed\n${streamblock_ret1}
    ...  ELSE  Log To Console  \n***** run traffic config successfully

    ${streamblock1} =  Get From Dictionary  ${streamblock_ret1}  stream_id

    ${streamblock_ret2} =  traffic config  mode=create   port_handle=${port2}   l2_encap=ethernet_ii   l3_protocol=ipv4   
    ...  l3_length=256   length_mode=fixed   ip_src_addr=192.168.1.100   ip_dst_addr=192.168.1.10   mac_discovery_gw=192.168.1.10
    ...  mac_dst=00:10:94:00:00:02   mac_src=00:10:94:00:00:03

    ${status} =  Get From Dictionary  ${streamblock_ret2}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun traffic config failed\n${streamblock_ret2}
    ...  ELSE  Log To Console  \n***** run traffic config successfully

    ${streamblock2} =  Get From Dictionary  ${streamblock_ret2}  stream_id

########################################
# Step4. RFC2544 test
########################################

#test 1 -- Latency Test:

    Log To Console  \n+++++ Start to create test 1 -- Latency Test:

    ${latency_config} =  test rfc2544 config  mode=create  streamblock_handle=${streamblock1}  test_type=latency  traffic_pattern=pair
    ...  endpoint_creation=0  bidirectional=0  iteration_count=1  latency_type=FIFO  start_traffic_delay=1  stagger_start_delay=1
    ...  delay_after_transmission=10  frame_size_mode=custom  frame_size=1024  test_duration_mode=seconds  test_duration=10
    ...  load_unit=percent_line_rate  load_type=step  load_start=20  load_step=10  load_end=30

    ${status} =  Get From Dictionary  ${latency_config}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun rfc2544 config failed\n${latency_config}
    ...  ELSE  Log To Console  \n***** run rfc2544 config successfully\n${latency_config}

    Log To Console  \n+++++ Start to run test 1 -- Latency Test:

    ${ctrl_ret1} =  test rfc2544 control  action=run   wait=1

    ${status} =  Get From Dictionary  ${ctrl_ret1}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun test rfc2544 control failed\n${ctrl_ret1}
    ...  ELSE  Log To Console  \n***** run test rfc2544 control successfully

    Log To Console  \n+++++ Start to get results of test 1 -- mixed class throughput test :

    ${results_ret1} =  test rfc2544 info  test_type=latency   clear_result=0

    ${status} =  Get From Dictionary  ${results_ret1}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun test rfc2544 info failed\n${results_ret1}
    ...  ELSE  Log To Console  \n***** run test rfc2544 info successfully, and results is:\n${results_ret1}

#test 2 -- Back to Back Test:

    Log To Console  \n+++++ Start to create test 2 -- Back to Back Test:

    ${b2b_config} =  test rfc2544 config  mode=create  streamblock_handle=${streamblock1}  test_type=b2b  traffic_pattern=pair
    ...  endpoint_creation=0  bidirectional=0  iteration_count=1  latency_type=FIFO  start_traffic_delay=2  stagger_start_delay=1
    ...  delay_after_transmission=10  frame_size_mode=custom  frame_size=1024  test_duration_mode=seconds  test_duration=10

    ${status} =  Get From Dictionary  ${b2b_config}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun rfc2544 config failed\n${b2b_config}
    ...  ELSE  Log To Console  \n***** run rfc2544 config successfully\n${b2b_config}

    Log To Console  \n+++++ Start to run test 2 -- Back to Back Test:

    ${ctrl_ret1} =  test rfc2544 control  action=run   wait=1

    ${status} =  Get From Dictionary  ${ctrl_ret1}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun test rfc2544 control failed\n${ctrl_ret1}
    ...  ELSE  Log To Console  \n***** run test rfc2544 control successfully

    Log To Console  \n+++++ Start to get results of test 2 -- Back to Back Test:

    ${results_ret1} =  test rfc2544 info  test_type=b2b   clear_result=0

    ${status} =  Get From Dictionary  ${results_ret1}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun test rfc2544 info failed\n${results_ret1}
    ...  ELSE  Log To Console  \n***** run test rfc2544 info successfully, and results is:\n${results_ret1}

#test 3 -- Frame Loss Test:

    Log To Console  \n+++++ Start to create test 3 -- Frame Loss Test:

    ${fl_config} =  test rfc2544 config  mode=create  streamblock_handle=${streamblock1}  test_type=fl  traffic_pattern=pair
    ...  endpoint_creation=0  bidirectional=0  iteration_count=1  latency_type=FIFO  start_traffic_delay=1  stagger_start_delay=1
    ...  delay_after_transmission=10  frame_size_mode=custom  frame_size=1024  test_duration_mode=seconds  test_duration=10
    ...  load_type=step  load_start=100  load_step=50  load_end=50

    ${status} =  Get From Dictionary  ${fl_config}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun rfc2544 config failed\n${fl_config}
    ...  ELSE  Log To Console  \n***** run rfc2544 config successfully\n${fl_config}

    Log To Console  \n+++++ Start to run test 3 -- Frame Loss Test:

    ${ctrl_ret1} =  test rfc2544 control  action=run   wait=1

    ${status} =  Get From Dictionary  ${ctrl_ret1}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun test rfc2544 control failed\n${ctrl_ret1}
    ...  ELSE  Log To Console  \n***** run test rfc2544 control successfully

    Log To Console  \n+++++ Start to get results of test 3 -- Frame Loss Test:

    ${results_ret1} =  test rfc2544 info  test_type=fl   clear_result=0

    ${status} =  Get From Dictionary  ${results_ret1}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun test rfc2544 info failed\n${results_ret1}
    ...  ELSE  Log To Console  \n***** run test rfc2544 info successfully, and results is:\n${results_ret1}

#test 4 -- Throughput Test:

    Log To Console  \n+++++ Start to create test 4 -- Throughput Test:

    ${tput_config} =  test rfc2544 config  mode=create  streamblock_handle=${streamblock1}  test_type=throughput  traffic_pattern=pair
    ...  endpoint_creation=0  bidirectional=0  iteration_count=1  latency_type=FIFO  start_traffic_delay=1  stagger_start_delay=1
    ...  delay_after_transmission=10  frame_size_mode=custom  frame_size=1024  test_duration_mode=seconds  test_duration=10
    ...  search_mode=binary  rate_lower_limit=20  rate_upper_limit=22  initial_rate=21

    ${status} =  Get From Dictionary  ${tput_config}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun rfc2544 config failed\n${tput_config}
    ...  ELSE  Log To Console  \n***** run rfc2544 config successfully\n${tput_config}

    Log To Console  \n+++++ Start to run test 4 -- Throughput Test:

    ${ctrl_ret1} =  test rfc2544 control  action=run   wait=1

    ${status} =  Get From Dictionary  ${ctrl_ret1}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun test rfc2544 control failed\n${ctrl_ret1}
    ...  ELSE  Log To Console  \n***** run test rfc2544 control successfully

    Log To Console  \n+++++ Start to get results of test 4 -- Throughput Test:

    ${results_ret1} =  test rfc2544 info  test_type=throughput   clear_result=0

    ${status} =  Get From Dictionary  ${results_ret1}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun test rfc2544 info failed\n${results_ret1}
    ...  ELSE  Log To Console  \n***** run test rfc2544 info successfully, and results is:\n${results_ret1}

#config part is finished

##############################################################
# Step5. Release resources
##############################################################

    ${cleanup_sta} =  cleanup session  port_handle=${port1} ${port2}   clean_dbfile=1

    ${status} =  Get From Dictionary  ${cleanup_sta}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun cleanup session failed\n${cleanup_sta}
    ...  ELSE  Log To Console  \n***** run cleanup session successfully

    
    Log To Console  \n**************Finish***************

