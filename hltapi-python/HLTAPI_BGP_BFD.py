#################################
#
# File Name:         HLTAPI_BGP_BFD.py
#
# Description:       This script demonstrates the use of Spirent HLTAPI to setup BFD enabled BGP in B2B mode.
#
# Test Step:         1. Reserve and connect chassis ports
#                    2. Config BGP router with BFD enabled
#                    3. Start BGP router
#                    4. Check BGP status
#                    5. Disable BFD 
#                    6. Telnet DUT to check neighbor status of BFD
#                    7. Release resources
# 
# DUT configuration:
#           router bgp 123
#             bgp router-id 220.1.1.1
#             neighbor 100.1.0.8 remote-as 1
#             neighbor 100.1.0.8 fall-over bfd
#           !
#          interface FastEthernet1/0
#            ip address 100.1.0.1 255.255.255.0
#            duplex full
#            bfd interval 500 min_rx 500 multiplier 3
#          !
#
#
# Topology
#                 STC Port1                            Cisco DUT                       
#                [BGP router]---------------------[BGP router(BFD enabled)]
#                                 100.1.0.0/24
#                                         
#
#################################

# Run sample:
#            c:>python HLTAPI_BGP_BFD.py 10.61.44.2 3/1 3/3

import sth
import time
from sys import argv
filename,device,port1,port2 = argv
port_list = [port1,port2]
port_handle = []


#Config the parameters for the logging
test_sta = sth.test_config (
    log                                              = '1',
    logfile                                          = 'bgp_bfd_logfile',
    vendorlogfile                                    = 'bgp_bfd_stcExport',
    vendorlog                                        = '1',
    hltlog                                           = '1',
    hltlogfile                                       = 'bgp_bfd_hltExport',
    hlt2stcmappingfile                               = 'bgp_bfd_hlt2StcMapping',
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
# Step 2.Config BGP router with BFD enabled
##############################################################

#start to create the device: Device 1
device_ret0 = sth.emulation_bgp_config (
          mode                                             = 'enable',
          ip_stack_version                                 = '4',
          port_handle                                      = port_handle[0],
          local_as                                         = '1',
          local_as_mode                                    = 'fixed',
          remote_as                                        = '123',
          local_ip_addr                                    = '100.1.0.8',
          remote_ip_addr                                   = '100.1.0.1',
          next_hop_ip                                      = '100.1.0.1',
          netmask                                          = '24',
          local_router_id                                  = '22.1.1.2',
          hold_time                                        = '90',
          update_interval                                  = '30',
          routes_per_msg                                   = '2000',
          ipv4_unicast_nlri                                = '1',
          active_connect_enable                            = '1',
          bfd_registration                                   = '1')
          
status = device_ret0['status']
if (status == '0') :
     print("run sth.emulation_bgp_config failed")
     print(device_ret0)
else:
     print("***** run sth.emulation_bgp_config successfully")
     bgpHandle = device_ret0['handles']
    

#config part is finished
sth.invoke ('stc::perform saveasxml -filename BGP_BFD.xml')


##############################################################
# Step 3.start BGP router
##############################################################
ctrl_ret1 = sth.emulation_bgp_control (
          handle                                           = bgpHandle,
          mode                                             = 'start');

status = ctrl_ret1['status']
if (status == '0') :
     print("run sth.emulation_bgp_control failed")
     print(ctrl_ret1)
else:
     print("***** run sth.emulation_bgp_control successfully")

time.sleep (5)
##############################################################
# Step 4. Check BGP status
##############################################################

results_ret1 = sth.emulation_bgp_info (
          handle                                           = bgpHandle,
          mode                                             = 'stats');

status = results_ret1['status']
if (status == '0') :
     print("run sth.emulation_bgp_info failed")
     print(results_ret1)
else:
     print("***** run sth.emulation_bgp_info successfully, and results is:")
     print(results_ret1)

     
########################################
# Step5: Disable BFD 
########################################     
device_ret1 = sth.emulation_bgp_config (
          handle                                           = bgpHandle,
          mode                                             = 'modify',
          bfd_registration                                 = '0');

status = device_ret1['status']
if (status == '0') :
     print("run sth.emulation_bgp_disable_bfd failed")
     print(device_ret1)
else:
     print("***** run sth.emulation_bgp_disable_bfd successfully")
     

# Step6: Telnet DUT to check neighbor status of BFD

##############################################################
# Step 7. Release resources
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
