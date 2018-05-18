################################################################################
#
# File Name:         HLTAPI_IGMP_Querier.py
#
# Description:       This script demonstrates the use of Spirent HLTAPI to setup Igmp Router.
#
# Test Step:          1. Reserve and connect chassis ports
#                     2. Configure IGMP Querier(router) on port1
#                     3. Configure IGMP Host on port2
#                     4. Setup Multicast group
#                     5. Attach multicast group to IGMP Host
#                     6. Start capture on all ports
#                     7. Join IGMP hosts to multicast group
#                     8. Get IGMP hosts Stats
#                     9. Start IGMP Querier
#                     10. Get the IGMP Querier Stats
#                     11. Check and Display IGMP router states
#                     12. Stop IGMP Querier
#                     13. Leave IGMP Host from the Multicast Group
#                     14. Stop the packet capture 
#                     15. Delete IGMP Querier 
#                     16. Release Resources
#
#
# Topology
#                   STC Port1                      STC Port2                       
#                [IGMP Queriers]-------------------[IGMP Hosts]
#                                              
################################################################################
# Run sample:
#            c:>python HLTAPI_IGMP_Querier.py 10.61.44.2 3/1 3/3

import sth
import time
from sys import argv
filename,device,port1,port2 = argv
port_list = [port1,port2]
port_handle = []
captureFlag = 0

