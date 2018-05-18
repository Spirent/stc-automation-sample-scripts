#################################
#
# File Name:         HLTAPI_ISIS_SR.py
#
# Description:       This script demonstrates the use of Spirent HLTAPI to setup ISIS with Segment Routing.                  
#
# Test Step:
#                    1. Reserve and connect chassis ports                             
#                    2. Config ISIS on port1 & port2 with Segment routing enabled in the routes
#                    3. Config bound stream traffic between ISIS router on port2 to ISIS LSP's configured on port1
#                    4. Start ISIS 
#                    5. Start Traffic
#                    6. Get ISIS Info
#                    7. Get Traffic Stats
#                    8. Release resources
#
#
# Topology:
#
#              STC Port1                      STC Port2           
#             [ISIS Router1]------------------[ISIS Router2]
#                                          
#                           
###################################

# Run sample:
#            c:\>python HLTAPI_ISIS_SR.py 10.61.44.2 1/1 1/2

import sth
import time
from sys import argv
filename,device,port1,port2 = argv
port_list = [port1,port2]
port_handle = []


#Config the parameters for the logging
test_sta = sth.test_config (
    log                                              = '1',
    logfile                                          = 'isis_logfile',
    vendorlogfile                                    = 'isis_stcExport',
    vendorlog                                        = '1',
    hltlog                                           = '1',
    hltlogfile                                       = 'isis_hltExport',
    hlt2stcmappingfile                               = 'isis_hlt2StcMapping',
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
        action                                           = 'enable');

status = test_ctrl_sta['status']
if (status == '0') :
    print("run sth.test_control failed")
    print(test_ctrl_sta)
else:
    print("***** run sth.test_control successfully")


##############################################################
# Step2.Config ISIS on port1 & port2 with Segment routing enabled in the routes
##############################################################

#start to create the device: Router 1
device_ret0 = sth.emulation_isis_config (
        mode                                             = 'enable',
        authentication_mode                              = 'none',
        intf_metric                                      = '1',
        holding_time                                     = '30',
        port_handle                                      = port_handle[0],
        router_id                                        = '192.0.0.1',
        mac_address_start                                = '00-10-94-00-00-01',
        intf_ip_prefix_length                            = '24',
        intf_ip_addr                                     = '10.1.1.1',
        gateway_ip_addr                                  = '10.1.1.2',
        hello_interval                                   = '10',
        ip_version                                       = '4',
        te_router_id                                     = '192.0.0.1',
        routing_level                                    = 'L2',
        graceful_restart_restart_time                    = '3',
        lsp_refresh_interval                             = '900',
        psnp_interval                                    = '2',
        intf_type                                        = 'broadcast',
        graceful_restart                                 = '0',
        wide_metrics                                     = '1',
        hello_padding                                    = 'true',
        area_id                                          = '000001');

status = device_ret0['status']
if (status == '0') :
    print("run sth.emulation_isis_config failed")
    print(device_ret0)
else:
    print("***** run sth.emulation_isis_config successfully")

isis_hnd1 = device_ret0['handle']

#configure ISIS LSP with segment routing enabled
lspStatus = sth.emulation_isis_lsp_generator (
        mode                                             = 'create',
        handle                                           = isis_hnd1,
        type                                             = 'tree',
        loopback_adver_enable                            = 'true', 
        tree_if_type                                     = 'POINT_TO_POINT',
        ipv4_internal_emulated_routers                   = 'NONE',
        ipv4_internal_simulated_routers                  = 'ALL',
        ipv4_internal_count                              = '0',
        tree_max_if_per_router                           = '2',
        tree_num_simulated_routers                       = '2',
        router_id_start                                  = '3.0.0.1',
        ipv4_addr_start                                  = '3.0.0.0',
        system_id_start                                  = '100000000001',
        isis_level                                       = 'LEVEL2',
        segment_routing_enabled                          = 'true',
        sr_algorithms                                    = '0',
        sr_cap_range                                     = '100',
        sr_cap_value                                     = '100',
        sr_cap_value_type                                = 'label')

