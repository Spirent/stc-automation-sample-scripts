#################################
#
# File Name:         HLTAPI_Pppol2tp_b2b.py
#
# Description:       This script demonstrates the use of Spirent HLTAPI to setup Pppol2tp LAC-LNS test.
#                    In this test, l2tp LNS and LAC are emulated in back-to-back mode.
#
# Test Step:         1. Reserve and connect chassis ports
#                    2. Config Pppoe over l2tp LAC on Port1
#                    3. Config Pppoe over l2tp LNS on Port2
#                    4. Start LAC-LNS Connect and Pppoe
#                    5. Retrive Statistics
#                    6. Release resources
#
# Dut Configuration:
#                            None
#
# Topology
#                   STC Port1                      STC Port2                       
#                [pppol2tp LNS]------------------[pppol2tp LAC]
#                                              
#                                         
#
#################################

# Run sample:
#            c:\>python HLTAPI_Pppol2tp_b2b.py 10.61.44.2 3/1 3/3

import sth
import time
from sys import argv

filename,device,port1,port2 = argv
port_list = [port1,port2]
port_handle = []

#Config the parameters for the logging
test_sta = sth.test_config (
    log                                              = '1',
    logfile                                          = 'pppol2tp_logfile',
    vendorlogfile                                    = 'pppol2tp_stcExport',
    vendorlog                                        = '1',
    hltlog                                           = '1',
    hltlogfile                                       = 'pppol2tp_hltExport',
    hlt2stcmappingfile                               = 'pppol2tp_hlt2StcMapping',
    hlt2stcmapping                                   = '1',
    log_level                                        = '7')

status = test_sta['status']
if  status == '0' :
    print "run sth.test_config failed"
    print test_sta
else:
    print "***** run sth.test_config successfully"


########################################
#Step1. Reserve and connect chassis ports
########################################

intStatus = sth.connect (
    device    = device,
    port_list = port_list);

status = intStatus['status']
i = 0
if  status == '1' :
    for port in port_list :
        port_handle.append(intStatus['port_handle'][device][port])
        print "\n reserved ports",port,":", port_handle[i],": port_handle[%s]" % i
        i += 1
else :
    print "\nFailed to retrieve port handle!\n"
    print port_handle

##############################################################
#Step2. Config Pppoe over l2tp LAC on Port2
##############################################################

device_ret2 = sth.l2tp_config (
    l2_encap                       = 'ethernet_ii',
    l2tp_src_count                 = '1',
    l2tp_src_addr                  = '192.85.1.3',
    l2tp_src_step                  = '0.0.0.1',
    l2tp_dst_addr                  = '192.85.1.4',
    l2tp_dst_step                  = '0.0.0.0',
    port_handle                    = port_handle[1],
    max_outstanding                = '100',
    disconnect_rate                = '1000',
    mode                           = 'lac',
    attempt_rate                   = '100',
    ppp_auto_retry                 = 'FALSE',
    max_terminate_req              = '10',
    auth_req_timeout               = '3',
    username                       = 'spirent',
    ppp_retry_count                = '65535',
    max_ipcp_req                   = '10',
    echo_req_interval              = '10',
    password                       = 'spirent',
    config_req_timeout             = '3',
    terminate_req_timeout          = '3',
    max_echo_acks                  = '0',
    auth_mode                      = 'none',
    echo_req                       = 'FALSE',
    enable_magic                   = 'TRUE',
    l2tp_mac_addr                  = '00:10:94:00:00:01',
    l2tp_mac_step                  = '00:00:00:00:00:01',
    hello_interval                 = '60',
    hello_req                      = 'FALSE',
    force_lcp_renegotiation        = 'FALSE',
    tunnel_id_start                = '1',
    num_tunnels                    = '1',
    tun_auth                       = 'TRUE',
    session_id_start               = '1',
    redial                         = 'FALSE',
    avp_framing_type               = 'sync',
    redial_max                     = '1',
    redial_timeout                 = '1', 
    sessions_per_tunnel            = '1',
    avp_tx_connect_speed           = '56000',
    udp_src_port                   = '1701',
    lcp_proxy_mode                 = 'none',
    secret                         = 'spirent',
    hostname                       = 'server.spirent.com',
    rws                            = '4')

status = device_ret2['status']
if  status == '0' :
    print "run sth.l2tp_config_lac failed"
    print device_ret2
else:
    print "***** run sth.l2tp_config_lac successfully"


##############################################################
#Step3. Config Pppoe over l2tp LNS on Port1
##############################################################

