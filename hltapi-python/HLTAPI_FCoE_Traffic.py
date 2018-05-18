#########################################################################################################################
#
# File Name:           HLTAPI_FCoE_Traffic.py                 
# Description:         This script demonstrates the use of Spirent HLTAPI to setup FCoE_Traffic in B2B mode.
#                      
# Test Steps:          
#                    1. Reserve and connect chassis ports
#                    2. Genearte L2 Traffic on Port1 and Port2
#                    3. Create FCoE and FIP Raw Traffic 
#                    4. Run the Traffic
#                    5. Release resources
#                                                                       
# Topology:
#                                      
#                [STC  port1]---------[DUT]---------[STC  port2]
#                                                                         
#  
################################################################################
# 
# Run sample:
#            c:>python HLTAPI_FCoE_Traffic.py 10.61.44.2 3/1 3/3
#

import sth
import time
from sys import argv
filename,device,port1,port2 = argv
port_list = [port1,port2]
port_handle = []

#Config the parameters for the logging
test_sta = sth.test_config (
    log                                              = '1',
    logfile                                          = 'HLTAPI_FCoE_Traffic_logfile',
    vendorlogfile                                    = 'HLTAPI_FCoE_Traffic_stcExport',
    vendorlog                                        = '1',
    hltlog                                           = '1',
    hltlogfile                                       = 'HLTAPI_FCoE_Traffic_hltExport',
    hlt2stcmappingfile                               = 'HHLTAPI_FCoE_Traffic_hlt2StcMapping',
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
# Step2. Genearte L2 Traffic on Port1 and Port2
########################################

streamblock_ret1 = sth.traffic_config (
        mode                                             = 'create',
        port_handle                                      = port_handle[0],
        l2_encap                                         = 'ethernet_ii',
        transmit_mode                                    = 'continuous',
        length_mode                                      = 'fixed',
        l3_length                                        = '1002',
        rate_pps                                         = '1000')
        
status = streamblock_ret1['status']
if (status == '0') :
    print("run sth.traffic_config failed")
    print(streamblock_ret1)
else:
    print("***** run sth.traffic_config successfully")

sb1 = streamblock_ret1['stream_id']

streamblock_ret2 = sth.traffic_config (
        mode                                             = 'create',
        port_handle                                      = port_handle[1],
        l2_encap                                         = 'ethernet_ii',
        transmit_mode                                    = 'continuous',
        length_mode                                      = 'fixed',
        l3_length                                        = '1002',
        rate_pps                                         = '1000')
        
status = streamblock_ret2['status']
if (status == '0') :
    print("run sth.traffic_config failed")
    print(streamblock_ret2)
else:
    print("***** run sth.traffic_config successfully")

sb2 = streamblock_ret2['stream_id']

########################################
# Step3. Create FCoE and FIP Raw Traffic 
########################################

stream_fcoe_ret = sth.fcoe_traffic_config (
        handle                                           = sb1,
        mode                                             = 'create',
        sof                                              = 'sofn3',
        eof                                              = 'eofn',
        h_did                                            = '000000000',
        h_sid                                            = '000000',
        h_type                                           = '00',
        h_framecontrol                                   = '000000',
        h_seqid                                          = '00',
        h_dfctl                                          = '00',
        h_seqcnt                                         = '0000',
        h_origexchangeid                                 = '0000',
        pl_id                                            = 'flogireq',
        pl_nodename                                      = '10:00:10:94:00:00:00:01')
        
status = stream_fcoe_ret['status']
if (status == '0') :
    print("run fcoe_traffic_config failed")
    print(stream_fcoe_ret)
else:
    print("***** run fcoe_traffic_config successfully")
    
    
streamblock_fip_ret = sth.fip_traffic_config (
        mode                                             = 'create',
        handle                                           = sb2,
        fp                                               = '1',
        sp                                               = '0',
        a                                                = '0',
        s                                                = '0',
        f                                                = '0',
        dl_id                                            = ['priority','macaddr','nameid','fabricname','fka_adv_period'],
        priority                                         = '64',
        macaddr                                          = '00:10:94:00:00:01',
        nameid                                           = '10:00:10:94:00:00:00:01',
        fabricname                                       = '20:00:10:94:00:00:00:01')
        
status = streamblock_fip_ret['status']
if (status == '0') :
    print("run sth.fip_traffic_config failed")
    print(streamblock_fip_ret)
else:
    print("***** run sth.fip_traffic_config successfully")
    
#config part is finished
sth.invoke ('stc::perform saveasxml -filename fcoe_traffic.xml')

########################################
# Step4. Run the Traffic
########################################

traffic_ctrl_ret = sth.traffic_control (
        port_handle                                      = 'all',
        action                                           = 'run');

status = traffic_ctrl_ret['status']
if (status == '0') :
    print("run sth.traffic_control failed")
    print(traffic_ctrl_ret)
else:
    print("***** run sth.traffic_control successfully")
    
##############################################################
# Step5. Release resources
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