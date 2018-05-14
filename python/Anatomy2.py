# Copyright (c) 2007 by Spirent Communications, Inc.
# All Rights Reserved
#
# By accessing or executing this software, you agree to be bound 
# by the terms of this agreement.
# 
# Redistribution and use of this software in source and binary forms,
# with or without modification, are permitted provided that the 
# following conditions are met:
#   1.  Redistribution of source code must contain the above copyright 
#       notice, this list of conditions, and the following disclaimer.
#   2.  Redistribution in binary form must reproduce the above copyright
#       notice, this list of conditions and the following disclaimer
#       in the documentation and/or other materials provided with the
#       distribution.
#   3.  Neither the name Spirent Communications nor the names of its
#       contributors may be used to endorse or promote products derived
#       from this software without specific prior written permission.
#
# This software is provided by the copyright holders and contributors 
# [as is] and any express or implied warranties, including, but not 
# limited to, the implied warranties of merchantability and fitness for
# a particular purpose are disclaimed.  In no event shall Spirent
# Communications, Inc. or its contributors be liable for any direct, 
# indirect, incidental, special, exemplary, or consequential damages
# (including, but not limited to: procurement of substitute goods or
# services; loss of use, data, or profits; or business interruption)
# however caused and on any theory of liability, whether in contract, 
# strict liability, or tort (including negligence or otherwise) arising
# in any way out of the use of this software, even if advised of the
# possibility of such damage.

# File Name:                 Anatomy.py
# Description:               This script demonstrates basic features 
#                            such as creating streams, generating traffic,
#                            enabling capture, saving realtime results
#                            to files, and retrieving results.

import sys
import time

ENABLE_CAPTURE = True

# This loads the TestCenter library.
from StcPython import StcPython
stc = StcPython()

stc.log("INFO", "Starting Test")

# This line will show the TestCenter commands on stdout
#stc.config("automationoptions", logto="stdout", loglevel="INFO")

# Retrieve and display the current API version.
print "SpirentTestCenter system version:\t", stc.get("system1", "version")

# Physical topology
szChassisIp1 = "10.29.0.49"
szChassisIp2 = "10.29.0.45"
txPortLoc = "//%s/%s/%s" % ( szChassisIp1, 1, 1)
rxPortLoc = "//%s/%s/%s" % ( szChassisIp2, 1, 1)

# Create the root project object
print "Creating project ..."
hProject = stc.create("project")

# Create ports
print "Creating ports ..."
hPortTx = stc.create("port", under=hProject, location=txPortLoc, useDefaultHost=False)
hPortRx = stc.create("port", under=hProject, location=rxPortLoc, useDefaultHost=False)

# Configure physical interface.
hPortTxCopperInterface = stc.create("EthernetCopper",  under=hPortTx)

# Attach ports. 
# Connects to chassis, reserves ports and sets up port mappings all in one step.
# By default, connects to all previously created ports.
print "Attaching ports ", txPortLoc, rxPortLoc
stc.perform("AttachPorts")

# Apply the configuration.
print "Apply configuration"
stc.apply()

# Retrieve the generator and analyzer objects.
hGenerator = stc.get(hPortTx, "children-Generator")
hAnalyzer = stc.get(hPortRx, "children-Analyzer")

# Create a stream block.
print "Configuring stream block ..."
hStreamBlock = stc.create("streamBlock", under=hPortTx, insertSig=True, frameConfig="", frameLengthMode="FIXED", maxFrameLength=1200, FixedFrameLength=256)

# Add an EthernetII Protocol Data Unit (PDU).
print "Adding headers"
hEthernet  = stc.create("ethernet:EthernetII", under=hStreamBlock, name="sb1_eth", srcMac="00:00:20:00:00:00", dstMac="00:00:00:00:00:00")

# Use modifier to generate multiple streams.
print "Creating Modifier on Stream Block ..."
hRangeModifier = stc.create("RangeModifier", \
      under=hStreamBlock, \
      ModifierMode="DECR", \
      Mask="00:00:FF:FF:FF:FF", \
      StepValue="00:00:00:00:00:01", \
      Data="00:00:10:10:00:01", \
      RecycleCount=20, \
      RepeatCount=0, \
      DataType="NATIVE", \
      EnableStream=True, \
      Offset=0, \
      OffsetReference="sb1_eth.dstMac")

# Display stream block information.
print "\n\nStreamBlock information"

dictStreamBlockInfo = stc.perform("StreamBlockGetInfo", StreamBlock=hStreamBlock)

