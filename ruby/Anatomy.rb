# Copyright (c) 2010 by Spirent Communications, Inc.
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

# File Name:                 Anatomy.rb
# Description:               This script demonstrates basic features 
#                            such as creating streams, generating traffic,
#                            enabling capture, saving realtime results
#                            to files, and retrieving results.

ENABLE_CAPTURE = 1

require 'rubygems'
require 'spirenttestcenter'

stcVersion = Stc.get("system1", "Version")
print "SpirentTestCenter system version:\t" + stcVersion + "\n"

# Physical topology
szChassisIp1 = "10.29.0.49";
szChassisIp2 = "10.29.0.45";
txPortLoc = "//#{szChassisIp1}/1/1";
rxPortLoc = "//#{szChassisIp2}/1/1";

# Create the root project object
print "Creating project ...\n"
hProject = Stc.create("project", "system1")

# Create ports
print "Creating ports ...\n"
hPortTx = Stc.create("port", hProject, "location"=>txPortLoc, "useDefaultHost"=>false)
hPortRx = Stc.create("port", hProject, "location"=>rxPortLoc, "useDefaultHost"=>false)

# Configure ethernet Fiber interface.
hPortTxCopperInterface = Stc.create("EthernetCopper", hPortTx)

# Attach ports. 
# Connects to chassis, reserves ports and sets up port mappings all in one step.
# By default, connects to all previously created ports.
print "Attaching ports #{txPortLoc} #{rxPortLoc}\n"
Stc.perform("AttachPorts")

# Apply the configuration.
print "Apply configuration\n"
Stc.apply()

# Initialize generator/analyzer.
hGenerator = Stc.get(hPortTx, "children-Generator")
stateGenerator = Stc.get(hGenerator, "state")
print "Stopping Generator -current state " + stateGenerator + "\n"
Stc.perform("GeneratorStop", "GeneratorList"=>hGenerator)

hAnalyzer = Stc.get(hPortRx, "children-Analyzer")  
stateAnalyzer = Stc.get(hAnalyzer, "state")
print "Stopping Analyzer -current state " + stateAnalyzer + "\n"
Stc.perform("AnalyzerStop", "AnalyzerList"=>hAnalyzer)

# Create a stream block. FrameConfig with blank double quotes clears the frame out.
print "Configuring stream block ...\n"
hStreamBlock = Stc.create("streamBlock", hPortTx, "insertSig"=>true, "frameConfig"=>"", "frameLengthMode"=>"FIXED", "maxFrameLength"=>"1200", "FixedFrameLength"=>"256")

# Add an EthernetII Protocol Data Unit (PDU).
print "Adding headers\n"
Stc.create("ethernet:EthernetII", hStreamBlock, "name"=>"sb1_eth", "srcMac"=>"00:00:20:00:00:00", "dstMac"=>"00:00:00:00:00:00")

# Use modifier to generate multiple streams.
print "Creating Modifier on Stream Block ...\n"
hRangeModifier = Stc.create("RangeModifier", hStreamBlock, "ModifierMode"=>"INCR", "Mask"=>"0000FFFFFFFF", "StepValue"=>"000000000001", "Data"=>"000000000000", "RecycleCount"=>"4294967295", "RepeatCount"=>"0", "DataType"=>"BYTE", "EnableStream"=>false, "Offset"=>"0", "OffsetReference"=>"sb1_eth.dstMac")


# Configure generator
print "Configuring Generator\n"
hGeneratorConfig = Stc.get(hGenerator, "children-GeneratorConfig")
  
Stc.config(hGeneratorConfig, "DurationMode"=>"SECONDS", "BurstSize"=>"1", "Duration"=>"100", "LoadMode"=>"FIXED", "FixedLoad"=>"25", "LoadUnit"=>"PERCENT_LINE_RATE", "SchedulingMode"=>"PORT_BASED")

# Analyzer Configuration
print "Configuring Analyzer\n"
hAnalyzerConfig = Stc.get(hAnalyzer, "children-AnalyzerConfig")

