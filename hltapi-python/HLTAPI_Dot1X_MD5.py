################################################################################
#
# File Name:         HLTAPI_Dot1X_MD5.py
#
# Description:       This script demonstrates the use of Spirent HLTAPI to setup 802.1x devices by MD5                   #                    authentication.                  
#
# Test Steps:        1. Reserve and connect chassis ports
#                    2. Configure interface
#                    3. Configure 10 802.1x supplicants
#                    4. Start 802.1x Authentication
#                    5. Check 802.1x Stats
#                    6. Stop 802.1x Authentication
#                    7. Release resources
#
# DUT configuration:omitted
#        
#
# Topology
#                 STC Port1----------------DUT---------------------Radius Server                   
#            [802.1x supplicant]    [Authenticator System]     [Authentication Server]
# 
################################################################################
# 
# Run sample:
#            c:>python HLTAPI_Dot1X_MD5.py 10.61.44.2 3/1 3/3

import sth
import time
from sys import argv
filename,device,port1,port2 = argv
port_list = [port1,port2]
port_handle = []

def TurnOnCapture (portHandleList,port):
    captureHndList = []
    for portHnd in portHandleList.split() :
        print "Turn on capture on %s" % portHnd
        capture = sth.invoke ('stc::get %s -children-capture' % portHnd)
        sth.invoke ('stc::perform CaptureStart -CaptureProxyId ' + capture)
        captureHndList.append(capture)
    return captureHndList
    
def TurnOffCapture (portHandleList,port) :
    fileNameList = []
    for portHnd in portHandleList.split() :
        print "Turn off capture on %s" % portHnd
        captureHnd = sth.invoke('stc::get %s -children-capture' % portHnd)
        sth.invoke('stc::perform CaptureStop -CaptureProxyId ' + captureHnd)
        name = port
        print "Saving capture to : " + name
        sth.invoke ('stc::perform SaveSelectedCaptureData -CaptureProxyId %s -filename %s.pcap' % (captureHnd,name))
        fileNameList.append('%s.pcap' % name)
    print "Save file Name list = %s" % fileNameList
    return fileNameList
        
        

#Config the parameters for the logging
test_sta = sth.test_config (
    log                                              = '1',
    logfile                                          = 'HLTAPI_Dot1x_MD5_logfile',
    vendorlogfile                                    = 'HLTAPI_Dot1x_MD5_stcExport',
    vendorlog                                        = '1',
    hltlog                                           = '1',
    hltlogfile                                       = 'HLTAPI_Dot1x_MD5_hltExport',
    hlt2stcmappingfile                               = 'HLTAPI_Dot1x_MD5_hlt2StcMapping',
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
    
########################################
# Step2: Configure interface
########################################
print "Configure interface"

for i in range(0,len(port_list)) :
    returnedString = sth.interface_config (
        mode                                              = 'config',
        port_handle                                       = port_handle[i],
        intf_mode                                         = 'ethernet',
        phy_mode                                          = 'fiber',
        speed                                             = 'ether1000',
        autonegotiation                                   = '1',
        duplex                                            = 'full',
        arp_send_req                                      = '1')
    
    status = returnedString['status']
    if (status == '0') :
        print("run sth.interface_config failed")
        print returnedString
    else:
        print("***** run sth.interface_config successfully")
        print returnedString

########################################
# Step3: Configure 10 802.1x supplicants
########################################
print "Configuring 802.1x devices"

returnedString = sth.emulation_dot1x_config (
    mode                                                  = "create",
    port_handle                                           = port_handle[0],
    name                                                  = 'Dot1x_1',
    num_sessions                                          = '10',
    encapsulation                                         = 'ethernet_ii',
    ip_version                                            = 'ipv4',
    supplicant_auth_rate                                  = '100',
    supplicant_logoff_rate                                = '300',
    max_authentications                                   = '600',
    retransmit_count                                      = '300',
    eap_auth_method                                       = 'md5',
    username                                              = 'spirent',
    password                                              = 'spirent')

status = returnedString['status']
if (status == '0') :
    print("sth::emulation_dot1x_config failed")
    print returnedString
else:
    print("***** sth::emulation_dot1x_config successfully")
    print returnedString

dot1xHandle = returnedString['handle']

#config part is finished
sth.invoke ('stc::perform saveasxml -filename dot1x_md5.xml')

########################################
# Step4: Start Authentication
########################################

TurnOnCapture (port_handle[0],"port1")

time.sleep(2)

print "Start Authentication"

returnedString = sth.emulation_dot1x_control (
    mode                                                   = 'start',
    handle                                                 = dot1xHandle)
    
status = returnedString['status']
if (status == '0') :
    print("sth::emulation_dot1x_control failed")
    print returnedString
else:
    print("***** sth::emulation_dot1x_control successfully")
    print returnedString
    
time.sleep(10)

TurnOffCapture (port_handle[0],"port1")

########################################
# Step5: Check 802.1x Stats
########################################    
returnedString = sth.emulation_dot1x_stats (
    mode                                                   = 'aggregate',
    handle                                                 = dot1xHandle)    
    
status = returnedString['status']
if (status == '0') :
    print("sth::emulation_dot1x_stats failed")
    print returnedString
else:
    print("***** sth::emulation_dot1x_stats successfully")
    print returnedString    
    
returnedString = sth.emulation_dot1x_stats (
    mode                                                   = 'session',
    handle                                                 = dot1xHandle)    
    
status = returnedString['status']
if (status == '0') :
    print("sth::emulation_dot1x_stats failed")
    print returnedString
else:
    print("***** sth::emulation_dot1x_stats successfully")
    print returnedString        
    
########################################
# Step6: Stop Authentication
########################################    
returnedString = sth.emulation_dot1x_control (
    mode                                                   = 'stop',
    handle                                                 = dot1xHandle)
    
status = returnedString['status']
if (status == '0') :
    print("sth::emulation_dot1x_control failed")
    print returnedString
else:
    print("***** sth::emulation_dot1x_control successfully")
    print returnedString    
    
returnedString = sth.emulation_dot1x_config (
    mode                                                   = 'delete',
    handle                                                 = dot1xHandle)    
    
status = returnedString['status']
if (status == '0') :
    print("sth::emulation_dot1x_config failed")
    print returnedString
else:
    print("***** sth::emulation_dot1x_config successfully")
    print returnedString        
    
##############################################################
# Step7. Release resources
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