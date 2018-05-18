################################################################################
#
# File Name:                 HLTAPI_Traffic_QoS.py
#
# Description:               This script demonstrates how to configure traffic QoS and query the result based on VLAN #                            priority/DSCP/ToS.
#
# Test steps:               
#                            1. Reserve and connect chassis ports
#                            2. Configure streamblock with multiple inner and outer vlan priorities
#                            3. Start taffic and then get real time and EOT results based on outer vlan priority
#                            4. Start taffic again and then get real time results and EOT results based on inner vlan priority
#                            5. Configure streamblock with multiple DSCP values
#                            6. Start taffic and then get real time results based on DSCP value
#                            7. Stop traffic and get EOT results of DSCP value
#                            8. Configure streamblock with multiple ToS values
#                            9. Start taffic and then get real time results based on ToS value
#                            10. Stop traffic and get EOT results of ToS
#                            11. Release resources
#
# Topology:
#                 Generate Traffic             Get Result     
#                   STC port1  ---------------- STC port2 
#                 [Streamblock]
#
################################################################################
# 
# Run sample:
#            c:>python HLTAPI_Traffic_QoS.py 10.61.44.2 3/1 3/3

import sth
import time
from sys import argv
filename,device,port1,port2 = argv
port_list = [port1,port2]
port_handle = []

#Config the parameters for the logging
test_sta = sth.test_config (
    log                                              = '1',
    logfile                                          = 'HLTAPI_Traffic_QoS_logfile',
    vendorlogfile                                    = 'HLTAPI_Traffic_QoS_stcExport',
    vendorlog                                        = '1',
    hltlog                                           = '1',
    hltlogfile                                       = 'HLTAPI_Traffic_QoS_hltExport',
    hlt2stcmappingfile                               = 'HHLTAPI_Traffic_QoS_hlt2StcMapping',
    hlt2stcmapping                                   = '1',
    log_level                                        = '7')

status = test_sta['status']
if  status == '0' :
    print "run sth.test_config failed"
    print test_sta
else:
    print "***** run sth.test_config successfully"


########################################
# Step1. Reserve and connect chassis ports
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
#config the parameters for optimization and parsing
##############################################################

test_ctrl_sta = sth.test_control (
        action                                           = 'enable')

status = test_ctrl_sta['status']
if (status == '0') :
    print("run sth.test_control failed")
    print(test_ctrl_sta)
else:
    print("***** run sth.test_control successfully")

########################################
# Step2. Configure streamblock with multiple inner and outer vlan priorities
########################################
streamblock_ret1 = sth.traffic_config (
    mode                                             = 'create',
    port_handle                                      = port_handle[0],
    l2_encap                                         = 'ethernet_ii_vlan',
    fill_type                                        = 'prbs',
    vlan_id                                          = '1',
    vlan_id_count                                    = '3',
    vlan_id_step                                     = '1',
    vlan_user_priority                               = '1',
    vlan_id_outer                                    = '100',
    vlan_id_outer_step                               = '1',
    rate_pps                                         = '1000',
    l3_protocol                                      = 'ipv4',
    vlan_id_repeat                                   = '0',
    vlan_id_mode                                     = 'increment',
    vlan_id_outer_count                              = '3',
    vlan_outer_user_priority                         = '4',
    transmit_mode                                    = 'continuous',
    ip_src_addr                                      = '10.0.0.11',
    ip_dst_addr                                      = '10.0.0.1')

status = streamblock_ret1['status']
if (status == '0') :
    print("run sth.traffic_config failed")
    print(streamblock_ret1)
else:
    print("***** run sth.traffic_config successfully")

vlanstreamHandle = streamblock_ret1['stream_id']

########################################
# Step3. Start taffic and then get real time and EOT results based on outer vlan priority
########################################
print "Start traffic generator for filtering outer vlan priority..."
traffic_ctrl_ret = sth.traffic_control (
        port_handle                                      = [port_handle[0]],
        action                                           = 'run',
        get                                              = 'vlan_pri')

status = traffic_ctrl_ret['status']
if (status == '0') :
    print("run sth.traffic_control failed")
    print(traffic_ctrl_ret)
else:
    print("***** run sth.traffic_control successfully")  

time.sleep(1)

print "Get realtime results of outer vlan priority"
traffic_results_ret = sth.traffic_stats (
        port_handle                                      = port_handle[1],
        mode                                             = 'aggregate');

status = traffic_results_ret['status']
if (status == '0') :
    print("run sth.traffic_stats failed")
    print(traffic_results_ret)
else:
    print("***** run sth.traffic_stats successfully, outer vlan priority and realtime results is:")
    print traffic_results_ret

time.sleep(3)

print "stop traffic"

traffic_ctrl_ret = sth.traffic_control (
        port_handle                                      = [port_handle[0]],
        action                                           = 'stop');