status = lspStatus['status']
if (status == '0') :
    print("run sth.emulation_isis_lsp_generator failed")
    print(lspStatus)
else:
    print("***** run sth.emulation_isis_lsp_generator successfully")


lsp1 = lspStatus['lsp_handle']
print "lsp_handle are : %s" % lsp1
    

    
#start to create the device: Router 2
device_ret1 = sth.emulation_isis_config (
        mode                                             = 'enable',
        authentication_mode                              = 'none',
        intf_metric                                      = '1',
        holding_time                                     = '30',
        port_handle                                      = port_handle[1],
        router_id                                        = '192.0.0.2',
        mac_address_start                                = '00-10-94-00-00-02',
        intf_ip_prefix_length                            = '24',
        intf_ip_addr                                     = '10.1.1.2',
        gateway_ip_addr                                  = '10.1.1.1',
        hello_interval                                   = '10',
        ip_version                                       = '4',
        te_router_id                                     = '192.0.0.1',
        routing_level                                    = 'L2',
        graceful_restart_restart_time                    = '3',
        lsp_refresh_interval                             = '900',
        psnp_interval                                    = '2',
        intf_type                                        = 'broadcast',
        graceful_restart                                 = '0',
        wide_metrics                                     = '1',
        hello_padding                                    = 'true',
        area_id                                          = '000001');

status = device_ret1['status']
if (status == '0') :
    print("run sth.emulation_isis_config failed")
    print(device_ret1)
else:
    print("***** run sth.emulation_isis_config successfully")

isis_hnd2 = device_ret1['handle']

#configure ISIS LSP with segment routing enabled
lspStatus1 = sth.emulation_isis_lsp_generator (
        mode                                             = 'create',
        handle                                           = isis_hnd2,
        type                                             = 'tree',
        loopback_adver_enable                            = 'true', 
        tree_if_type                                     = 'POINT_TO_POINT',
        ipv4_internal_emulated_routers                   = 'NONE',
        ipv4_internal_simulated_routers                  = 'ALL',
        ipv4_internal_count                              = '10',
        tree_max_if_per_router                           = '2',
        tree_num_simulated_routers                       = '2',
        router_id_start                                  = '4.0.0.1',
        ipv4_addr_start                                  = '4.0.0.0',
        system_id_start                                  = '100000000002',
        isis_level                                       = 'LEVEL2',
        segment_routing_enabled                          = 'true',
        sr_algorithms                                    = '0',
        sr_cap_range                                     = '100',
        sr_cap_value                                     = '100',
        sr_cap_value_type                                = 'label')

status = lspStatus1['status']
if (status == '0') :
    print("run sth.emulation_isis_lsp_generator failed")
    print(lspStatus1)
else:
    print("***** run sth.emulation_isis_lsp_generator successfully")
    print(lspStatus1)

#########################################################################
# Step3. Config bound stream traffic from ISIS router on port2 to port1
#########################################################################
src_hdl = device_ret1['handle'].split()[0]


streamblock_ret1 = sth.traffic_config (
        mode                                             = 'create',
        port_handle                                      = port_handle[1],
        emulation_src_handle                             = src_hdl,
        emulation_dst_handle                             = lsp1,
        tunnel_bottom_label                              = src_hdl,
        l3_protocol                                      = 'ipv4',
        ip_id                                            = '0',
        ip_dst_addr                                      = '192.0.0.1',
        ip_ttl                                           = '255',
        ip_hdr_length                                    = '5',
        ip_protocol                                      = '253',
        ip_fragment_offset                               = '0',
        ip_mbz                                           = '0',
        ip_precedence                                    = '6',
        ip_tos_field                                     = '0',
        enable_control_plane                             = '0',
        l3_length                                        = '128',
        name                                             = 'StreamBlock_2-2',
        fill_type                                        = 'constant',
        fcs_error                                        = '0',
        fill_value                                       = '0',
        frame_size                                       = '128',
        traffic_state                                    = '1',
        high_speed_result_analysis                       = '1',
        length_mode                                      = 'fixed',
        tx_port_sending_traffic_to_self_en               = 'false',
        disable_signature                                = '0',
        enable_stream_only_gen                           = '1',
        pkts_per_burst                                   = '1',
        inter_stream_gap_unit                            = 'bytes',
        burst_loop_count                                 = '1',
        transmit_mode                                    = 'multi_burst',
        inter_stream_gap                                 = '12',
        rate_percent                                     = '10',
        mac_discovery_gw                                 = '10.1.1.1');

