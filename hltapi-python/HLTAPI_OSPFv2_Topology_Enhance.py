#################################
#
# File Name:         HLTAPI_OSPFv2_topylogy_enhance.py
#
# Description:       This script demonstrates the use of Spirent HLTAPI to setup OSPFv2 with enhancement for 
#                    emulation_ospf_topology_route_config.                  
#                    1)For these LSAs (type ext_routes, nssa_routes, summary_routes, router), a default router LSA for the #                      emulated router1(created by emulation_ospf_config) will be created automatically.
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
#            c:>python HLTAPI_OSPFv2_topylogy_enhance.py 10.61.44.2 3/1 3/3

import sth
import time
from sys import argv
filename,device,port1,port2 = argv
port_list = [port1,port2]
port_handle = []


#Config the parameters for the logging
test_sta = sth.test_config (
    log                                              = '1',
    logfile                                          = 'ospf_enhance_logfile',
    vendorlogfile                                    = 'ospf_enhance_stcExport',
    vendorlog                                        = '1',
    hltlog                                           = '1',
    hltlogfile                                       = 'iospf_enhance_hltExport',
    hlt2stcmappingfile                               = 'ospf_enhance_hlt2StcMapping',
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
# Step2.Config OSPF routers and routes on port1 & port2 
##############################################################

#start to create the device: Router 1
#configure OSPF router1 on port1
device_ret0 = sth.emulation_ospf_config (
        mode                                             = 'create',
        session_type                                     = 'ospfv2',
        port_handle                                      = port_handle[0],
        count                                            = '4',
        dead_interval                                    = '200',
        area_id                                          = '0.0.0.4',
        demand_circuit                                   = '1',
        router_id                                        = '2.2.2.2',
        router_id_step                                   = '0.0.0.10',
        mac_address_start                                = '00:10:94:00:00:31',
        intf_ip_addr                                     = '1.100.0.1',
        intf_ip_addr_step                                = '0.0.0.1',
        gateway_ip_addr                                  = '1.100.0.101',
        gateway_ip_addr_step                             = '0.0.0.1',
        graceful_restart_enable                          = '1')

status = device_ret0['status']
if (status == '0') :
    print("run sth.emulation_ospf_config failed")
    print(device_ret0)
else:
    print("***** run sth.emulation_ospf_config successfully")

handle_list1 = device_ret0['handle']
router1 = handle_list1.split(' ')[0]
router2 = handle_list1.split(' ')[1]
router5 = handle_list1.split(' ')[2]


#start to create the device: Router5-8
#configure OSPF router5-8 on port2

device_ret1 = sth.emulation_ospf_config (
        mode                                             = 'create',
        session_type                                     = 'ospfv2',
        port_handle                                      = port_handle[1],
        count                                            = '4',
        dead_interval                                    = '200',
        area_id                                          = '0.0.0.4',
        demand_circuit                                   = '1',
        router_id                                        = '1.1.1.1',
        router_id_step                                   = '0.0.0.1',
        mac_address_start                                = '00:10:94:00:00:32',
        intf_ip_addr                                     = '1.100.0.101',
        intf_ip_addr_step                                = '0.0.0.1',
        gateway_ip_addr                                  = '1.100.0.1',
        gateway_ip_addr_step                             = '0.0.0.1',
        graceful_restart_enable                          = '1',
        area_type                                        = 'stub')

status = device_ret1['status']
if (status == '0') :
    print("run sth.emulation_ospf_config failed")
    print(device_ret1)
else:
    print("***** run sth.emulation_ospf_config successfully")
    
handle_list2 = device_ret1['handle']
router3 = handle_list2.split(' ')[0]
router4 = handle_list2.split(' ')[1]
router6 = handle_list2.split(' ')[2]

print "\n %s , type ext_routes " % router1

route_config1 = sth.emulation_ospf_topology_route_config (
        mode                                              = 'create',
        type                                              = 'ext_routes',
        handle                                            = router1,
        external_number_of_prefix                         = '30',
        external_prefix_start                             = '91.0.0.1',
        external_prefix_step                              = '2',
        external_prefix_length                            = '32',
        external_prefix_type                              = '2')

status = route_config1['status']
if (status == '0') :
    print("run sth.emulation_ospf_topology_route_config failed")
    print(route_config1)
else:
    print("***** run sth.emulation_ospf_topology_route_config successfully")

print "\n %s , type ext_routes " % router1

route_config2 = sth.emulation_ospf_topology_route_config (
        mode                                              = 'create',
        type                                              = 'ext_routes',
        handle                                            = router1,
        external_number_of_prefix                         = '20',
        external_prefix_start                             = '191.0.0.1',
        external_prefix_step                              = '2',
        external_prefix_length                            = '32',
        external_prefix_type                              = '2')

status = route_config2['status']
if (status == '0') :
    print("run sth.emulation_ospf_topology_route_config failed")
    print(route_config2)
else:
    print("***** run sth.emulation_ospf_topology_route_config successfully")

print "\n %s , type grid+ext_routes " % router2

route_config3 = sth.emulation_ospf_topology_route_config (
        mode                                              = 'create',
        type                                              = 'grid',
        handle                                            = router2,
        grid_connect                                      = '1 1',
        grid_col                                          = '2',
        grid_row                                          = '2',
        grid_link_type                                    = 'ptop_unnumbered',
        grid_router_id                                    = '2.2.2.2',
        grid_router_id_step                               = '0.0.0.1')

status = route_config3['status']
if (status == '0') :
    print("run sth.emulation_ospf_topology_route_config failed")
    print(route_config3)
else:
    print("***** run sth.emulation_ospf_topology_route_config successfully")

gridSession = route_config3['grid']['connected_session']
ospfGrid = route_config3['elem_handle']

route_config4 = sth.emulation_ospf_topology_route_config (
        mode                                              = 'create',
        type                                              = 'ext_routes',
        handle                                            = router2,
        external_number_of_prefix                         = '30',
        external_prefix_start                             = '91.0.0.1',
        external_prefix_step                              = '2',
        external_prefix_length                            = '32',
        external_prefix_type                              = '2')

status = route_config4['status']
if (status == '0') :
    print("run sth.emulation_ospf_topology_route_config failed")
    print(route_config4)
else:
    print("***** run sth.emulation_ospf_topology_route_config successfully")

print "\n type nssa_routes"

route_config5 = sth.emulation_ospf_topology_route_config (
        mode                                              = 'create',
        type                                              = 'nssa_routes',
        handle                                            = router1,
        nssa_number_of_prefix                             = '30',
        nssa_prefix_forward_addr                          = '10.0.0.1',
        nssa_prefix_start                                 = '90.0.0.1',
        nssa_prefix_step                                  = '2',
        nssa_prefix_length                                = '32',
        nssa_prefix_metric                                = '5',
        nssa_prefix_type                                  = '2')

status = route_config5['status']
if (status == '0') :
    print("run sth.emulation_ospf_topology_route_config failed")
    print(route_config5)
else:
    print("***** run sth.emulation_ospf_topology_route_config successfully")

route_config6 = sth.emulation_ospf_topology_route_config (
        mode                                              = 'create',
        type                                              = 'nssa_routes',
        nssa_connect                                      = '1 1',
        handle                                            = router2,
        nssa_number_of_prefix                             = '30',
        nssa_prefix_forward_addr                          = '10.0.0.1',
        nssa_prefix_start                                 = '90.0.0.1',
        nssa_prefix_step                                  = '2',
        nssa_prefix_length                                = '32',
        nssa_prefix_metric                                = '5',
        nssa_prefix_type                                  = '2')

status = route_config6['status']
if (status == '0') :
    print("run sth.emulation_ospf_topology_route_config failed")
    print(route_config6)
else:
    print("***** run sth.emulation_ospf_topology_route_config successfully")

print "\n %s ,type summary_routes" % router3

route_config7 = sth.emulation_ospf_topology_route_config (
        mode                                              = 'create',
        type                                              = 'summary_routes',
        handle                                            = router3,
        summary_number_of_prefix                          = '20',
        summary_prefix_start                              = '91.0.1.0',
        summary_prefix_step                               = '2',
        summary_prefix_length                             = '27',
        summary_prefix_metric                             = '10')

status = route_config7 ['status']
if (status == '0') :
    print("run sth.emulation_ospf_topology_route_config failed")
    print(route_config7)
else:
    print("***** run sth.emulation_ospf_topology_route_config successfully")

print "\n %s ,type router" % router4

route_config8 = sth.emulation_ospf_topology_route_config (
        mode                                              = 'create',
        type                                              = 'router',
        handle                                            = router4,
        link_enable                                       = '0',
        router_id                                         = '10.0.0.1')

status = route_config8 ['status']
if (status == '0') :
    print("run sth.emulation_ospf_topology_route_config failed")
    print(route_config8)
else:
    print("***** run sth.emulation_ospf_topology_route_config successfully")

print "\n %s ,type router" % router4

route_config9 = sth.emulation_ospf_topology_route_config (
        mode                                              = 'create',
        type                                              = 'router',
        handle                                            = router4,
        link_enable                                       = '1',
        router_id                                         = '20.0.0.1')

status = route_config8 ['status']
if (status == '0') :
    print("run sth.emulation_ospf_topology_route_config failed")
    print(route_config8)
else:
    print("***** run sth.emulation_ospf_topology_route_config successfully")

#config part is finished
sth.invoke ('stc::perform saveasxml -filename ospfv2_topology_enhance.xml')   
 
##############################################################
# Step 3. Start OSPF
############################################################## 
for i in range (0,4) :
        devices1 = handle_list1.split(" ")[i]
        ctrl_ret1 = sth.emulation_ospf_control (
            handle                                           = devices1,
            mode                                             = 'start');

        status = ctrl_ret1['status']
        if (status == '0') :
            print("run sth.emulation_ospf_control failed")
            print(ctrl_ret1)
        else:
            print("***** run sth.emulation_ospf_control successfully")

for i in range (0,4) :
        devices2 = handle_list2.split(" ")[i]
        ctrl_ret2 = sth.emulation_ospf_control (
            handle                                           = devices2,
            mode                                             = 'start');

        status = ctrl_ret2['status']
        if (status == '0') :
            print("run sth.emulation_ospf_control failed")
            print(ctrl_ret2)
        else:
            print("***** run sth.emulation_ospf_control successfully")            

time.sleep (10)            
##############################################################
# Step 4. Get OSPF info
##############################################################             
for i in range (0,4) :
        devices1 = handle_list1.split(" ")[i]
        result_ret1 = sth.emulation_ospfv2_info (
            handle                                           = devices1);

        status = result_ret1['status']
        if (status == '0') :
            print("run sth.emulation_ospf_info failed")
            print(result_ret1)
        else:
            print("***** run sth.emulation_ospf_info successfully")
            print(result_ret1)

for i in range (0,4) :
        devices2 = handle_list2.split(" ")[i]
        result_ret2 = sth.emulation_ospfv2_info (
            handle                                           = devices2);

        status = result_ret2['status']
        if (status == '0') :
            print("run sth.emulation_ospf_info failed")
            print(result_ret2)
        else:
            print("***** run sth.emulation_ospf_info successfully")
            print(result_ret2)

for i in range (0,4) :
        devices1 = handle_list1.split(" ")[i]
        result_ret3 = sth.emulation_ospf_route_info (
            handle                                           = devices1);

        status = result_ret3['status']
        if (status == '0') :
            print("run sth.emulation_ospf_route_info failed")
            print(result_ret3)
        else:
            print("***** run sth.emulation_ospf_route_info successfully")
            print(result_ret3)

for i in range (0,4) :
        devices2 = handle_list2.split(" ")[i]
        result_ret4 = sth.emulation_ospf_route_info (
            handle                                           = devices2);

        status = result_ret4['status']
        if (status == '0') :
            print("run sth.emulation_ospf_route_info failed")
            print(result_ret4)
        else:
            print("***** run sth.emulation_ospf_route_info successfully")
            print(result_ret4)


##############################################################
# Step 5. Release resources
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