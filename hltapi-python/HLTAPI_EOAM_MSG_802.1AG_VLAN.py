#########################################################################################################################
#
# File Name:           HLTAPI_EOAM_MSG_802.1AG_VLAN.py                 
# Description:         This script demonstrates the use of Spirent HLTAPI to setup EOAM and 802.1ag in B2B connection.
#                      
# Test Steps:          
#                    1. Reserve and connect chassis ports
#                    2. Configure EOAM 
#                    3. Start EOAM 
#                    4. Stop EOAM
#                    5. Get ports info
#                    6. Modify EOAM
#                    7. Start EOAM again
#                    8. Stop EOAM again
#                    9. Get ports info again
#                    10. Reset EOAM 
#                    11. Release resources
#                                                                       
# Topology:
#                      STC Port2                    STC Port1                       
#                     [EOAM port]------------------[EOAM port]
#                                                                         
#  
################################################################################
# 
# Run sample:
#            c:>python HLTAPI_EOAM_MSG_802.1AG_VLAN.py 10.61.44.2 3/1 3/3
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
    logfile                                          = 'HLTAPI_EOAM_MSG_802.1AG_VLAN_logfile',
    vendorlogfile                                    = 'HLTAPI_EOAM_MSG_802.1AG_VLAN_stcExport',
    vendorlog                                        = '1',
    hltlog                                           = '1',
    hltlogfile                                       = 'HLTAPI_EOAM_MSG_802.1AG_VLAN_hltExport',
    hlt2stcmappingfile                               = 'HHLTAPI_EOAM_MSG_802.1AG_VLAN_hlt2StcMapping',
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
# Step2. Configure EOAM 
########################################
print "Configure EOAM on port1"

device_ret0 = sth.emulation_oam_config_msg (
        mode                                             = 'create',
        port_handle                                      = port_handle[0],
        count                                            = '1',
        dst_addr_type                                    = 'unicast',
        msg_type                                         = 'loopback',
        mac_local                                        = '00:94:01:00:00:01',
        mac_local_incr_mode                              = 'increment',
        mac_local_step                                   = '00:00:00:00:00:02',
        mac_local_repeat                                 = '2',
        mac_remote                                       = '00:94:01:00:01:01',
        mac_remote_incr_mode                             = 'increment',
        mac_remote_step                                  = '00:00:00:00:00:02',
        mac_remote_repeat                                = '2',
        oam_standard                                     = 'ieee_802.1ag',
        vlan_outer_id                                    = '1000',
        vlan_outer_ether_type                            = '0x88A8',
        vlan_id_outer_step                               = '5',
        vlan_id                                          = '100',
        vlan_ether_type                                  = '0x9100',
        vlan_id_step                                     = '5',
        mac_dst                                          = '00:94:01:00:01:01',
        mac_dst_incr_mode                                = 'increment',
        mac_dst_step                                     = '00:00:00:00:00:02',
        md_level_incr_mode                               = 'increment',
        md_level_step                                    = '1',
        md_level_repeat                                  = '2',                                        
        trans_id                                         = '100',
        tlv_sender_length                                = '10',
        tlv_sender_chassis_id                            = '21',
        tlv_sender_chassis_id_length                     = '10',
        tlv_sender_chassis_id_subtype                    = '5',
        tlv_org_length                                   = '10',
        tlv_org_oui                                      = '22',
        tlv_org_subtype                                  = '11',
        tlv_org_value                                    = 'FF',
        tlv_data_length                                  = '10',
        tlv_data_pattern                                 = '0xAA',
        tlv_user_type                                    = '5',
        tlv_user_length                                  = '10',
        tlv_user_value                                   = '0xff',
        tlv_test_length                                  = '30',
        tlv_test_pattern                                 = 'null_with_crc',
        transmit_mode                                    = 'continuous',
        pkts_per_burst                                   = '3',
        rate_pps                                         = '5')

status = device_ret0['status']
if (status == '0') :
    print("run sth.emulation_oam_config_msg failed")
    print(device_ret0)
else:
    print("***** run sth.emulation_oam_config_msg successfully")

    
msgHandleList1 = device_ret0['handle']
    
print "Configure EOAM on port2"

