#################################
#
# File Name:         ospfv2_topylogy_enhance.robot
#
# Description:       This script demonstrates the use of Spirent HLTAPI to setup OSPFv2 with enhancement for 
#                    emulation_ospf_topology_route_config.                  
#                    1)For these LSAs (type ext_routes, nssa_routes, summary_routes, router), a default router LSA for the 
#                      emulated router1(created by emulation_ospf_config) will be created automatically.
#                    2)If a grid of simulated routers are created firstly on router2, and AS-external/NSSA/summary LSA will be #                      created on the same router2, then you can "connect" the latter LSA with one of the simulated router, by #                      using ?external_connect? to select the advertising router.
#                    3)Enhancement both for OSPFv2 and OSPFv3    
#                    
# Test Step:
#                    1. Reserve and connect chassis ports                             
#                    2. Config OSPF routers and routes on Port1 & port2 
#                    3. Start OSPF
#                    4. Get OSPF info
#                    5. Release resources
#
# Topology:
#
#              STC Port1                      STC Port2           
#             [OSPF Router1-4]---------------[OSPF Router5-8]
#                                          
#                           
###################################
# Run sample:
#            c:\>robot ospfv2_topylogy_enhance.robot


*** Settings ***
Documentation  Get libraries
Library           BuiltIn
Library           Collections
Library           sth.py
Library           String


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
ospfv2 topology enhance Test

##############################################################
#config the parameters for the logging
##############################################################

    ${test_sta} =  test config  log=1   logfile=ospfv2_topylogy_enhance_logfile   vendorlogfile=ospfv2_topylogy_enhance_stcExport   vendorlog=1   hltlog=1   hltlogfile=ospfv2_topylogy_enhance_hltExport   hlt2stcmappingfile=ospfv2_topylogy_enhance_hlt2StcMapping   hlt2stcmapping=1   log_level=7

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
# Step2.Config OSPF routers and routes on port1 & port2 
##############################################################

#start to create devices: OSPF router1-4 on port1

    ${device_ret0} =  emulation ospf config  mode=create   session_type=ospfv2   port_handle=${port1}   count=4   dead_interval=200
    ...  area_id=0.0.0.4   demand_circuit=1   router_id=2.2.2.2   router_id_step=0.0.0.10   mac_address_start=00:10:94:00:00:31 
    ...  intf_ip_addr=1.100.0.1   intf_ip_addr_step=0.0.0.1   gateway_ip_addr=1.100.0.101   gateway_ip_addr_step=0.0.0.1
    ...  graceful_restart_enable=1  

    ${status} =  Get From Dictionary  ${device_ret0}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun emulation ospf config failed\n${device_ret0}
    ...  ELSE  Log To Console  \n***** run emulation ospf config successfully\n${device_ret0}

    ${handle_list1} =  Get From Dictionary  ${device_ret0}  handle

    
    ${router1} =  Get From List  ${handle_list1.split()}  0

    ${router2} =  Get From List  ${handle_list1.split()}  1

    ${router5} =  Get From List  ${handle_list1.split()}  2

    
