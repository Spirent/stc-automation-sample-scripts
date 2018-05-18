#################################
#
# File Name:                 HLTAPI_PPPox_IPv6_Traffic.py
#
# Description:               This script demonstrates how to test IPv6 traffic over pppox
# Test Step:                 1. Reserve and connect chassis ports
#                            2. Interface config
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
#            c:>python HLTAPI_PPPox_IPv6_Traffic.py 10.61.44.2 3/1 3/3


import sth
import time
from sys import argv

filename,device,port1,port2 = argv
port_list = [port1,port2]
port_handle = []


#Config the parameters for the logging
test_sta = sth.test_config (
    log                                              = '1',
    logfile                                          = 'pppoe_ipv6_traffic_logfile',
    vendorlogfile                                    = 'pppoe_ipv6_traffic_stcExport',
    vendorlog                                        = '1',
    hltlog                                           = '1',
    hltlogfile                                       = 'pppoe_ipv6_traffic_hltExport',
    hlt2stcmappingfile                               = 'pppoe_ipv6_traffic_hlt2StcMapping',
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
# Step2: Config interface
##############################################################

int_ret0 = sth.interface_config (
        mode                                             = 'config',
        port_handle                                      = port_handle[0],
        ipv6_gateway                                     = 'BBBB:1::1',
        ipv6_intf_addr                                   = 'BBBB:1::2',
        autonegotiation                                  = '1',
        arp_send_req                                     = '1');

status = int_ret0['status']
if (status == '0') :
    print("run sth.interface_config failed")
    print(int_ret0)
else:
    print("***** run sth.interface_config successfully")

int_ret1 = sth.interface_config (
        mode                                             = 'config',
        port_handle                                      = port_handle[1],
        ipv6_gateway                                     = 'aaaa:1::1',
        ipv6_intf_addr                                   = 'aaaa:1::2',
        autonegotiation                                  = '1',
        arp_send_req                                     = '1');

status = int_ret1['status']
if (status == '0') :
    print("run sth.interface_config failed")
    print(int_ret1)
else:
    print("***** run sth.interface_config successfully")


##############################################################
# Step3: create pppoe client
##############################################################

device_ret1 = sth.pppox_config (
        mode                                             = 'create',
        encap                                            = 'ethernet_ii',
        port_handle                                      = port_handle[0],
        protocol                                         = 'pppoe',
        ip_cp                                            = 'ipv6_cp',
        num_sessions                                     = '4',
        auth_mode                                        = 'none')

status = device_ret1['status']
if (status == '0') :
    print("run sth.pppox_config failed")
    print(device_ret1)
else:
    print("***** run sth.pppox_config successfully") 
    deviceHdlClient = device_ret1['handle']
    


##############################################
#step4: create stream block
#############################################    

streamblock = sth.traffic_config (
    mode                                                = 'create',
    port_handle                                         = port_handle[0],
    port_handle2                                        = port_handle[1],
    emulation_src_handle                                = deviceHdlClient,
    emulation_dst_handle                                = deviceHdlClient,
    l3_protocol                                         = 'ipv6',
    l2_encap                                            = 'ethernet_ii')

status = streamblock['status']
if (status =='0') :
    print "run sth.traffic_config failed"
    print streamblock
else:
    print "***** run sth.traffic_config successfully."

#config part is finished
sth.invoke ('stc::perform saveasxml -filename pppox_ipv6_traffic.xml')

##############################################################
# step5: connect pppoe client
##############################################################

pc_control = sth.pppox_control (
    action                                        = 'connect',
    handle                                        = deviceHdlClient)

status = pc_control['status']
if  status == '0' :
    print "run sth.pppox_control failed"
    print pc_control
else:
    print '***** run sth.pppox_control successfully'

time.sleep (10)

    
########################################
#step6: start and stop traffic
########################################    
traffic_ctrl = sth.traffic_control (
    port_handle = 'all',
    action = 'run');
    
status = traffic_ctrl['status']
if (status =='0') :
    print "run sth.traffic_control_start failed"
    print traffic_ctrl
else:
    print "***** run sth.traffic_control_start successfully."

#Stop traffic
time.sleep( 5 )
traffic_ctrl = sth.traffic_control (
    port_handle = 'all',
    action = 'stop');
    
status = traffic_ctrl['status']
if (status =='0') :
    print "run sth.traffic_control_stop failed"
    print traffic_ctrl
else:
    print "***** run sth.traffic_control_stop successfully."


##############################################################
# step7: get results
##############################################################

results_ret3 = sth.pppox_stats (
        handle                                           = deviceHdlClient,
        mode                                             = 'session');

status = results_ret3['status']
if (status == '0') :
    print("run sth.pppox_stats failed")
    print(results_ret3)
else:
    print("***** run sth.pppox_stats successfully, and results is:")
    print(results_ret3)


time.sleep( 2 )
traffic_result = sth.traffic_stats (
    port_handle = [port_handle[0],port_handle[1]],
    mode = 'aggregate');

status = traffic_result['status']
if (status =='0') :
    print "run sth.traffic_stats failed"
    print traffic_result
else:
    print "***** run sth.traffic_stats successfully, and results is:"
    print "aggregate traffic result : ",traffic_result; 


##############################################################
# step8: Release resources
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