device_ret1 = sth.emulation_oam_config_msg (
        mode                                             = 'create',
        port_handle                                      = port_handle[1],
        count                                            = '1',
        dst_addr_type                                    = 'unicast',
        msg_type                                         = 'loopback',
        mac_local                                        = '00:94:01:00:01:01',
        mac_local_incr_mode                              = 'increment',
        mac_local_step                                   = '00:00:00:00:00:02',
        mac_local_repeat                                 = '2',
        mac_remote                                       = '00:94:01:00:00:01',
        mac_remote_incr_mode                             = 'increment',
        mac_remote_step                                  = '00:00:00:00:00:02',
        mac_remote_repeat                                = '2',
        oam_standard                                     = 'ieee_802.1ag',
        vlan_outer_id                                    = '1000',
        vlan_outer_ether_type                            = '0x88A8',
        vlan_id_outer_step                               = '5',
        vlan_id                                          = '100',
        vlan_ether_type                                  = '0x9100',
        vlan_id_step                                     = '5',
        mac_dst                                          = '00:94:01:00:01:01',
        mac_dst_incr_mode                                = 'increment',
        mac_dst_step                                     = '00:00:00:00:00:02',
        md_level_incr_mode                               = 'increment',
        md_level_step                                    = '1',
        md_level_repeat                                  = '2',                                        
        trans_id                                         = '100',
        tlv_sender_length                                = '10',
        tlv_sender_chassis_id                            = '21',
        tlv_sender_chassis_id_length                     = '10',
        tlv_sender_chassis_id_subtype                    = '5',
        tlv_org_length                                   = '10',
        tlv_org_oui                                      = '22',
        tlv_org_subtype                                  = '11',
        tlv_org_value                                    = 'FF',
        tlv_data_length                                  = '10',
        tlv_data_pattern                                 = '0xAA',
        tlv_user_type                                    = '5',
        tlv_user_length                                  = '10',
        tlv_user_value                                   = '0xff',
        tlv_test_length                                  = '30',
        tlv_test_pattern                                 = 'null_with_crc',
        transmit_mode                                    = 'continuous',
        pkts_per_burst                                   = '3',
        rate_pps                                         = '5')

status = device_ret1['status']
if (status == '0') :
    print("run sth.emulation_oam_config_msg failed")
    print(device_ret1)
else:
    print("***** run sth.emulation_oam_config_msg successfully")
    print device_ret1

msgHandleList2 = device_ret1['handle']

#config part is finished
sth.invoke ('stc::perform saveasxml -filename eoam_msg_802.1ag_vlan.xml')

########################################
# Step3. Start EOAM 
########################################
print "Start EOAM on port1"
ctrl_ret1 = sth.emulation_oam_control (
        handle                                           = msgHandleList1,
        action                                           = 'start');

status = ctrl_ret1['status']
if (status == '0') :
    print("run sth.emulation_oam_control failed")
    print(ctrl_ret1)
else:
    print("***** run sth.emulation_oam_control successfully")
    
print "Wait 10 seconds"
time.sleep(10)

########################################
# Step4. Stop EOAM
########################################
print "Stop EOAM on port1"

ctrl_ret2 = sth.emulation_oam_control (
        handle                                           = msgHandleList1,
        action                                           = 'stop');

status = ctrl_ret2['status']
if (status == '0') :
    print("run sth.emulation_oam_control failed")
    print(ctrl_ret2)
else:
    print("***** run sth.emulation_oam_control successfully")
    
########################################
# Step5. Get ports info
########################################

results_ret0 = sth.emulation_oam_info (
        port_handle                                      = port_handle[0],
        mode                                             = 'aggregate')

status = results_ret0['status']
if (status == '0') :
    print("run sth.emulation_oam_info failed")
    print(results_ret0)
else:
    print("***** run sth.emulation_oam_info successfully, and results is:")
    print(results_ret0)

results_ret1 = sth.emulation_oam_info (
        port_handle                                      = port_handle[1],
        mode                                             = 'aggregate')

status = results_ret1['status']
if (status == '0') :
    print("run sth.emulation_oam_info failed")
    print(results_ret1)
else:
    print("***** run sth.emulation_oam_info successfully, and results is:")
    print(results_ret1)
    
fm_pkts1 = results_ret0['aggregate']['tx']['fm_pkts']
fm_pkts2 = results_ret1['aggregate']['rx']['fm_pkts']

print "port1_TX_fm_pkts is : %s" % fm_pkts1
print "port2_RX_fm_pkts is : %s" % fm_pkts2

fm_pkts1 = float(fm_pkts1)
fm_pkts2 = float(fm_pkts2)

if fm_pkts2 < fm_pkts1*0.998 :
    print "Failed"
else :
    print "Passed"

########################################
# Step6. Modify EOAM
########################################
print "Modify EOAM on port1"

device_ret2 = sth.emulation_oam_config_msg (
        mode                                             = 'modify',
        handle                                           = msgHandleList1,
        dst_addr_type                                    = 'unicast',
        mac_local                                        = '00:94:01:00:10:01',
        mac_remote                                       = '00:94:01:10:01:01',
        vlan_outer_id                                    = '2100',
        vlan_outer_ether_type                            = '0x9100',
        vlan_id                                          = '2200',
        vlan_ether_type                                  = '0x88A8',
        oam_standard                                     = 'ieee_802.1ag',
        mac_dst                                          = '00:94:01:10:01:01',
        sut_ip_address                                   = '13.1.0.1',
        md_level                                         = '3',
        trans_id                                         = '10',
        tlv_sender_length                                = '10',
        tlv_sender_chassis_id                            = '21',
        tlv_sender_chassis_id_length                     = '10',
        tlv_sender_chassis_id_subtype                    = '5',
        tlv_org_length                                   = '10',
        tlv_org_oui                                      = '22',
        tlv_org_subtype                                  = '11',
        tlv_org_value                                    = 'FF',
        tlv_data_length                                  = '10',
        tlv_data_pattern                                 = '0xAA',
        tlv_user_type                                    = '5',
        tlv_user_length                                  = '10',
        tlv_user_value                                   = '0xff',
        tlv_test_length                                  = '30',
        tlv_test_pattern                                 = 'null_with_crc',
        transmit_mode                                    = 'continuous',
        pkts_per_burst                                   = '4',
        rate_pps                                         = '15')
        