#start to create devices: OSPF router5-8 on port2

    ${device_ret1} =  emulation ospf config  mode=create   session_type=ospfv2   port_handle=${port2}   count=4   dead_interval=200
    ...  area_id=0.0.0.4   demand_circuit=1   router_id=1.1.1.1   router_id_step=0.0.0.10   mac_address_start=00:10:94:00:00:32 
    ...  intf_ip_addr=1.100.0.101   intf_ip_addr_step=0.0.0.1   gateway_ip_addr=1.100.0.1   gateway_ip_addr_step=0.0.0.1
    ...  graceful_restart_enable=1  area_type=stub

    ${status} =  Get From Dictionary  ${device_ret1}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun emulation ospf config failed\n${device_ret1}
    ...  ELSE  Log To Console  \n***** run emulation ospf config successfully\n${device_ret1}

    ${handle_list2} =  Get From Dictionary  ${device_ret1}  handle

    ${router3} =  Get From List  ${handle_list2.split()}  0

    ${router4} =  Get From List  ${handle_list2.split()}  1

    ${router6} =  Get From List  ${handle_list2.split()}  2

    Log To Console  \nCreate ext_routes on ${router1} :

    ${route_config1} =  emulation ospf topology route config  mode=create  type=ext_routes  handle=${router1} 
    ...  external_number_of_prefix=30  external_prefix_start=91.0.0.1  external_prefix_step=2  
    ...  external_prefix_length=32  external_prefix_type=2

    ${status} =  Get From Dictionary  ${route_config1}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun emulation ospf topology route config failed\n${route_config1}
    ...  ELSE  Log To Console  \n***** run emulation ospf topology route config successfully\n${route_config1}

    Log To Console  \nCreate ext_routes on ${router1} :

    ${route_config2} =  emulation ospf topology route config  mode=create  type=ext_routes  handle=${router1} 
    ...  external_number_of_prefix=20  external_prefix_start=191.0.0.1  external_prefix_step=2  
    ...  external_prefix_length=32  external_prefix_type=2

    ${status} =  Get From Dictionary  ${route_config1}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun emulation ospf topology route config failed\n${route_config1}
    ...  ELSE  Log To Console  \n***** run emulation ospf topology route config successfully\n${route_config1}

    Log To Console  \nCreate grid+ext_routes on ${router2} :

    ${route_config3} =  emulation ospf topology route config  mode=create  type=grid  handle=${router2} 
    ...  grid_connect=1 1  grid_col=2  grid_row=2  grid_link_type=ptop_unnumbered  grid_router_id=2.2.2.2
    ...  grid_router_id_step=0.0.0.1

    ${status} =  Get From Dictionary  ${route_config3}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun emulation ospf topology route config failed\n${route_config3}
    ...  ELSE  Log To Console  \n***** run emulation ospf topology route config successfully\n${route_config3}

    ${gridSession} =  evaluate  ${route_config3}['grid']['connected_session']
    ${ospfGrid} =  Get From Dictionary  ${route_config3}  elem_handle

    ${route_config4} =  emulation ospf topology route config  mode=create  type=ext_routes  handle=${router2} 
    ...  external_number_of_prefix=30  external_prefix_start=91.0.0.1  external_prefix_step=2  
    ...  external_prefix_length=32  external_prefix_type=2

    ${status} =  Get From Dictionary  ${route_config4}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun emulation ospf topology route config failed\n${route_config4}
    ...  ELSE  Log To Console  \n***** run emulation ospf topology route config successfully\n${route_config4}
    
    Log To Console  \nCreate nssa_routes on ${router1} and ${router2} :

    ${route_config5} =  emulation ospf topology route config  mode=create  type=nssa_routes  handle=${router1} 
    ...  nssa_number_of_prefix=30  nssa_prefix_forward_addr=10.0.0.1  nssa_prefix_start=90.0.0.1  nssa_prefix_step=2  
    ...  nssa_prefix_length=32  nssa_prefix_metric=5  nssa_prefix_type=2

    ${status} =  Get From Dictionary  ${route_config5}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun emulation ospf topology route config failed\n${route_config5}
    ...  ELSE  Log To Console  \n***** run emulation ospf topology route config successfully\n${route_config5}

    ${route_config6} =  emulation ospf topology route config  mode=create  type=nssa_routes  handle=${router2} 
    ...  nssa_number_of_prefix=30  nssa_prefix_forward_addr=10.0.0.1  nssa_prefix_start=90.0.0.1  nssa_prefix_step=2  
    ...  nssa_prefix_length=32  nssa_prefix_metric=5  nssa_prefix_type=2

    ${status} =  Get From Dictionary  ${route_config6}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun emulation ospf topology route config failed\n${route_config6}
    ...  ELSE  Log To Console  \n***** run emulation ospf topology route config successfully\n${route_config6}

    Log To Console  \nCreate summary_routes on ${router3} :

    ${route_config7} =  emulation ospf topology route config  mode=create  type=summary_routes  handle=${router3} 
    ...  summary_number_of_prefix=20  summary_prefix_start=90.0.1.0  summary_prefix_step=2  
    ...  summary_prefix_length=27  summary_prefix_metric=10

    ${status} =  Get From Dictionary  ${route_config7}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun emulation ospf topology route config failed\n${route_config7}
    ...  ELSE  Log To Console  \n***** run emulation ospf topology route config successfully\n${route_config7}

    Log To Console  \nCreate router on ${router4} :

    ${route_config8} =  emulation ospf topology route config  mode=create  type=router  handle=${router4} 
    ...  link_enable=0  router_id=10.0.0.1

    ${status} =  Get From Dictionary  ${route_config8}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun emulation ospf topology route config failed\n${route_config8}
    ...  ELSE  Log To Console  \n***** run emulation ospf topology route config successfully\n${route_config8}

    Log To Console  \nCreate router on ${router4} :

    ${route_config9} =  emulation ospf topology route config  mode=create  type=router  handle=${router4} 
    ...  link_enable=1  router_id=20.0.0.1

    ${status} =  Get From Dictionary  ${route_config9}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun emulation ospf topology route config failed\n${route_config9}
    ...  ELSE  Log To Console  \n***** run emulation ospf topology route config successfully\n${route_config9}

