#########################################################################################################################
#
# File Name:           HLTAPI_RFC3918.py                 
# Description:         This script demonstrates the use of Spirent HLTAPI to setup RFC3918 in B2B mode.
#                      
# Test Steps:          
#                    1. Reserve and connect chassis ports
#                    2. Create interfaces on port1 and port2 
#                    3. Create multicast group 
#                    4. Configure IGMP client on port2
#                    5. Bound IGMP client and the Multicast Group
#                    6. Create multicast and unicast streamblock 
#                    7. Create mixed_tput test and get results
#                    8. Create matrix test and get results
#                    9. Create agg_tput test and get results 
#                    10. Create fwd_latency test and get results 
#                    11. Create capacity test and get results
#                    12. Create join leave latency test and get results
#                    13. Release resources
#                                                                       
# Topology:
#                    STC Port2                      STC Port1                       
#                  [IGMP client]------------------[Multicast/Unicast groups]
#                                                                         
#  
################################################################################
# 
# Run sample:
#            c:>python HLTAPI_RFC3918.py 10.61.44.2 3/1 3/3
#

import time
print "**************************************************starttime:\n"
print (time.strftime("%H:%M:%S"))
import sth
from sys import argv
filename,device,port1,port2 = argv
port_list = [port1,port2]
port_handle = []