status = traffic_ctrl_ret['status']
if (status == '0') :
    print("run sth.traffic_control failed")
    print(traffic_ctrl_ret)
else:
    print("***** run sth.traffic_control successfully") 

print "Get EOT results of outer vlan priority"
traffic_results_ret = sth.traffic_stats (
        port_handle                                      = port_handle[1],
        mode                                             = 'aggregate');

status = traffic_results_ret['status']
if (status == '0') :
    print("run sth.traffic_stats failed")
    print(traffic_results_ret)
else:
    print("***** run sth.traffic_stats successfully, outer vlan priority and EOT results is:")
    print traffic_results_ret

########################################
# Step4. Start taffic again and then get real time results and EOT results based on inner vlan priority
########################################
print "Start traffic generator again for filtering innner vlan priority..."

traffic_ctrl_ret = sth.traffic_control (
        port_handle                                      = [port_handle[0]],
        action                                           = 'run',
        get                                              = 'vlan_pri_inner');

status = traffic_ctrl_ret['status']
if (status == '0') :
    print("run sth.traffic_control failed")
    print(traffic_ctrl_ret)
else:
    print("***** run sth.traffic_control successfully")  

time.sleep(1)
    
print "Get realtime result of inner vlan priority "

traffic_results_ret = sth.traffic_stats (
        port_handle                                      = port_handle[1],
        mode                                             = 'aggregate');

status = traffic_results_ret['status']
if (status == '0') :
    print("run sth.traffic_stats failed")
    print(traffic_results_ret)
else:
    print("***** run sth.traffic_stats successfully, inner vlan priority and realtime results is:")
    print traffic_results_ret

time.sleep(3)

print "stop traffic"

traffic_ctrl_ret = sth.traffic_control (
        port_handle                                      = [port_handle[0]],
        action                                           = 'stop');

status = traffic_ctrl_ret['status']
if (status == '0') :
    print("run sth.traffic_control failed")
    print(traffic_ctrl_ret)
else:
    print("***** run sth.traffic_control successfully")

time.sleep(3)    

print "Get EOT results of inner vlan priority"

traffic_results_ret = sth.traffic_stats (
        port_handle                                      = port_handle[1],
        mode                                             = 'aggregate');

status = traffic_results_ret['status']
if (status == '0') :
    print("run sth.traffic_stats failed")
    print(traffic_results_ret)
else:
    print("***** run sth.traffic_stats successfully, inner vlan priority and EOT results is:")
    print traffic_results_ret
    
print "Disable streamblock of vlan priority"

disable_sb = sth.traffic_config (
        mode                                              = 'disable',
        stream_id                                         = vlanstreamHandle)
        
status = disable_sb['status']
if (status == '0') :
    print("run sth.traffic_config failed")
    print(disable_sb)
else:
    print("***** Disable streamblock successfully")

########################################
# Step5. Configure streamblock with multiple DSCP values
########################################
print "create DSCP streamblock"
streamblock_ret2 = sth.traffic_config (
        mode                                             = 'create',
        port_handle                                      = port_handle[0],
        l2_encap                                         = 'ethernet_ii',
        l3_protocol                                      = 'ipv4',
        ip_dscp                                          = '26',
        ip_dscp_step                                     = '1',
        ip_dscp_count                                    = '3',
        transmit_mode                                    = 'continuous',
        rate_pps                                         = '10000',
        ip_src_addr                                      = '10.0.0.11',
        ip_dst_addr                                      = '10.0.0.1',
        l4_protocol                                      = 'tcp',
        tcp_src_port                                     = '1000',
        tcp_dst_port                                     = '2000');

status = streamblock_ret2['status']
if (status == '0') :
    print("run sth.traffic_config failed")
    print(streamblock_ret2)
else:
    print("***** run sth.traffic_config successfully")

dscpstreamHandle = streamblock_ret2['stream_id']

#config part is finished
sth.invoke ('stc::perform saveasxml -filename traffic_qos.xml')

########################################
# Step6. Start taffic and then get real time results based on DSCP value
########################################
print "Start traffic generator for filtering DSCP value..."

traffic_ctrl_ret = sth.traffic_control (
        port_handle                                      = [port_handle[0]],
        action                                           = 'run',
        get                                              = 'dscp');

status = traffic_ctrl_ret['status']
if (status == '0') :
    print("run sth.traffic_control failed")
    print(traffic_ctrl_ret)
else:
    print("***** run sth.traffic_control successfully")  

time.sleep(1)
    
print "Get realtime result of dscp "

traffic_results_ret = sth.traffic_stats (
        port_handle                                      = port_handle[1],
        mode                                             = 'aggregate');

status = traffic_results_ret['status']
if (status == '0') :
    print("run sth.traffic_stats failed")
    print(traffic_results_ret)
