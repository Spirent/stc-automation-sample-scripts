#################################
#
# File Name:         HLTAPI_NOKIA_CUSTOMIZE_HEADER.py
#
# Description:       This script demonstrates the use of Spirent HLTAPI to setup NOKIA customize header for raw stream block.
#                    some examples for these 4 APIs: addHeader, deleteHeader, insertHeader and replaceHeader.
#
# Test Step:         
#                   1. Reserve and connect chassis ports         
#                   2. Create raw stream blocks
#                   3. Insert or add NOKIA customize header to raw stream block
#                   4. Release resources
#
# DUT configuration:
#           none
#
##################################

# Run sample:
#            c:\>python HLTAPI_NOKIA_CUSTOMIZE_HEADER.py 10.61.44.2 1/1

import sth
import time
from sys import argv
filename,device,port1 = argv
port_list = [port1]
port_handle = []


#Config the parameters for the logging
test_sta = sth.test_config (
    log                                              = '1',
    logfile                                          = 'nokia_customize_header_logfile',
    vendorlogfile                                    = 'nokia_customize_header_stcExport',
    vendorlog                                        = '1',
    hltlog                                           = '1',
    hltlogfile                                       = 'nokia_customize_header_hltExport',
    hlt2stcmappingfile                               = 'nokia_customize_header_hlt2StcMapping',
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

############################################################################
# Step2. Configure streamblock with multiple inner and outer vlan priorities
############################################################################

streamblock_ret1 = sth.traffic_config (
    mode                                             = 'create',
    name                                             = 'BIP',
    port_handle                                      = port_handle[0],
    l2_encap                                         = 'ethernet_ii')

status = streamblock_ret1['status']
if (status == '0') :
    print("run sth.traffic_config failed")
    print(streamblock_ret1)
else:
    print("***** run sth.traffic_config successfully")
    stream_id1 = streamblock_ret1['stream_id']
    sth._private_invoke('stc::config %s -AllowInvalidHeaders true' % stream_id1)
# add NOKIA BIP header to raw stream block

protocolData = dict()
protocolData['newHeader'] = 'bip'                 # Mention new Header to be added
protocolData['bipStreamID'] = '1'
protocolData['eventSize'] = '2'
protocolData['eventSequenceNum'] = '3'
protocolData['fragmentIndex'] = '4'
protocolData['localQueueID'] = '5'

# add header function
sth.addHeader(stream_id1,**protocolData)


streamblock_ret2 = sth.traffic_config (
    mode                                             = 'create',
    name                                             = 'GTPF',
    port_handle                                      = port_handle[0],
    l2_encap                                         = 'ethernet_ii')

status = streamblock_ret2['status']
if (status == '0') :
    print("run sth.traffic_config failed")
    print(streamblock_ret2)
else:
    print("***** run sth.traffic_config successfully")
    stream_id2 = streamblock_ret2['stream_id']
    sth._private_invoke('stc::config %s -AllowInvalidHeaders true' % stream_id2)

# add NOKIA GTPF header to raw stream block

protocolData = dict()
protocolData['oldHeader'] = 'ethernet'
protocolData['newHeader'] = 'gtpf'
protocolData['version'] = '7'
protocolData['protocol'] = '1'
protocolData['reserved'] = '1'
protocolData['eFlg'] = '1'
protocolData['sFlg'] = '1'
protocolData['pnFlg'] = '1'
protocolData['msgType'] = '255'
protocolData['mlength'] = '8'
protocolData['teid'] = '2000'

# replace header function
sth.replaceHeader(stream_id2,**protocolData)


streamblock_ret3 = sth.traffic_config (
    mode                                             = 'create',
    name                                             = 'GTPF_Option_Extension',
    port_handle                                      = port_handle[0],
    l2_encap                                         = 'ethernet_ii',
    l3_protocol                                      = 'ipv4')
status = streamblock_ret3['status']
if (status == '0') :
    print("run sth.traffic_config failed")
    print(streamblock_ret3)
else:
    print("***** run sth.traffic_config successfully")
    stream_id3 = streamblock_ret3['stream_id']
    sth._private_invoke('stc::config %s -AllowInvalidHeaders true' % stream_id3)

protocolData = dict()
protocolData['oldHeader'] = 'ipv4'

# delete header function
sth.deleteHeader(stream_id3,**protocolData)

protocolData['oldHeader'] = 'ethernet'
protocolData['newHeader'] = 'gtpfOptExt'
protocolData['seqno'] = '180'
protocolData['Npdu'] = '189'
protocolData['curHdrType'] = '248'
protocolData['mlength'] = '1'
protocolData['pattern'] = '0F3F9'
protocolData['nxtHdrType'] = '255'

sth.replaceHeader(stream_id3,**protocolData)


streamblock_ret4 = sth.traffic_config (
    mode                                             = 'create',
    name                                             = 'GTPF_Extension_Headers',
    port_handle                                      = port_handle[0],
    l2_encap                                         = 'ethernet_ii')
status = streamblock_ret4['status']
if (status == '0') :
    print("run sth.traffic_config failed")
    print(streamblock_ret4)
else:
    print("***** run sth.traffic_config successfully")
    stream_id4 = streamblock_ret4['stream_id']
    sth._private_invoke('stc::config %s -AllowInvalidHeaders true' % stream_id4)

protocolData = dict()

protocolData['oldHeader'] = 'ethernet'
protocolData['newHeader'] = 'gtpfExtHdr'
protocolData['mlength'] = '1'
protocolData['pattern'] = '256787ABCDEF'
protocolData['nxtHdrType'] = '255'

sth.replaceHeader(stream_id4,**protocolData)


streamblock_ret5 = sth.traffic_config (
    mode                                             = 'create',
    name                                             = 'GTPF_Optional_Field',
    port_handle                                      = port_handle[0],
    l2_encap                                         = 'ethernet_ii',
    l3_protocol                                      = 'ipv4')
status = streamblock_ret5['status']
if (status == '0') :
    print("run sth.traffic_config failed")
    print(streamblock_ret5)
else:
    print("***** run sth.traffic_config successfully")
    stream_id5 = streamblock_ret5['stream_id']
    sth._private_invoke('stc::config %s -AllowInvalidHeaders true' % stream_id5)

protocolData = dict()

protocolData['oldHeader'] = 'ethernet'
protocolData['newHeader'] = 'gtpfOptOnly'

sth.replaceHeader(stream_id5,**protocolData)

streamblock_ret6 = sth.traffic_config (
    mode                                             = 'create',
    name                                             = 'Transport_software_data',
    port_handle                                      = port_handle[0],
    l2_encap                                         = 'ethernet_ii',
    l3_protocol                                      = 'ipv4',
    l4_protocol                                      = 'udp')
status = streamblock_ret6['status']
if (status == '0') :
    print("run sth.traffic_config failed")
    print(streamblock_ret6)
else:
    print("***** run sth.traffic_config successfully")
    stream_id6 = streamblock_ret6['stream_id']
    sth._private_invoke('stc::config %s -AllowInvalidHeaders true' % stream_id6)

protocolData = dict()

protocolData['oldHeader'] = 'ethernet'
protocolData['newHeader'] = 'trswdata'
protocolData['Version'] = '12'
protocolData['DSCP'] = '3'
protocolData['Padding'] = '1'
protocolData['DstPort'] = '1024'
protocolData['SrcPort'] = '1025'
protocolData['sourceAddr'] = '10.10.10.1'
protocolData['destAddr'] = '10.10.10.2'

sth.replaceHeader(stream_id6,**protocolData)

protocolData = dict()
protocolData['oldHeader'] = 'ipv4'
protocolData['newHeader'] = 'gtpf'
protocolData['version'] = '7'
protocolData['protocol'] = '1'
protocolData['reserved'] = '1'
protocolData['eFlg'] = '1'
protocolData['sFlg'] = '1'
protocolData['pnFlg'] = '1'
protocolData['msgType'] = '255'
protocolData['mlength'] = '8'
protocolData['teid'] = '2000'

# insert header function

sth.insertHeader(stream_id6,**protocolData)

sth.save_xml(filename = 'sample_script.xml')

cleanup_sta = sth.cleanup_session (
    port_handle                                      = port_handle[0],
    clean_dbfile                                     = '1')