status = streamblock_ret1['status']
if (status == '0') :
    print("run sth.traffic_config failed")
    print(streamblock_ret1)
else:
    print("***** run sth.traffic_config successfully")

#config part is finished
sth.invoke ('stc::perform saveasxml -filename isis_sr.xml')

##############################################################
# Step4. Start ISIS
##############################################################
device_list0 = device_ret0['handle'].split()[0]

ctrl_ret0 = sth.emulation_isis_control (
        handle                                           = device_list0,
        mode                                             = 'start');

status = ctrl_ret0['status']
if (status == '0') :
    print("run sth.emulation_isis_control failed")
    print(ctrl_ret0)
else:
    print("***** run sth.emulation_isis_control successfully")

device_list1 = device_ret1['handle'].split()[0]

ctrl_ret1 = sth.emulation_isis_control (
        handle                                           = device_list1,
        mode                                             = 'start');

status = ctrl_ret1['status']
if (status == '0') :
    print("run sth.emulation_isis_control failed")
    print(ctrl_ret1)
else:
    print("***** run sth.emulation_isis_control successfully")

##############################################################
# Step5. Start Traffic
##############################################################

traffic_ctrl_ret = sth.traffic_control (
        port_handle                                      = [port_handle[0],port_handle[1]],
        action                                           = 'run');

status = traffic_ctrl_ret['status']
if (status == '0') :
    print("run sth.traffic_control failed")
    print(traffic_ctrl_ret)
else:
    print("***** run sth.traffic_control successfully")

time.sleep (3)    
########################################
# Step6. Get ISIS Info
########################################     
device0 = device_ret0['handle'].split()[0]

results_ret0 = sth.emulation_isis_info (
        handle                                           = device0,
        mode                                             = 'stats');

status = results_ret0['status']
if (status == '0') :
    print("run sth.emulation_isis_info failed")
    print(results_ret0)
else:
    print("***** run sth.emulation_isis_info successfully, and results is:")
    print(results_ret0)

device1 = device_ret1['handle'].split()[0]

results_ret1 = sth.emulation_isis_info (
        handle                                           = device1,
        mode                                             = 'stats');

status = results_ret1['status']
if (status == '0') :
    print("run sth.emulation_isis_info failed")
    print(results_ret1)
else:
    print("***** run sth.emulation_isis_info successfully, and results is:")
    print(results_ret1)

time.sleep (3)
##############################################################
# Step 7. Get Traffic Stats
##############################################################
traffic_results_ret = sth.traffic_stats (
        port_handle                                      = [port_handle[0],port_handle[1]],
        mode                                             = 'all');

status = traffic_results_ret['status']
if (status == '0') :
    print("run sth.traffic_stats failed")
    print(traffic_results_ret)
else:
    print("***** run sth.traffic_stats successfully, and results is:")
    print(traffic_results_ret)

##############################################################
# Step 8. Release resources
##############################################################

cleanup_sta = sth.cleanup_session (
          port_handle                                      = [port_handle[0],port_handle[1]],
          clean_dbfile                                     = '1');

status = cleanup_sta['status']
if (status == '0') :
     print("run sth.cleanup_session failed")
     print(cleanup_sta)
else:
     print("***** run sth.cleanup_session successfully")


print("**************Finish***************")