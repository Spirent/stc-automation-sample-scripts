
#################################
#
# File Name:         HLTAPI_PPPox_Server_b2b.py
#
# Description:       This script demonstrates the use of Spirent HLTAPI to setup PPPox Server devices
#                    and create bound traffic between PPPox servers and clients.                  
#
# Test Step:         1. Reserve and connect chassis ports
#                    2. Interface config
#                    3. Config PPPox Server
#                    4. Config PPPox Clients
#                    5. Connect PPPoE server & client
#                    6. Check PPPoE server & client Stats
#                    7. Stop PPPoE server & client
#                    8. Release resources
#
# DUT configuration:
#           none
#
# Topology
#                 STC Port1                    STC Port2                       
#               [PPPox Servers]----------------[PPPox Clients]
#                       <-----traffic stream----->
#                                         
#
#################################

# Run sample:
#            c:>python HLTAPI_PPPox_Server_b2b.py 10.61.44.2 3/1 3/3


import sth
import time
from sys import argv

filename,device,port1,port2 = argv
port_list = [port1,port2]
port_handle = []
deviceNum = 10

#Config the parameters for the logging
test_sta = sth.test_config (
    log                                              = '1',
    logfile                                          = 'pppox_logfile',
    vendorlogfile                                    = 'pppox_stcExport',
    vendorlog                                        = '1',
    hltlog                                           = '1',
    hltlogfile                                       = 'pppox_hltExport',
    hlt2stcmappingfile                               = 'pppox_hlt2StcMapping',
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

########################################
# Step2: Interface config
########################################

int_ret0 = sth.interface_config (
    mode                                             = 'config',
    port_handle                                      = port_handle[0],
    intf_mode                                        = 'ethernet',
    duplex                                           = 'full',
    autonegotiation                                  = '1');

status = int_ret0['status']
if (status == '0') :
    print "run sth.interface_config failed"
    print int_ret0
else:
    print "***** run sth.interface_config successfully"

int_ret1 = sth.interface_config (
    mode                                             = 'config',
    port_handle                                      = port_handle[1],
    intf_mode                                        = 'ethernet',
    duplex                                           = 'full',
    autonegotiation                                  = '1');

status = int_ret1['status']
if (status == '0') :
    print "run sth.interface_config failed"
    print int_ret1
else:
    print "***** run sth.interface_config successfully"
    

########################################
# Step3: Config PPPox Server
########################################
device_ps = sth.pppox_server_config (
    port_handle                                      = port_handle[0],
    num_sessions                                     = deviceNum,
    encap                                            = 'ethernet_ii_qinq',
    protocol                                         = 'pppoe',
    attempt_rate                                     = '50',
    disconnect_rate                                  = '50',
    max_outstanding                                  = '100',
    auth_mode                                        = 'chap',
    username                                         = 'spirent',
    password                                         = 'spirent',
    mac_addr                                         = '00:10:94:01:00:01',
    mac_addr_step                                    = '00.00.00.00.00.01',
    intf_ip_addr                                     = '192.0.0.8',
    intf_ip_addr_step                                = '0.0.0.1',
    gateway_ip_addr                                  = '192.0.0.1',
    qinq_incr_mode                                   = 'inner',
    vlan_id                                          = '200',
    vlan_id_count                                    = '2',
    vlan_id_outer                                    = '300',
    vlan_id_outer_count                              = '5',
    ipv4_pool_addr_start                             = '10.1.0.0',
    ipv4_pool_addr_prefix_len                        = '24',
    ipv4_pool_addr_count                             = '50',
    ipv4_pool_addr_step                              = '1')
 
status = device_ps['status']
if  status == '0' :
    print "run sth.pppox_server_config failed"
    print device_ps
else:
    print "***** run sth.pppox_server_config successfully"
 
########################################
# Step4: Config PPPox Clients
########################################

device_pc = sth.pppox_config (
    mode                                             = 'create',
    port_handle                                      = port_handle[1],
    encap                                            = 'ethernet_ii_qinq',
    protocol                                         = 'pppoe',
    ip_cp                                            = 'ipv4_cp',
    num_sessions                                     = deviceNum,
    auth_mode                                        = 'chap',
    username                                         = 'spirent',
    password                                         = 'spirent',
    mac_addr                                         = '00:10:94:01:00:45',
    mac_addr_step                                    = '00.00.00.00.00.01',
    vlan_id                                          = '200',
    vlan_id_count                                    = '2',
    vlan_id_outer                                    = '300',
    vlan_id_outer_count                              = '5')

status = device_pc['status']
if  status == '0' :
    print "run sth.pppox_config failed"
    print device_pc
else:
    print '***** run sth.pppox_config successfully'

#config part is finished
sth.invoke ('stc::perform saveasxml -filename pppox_server.xml')

########################################
# Step5: Connect PPPoE server & client
########################################    
   
print 'Connect PPPoE server'

ps_control = sth.pppox_server_control (
    action                                        = 'connect',
    port_handle                                   = port_handle[0])

status = ps_control['status']
if  status == '0' :
    print "run sth.pppox_server_control failed"
    print ps_control
else:
    print '***** run sth.pppox_server_control successfully'

print 'Bind PPPoE Client'

clientHandle = device_pc['handle']

pc_control = sth.pppox_control (
    action                                        = 'connect',
    handle                                        = clientHandle)

status = pc_control['status']
if  status == '0' :
    print "run sth.pppox_control failed"
    print pc_control
else:
    print '***** run sth.pppox_control successfully'


time.sleep (10)
    
########################################
# Step6: Check PPPoE server & client Stats
########################################
print "Get PPPoE Server Stats"

results_ps = sth.pppox_server_stats (
    port_handle                     = port_handle[0],
    mode                            = 'aggregate');

status = results_ps['status']

if status == 0 :
    print "get results_ps failed :"
    print results_ps

connect = results_ps['aggregate']['connected']


if connect == '1' :
    print "PPPoE server and clients connected successfully"
else :
    print "The connection of PPPoE server and clients is failed"

print "Get PPPoE Client Stats"

results_pc = sth.pppox_stats (
    handle                          = clientHandle,
    mode                            = 'session');

status = results_pc['status']

if status == 0 :
    print "get results_pc failed :"
    print results_pc


print "The assigned pppoe client ipv4 addresses are:"

for i in range(deviceNum,0,-1) :
    i = str(i)
    ip = results_pc['session']['%s' % i]['ip_addr']
    print ip

########################################
#step7: Stop PPPoE server & client
########################################

print 'Stop PPPoE Client'

pc_stop = sth.pppox_control (
    action                                        = 'disconnect',
    handle                                        = clientHandle)

status = pc_stop['status']
if  status == '0' :
    print "run sth.pppox_client_stop failed"
    print pc_stop
else:
    print '***** run sth.pppox_client_stop successfully'


print 'Stop PPPoE Server'

ps_stop = sth.pppox_server_control (
    action                                        = 'disconnect',
    port_handle                                   = port_handle[0])

status = ps_stop['status']
if  status == '0' :
    print "run sth.pppox_server_stop failed"
    print ps_stop
else:
    print '***** run sth.pppox_server_stop successfully'


########################################
#step8: Release resources
########################################
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