#config part is finished

##############################################################
# Step 3. Start OSPF
##############################################################

    @{handle_list1} =  Split String  ${handle_list1}

    @{handle_list2} =  Split String  ${handle_list2}

    :FOR  ${router}  IN  @{handle_list1}
    \  ${ctrl_ret1} =  emulation ospf control  handle=${router}  mode=start
    \  ${status} =  Get From Dictionary  ${ctrl_ret1}  status
    \  Run Keyword If  ${status} == 0  Log To Console  \nrun emulation ospf control failed\n${ctrl_ret1}
    ...  ELSE  Log To Console  \n***** run emulation ospf control successfully\n${ctrl_ret1}


    :FOR  ${router}  IN  @{handle_list2}
    \  ${ctrl_ret2} =  emulation ospf control  handle=${router}  mode=start
    \  ${status} =  Get From Dictionary  ${ctrl_ret2}  status
    \  Run Keyword If  ${status} == 0  Log To Console  \nrun emulation ospf control failed\n${ctrl_ret2}
    ...  ELSE  Log To Console  \n***** run emulation ospf control successfully\n${ctrl_ret2}


    Sleep  5s

##############################################################
# Step 4. Get OSPF info
############################################################## 

    :FOR  ${router}  IN  @{handle_list1}
    \  ${result_ret1} =  emulation ospfv2 info  handle=${router}  
    \  ${status} =  Get From Dictionary  ${result_ret1}  status
    \  Run Keyword If  ${status} == 0  Log To Console  \nrun emulation ospfv2 info failed\n${result_ret1}
    ...  ELSE  Log To Console  \n***** run emulation ospfv2 info successfully\n${result_ret1}

    :FOR  ${router}  IN  @{handle_list2}
    \  ${result_ret2} =  emulation ospfv2 info  handle=${router}  
    \  ${status} =  Get From Dictionary  ${result_ret2}  status
    \  Run Keyword If  ${status} == 0  Log To Console  \nrun emulation ospfv2 info failed\n${result_ret2}
    ...  ELSE  Log To Console  \n***** run emulation ospfv2 info successfully\n${result_ret2}

    :FOR  ${router}  IN  @{handle_list1}
    \  ${result_ret3} =  emulation ospf route info  handle=${router}  
    \  ${status} =  Get From Dictionary  ${result_ret3}  status
    \  Run Keyword If  ${status} == 0  Log To Console  \nrun emulation ospf route info failed\n${result_ret3}
    ...  ELSE  Log To Console  \n***** run emulation ospf route info successfully\n${result_ret3}

    :FOR  ${router}  IN  @{handle_list2}
    \  ${result_ret4} =  emulation ospf route info  handle=${router}  
    \  ${status} =  Get From Dictionary  ${result_ret4}  status
    \  Run Keyword If  ${status} == 0  Log To Console  \nrun emulation ospf route info failed\n${result_ret4}
    ...  ELSE  Log To Console  \n***** run emulation ospf route info successfully\n${result_ret4}

##############################################################
# Step 5. Release resources
##############################################################

    ${cleanup_sta} =  cleanup session  port_handle=${port1} ${port2}   clean_dbfile=1

    ${status} =  Get From Dictionary  ${cleanup_sta}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun cleanup session failed\n${cleanup_sta}
    ...  ELSE  Log To Console  \n***** run cleanup session successfully

    
    Log To Console  \n**************Finish***************