#Config the parameters for the logging
test_sta = sth.test_config (
    log                                              = '1',
    logfile                                          = 'HLTAPI_RFC3918_logfile',
    vendorlogfile                                    = 'HLTAPI_RFC3918_stcExport',
    vendorlog                                        = '1',
    hltlog                                           = '1',
    hltlogfile                                       = 'HLTAPI_RFC3918_hltExport',
    hlt2stcmappingfile                               = 'HLTAPI_RFC3918_hlt2StcMapping',
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
# Step2. Create interfaces on port1 and port2 
########################################
interface1 = sth.interface_config (
    port_handle                                     = port_handle[0],
    intf_mode                                       = 'ethernet',
    mode                                            = 'config',
    intf_ip_addr                                    = '192.168.1.10',
    gateway                                         = '192.168.1.100',
    resolve_gateway_mac                             = 'false',
    dst_mac_addr                                    = '00:10:94:10:00:02',
    src_mac_addr                                    = '00:10:94:10:00:01')


status = interface1['status']
if (status == '0') :
    print("set interface on port1 failed")
    print(interface1)
else:
    print("***** set interface on port1 successfully")

    
hdl = interface1['handles']

interface2 = sth.interface_config (
    port_handle                                     = port_handle[1],
    intf_mode                                       = 'ethernet',
    mode                                            = 'config',
    intf_ip_addr                                    = '192.168.1.100',
    gateway                                         = '192.168.1.10',
    resolve_gateway_mac                             = 'false',
    dst_mac_addr                                    = '00:10:94:10:00:01',
    src_mac_addr                                    = '00:10:94:10:00:02')


status = interface2['status']
if (status == '0') :
    print("set interface on port2 failed")
    print(interface2)
else:
    print("***** set interface on port2 successfully")


########################################
# Step3. Create multicast group 
########################################
print "Configure Multicast group"
groupStatus = sth.emulation_multicast_group_config (
        ip_addr_start                                    = '225.0.0.1',
        mode                                             = 'create',
        num_groups                                       = '5')
        
status = groupStatus['status']
if (status == '0') :
    print("***** Created Multicast Group failed")
    print(groupStatus)
else:
    print("***** Created Multicast Group successfully")
    
McGroupHandle = groupStatus['handle']

##############################################################
# Step 4. Configure IGMP client on port2
##############################################################
print "Config IGMP client on Port2"

device_ret0 = sth.emulation_igmp_config (
        mode                                             = 'create',
        port_handle                                      = port_handle[1],
        count                                            = '1',
        source_mac                                       = '00:10:94:10:00:02',
        source_mac_step                                  = '00:00:00:00:00:01',
        neighbor_intf_ip_addr                            = '6.41.1.10',
        intf_ip_addr                                     = '6.41.1.100');

status = device_ret0['status']
if (status == '0') :
    print("run sth.emulation_igmp_config failed")
    print(device_ret0)
else:
    print("***** run sth.emulation_igmp_config successfully")

igmpSession = device_ret0['handle']

##############################################################
# Step 5. Bound IGMP client and the Multicast Group
##############################################################
print "Bound IGMP to multicast group"
membershipStatus = sth.emulation_igmp_group_config (
        session_handle                                   = igmpSession,
        mode                                             = 'create',
        group_pool_handle                                = McGroupHandle);

status = membershipStatus['status']
if (status == '0') :
    print("***** Bound the IGMP and the Multicast Group failed")
    print(membershipStatus)
else:
    print("***** Bound the IGMP and the Multicast Group successfully")
    print(membershipStatus)
    
##############################################################
# Step 6. Create multicast and unicast streamblock 
##############################################################

streamblock_multicast = sth.traffic_config (
        mode                                             = 'create',
        port_handle                                      = port_handle[0],
        emulation_src_handle                             = hdl,
        emulation_dst_handle                             = McGroupHandle,
        l3_length                                        = '128',
        length_mode                                      = 'fixed',
        mac_discovery_gw                                 = '6.41.1.100',
        rate_percent                                     = '10')

status = streamblock_multicast['status']
if (status == '0') :
    print("run sth.traffic_config failed")
    print(streamblock_multicast)
else:
    print("***** run sth.traffic_config successfully")
    
streamblock_unicast = sth.traffic_config (
        mode                                             = 'create',
        port_handle                                      = port_handle[0],
        ip_src_addr                                      = '6.41.1.10',
        ip_dst_addr                                      = '6.41.1.100',
        l3_length                                        = '256',
        l3_protocol                                      = 'ipv4',
        l2_encap                                         = 'ethernet_ii',
        length_mode                                      = 'fixed',
        mac_discovery_gw                                 = '6.41.1.100',
        rate_percent                                     = '10')

status = streamblock_unicast['status']
if (status == '0') :
    print("run sth.traffic_config failed")
    print(streamblock_unicast)
else:
    print("***** run sth.traffic_config successfully")
    
mc_str = streamblock_multicast['stream_id']
uc_str = streamblock_unicast['stream_id']
    
##############################################################
# Step 7. Create mixed_tput test and get results
##############################################################
print "\n+++++ Start to create test 1 -- mixed class throughput test : "

rfc_cfg0 = sth.test_rfc3918_config (
        mode                                             = 'create',
        test_type                                        = 'mixed_tput',
        multicast_streamblock                            = mc_str,
        unicast_streamblock                              = uc_str,
        join_group_delay                                 = '15',
        leave_group_delay                                = '15',
        mc_msg_tx_rate                                   = '2000',
        latency_type                                     = 'FIFO',
        test_duration_mode                               = 'seconds',
        test_duration                                    = '20',
        result_delay                                     = '10',
        start_test_delay                                 = '5',
        frame_size_mode                                  = 'custom',
        frame_size                                       = '256',
        l2_learning_rate                                 = '100',
        l3_learning_rate                                 = '200',
        group_count_mode                                 = 'custom',
        group_count                                      = '60',
        enable_same_frame_size                           = '1',
        unicast_frame_size_mode                          = 'custom',
        unicast_frame_size                               = '128',
        mc_traffic_percent_mode                          = 'custom',
        mc_traffic_percent                               = '30',
        initial_rate                                     = '10',
        rate_lower_limit                                 = '10',
        rate_upper_limit                                 = '10')

#rfc_cfg_handle0 = rfc_cfg0['handle']

status = rfc_cfg0['status']
if (status == '0') :
    print("run sth.test_rfc3918_config failed")
    print(rfc_cfg0)
else:
    print("***** run sth.test_rfc3918_config successfully")
    
print "+++++ Start to run mixed class throughput test : "

ctrl_ret1 = sth.test_rfc3918_control (
        action                                           = 'run',
        wait                                             = '1');

status = ctrl_ret1['status']
if (status == '0') :
    print("run sth.test_rfc3918_control failed")
    print(ctrl_ret1)
else:
    print("***** run sth.test_rfc3918_control successfully")

print "+++++ Start to get results of mixed class throughput test : "
results_ret1 = sth.test_rfc3918_info (
        test_type                                        = 'mixed_tput',
        clear_result                                     = '0');

status = results_ret1['status']
if (status == '0') :
    print("run sth.test_rfc3918_info failed")
    print(results_ret1)
else:
    print("***** run sth.test_rfc3918_info successfully, and results is:")
    print(results_ret1)
    
ctrl_ret_stop = sth.test_rfc3918_control (
        action                                           = 'stop',
        cleanup                                          = '1');

status = ctrl_ret_stop['status']
if (status == '0') :
    print("run sth.test_rfc3918_control failed")
    print(ctrl_ret_stop)
else:
    print("***** run sth.test_rfc3918_control successfully")
    


##############################################################
# Step 8. Create matrix test and get results 
##############################################################
print "\n+++++ Start to create test 2 -- scaled group forwarding matrix test : "
rfc_cfg1 = sth.test_rfc3918_config (
        mode                                             = 'create',
        test_type                                        = 'matrix',
        multicast_streamblock                            = mc_str,
        frame_size_mode                                  = 'custom',
        frame_size                                       = '256',
        load_start                                       = '10',
        load_end                                         = '10',
        join_group_delay                                 = '15',
        leave_group_delay                                = '15',
        mc_msg_tx_rate                                   = '1000',
        latency_type                                     = 'FIFO',
        test_duration_mode                               = 'seconds',
        test_duration                                    = '20',
        result_delay                                     = '10',
        start_test_delay                                 = '2',
        group_count                                      = '60')
        
#rfc_cfg_handle1 = rfc_cfg1['handle']
        
status = rfc_cfg1['status']
if (status == '0') :
    print("run sth.test_rfc3918_config failed")
    print(rfc_cfg1)
else:
    print("***** run sth.test_rfc3918_config successfully")

print "+++++ Start to run scaled group forwarding matrix test : "
ctrl_ret1 = sth.test_rfc3918_control (
        action                                           = 'run',
        wait                                             = '1');

status = ctrl_ret1['status']
if (status == '0') :
    print("run sth.test_rfc3918_control failed")
    print(ctrl_ret1)
else:
    print("***** run sth.test_rfc3918_control successfully")


print "+++++ Start to get results of matrix test : "

results_ret1 = sth.test_rfc3918_info (
        test_type                                        = 'matrix',
        clear_result                                     = '0');

status = results_ret1['status']
if (status == '0') :
    print("run sth.test_rfc3918_info failed")
    print(results_ret1)
else:
    print("***** run sth.test_rfc3918_info successfully, and results is:")
    print(results_ret1)
    
ctrl_ret_stop = sth.test_rfc3918_control (
        action                                           = 'stop',
        cleanup                                          = '1');

status = ctrl_ret_stop['status']
if (status == '0') :
    print("run sth.test_rfc3918_control failed")
    print(ctrl_ret_stop)
else:
    print("***** run sth.test_rfc3918_control successfully")
    


##############################################################
# Step 9. Create agg_tput test and get results 
##############################################################
print "\n+++++ Start to create test 3 -- aggregated multicast throughput test : "

rfc_cfg2 = sth.test_rfc3918_config (
        mode                                             = 'create',
        test_type                                        = 'agg_tput',
        multicast_streamblock                            = mc_str,
        join_group_delay                                 = '15',
        leave_group_delay                                = '15',
        mc_msg_tx_rate                                   = '1000',
        latency_type                                     = 'FIFO',
        test_duration_mode                               = 'seconds',
        test_duration                                    = '20',
        result_delay                                     = '10',
        start_test_delay                                 = '5',
        frame_size_mode                                  = 'custom',
        frame_size                                       = '256',
        l2_learning_rate                                 = '100',
        l3_learning_rate                                 = '200',
        group_count_mode                                 = 'custom',
        group_count                                      = '60',
        initial_rate                                     = '10',
        rate_lower_limit                                 = '10',
        rate_upper_limit                                 = '10')

#rfc_cfg_handle2 = rfc_cfg2['handle']
        
status = rfc_cfg2['status']
if (status == '0') :
    print("run sth.test_rfc3918_config failed")
    print(rfc_cfg2)
else:
    print("***** run sth.test_rfc3918_config successfully")    
    
print "+++++ Start to run aggregated multicast throughput test : "
ctrl_ret1 = sth.test_rfc3918_control (
        action                                           = 'run',
        wait                                             = '1');

status = ctrl_ret1['status']
if (status == '0') :
    print("run sth.test_rfc3918_control failed")
    print(ctrl_ret1)
else:
    print("***** run sth.test_rfc3918_control successfully")


print "+++++ Start to get results of aggregated multicast throughput: "

results_ret1 = sth.test_rfc3918_info (
        test_type                                        = 'agg_tput',
        clear_result                                     = '0');

status = results_ret1['status']
if (status == '0') :
    print("run sth.test_rfc3918_info failed")
    print(results_ret1)
else:
    print("***** run sth.test_rfc3918_info successfully, and results is:")
    print(results_ret1)
    
ctrl_ret_stop = sth.test_rfc3918_control (
        action                                           = 'stop',
        cleanup                                          = '1');

status = ctrl_ret_stop['status']
if (status == '0') :
    print("run sth.test_rfc3918_control failed")
    print(ctrl_ret_stop)
else:
    print("***** run sth.test_rfc3918_control successfully")
    
    
##############################################################
# Step 10. Create fwd_latency test and get results 
##############################################################
print "\n+++++ Start to create test 4 -- multicast forwarding latency test : "

rfc_cfg3 = sth.test_rfc3918_config (
        mode                                             = 'create',
        test_type                                        = 'fwd_latency',
        multicast_streamblock                            = mc_str,
        join_group_delay                                 = '15',
        leave_group_delay                                = '15',
        mc_msg_tx_rate                                   = '2000',
        latency_type                                      = 'FIFO',
        test_duration_mode                               = 'seconds',
        test_duration                                    = '20',
        result_delay                                     = '10',
        start_test_delay                                 = '5',
        frame_size_mode                                  = 'custom',
        frame_size                                       = '256',
        l2_learning_rate                                 = '100',
        l3_learning_rate                                 = '200',
        group_count_mode                                 = 'custom',
        group_count                                      = '60',
        load_end                                         = '10')

#rfc_cfg_handle3 = rfc_cfg3['handle']
        
status = rfc_cfg3['status']
if (status == '0') :
    print("run sth.test_rfc3918_config failed")
    print(rfc_cfg3)
else:
    print("***** run sth.test_rfc3918_config successfully")    
    
print "+++++ Start to run multicast forwarding latency test : "
ctrl_ret1 = sth.test_rfc3918_control (
        action                                           = 'run',
        wait                                             = '1');

status = ctrl_ret1['status']
if (status == '0') :
    print("run sth.test_rfc3918_control failed")
    print(ctrl_ret1)
else:
    print("***** run sth.test_rfc3918_control successfully")


print "+++++ Start to get results of multicast forwarding latency: "

results_ret1 = sth.test_rfc3918_info (
        test_type                                        = 'fwd_latency',
        clear_result                                     = '0');

status = results_ret1['status']
if (status == '0') :
    print("run sth.test_rfc3918_info failed")
    print(results_ret1)
else:
    print("***** run sth.test_rfc3918_info successfully, and results is:")
    print(results_ret1)
    
ctrl_ret_stop = sth.test_rfc3918_control (
        action                                           = 'stop',
        cleanup                                          = '1');

status = ctrl_ret_stop['status']
if (status == '0') :
    print("run sth.test_rfc3918_control failed")
    print(ctrl_ret_stop)
else:
    print("***** run sth.test_rfc3918_control successfully")
    
 
##############################################################
# Step 11. Create capacity test and get results
##############################################################
print "\n+++++ Start to create test 5 -- multicast group capacity test : "
rfc_cfg4 = sth.test_rfc3918_config (
        mode                                             = 'create',
        test_type                                        = 'capacity',
        multicast_streamblock                            = mc_str,
        join_group_delay                                 = '15',
        leave_group_delay                                = '15',
        mc_msg_tx_rate                                   = '1000',
        latency_type                                     = 'FIFO',
        test_duration_mode                               = 'seconds',
        test_duration                                    = '20',
        result_delay                                     = '10',
        start_test_delay                                 = '5',
        group_upper_limit                                = '10',
        load_end                                         = '10',
        frame_size                                       = '256')     

#rfc_cfg_handle4 = rfc_cfg4['handle']        

status = rfc_cfg4['status']
if (status == '0') :
    print("run sth.test_rfc3918_config failed")
    print(rfc_cfg4)
else:
    print("***** run sth.test_rfc3918_config successfully")
    
print "+++++ Start to run multicast group capacity test : "
ctrl_ret1 = sth.test_rfc3918_control (
        action                                           = 'run',
        wait                                             = '1');

status = ctrl_ret1['status']
if (status == '0') :
    print("run sth.test_rfc3918_control failed")
    print(ctrl_ret1)
else:
    print("***** run sth.test_rfc3918_control successfully")


print "+++++ Start to get results of multicast group capacity test: "

results_ret1 = sth.test_rfc3918_info (
        test_type                                        = 'capacity',
        clear_result                                     = '0');

status = results_ret1['status']
if (status == '0') :
    print("run sth.test_rfc3918_info failed")
    print(results_ret1)
else:
    print("***** run sth.test_rfc3918_info successfully, and results is:")
    print(results_ret1)
        
ctrl_ret_stop = sth.test_rfc3918_control (
        action                                           = 'stop',
        cleanup                                          = '1');

status = ctrl_ret_stop['status']
if (status == '0') :
    print("run sth.test_rfc3918_control failed")
    print(ctrl_ret_stop)
else:
    print("***** run sth.test_rfc3918_control successfully")
        
##############################################################
# Step 12. Create join leave latency test and get results
##############################################################
print "\n+++++ Start to create test 6 -- join leave latency test : "

rfc_cfg5 = sth.test_rfc3918_config (
        mode                                             = 'create',
        test_type                                        = 'join_latency',
        multicast_streamblock                            = mc_str,
        join_group_delay                                 = '15',
        leave_group_delay                                = '15',
        mc_msg_tx_rate                                   = '2000',
        latency_type                                     = 'FIFO',
        test_duration_mode                               = 'seconds',
        test_duration                                    = '20',
        result_delay                                     = '10',
        start_test_delay                                 = '5',
        group_count                                      = '60',
        load_end                                         = '10',
        frame_size                                       = '256')  

#rfc_cfg_handle5 = rfc_cfg5['handle']        

status = rfc_cfg5['status']
if (status == '0') :
    print("run sth.test_rfc3918_config failed")
    print(rfc_cfg5)
else:
    print("***** run sth.test_rfc3918_config successfully")
    
print "+++++ Start to run join leave latency test : "
ctrl_ret1 = sth.test_rfc3918_control (
        action                                           = 'run',
        wait                                             = '1');

status = ctrl_ret1['status']
if (status == '0') :
    print("run sth.test_rfc3918_control failed")
    print(ctrl_ret1)
else:
    print("***** run sth.test_rfc3918_control successfully")


print "+++++ Start to get results of join leave latency test: "

results_ret1 = sth.test_rfc3918_info (
        test_type                                        = 'join_latency',
        clear_result                                     = '0');

status = results_ret1['status']
if (status == '0') :
    print("run sth.test_rfc3918_info failed")
    print(results_ret1)
else:
    print("***** run sth.test_rfc3918_info successfully, and results is:")
    print(results_ret1)
 
ctrl_ret_stop = sth.test_rfc3918_control (
        action                                           = 'stop',
        cleanup                                          = '1');

status = ctrl_ret_stop['status']
if (status == '0') :
    print("run sth.test_rfc3918_control failed")
    print(ctrl_ret_stop)
else:
    print("***** run sth.test_rfc3918_control successfully") 

#config part is finished
sth.invoke ('stc::perform saveasxml -filename rfc3918_all.xml')



##############################################################
# Step 13. Release resources
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
print (time.strftime("%H:%M:%S"))