#Config the parameters for the logging
test_sta = sth.test_config (
    log                                              = '1',
    logfile                                          = 'HLTAPI_Igmp_Querier_logfile',
    vendorlogfile                                    = 'HLTAPI_Igmp_Querier_stcExport',
    vendorlog                                        = '1',
    hltlog                                           = '1',
    hltlogfile                                       = 'HLTAPI_Igmp_Querier_hltExport',
    hlt2stcmappingfile                               = 'HLTAPI_Igmp_Querier_hlt2StcMapping',
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
# Step 2. Configure IGMP Querier(router) on port1
##############################################################
print "Create the igmp querier router on port1"

device_ret0 = sth.emulation_igmp_querier_config (
        mode                                             = 'create',
        port_handle                                      = port_handle[0],
        count                                            = '7',
        igmp_version                                     = 'v2',
        intf_ip_addr                                     = '1.1.1.40',
        intf_ip_addr_step                                = '0.0.0.1',
        neighbor_intf_ip_addr                            = '1.1.1.10',
        neighbor_intf_ip_addr_step                       = '0.0.0.1',
        vlan_id                                          = '111',
        vlan_id_count                                    = '3',
        vlan_id_step                                     = '2',
        vlan_id_mode                                     = 'increment',
        vlan_id_outer                                    = '101',
        vlan_id_outer_count                              = '5',
        vlan_id_outer_step                               = '2',
        vlan_id_outer_mode                               = 'increment')
        
status = device_ret0['status']
if (status == '0') :
    print("run sth.emulation_igmp_querier_config failed")
    print(device_ret0)
else:
    print("***** run sth.emulation_igmp_querier_config successfully")

igmpQuerierRouterList = device_ret0['handle']
    
##############################################################
# Step 3. Configure IGMP Host on port2
##############################################################
print "Create the igmp host on port2"

device_ret1 = sth.emulation_igmp_config (
        mode                                             = 'create',
        port_handle                                      = port_handle[1],
        count                                            = '7',
        igmp_version                                     = 'v2',
        robustness                                       = '10',
        intf_ip_addr                                     = '1.1.1.10',
        intf_ip_addr_step                                = '0.0.0.1',
        neighbor_intf_ip_addr                            = '1.1.1.40',
        neighbor_intf_ip_addr_step                       = '0.0.0.1',
        vlan_id                                          = '111',
        vlan_id_count                                    = '3',
        vlan_id_step                                     = '2',
        vlan_id_mode                                     = 'increment',
        vlan_id_outer                                    = '101',
        vlan_id_outer_count                              = '5',
        vlan_id_outer_step                               = '2',
        vlan_id_outer_mode                               = 'increment',
        qinq_incr_mode                                   = 'outer',
        general_query                                    = '1',
        group_query                                      = '1')
        
status = device_ret1['status']
if (status == '0') :
    print("run sth.emulation_igmp_config failed")
    print(device_ret1)
else:
    print("***** run sth.emulation_igmp_config successfully")

igmpHostHandle = device_ret1['handle']
##############################################################
# Step 4. Setup Multicast group
##############################################################
groupStatus = sth.emulation_multicast_group_config (
        ip_addr_start                                    = '225.1.0.1',
        mode                                             = 'create',
        num_groups                                       = '1')
        
status = groupStatus['status']
if (status == '0') :
    print("***** Created Multicast Group failed")
    print(groupStatus)
else:
    print("***** Created Multicast Group successfully")
    
mcGroupHandle = groupStatus['handle']

##############################################################
# Step 5. Attach multicast group to IGMP Host
##############################################################
membershipStatus = sth.emulation_igmp_group_config (
        session_handle                                   = igmpHostHandle,
        mode                                             = 'create',
        group_pool_handle                                = mcGroupHandle);

status = membershipStatus['status']
if (status == '0') :
    print("***** Attached Multicast Group to Host failed")
    print(membershipStatus)
else:
    print("***** Attached Multicast Group to Host successfully")
    
##############################################################
# Step 6. Start capture on all ports
##############################################################
if captureFlag == 0 :
    print "starting the capture on all ports"
    #Set data packet capture and start capture
    packet_control = sth.packet_control (
        port_handle = 'all',
        action = 'start')

##############################################################
# Step 7. Join IGMP hosts to multicast group
##############################################################
print " IGMP Host Join the Multicast Group"
joinStatus = sth.emulation_igmp_control (
        handle                                           = igmpHostHandle,
        mode                                             = 'join');

status = joinStatus['status']
if (status == '0') :
    print("Started(Join) IGMP Host failed")
    print(joinStatus)
else:
    print("***** Started(Join) IGMP Host successfully")

time.sleep(10)

#config part is finished
sth.invoke ('stc::perform saveasxml -filename igmp_querier.xml')

##############################################################
# Step 8. Get IGMP hosts Stats
##############################################################
results_hosts = sth.emulation_igmp_info (
        handle                                           = igmpHostHandle,
        mode                                             = 'stats');

status = results_hosts['status']
if (status == '0') :
    print("run sth.emulation_igmp_host_info failed")
    print(results_hosts)
else:
    print("***** run sth.emulation_igmp_host_info successfully, and results is:")
    print(results_hosts)
    
##############################################################
# Step 9. Start IGMP Querier
##############################################################
querier_control = sth.emulation_igmp_querier_control (
        port_handle                                      = port_handle[0],
        mode                                             = 'start');

status = querier_control['status']
if (status == '0') :
    print("run sth.emulation_igmp_querier_control failed")
    print(querier_control)
else:
    print("***** run sth.emulation_igmp_querier_control successfully, and results is:")


time.sleep(10)

##############################################################
# Step 10. Get the IGMP Querier Stats
##############################################################
igmpQuerierInfo = sth.emulation_igmp_querier_info (
        port_handle                                      = port_handle[0]);

status = igmpQuerierInfo['status']
if (status == '0') :
    print("run sth.emulation_igmp_querier_info failed")
    print(igmpQuerierInfo)
else:
    print("***** run sth.emulation_igmp_querier_info successfully, and results is:")
    print(igmpQuerierInfo)

##############################################################
# Step 11. Check and Display IGMP router states
##############################################################
for router in igmpQuerierRouterList.split() :
    routerState = igmpQuerierInfo['results'][router]['router_state'] 
    print " Router: %s Router State: %s" % (router,routerState)
    if routerState != 'UP':
        print " IGMP Querier %s is not UP " % router

##############################################################
# Step 12. Stop IGMP Querier
##############################################################
querierStopStatus = sth.emulation_igmp_querier_control (
        port_handle                                      = port_handle[0],
        mode                                             = 'stop');

status = querierStopStatus['status']
if (status == '0') :
    print("***** Stop IGMP Querier failed")
    print(querierStopStatus)
else:
    print("***** Stop IGMP Querier successfully")

##############################################################
# Step 13. Leave IGMP Host from the Multicast Group
##############################################################
print " Leave IGMP Hosts from the Multicast Group"
leaveStatus = sth.emulation_igmp_control (
        handle                                           = igmpHostHandle,
        mode                                             = 'leave');

status = leaveStatus['status']
if (status == '0') :
    print("***** IGMP Hosts left IGMP group failed")
    print(leaveStatus)
else:
    print("***** IGMP Hosts left IGMP group successfully")

    
##############################################################
# Step 14. Stop the packet capture
##############################################################
#Stop capture and get captured pcap file
if captureFlag == 0 :
    packet_stats1 = sth.packet_stats (
        port_handle = port_handle[0],
        action = 'filtered',
        stop = '1',
        format = 'pcap',
        filename = 'igmp_querier_port1.pcap');
        
    packet_stats2 = sth.packet_stats (
        port_handle = port_handle[1],
        action = 'filtered',
        stop = '1',
        format = 'pcap',
        filename = 'igmp_querier_port2.pcap');

##############################################################
# Step 15. Delete IGMP Querier
##############################################################    
querierDeleteStatus = sth.emulation_igmp_querier_config (
        handle                                           = igmpQuerierRouterList,
        mode                                             = 'delete');

status = querierDeleteStatus['status']
if (status == '0') :
    print("***** Delete IGMP Querier failed")
    print(querierDeleteStatus)
else:
    print("***** Delete IGMP Querier successfully")    
    
##############################################################
# Step 16. Release resources
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