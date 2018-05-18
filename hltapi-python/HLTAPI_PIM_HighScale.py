#################################
#
# File Name:         HLTAPI_PIM_HighScale.py
#
# Description:       This script demonstrates the use of Spirent HLTAPI PIM with 20K Multicast groups.
# 
# Test Step:
#                    1. Reserve and connect chassis ports                             
#                    2. Config multicast groups  
#                    3. Config upstrem PIM router on port1 
#                    4. Config downstrem PIM router on port2
#                    5. Config traffic
#                    6. Start traffic
#                    7. Start PIM Routers
#                    8. Get PIM routers info
#                    9. Get traffic results
#                    10. Release resources
#
# Topology:
#
#              STC Port1                                  STC Port2           
#         [Upstream PIM Router1]-----------------  [Downstream PIM Router2]
#                                          
#                           
###################################

# Run sample:
#            c:\>python HLTAPI_PIM_HighScale.py 10.61.44.2 3/1 3/3

import sth
import time
from sys import argv
filename,device,port1,port2 = argv
port_list = [port1,port2]
port_handle = []

#Create function to print object Pimv4GroupBlk in sth.emulation_pim_group_config
def printProperties (lbl,handle):
    if handle.isspace() :
        print " "
    else :
        print "%s Properties" % lbl
        print "================"
        handle_list = sth.invoke ('stc::get %s' % handle)
        handle_list1 = handle_list.split(" -")
        for i in handle_list1:
            print i