device_ret1 = sth.l2tp_config (
    l2_encap                       = 'ethernet_ii',
    l2tp_src_count                 = '1',
    l2tp_src_addr                  = '192.85.1.3',
    l2tp_src_step                  = '0.0.0.0',
    l2tp_dst_addr                  = '192.85.1.4',
    l2tp_dst_step                  = '0.0.0.1',
    port_handle                    = port_handle[0],
    ppp_server_ip                  = '192.85.1.4',
    ppp_server_step                = '0.0.0.1',
    ppp_client_ip                  = '192.0.1.0',
    ppp_client_step                = '0.0.0.1',
    max_outstanding                = '100',
    disconnect_rate                = '1000',
    mode                           = 'lns',
    attempt_rate                   = '100',
    ppp_auto_retry                 = 'FALSE',
    max_terminate_req              = '10',
    auth_req_timeout               = '3',
    username                       = 'spirent',
    ppp_retry_count                = '65535',
    max_ipcp_req                   = '10',
    echo_req_interval              = '10',
    password                       = 'spirent',
    config_req_timeout             = '3',
    terminate_req_timeout          = '3',
    max_echo_acks                  = '0',
    auth_mode                      = 'none',
    echo_req                       = 'FALSE',
    enable_magic                   = 'TRUE',
    l2tp_mac_addr                  = '00:10:94:00:00:02',
    l2tp_mac_step                  = '00:00:00:00:00:01',
    hello_interval                 = '60',
    hello_req                      = 'FALSE',
    force_lcp_renegotiation        = 'FALSE',
    tunnel_id_start                = '1',
    num_tunnels                    = '1',
    tun_auth                       = 'TRUE',
    session_id_start               = '1',
    redial                         = 'FALSE',
    avp_framing_type               = 'sync',
    redial_max                     = '1',
    redial_timeout                 = '1', 
    sessions_per_tunnel            = '1',
    avp_tx_connect_speed           = '56000',
    udp_src_port                   = '1701',
    lcp_proxy_mode                 = 'none',
    secret                         = 'spirent',
    hostname                       = 'server.spirent.com',
    rws                            = '4')

status = device_ret1['status']
if  status == '0' :
    print "run sth.l2tp_config_lns failed"
    print device_ret1
else:
    print "***** run sth.l2tp_config_lns successfully"


#config part is finished
sth.invoke ('stc::perform saveasxml -filename pppol2tp.xml')

##############################################################
#Step4. Start LAC-LNS Connect and Pppoe
##############################################################
device1 = device_ret1['handle']

ctrl_ret1 = sth.l2tp_control (
    handle                          = device1,
    action                          = 'connect');

status = ctrl_ret1['status']
if  status == '0' :
    print "run sth.l2tp_control_lns failed"
    print ctrl_ret1
else:
    print "***** run sth.l2tp_control_lns successfully"

time.sleep (1)

device2 = device_ret2['handle']

ctrl_ret2 = sth.l2tp_control (
    handle                          = device2,
    action                          = 'connect');

status = ctrl_ret2['status']
if  status == '0' :
    print "run sth.l2tp_control_lac failed"
    print ctrl_ret2
else:
    print "***** run sth.l2tp_control_lac successfully"

##############################################################
#Step5. Retrive Statistics
##############################################################

results_ret1 = sth.l2tp_stats (
    handle                          = device1,
    mode                            = 'aggregate');

status = results_ret1['status']
if  status == '0' :
    print "run sth.l2tp_stats_lns failed"
    print results_ret1
else:
    for i in range(0,10):
        time.sleep ( 1 )
        if  results_ret1['aggregate']['sessions_up'] == '1' and results_ret1['aggregate']['connected'] == '1' :
            print "***** run sth.l2tp_stats_lns successfully, and results is:"
            print  results_ret1
            break
        else:
            print "the session is not up and link not connected"
    if i == 9:
        print "run sth.l2tp_stat_lns failed"
        print results_ret1


results_ret2 = sth.l2tp_stats (
    handle                          = device2,
    mode                            = 'aggregate');

status = results_ret2['status']
if  status == '0' :
    print "run sth.l2tp_stats_lac failed"
    print results_ret2
else:
    for i in range(0,10):
        time.sleep ( 1 )
        if  results_ret2['aggregate']['sessions_up'] == '1' and results_ret2['aggregate']['connected'] == '1' :
            print "***** run sth.l2tp_stats_lac successfully, and results is:"
            print  results_ret2
            break
    if i == 9 :
        print "run sth.l2tp_stat_lac failed"
        print result_ret2

##############################################################
#Step6. Release resources
##############################################################

cleanup_sta = sth.cleanup_session (
    port_handle                                      = [port_handle[0],port_handle[1]],
    clean_dbfile                                     = '1')

status = cleanup_sta['status']
if  status == '0' :
    print "run sth.cleanup_session failed"
    print cleanup_sta
else:
    print "***** run sth.cleanup_session successfully"
    
print "**************Finish***************"
 