else:
    print("***** run sth.traffic_stats successfully, DSCP value and realtime results is:")
    print traffic_results_ret

time.sleep(1)

########################################
# Step7. Stop traffic and get EOT results of DSCP value
########################################
print "stop traffic"

traffic_ctrl_ret = sth.traffic_control (
        port_handle                                      = [port_handle[0]],
        action                                           = 'stop');

status = traffic_ctrl_ret['status']
if (status == '0') :
    print("run sth.traffic_control failed")
    print(traffic_ctrl_ret)
else:
    print("***** run sth.traffic_control successfully")

time.sleep(3)    

print "Get EOT results of DSCP"

traffic_results_ret = sth.traffic_stats (
        port_handle                                      = port_handle[1],
        mode                                             = 'aggregate');

status = traffic_results_ret['status']
if (status == '0') :
    print("run sth.traffic_stats failed")
    print(traffic_results_ret)
else:
    print("***** run sth.traffic_stats successfully, DSCP and EOT results is:")
    print traffic_results_ret
    
print "Disable streamblock of DSCP"

disable_sb = sth.traffic_config (
        mode                                              = 'disable',
        stream_id                                         = dscpstreamHandle)
        
status = disable_sb['status']
if (status == '0') :
    print("run sth.traffic_config failed")
    print(disable_sb)
else:
    print("***** Disable streamblock successfully")

########################################
# Step8. Configure streamblock with multiple ToS values
########################################
print "create ToS streamblock"
streamblock_ret3 = sth.traffic_config (
        mode                                             = 'create',
        port_handle                                      = port_handle[0],
        l2_encap                                         = 'ethernet_ii',
        l3_protocol                                      = 'ipv4',
        l4_protocol                                      = 'tcp',
        ip_tos_count                                     = '3',
        ip_tos_step                                      = '1',
        ip_tos_field                                     = '2',
        ip_precedence                                    = '2',
        ip_mbz                                           = '1',
        transmit_mode                                    = 'continuous',
        rate_pps                                         = '1000',
        ip_src_addr                                      = '10.0.0.11',
        ip_dst_addr                                      = '10.0.0.1',
        tcp_src_port                                     = '1000',
        tcp_dst_port                                     = '2000')

status = streamblock_ret3['status']
if (status == '0') :
    print("run sth.traffic_config failed")
    print(streamblock_ret3)
else:
    print("***** run sth.traffic_config successfully")

tosstreamHandle = streamblock_ret3['stream_id']

########################################
# Step9. Start taffic and then get real time results based on ToS value
########################################
print "Start traffic generator for filtering ToS value..."

traffic_ctrl_ret = sth.traffic_control (
        port_handle                                      = [port_handle[0]],
        action                                           = 'run',
        get                                              = 'tos');

status = traffic_ctrl_ret['status']
if (status == '0') :
    print("run sth.traffic_control failed")
    print(traffic_ctrl_ret)
else:
    print("***** run sth.traffic_control successfully")  

time.sleep(1)
    
print "Get realtime result of ToS "

traffic_results_ret = sth.traffic_stats (
        port_handle                                      = port_handle[1],
        mode                                             = 'aggregate');

status = traffic_results_ret['status']
if (status == '0') :
    print("run sth.traffic_stats failed")
    print(traffic_results_ret)
else:
    print("***** run sth.traffic_stats successfully, ToS value and realtime results is:")
    print traffic_results_ret

time.sleep(1)

########################################
# Step10. Stop traffic and get EOT results of ToS
########################################
print "stop traffic"

traffic_ctrl_ret = sth.traffic_control (
        port_handle                                      = [port_handle[0]],
        action                                           = 'stop');

status = traffic_ctrl_ret['status']
if (status == '0') :
    print("run sth.traffic_control failed")
    print(traffic_ctrl_ret)
else:
    print("***** run sth.traffic_control successfully")

time.sleep(1)    

print "Get EOT results of ToS"

traffic_results_ret = sth.traffic_stats (
        port_handle                                      = port_handle[1],
        mode                                             = 'aggregate');

status = traffic_results_ret['status']
if (status == '0') :
    print("run sth.traffic_stats failed")
    print(traffic_results_ret)
else:
    print("***** run sth.traffic_stats successfully, ToS and EOT results is:")
    print traffic_results_ret
    
print "Disable streamblock of ToS"

disable_sb = sth.traffic_config (
        mode                                              = 'disable',
        stream_id                                         = tosstreamHandle)
        
status = disable_sb['status']
if (status == '0') :
    print("run sth.traffic_config failed")
    print(disable_sb)
else:
    print("***** Disable streamblock successfully")
    
##############################################################
# Step 11. Release resources
##############################################################
print "Release resources"
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