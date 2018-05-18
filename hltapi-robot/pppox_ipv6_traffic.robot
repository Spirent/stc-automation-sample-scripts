#################################
#
# File Name:                 pppox_ipv6_traffic.robot
#
# Description:               This script demonstrates how to test IPv6 traffic over pppox
# Test Step:                 1. Reserve and connect chassis ports
#                            2. Interface config(optional)
#                            3. Create pppoe client
#                            4. Create stream block
#                            5. Connect pppoe client 
#                            6. Start and stop traffic
#                            7. Get results
#                            8. Release resources
#                            
#DUT Configuration:
        #ipv6 unicast-routing
        #
        #ipv6 local pool rui-pool2 BBBB:1::/48 64
        #ipv6 dhcp pool pool22
        #    prefix-delegation BBBB:1::23F6:33BA/64 0003000100146A54561B 
        #    prefix-delegation pool rui-pool2
        #    dns-server BBBB:1::19
        #    domain-name spirent.com
        #
        #
        #int g0/3
        #    ipv6 address BBBB:1::1/64
        #    ipv6 address FE80:1::1 link-local
        #    pppoe enable group bba-group2
        #int g5/0
        #    ipv6 address aaaa:1::1/64
        #    ipv6 address FE80:2::1 link-local
        #
        #
        #
        #bba-group pppoe bba-group2
        #virtual-template 6
        #sessions per-mac limit 20
        #
        #int virtual-template 6
        #    ipv6 enable
        #    ipv6 unnumbered gigabitEthernet 0/3
        #   no ppp authentication 
        #   encapsulation ppp
        #    ipv6 nd managed-config-flag
        #    ipv6 nd other-config-flag
        #    ipv6 dhcp server pool22 rapid-commit preference 1 allow-hint
#
#Topology
#                 PPPox Client            DHCP/PPPoX Server                  IPv6Host
#                [STC  port1]-------------[g0/3 DUT g5/0]------------------[STC port2 ]
#                 unknown             bbbb:1::1       aaaa:1::1              aaaa:1::2
#
#
########################################

# Run sample:
#            c:\>robot pppox_ipv6_traffic.robot


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
pppox ipv6 traffic test
    [Documentation]  pppox ipv6 traffic test

##############################################################
#config the parameters for the logging
##############################################################

    ${test_sta} =  test config  log=1   logfile=pppox_ipv6_traffic_logfile   vendorlogfile=pppox_ipv6_traffic_stcExport   vendorlog=1   hltlog=1   hltlogfile=pppox_ipv6_traffic_hltExport   hlt2stcmappingfile=pppox_ipv6_traffic_hlt2StcMapping   hlt2stcmapping=1   log_level=7

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

##############################################################
# Step3: create pppoe client
##############################################################

    ${device_ret0} =  pppox config  mode=create   encap=ethernet_ii   protocol=pppoe   ac_select_mode=service_name   circuit_id_suffix_mode=none   port_handle=${port1}   max_outstanding=100   disconnect_rate=1000   attempt_rate=100   pppoe_circuit_id=circuit   mru_neg_enable=1   max_configure_req=10   chap_ack_timeout=3   max_padi_req=10   padi_include_tag=1   padr_req_timeout=3   max_terminate_req=10   term_req_timeout=3   username=spirent   use_partial_block_state=false   max_auto_retry_count=65535   agent_type=2516   max_ipcp_req=10   intermediate_agent=false   echo_req_interval=10   password=spirent   local_magic=1   config_req_timeout=3   active=1   auto_retry=false   padi_req_timeout=3   agent_mac_addr=00:00:00:00:00:00   lcp_mru=1492   ip_cp=ipv6_cp   auto_fill_ipv6=1   max_echo_acks=0   auth_mode=none   include_id=1   ipcp_req_timeout=3   max_padr_req=10   padr_include_tag=1   echo_req=false   fsm_max_naks=5   local_ipv6_addr=fe80::210:94ff:fe01:1   gateway_ipv6_step=::   intf_ipv6_addr=2000::2   intf_ipv6_addr_step=::1   gateway_ipv6_addr=::   mac_addr=00:10:94:01:00:01   mac_addr_repeat=0   mac_addr_step=00:00:00:00:00:01   num_sessions=4

    ${status} =  Get From Dictionary  ${device_ret0}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun pppox config failed\n${device_ret0}
    ...  ELSE  Log To Console  \n***** run pppox config successfully

    ${deviceHdlClient} =  Get From Dictionary  ${device_ret0}  handle