# Subscribe to realtime results
print "Subscribe to results\n"
Stc.subscribe("Parent"=>hProject, "ConfigType"=>"Analyzer", "resulttype"=>"AnalyzerPortResults", "filenameprefix"=>"Analyzer_Port_Results")

Stc.subscribe("Parent"=>hProject, "ConfigType"=>"Generator", "resulttype"=>"GeneratorPortResults", "filenameprefix"=>"Generator_Port_Counter", "Interval"=>"2")

# Configure Capture.
hCapture = ""
if ENABLE_CAPTURE
	print "\nStarting Capture...\n"
  
  	# Create a capture object. Automatically created.
    	hCapture = Stc.get(hPortRx, "children-capture")
    	Stc.config(hCapture, "mode"=>"REGULAR_MODE", "srcMode"=>"TX_RX_MODE")
    	Stc.perform("CaptureStart", "captureProxyId"=>hCapture)
end

# Apply configuration.  
print "Apply configuration\n"
Stc.apply()

# Save the configuration as an XML file for later import into the GUI.
print "\nSave configuration as an XML file.\n"
Stc.perform("SaveAsXml")
  
# Start the analyzer and generator.
print "Start Analyzer\n"
Stc.perform("AnalyzerStart", "AnalyzerList"=>hAnalyzer)
stateAnalyzer = Stc.get(hAnalyzer, "state")
print "Current analyzer state " + stateAnalyzer + "\n"
  
sleep 2

print "Start Generator\n"
Stc.perform("GeneratorStart", "GeneratorList"=>hGenerator)
stateGenerator = Stc.get(hGenerator, "state")
print "Current generator state " + stateGenerator + "\n"

print "Wait 5 seconds ...\n"
sleep 5

stateGenerator = Stc.get(hGenerator, "state")
stateAnalyzer = Stc.get(hAnalyzer, "state")
print "Current analyzer state " + stateAnalyzer + "\n"
print "Current generator state " + stateGenerator + "\n"
print "Stop Analyzer\n"

# Stop the analyzer.  
Stc.perform("AnalyzerStop", "AnalyzerList"=>hAnalyzer)
sleep 1

# Display some statistics.

print "Frames Counts:\n"
# Example of Direct-Descendant Notation ( DDN ) syntax. ( DDN starts with an object reference )  
sigFrameCount = Stc.get("#{hAnalyzer}.AnalyzerPortResults(1)", "sigFrameCount")
totalFrameCount = Stc.get("#{hAnalyzer}.AnalyzerPortResults(1)", "totalFrameCount")
print "\tSignature frames: #{sigFrameCount}\n"
print "\tTotal frames: #{totalFrameCount}\n"

# Example of Descendant-Attribute Notation ( DAN ) syntax. ( using explicit indeces )
minFrameLength = Stc.get(hPortRx, "Analyzer(1).AnalyzerPortResults(1).minFrameLength")
print "\tMinFrameLength: #{minFrameLength}\n"
# Notice indexing is not necessary since there is only 1 child. 
maxFrameLength = Stc.get(hPortRx, "Analyzer.AnalyzerPortResults.maxFrameLength")
print "\tMaxFrameLength: #{maxFrameLength}\n"

if ENABLE_CAPTURE
	print "Retrieving Captured frames...\n"
    
    	Stc.perform("CaptureStop", "captureProxyId"=>hCapture)
    
  	# Save captured frames to a file.
    	Stc.perform("CaptureDataSave", "captureProxyId"=>hCapture, "FileName"=>"capture.pcap", "FileNameFormat"=>"PCAP", "IsScap"=>false)
	
	pktCount = Stc.get(hCapture, "PktCount")    
    	print "Captured frames:\t" + pktCount + "\n"
end

# Disconnect from chassis, release ports, and reset configuration.
print "Release ports and disconnect from chassis\n";
Stc.perform("ChassisDisconnectAll")
Stc.perform("ResetConfig")

# Delete configuration
print "Deleting project\n"
Stc.delete(hProject)