status = device_ret2['status']
if (status == '0') :
    print("run sth.emulation_oam_config_msg failed")
    print(device_ret2)
else:
    print("***** run sth.emulation_oam_config_msg successfully")

msgHandleList3 = device_ret2['handle']
        
print "Modify EOAM on port2"

device_ret3 = sth.emulation_oam_config_msg (
        mode                                             = 'modify',
        handle                                           = msgHandleList2,
        dst_addr_type                                    = 'unicast',
        mac_local                                        = '00:94:01:10:01:01',
        mac_remote                                       = '00:94:01:00:10:01',
        vlan_outer_id                                    = '2100',
        vlan_outer_ether_type                            = '0x9100',
        vlan_id                                          = '2200',
        vlan_ether_type                                  = '0x88A8',
        oam_standard                                     = 'ieee_802.1ag',
        mac_dst                                          = '00:94:01:10:01:01',
        sut_ip_address                                   = '13.1.0.1',
        md_level                                         = '3',
        trans_id                                         = '10',
        tlv_sender_length                                = '10',
        tlv_sender_chassis_id                            = '21',
        tlv_sender_chassis_id_length                     = '10',
        tlv_sender_chassis_id_subtype                    = '5',
        tlv_org_length                                   = '10',
        tlv_org_oui                                      = '22',
        tlv_org_subtype                                  = '11',
        tlv_org_value                                    = 'FF',
        tlv_data_length                                  = '10',
        tlv_data_pattern                                 = '0xAA',
        tlv_user_type                                    = '5',
        tlv_user_length                                  = '10',
        tlv_user_value                                   = '0xff',
        tlv_test_length                                  = '30',
        tlv_test_pattern                                 = 'null_with_crc',
        transmit_mode                                    = 'continuous',
        pkts_per_burst                                   = '4',
        rate_pps                                         = '15')
        
status = device_ret3['status']
if (status == '0') :
    print("run sth.emulation_oam_config_msg failed")
    print(device_ret3)
else:
    print("***** run sth.emulation_oam_config_msg successfully")

########################################
# Step7. Start EOAM again
########################################
print "Start EOAM on port1 again"
ctrl_ret1 = sth.emulation_oam_control (
        handle                                           = msgHandleList3,
        action                                           = 'start');

status = ctrl_ret1['status']
if (status == '0') :
    print("run sth.emulation_oam_control failed")
    print(ctrl_ret1)
else:
    print("***** run sth.emulation_oam_control successfully")
    
print "Wait 10 seconds"
time.sleep(10)

########################################
# Step8. Stop EOAM again
########################################
print "Stop EOAM on port1 again"

ctrl_ret2 = sth.emulation_oam_control (
        handle                                           = msgHandleList3,
        action                                           = 'stop');

status = ctrl_ret2['status']
if (status == '0') :
    print("run sth.emulation_oam_control failed")
    print(ctrl_ret2)
else:
    print("***** run sth.emulation_oam_control successfully")    
    
########################################
# Step9. Get ports info again
########################################

results_ret0 = sth.emulation_oam_info (
        port_handle                                      = port_handle[0],
        mode                                             = 'aggregate')

status = results_ret0['status']
if (status == '0') :
    print("run sth.emulation_oam_info failed")
    print(results_ret0)
else:
    print("***** run sth.emulation_oam_info successfully, and results is:")
    print(results_ret0)

results_ret1 = sth.emulation_oam_info (
        port_handle                                      = port_handle[1],
        mode                                             = 'aggregate')

status = results_ret1['status']
if (status == '0') :
    print("run sth.emulation_oam_info failed")
    print(results_ret1)
else:
    print("***** run sth.emulation_oam_info successfully, and results is:")
    print(results_ret1)
    
fm_pkts1 = results_ret0['aggregate']['tx']['fm_pkts']
fm_pkts2 = results_ret1['aggregate']['rx']['fm_pkts']

print "port1_TX_fm_pkts is : %s" % fm_pkts1
print "port2_RX_fm_pkts is : %s" % fm_pkts2

if float(fm_pkts2) < float(fm_pkts1)*0.998 :
    print "Failed"
else :
    print "Passed"

########################################
# Step10. Reset EOAM 
########################################
print "Rest EOAM on port1"
ctrl_ret1 = sth.emulation_oam_control (
        handle                                           = msgHandleList1,
        action                                           = 'reset');

status = ctrl_ret1['status']
if (status == '0') :
    print("run sth.emulation_oam_control failed")
    print(ctrl_ret1)
else:
    print("***** run sth.emulation_oam_control successfully")
    
##############################################################
# Step11. Release resources
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