##############################################
#step4: create stream block
############################################# 

    ${streamblock_ret1} =  traffic config  mode=create   port_handle=${port1}   port_handle2=${port2}   emulation_src_handle=${deviceHdlClient}   emulation_dst_handle=${deviceHdlClient}   l2_encap=ethernet_ii_pppoe   l3_protocol=ipv6   ipv6_traffic_class=0   ipv6_next_header=97   ipv6_length=0   ipv6_flow_label=7   ipv6_hop_limit=255   mac_src=00:10:94:01:00:01   mac_dst=00:00:01:00:00:01   enable_control_plane=0   l3_length=102   name=StreamBlock_2   fill_type=constant   fcs_error=0   fill_value=0   frame_size=128   traffic_state=1   high_speed_result_analysis=1   length_mode=fixed   tx_port_sending_traffic_to_self_en=false   disable_signature=0   enable_stream_only_gen=1   endpoint_map=one_to_one   pkts_per_burst=1   inter_stream_gap_unit=bytes   burst_loop_count=30   transmit_mode=continuous   inter_stream_gap=12   rate_percent=10   mac_discovery_gw=::

    ${status} =  Get From Dictionary  ${streamblock_ret1}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun traffic config failed\n${streamblock_ret1}
    ...  ELSE  Log To Console  \n***** run traffic config successfully

    #config part is finished
    
##############################################################
# step5: connect pppoe client
##############################################################

    ${ctrl_ret1} =  pppox control  handle=${deviceHdlClient}   action=connect

    ${status} =  Get From Dictionary  ${ctrl_ret1}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun pppox control failed\n${ctrl_ret1}
    ...  ELSE  Log To Console  \n***** run pppox control successfully

    Sleep  5s

########################################
#step6: start and stop traffic
######################################## 

    ${traffic_ctrl_ret} =  traffic control  port_handle=all   action=run

    ${status} =  Get From Dictionary  ${traffic_ctrl_ret}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun traffic control failed\n${traffic_ctrl_ret}
    ...  ELSE  Log To Console  \n***** run traffic control successfully

    Sleep  5s

    ${traffic_ctrl_ret} =  traffic control  port_handle=all   action=stop

    ${status} =  Get From Dictionary  ${traffic_ctrl_ret}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun traffic control failed\n${traffic_ctrl_ret}
    ...  ELSE  Log To Console  \n***** run traffic control successfully

##############################################################
# step7: get results
##############################################################

    ${results_ret1} =  pppox stats  handle=${deviceHdlClient}   mode=session

    ${status} =  Get From Dictionary  ${results_ret1}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun pppox stats failed\n${results_ret1}
    ...  ELSE  Log To Console  \n***** run pppox stats successfully, and results is:\n${results_ret1}
    
    Sleep  2s

    ${traffic_results_ret} =  traffic stats  port_handle=${port1} ${port2}   mode=aggregate

    ${status} =  Get From Dictionary  ${traffic_results_ret}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun traffic stats failed\n${traffic_results_ret}
    ...  ELSE  Log To Console  \n***** run traffic stats successfully, and results is:\n${traffic_results_ret}
    
##############################################################
# step8: Release resources
##############################################################

    ${cleanup_sta} =  cleanup session  port_handle=${port1} ${port2}   clean_dbfile=1

    ${status} =  Get From Dictionary  ${cleanup_sta}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun cleanup session failed\n${cleanup_sta}
    ...  ELSE  Log To Console  \n***** run cleanup session successfully

    
    Log To Console  \n**************Finish***************