#Config the parameters for the logging
test_sta = sth.test_config (
    log                                              = '1',
    logfile                                          = 'HLTAPI_PIM_HighScale_logfile',
    vendorlogfile                                    = 'HLTAPI_PIM_HighScale_stcExport',
    vendorlog                                        = '1',
    hltlog                                           = '1',
    hltlogfile                                       = 'HLTAPI_PIM_HighScale_hltExport',
    hlt2stcmappingfile                               = 'HLTAPI_PIM_HighScale_hlt2StcMapping',
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
# Step2.Config multicast groups  
##############################################################
device_ret0_pim_group0_macstgroup = sth.emulation_multicast_group_config (
        mode                                             = 'create',
        ip_prefix_len                                    = '32',
        ip_addr_start                                    = '225.18.0.10',
        ip_addr_step                                     = '1',
        num_groups                                       = '10000',
        pool_name                                        = 'Ipv4Group_1');

status = device_ret0_pim_group0_macstgroup['status']
if (status == '0') :
    print("run sth.emulation_multicast_group_config failed")
    print(device_ret0_pim_group0_macstgroup)
else:
    print("***** run sth.emulation_multicast_group_config successfully")


device_ret1_pim_group0_macstgroup = sth.emulation_multicast_group_config (
        mode                                             = 'create',
        ip_prefix_len                                    = '32',
        ip_addr_start                                    = '225.19.0.10',
        ip_addr_step                                     = '1',
        num_groups                                       = '10000',
        pool_name                                        = 'Ipv4Group_2');

status = device_ret1_pim_group0_macstgroup['status']
if (status == '0') :
    print("run sth.emulation_multicast_group_config failed")
    print(device_ret1_pim_group0_macstgroup)
else:
    print("***** run sth.emulation_multicast_group_config successfully")
    
    
##############################################################
# Step3.Config upstrem PIM router on port1
##############################################################
#start to create the device: Router 1
device_ret0 = sth.emulation_pim_config (
        mode                                             = 'create',
        prune_delay                                      = '100',
        hello_max_delay                                  = '50',
        override_interval                                = '1000',
        prune_delay_enable                               = '1',
        c_bsr_rp_addr                                    = '1.1.1.4',
        c_bsr_rp_holdtime                                = '130',
        c_bsr_rp_priority                                = '100',
        c_bsr_rp_mode                                    = 'create',
        port_handle                                      = port_handle[0],
        hello_interval                                   = '40',
        ip_version                                       = '4',
        bs_period                                        = '160',
        hello_holdtime                                   = '140',
        dr_priority                                      = '1',
        join_prune_interval                              = '80',
        bidir_capable                                    = '1',
        pim_mode                                         = 'sm',
        join_prune_holdtime                              = '240',
        type                                             = 'c_bsr',
        c_bsr_priority                                   = '1',
        router_id                                        = '13.13.0.10',
        router_id_step                                   = '0.0.1.0',
        mac_address_start                                = '00:10:94:00:00:04',
        intf_ip_addr                                     = '13.13.0.10',
        intf_ip_addr_step                                = '0.0.1.0',
        intf_ip_prefix_len                               = '24',
        neighbor_intf_ip_addr                            = '13.13.0.1');

status = device_ret0['status']
if (status == '0') :
    print("run sth.emulation_pim_config failed")
    print(device_ret0)
else:
    print("***** run sth.emulation_pim_config successfully")

# Link the upstream router to multicast group
session_handle = device_ret0['handle'].split()[0]
group_pool_handle = device_ret0_pim_group0_macstgroup['handle'].split()[0]

device_ret0_pim_group0 = sth.emulation_pim_group_config (
        mode                                             = 'create',
        session_handle                                   = session_handle,
        group_pool_handle                                = group_pool_handle,
        interval                                         = '1',
        rate_control                                     = '0',
        rp_ip_addr                                       = '1.1.1.4');

pimGroupMemberHandle1 = device_ret0_pim_group0['handle']

status = device_ret0_pim_group0['status']
if (status == '0') :
    print("run sth.emulation_pim_group_config failed")
    print(device_ret0_pim_group0)
else:
    print("***** run sth.emulation_pim_group_config successfully")
    print(device_ret0_pim_group0)
    lbl = "PIM Group Member 1"
    printProperties (lbl,pimGroupMemberHandle1)

##############################################################
# Step4.Config downstrem PIM router on port2
##############################################################

#start to create the device: Router 2
device_ret1 = sth.emulation_pim_config (
        mode                                             = 'create',
        prune_delay                                      = '100',
        hello_max_delay                                  = '30',
        override_interval                                = '1000',
        prune_delay_enable                               = '1',
        c_bsr_rp_addr                                    = '1.1.1.4',
        c_bsr_rp_holdtime                                = '30',
        c_bsr_rp_priority                                = '10',
        c_bsr_rp_mode                                    = 'create',
        port_handle                                      = port_handle[1],
        hello_interval                                   = '30',
        ip_version                                       = '4',
        bs_period                                        = '60',
        hello_holdtime                                   = '105',
        dr_priority                                      = '1',
        join_prune_interval                              = '60',
        bidir_capable                                    = '0',
        pim_mode                                         = 'sm',
        join_prune_holdtime                              = '210',
        type                                             = 'c_bsr',
        c_bsr_priority                                   = '1',
        router_id                                        = '13.14.0.10',
        mac_address_start                                = '00:10:94:00:00:05',
        intf_ip_addr                                     = '13.14.0.10',
        intf_ip_prefix_len                               = '24',
        neighbor_intf_ip_addr                            = '13.14.0.1');

status = device_ret1['status']
if (status == '0') :
    print("run sth.emulation_pim_config failed")
    print(device_ret1)
else:
    print("***** run sth.emulation_pim_config successfully")

# Link the downstream router to multicast group
session_handle = device_ret1['handle'].split()[0]
group_pool_handle = device_ret1_pim_group0_macstgroup['handle'].split()[0]

device_ret0_pim_group0 = sth.emulation_pim_group_config (
        mode                                             = 'create',
        session_handle                                   = session_handle,
        group_pool_handle                                = group_pool_handle,
        interval                                         = '1',
        rate_control                                     = '0',
        rp_ip_addr                                       = '1.1.1.4');

pimGroupMemberHandle2 = device_ret0_pim_group0['handle']

status = device_ret0_pim_group0['status']
if (status == '0') :
    print("run sth.emulation_pim_group_config failed")
    print(device_ret0_pim_group0)
else:
    print("***** run sth.emulation_pim_group_config successfully")
    print(device_ret0_pim_group0)
    lbl = "PIM Group Member 2"
    printProperties (lbl,pimGroupMemberHandle2)


##############################################################
# Step5. Config traffic
##############################################################
src_hdl = device_ret0['handle'].split()[0]

dst_hdl = device_ret1_pim_group0_macstgroup['handle'].split()[0]


streamblock_ret1 = sth.traffic_config (
        mode                                             = 'create',
        port_handle                                      = port_handle[0],
        emulation_src_handle                             = src_hdl,
        emulation_dst_handle                             = dst_hdl,
        l2_encap                                         = 'ethernet_ii',
        l3_protocol                                      = 'ipv4',
        l3_length                                        = '128',
        length_mode                                      = 'fixed',
        mac_discovery_gw                                 = '41.1.0.1',
        mac_dst_mode                                     = 'increment',
        mac_src                                          = '00.21.00.00.00.21',
        mac_dst                                          = '01:00:5E:00:00:01',
        ip_src_addr                                      = '13.13.0.10',
        ip_dst_addr                                      = '225.19.0.10');

status = streamblock_ret1['status']
if (status == '0') :
    print("run sth.traffic_config failed")
    print(streamblock_ret1)
else:
    print("***** run sth.traffic_config successfully")

src_hdl = device_ret1['handle'].split()[0]

dst_hdl = device_ret0_pim_group0_macstgroup['handle'].split()[0]


streamblock_ret2 = sth.traffic_config (
        mode                                             = 'create',
        port_handle                                      = port_handle[1],
        emulation_src_handle                             = src_hdl,
        emulation_dst_handle                             = dst_hdl,
        l2_encap                                         = 'ethernet_ii',
        l3_protocol                                      = 'ipv4',
        l3_length                                        = '128',
        length_mode                                      = 'fixed',
        mac_discovery_gw                                 = '42.1.0.1',
        mac_dst_mode                                     = 'increment',
        mac_src                                          = '00.21.00.00.00.22',
        mac_dst                                          = '01:00:5E:00:00:06',
        ip_src_addr                                      = '13.14.0.10',
        ip_dst_addr                                      = '225.18.0.10');

status = streamblock_ret2['status']
if (status == '0') :
    print("run sth.traffic_config failed")
    print(streamblock_ret2)
else:
    print("***** run sth.traffic_config successfully")

#config part is finished
sth.invoke ('stc::perform saveasxml -filename pim_highscale.xml')

##############################################################
# Step 6. Start traffic
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

##############################################################
# Step 7. Start PIM Routers
##############################################################
print "\nStart upstream pim routers"
ctrl_ret1 = sth.emulation_pim_control (
        port_handle                                      = port_handle[0],
        mode                                             = 'start');

status = ctrl_ret1['status']
if (status == '0') :
    print("run sth.emulation_pim_control failed")
    print(ctrl_ret1)
else:
    print("***** run sth.emulation_pim_control successfully")

print "\nStart downstream pim routers"

ctrl_ret2 = sth.emulation_pim_control (
        port_handle                                      = port_handle[1],
        mode                                             = 'start');

status = ctrl_ret2['status']
if (status == '0') :
    print("run sth.emulation_pim_control failed")
    print(ctrl_ret2)
else:
    print("***** run sth.emulation_pim_control successfully")

print "\nPIM routers started. Pausing 30 seconds to form neighbor relationship"

for i in range (30):
    print ".",
    time.sleep (1)

##############################################################
# Step 8. Get PIM routers info
##############################################################
device = device_ret0['handle'].split()[0]

results_ret1 = sth.emulation_pim_info (
        handle                                           = device);

status = results_ret1['status']
if (status == '0') :
    print("run sth.emulation_pim_info failed")
    print(results_ret1)
else:
    print("\n***** run sth.emulation_pim_info successfully, and results is:")
    print(results_ret1)

device = device_ret1['handle'].split()[0]

results_ret2 = sth.emulation_pim_info (
        handle                                           = device);

status = results_ret2['status']
if (status == '0') :
    print("run sth.emulation_pim_info failed")
    print(results_ret2)
else:
    print("***** run sth.emulation_pim_info successfully, and results is:")
    print(results_ret2)


##############################################################
# Step 9. Get traffic results
##############################################################
traffic_results_ret = sth.traffic_stats (
        port_handle                                      = [port_handle[0],port_handle[1]],
        mode                                             = 'aggregate');

status = traffic_results_ret['status']
if (status == '0') :
    print("run sth.traffic_stats failed")
    print(traffic_results_ret)
else:
    print("***** run sth.traffic_stats successfully, and results is:")
    print(traffic_results_ret)


##############################################################
# Step 10. Release resources
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