for szName in dictStreamBlockInfo:
    print "\t", szName, "\t", dictStreamBlockInfo[szName]

print "\n\n"


# Configure generator.
print "Configuring Generator"
hGeneratorConfig = stc.get(hGenerator, "children-GeneratorConfig")

stc.config(hGeneratorConfig, \
          DurationMode="BURSTS", \
          BurstSize=1, \
          Duration=100, \
          LoadMode="FIXED", \
          FixedLoad=100, \
          LoadUnit="PERCENT_LINE_RATE", \
          SchedulingMode="PORT_BASED")

# Analyzer Configuration.
print "Configuring Analyzer"
hAnalyzerConfig = stc.get(hAnalyzer, "children-AnalyzerConfig")

# Subscribe to realtime results.
print "Subscribe to results"
hAnaResults = stc.subscribe(Parent=hProject, \
            ConfigType="Analyzer", \
            resulttype="AnalyzerPortResults",  \
            filenameprefix="Analyzer_Port_Results")

hGenResults = stc.subscribe(Parent=hProject, \
            ConfigType="Generator", \
            resulttype="GeneratorPortResults",  \
            filenameprefix="Generator_Port_Counter", \
            Interval=2)

# Configure Capture.
if ENABLE_CAPTURE:
    print "\nStarting Capture..."

    # Create a capture object. Automatically created.
    hCapture = stc.get(hPortRx, "children-capture")
    stc.config(hCapture, mode="REGULAR_MODE", srcMode="TX_RX_MODE")
    stc.perform("CaptureStart", captureProxyId=hCapture)

# Apply configuration.  
print "Apply configuration" 
stc.apply()

# Save the configuration as an XML file. Can be imported into the GUI.
print "\nSave configuration as an XML file."
stc.perform("SaveAsXml")

# Start the analyzer and generator.
print "Start Analyzer"
stc.perform("AnalyzerStart", AnalyzerList=hAnalyzer)
print "Current analyzer state ", stc.get(hAnalyzer, "state")

print "Start Generator"
stc.perform("GeneratorStart", GeneratorList=hGenerator)
print "Current generator state",  stc.get(hGenerator, "state")

print "Wait 2 seconds ..."
stc.sleep(2)

print "Wait until generator stops ..."
stc.waitUntilComplete(timeout=100)

print "Current analyzer state ", stc.get(hAnalyzer, "state")
print "Current generator state ", stc.get(hGenerator, "state")
print "Stop Analyzer"

# Stop the generator.  
stc.perform("GeneratorStop", GeneratorList=hGenerator)

# Stop the analyzer.  
stc.perform("AnalyzerStop", AnalyzerList=hAnalyzer)

# Display some statistics.

# Example of Direct-Descendant Notation ( DDN ) syntax. ( DDN starts with an object reference )
print "Frames Counts:"
print "\tSignature frames: ", stc.get("%s.AnalyzerPortResults(1)" % hAnalyzer, "sigFrameCount")
print "\tTotal frames: ", stc.get("%s.AnalyzerPortResults(1)" % hAnalyzer, "totalFrameCount")

# Example of Descendant-Attribute Notation ( DAN ) syntax. ( using explicit indeces )
print "\tMinFrameLength: ", stc.get(hPortRx, "Analyzer(1).AnalyzerPortResults(1).minFrameLength")
# Notice indexing is not necessary since there is only 1 child.
print "\tMaxFrameLength: ", stc.get(hPortRx, "Analyzer.AnalyzerPortResults.maxFrameLength")

if ENABLE_CAPTURE: 
    from time import gmtime, strftime
    print strftime("%Y-%m-%d %H:%M:%S", gmtime()), " Retrieving Captured frames..."

    stc.perform("CaptureStop", captureProxyId=hCapture)

    # Save captured frames to a file.
    stc.perform("CaptureDataSave", captureProxyId=hCapture, FileName="capture.pcap", FileNameFormat="PCAP", IsScap=False)

    print "Captured frames:\t", stc.get(hCapture, "PktCount")

# Unsubscribe from results
print "Unsubscribe results ..."
stc.unsubscribe(hAnaResults)
stc.unsubscribe(hGenResults)

# Disconnect from chassis, release ports, and reset configuration.
print "Release ports and disconnect from chassis"
stc.perform("ChassisDisconnectAll")
stc.perform("ResetConfig")

# Delete configuration
print "Deleting project"
stc.delete(hProject)

stc.log("INFO", "Ending Test")
