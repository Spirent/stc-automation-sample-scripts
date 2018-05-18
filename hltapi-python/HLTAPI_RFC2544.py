#########################################################################################################################
#
# File Name:           HLTAPI_RFC2544.py                 
# Description:         This script demonstrates the use of Spirent HLTAPI to test RFC2544 includes latency, back to back,frame #                      loss,and throughput.
#                      
#                      
# Test Steps:          
#                    1. Reserve and connect chassis ports
#                    2. Configure interfaces
#                    3. Configure streamblock on two ports
#                    4. RFC2544 test                  
#                    5. Release resources
#                                                                       
# Topology:
#                      [STC port1]---------[DUT]---------[STC port2]          
#  
################################################################################
# 
# Run sample:
#            c:\>python HLTAPI_RFC2544.py 10.61.44.2 3/1 3/3
#

import sth
import time
from sys import argv
filename,device,port1,port2 = argv
port_list = [port1,port2]
port_handle = []

#Enable/Disable different test type here
# tput_test = 1
# latency_test = 1
# b2b_test = 1
# fl_test = 1

#print type(tput_test)

#Config the parameters for the logging
test_sta = sth.test_config (
    log                                              = '1',
    logfile                                          = 'HLTAPI_RFC2544_logfile',
    vendorlogfile                                    = 'HLTAPI_RFC2544_stcExport',
    vendorlog                                        = '1',
    hltlog                                           = '1',
    hltlogfile                                       = 'HLTAPI_RFC2544_hltExport',
    hlt2stcmappingfile                               = 'HLTAPI_RFC2544_hlt2StcMapping',
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
    
##############################################################
#Step2. Configure interfaces
##############################################################
print "Configure interface on port1"

int_ret0 = sth.interface_config (
        mode                                             = 'config',
        port_handle                                      = port_handle[0],
        intf_ip_addr                                     = '192.168.1.10',
        gateway                                          = '192.168.1.100',
        autonegotiation                                  = '1',
        arp_send_req                                     = '1')
        
status = int_ret0['status']
if (status == '0') :
    print("run sth.interface_config failed")
    print(int_ret0)
else:
    print("***** run sth.interface_config successfully")
    print int_ret0
    
print "Configure interface on port2"

int_ret1 = sth.interface_config (
        mode                                             = 'config',
        port_handle                                      = port_handle[1],
        intf_ip_addr                                     = '192.168.1.100',
        gateway                                          = '192.168.1.10',
        autonegotiation                                  = '1',
        arp_send_req                                     = '1')
        
status = int_ret1['status']
if (status == '0') :
    print("run sth.interface_config failed")
    print(int_ret1)
else:
    print("***** run sth.interface_config successfully")
    print int_ret1
    
##############################################################
#Step3. Configure streamblock on two ports
##############################################################
print "Configure streamblock on port1 : port1 -> port2"
streamblock_ret1 = sth.traffic_config (
        mode                                             = 'create',
        port_handle                                      = port_handle[0],
        l2_encap                                         = 'ethernet_ii',
        l3_protocol                                      = 'ipv4',
        l3_length                                        = '256',
        length_mode                                      = 'fixed',
        ip_src_addr                                      = '192.168.1.10',
        ip_dst_addr                                      = '192.168.1.100',
        mac_discovery_gw                                 = '192.168.1.100',
        mac_dst                                          = '00:10:94:00:00:03',
        mac_src                                          = '00:10:94:00:00:02')
                
status = streamblock_ret1['status']
if (status == '0') :
    print("run sth.traffic_config failed")
    print(streamblock_ret1)
else:
    print("***** run sth.traffic_config successfully")

streamblock1 = streamblock_ret1['stream_id']

print "Configure streamblock on port2 : port2 -> port1"

streamblock_ret2 = sth.traffic_config (
        mode                                             = 'create',
        port_handle                                      = port_handle[1],
        l2_encap                                         = 'ethernet_ii',
        l3_protocol                                      = 'ipv4',
        l3_length                                        = '256',
        length_mode                                      = 'fixed',
        ip_src_addr                                      = '192.168.1.100',
        ip_dst_addr                                      = '192.168.1.10',
        mac_discovery_gw                                 = '192.168.1.10',
        mac_dst                                          = '00:10:94:00:00:02',
        mac_src                                          = '00:10:94:00:00:03')
        
status = streamblock_ret2['status']
if (status == '0') :
    print("run sth.traffic_config failed")
    print(streamblock_ret2)
else:
    print("***** run sth.traffic_config successfully")

streamblock2 = streamblock_ret2['stream_id']

########################################
# Step4. RFC2544 test
########################################
print "Latency Test"

latency_config = sth.test_rfc2544_config (
    mode                                             = 'create',
    streamblock_handle                               = streamblock1,
    test_type                                        = 'latency',
    traffic_pattern                                  = 'pair',
    endpoint_creation                                = '0',
    bidirectional                                    = '0',
    iteration_count                                  = '1',
    latency_type                                     = 'FIFO',
    start_traffic_delay                              = '1',
    stagger_start_delay                              = '1',
    delay_after_transmission                         = '10',
    frame_size_mode                                  = 'custom',
    frame_size                                       = ['1024'],
    test_duration_mode                               = 'seconds',
    test_duration                                    = '10',
    load_unit                                        = 'percent_line_rate',
    load_type                                        = 'step',
    load_start                                       = '20',
    load_step                                        = '10',
    load_end                                         = '30')

status = latency_config['status']
if (status == '0') :
    print("run sth.test_rfc2544_config failed")
    print(latency_config)
else:
    print("***** run sth.test_rfc2544_config successfully")

sth.invoke ('stc::perform saveasxml -config system1 -filename rfc2544_latency.xml')

latency_control = sth.test_rfc2544_control (
    action                                           = 'run',
    wait                                             = '1');

status = latency_control['status']
if (status == '0') :
    print("run sth.test_rfc2544_control failed")
    print(latency_control)
else:
    print("***** run sth.test_rfc2544_control successfully")

latency_results = sth.test_rfc2544_info (
    test_type                                        = 'latency',
    clear_result                                     = '0');

status = latency_results['status']
if (status == '0') :
    print("run sth.test_rfc2544_info failed")
    print(latency_results)
else:
    print("***** run sth.test_rfc2544_info successfully, and results is:")
    print(latency_results)

print "Back to back Test"    

b2b_config = sth.test_rfc2544_config (
    mode                                             = 'create',
    streamblock_handle                               = streamblock1,
    test_type                                        = 'b2b',
    traffic_pattern                                  = 'pair',
    endpoint_creation                                = '0',
    bidirectional                                    = '1',
    iteration_count                                  = '1',
    latency_type                                     = 'FIFO',
    start_traffic_delay                              = '2',
    stagger_start_delay                              = '1',
    delay_after_transmission                         = '10',
    frame_size_mode                                  = 'custom',
    frame_size                                       = ['1024'],
    test_duration_mode                               = 'seconds',
    test_duration                                    = '10')

status = b2b_config['status']
if status == '0' :
    print("run sth.test_rfc2544_config failed")
    print(b2b_config)
else :
    print("***** run sth.test_rfc2544_config successfully")

sth.invoke ('stc::perform saveasxml -config system1 -filename rfc2544_b2b.xml')
    
b2b_control = sth.test_rfc2544_control (
    action                                           = 'run',
    wait                                             = '1');

status = b2b_control['status']
if (status == '0') :
    print("run sth.test_rfc2544_control failed")
    print(b2b_control)
else:
    print("***** run sth.test_rfc2544_control successfully")

b2b_results = sth.test_rfc2544_info (
    test_type                                        = 'b2b',
    clear_result                                     = '0');

status = b2b_results['status']
if (status == '0') :
    print("run sth.test_rfc2544_info failed")
    print(b2b_results)
else:
    print("***** run sth.test_rfc2544_info successfully, and results is:")
    print(b2b_results)


print "Frame Loss Test"


fl_config = sth.test_rfc2544_config (
    mode                                             = 'create',
    streamblock_handle                               = streamblock1,
    test_type                                        = 'fl',
    traffic_pattern                                  = 'pair',
    endpoint_creation                                = '0',
    bidirectional                                    = '0',
    iteration_count                                  = '1',
    latency_type                                     = 'FIFO',
    start_traffic_delay                              = '1',
    stagger_start_delay                              = '1',
    delay_after_transmission                         = '10',
    frame_size_mode                                  = 'custom',
    frame_size                                       = ['1024'],
    test_duration_mode                               = 'seconds',
    test_duration                                    = '10',
    load_type                                        = 'step',
    load_start                                       = '100',
    load_step                                        = '50',
    load_end                                         = '50')

status = fl_config['status']
if (status == '0') :
    print("run sth.test_rfc2544_config failed")
    print(fl_config)
else:
    print("***** run sth.test_rfc2544_config successfully")

sth.invoke ('stc::perform saveasxml -config system1 -filename rfc2544_fl.xml')

fl_control = sth.test_rfc2544_control (
    action                                           = 'run',
    wait                                             = '1');

status = fl_control['status']
if (status == '0') :
    print("run sth.test_rfc2544_control failed")
    print(fl_control)
else:
    print("***** run sth.test_rfc2544_control successfully")

fl_results = sth.test_rfc2544_info (
    test_type                                        = 'fl',
    clear_result                                     = '0');

status = fl_results['status']
if (status == '0') :
    print("run sth.test_rfc2544_info failed")
    print(fl_results)
else:
    print("***** run sth.test_rfc2544_info successfully, and results is:")
    print(fl_results)


print "Throughput Test"


tput_config = sth.test_rfc2544_config (
    mode                                             = 'create',
    streamblock_handle                               = streamblock1,
    test_type                                        = 'throughput',
    traffic_pattern                                  = 'pair',
    enable_learning                                  = '0',
    endpoint_creation                                = '0',
    bidirectional                                    = '0',
    iteration_count                                  = '1',
    latency_type                                     = 'FIFO',
    start_traffic_delay                              = '1',
    stagger_start_delay                              = '1',
    delay_after_transmission                         = '10',
    frame_size_mode                                  = 'custom',
    frame_size                                       = ['1518'],
    test_duration_mode                               = 'seconds',
    test_duration                                    = '10',
    search_mode                                      = 'binary',                              
    rate_lower_limit                                 = '20',
    rate_upper_limit                                 = '22',
    initial_rate                                     = '21')
    
status = tput_config['status']
if (status == '0') :
    print("run sth.test_rfc2544_config failed")
    print(tput_config)
else:
    print("***** run sth.test_rfc2544_config successfully")

sth.invoke ('stc::perform saveasxml -config system1 -filename rfc2544_Tput.xml')

tput_control = sth.test_rfc2544_control (
    action                                           = 'run',
    wait                                             = '1');

status = tput_control['status']
if (status == '0') :
    print("run sth.test_rfc2544_control failed")
    print(tput_control)
else:
    print("***** run sth.test_rfc2544_control successfully")

tput_results = sth.test_rfc2544_info (
    test_type                                        = 'throughput',
    clear_result                                     = '0');

status = tput_results['status']
if (status == '0') :
    print("run sth.test_rfc2544_info failed")
    print(tput_results)
else:
    print("***** run sth.test_rfc2544_info successfully, and results is:")
    print(tput_results)

#config part is finished

        
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


    