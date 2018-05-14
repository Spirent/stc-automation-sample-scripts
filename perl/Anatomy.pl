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

# File Name:                 Anatomy.pl
# Description:               This script demonstrates basic features 
#                            such as creating streams, generating traffic,
#                            enabling capture, saving realtime results
#                            to files, and retrieving results.

my $ENABLE_CAPTURE = 1;

use strict;
use SpirentTestCenter;

my $stc = new StcPerl;
my $systemVersion = $stc->get("system1", "Version");
print "SpirentTestCenter system version:\t$systemVersion\n";

# Physical topology
my $szChassisIp1 = "10.29.0.49";
my $szChassisIp2 = "10.29.0.45";
my $txPortLoc = "//$szChassisIp1/1/1";
my $rxPortLoc = "//$szChassisIp2/1/1";

# Create the root project object
print "Creating project ...\n";
my $hProject = $stc->create("project");

# Create ports
print "Creating ports ...\n";
my $hPortTx = $stc->create("port", under=>$hProject, location=>$txPortLoc, useDefaultHost=>"False");
my $hPortRx = $stc->create("port", under=>$hProject, location=>$rxPortLoc, useDefaultHost=>"False");

# Configure ethernet Fiber interface.
my $hPortTxCopperInterface = $stc->create("EthernetCopper", under=>$hPortTx);

# Attach ports. 
# Connects to chassis, reserves ports and sets up port mappings all in one step.
# By default, connects to all previously created ports.
print "Attaching ports $txPortLoc $rxPortLoc\n";
$stc->perform("AttachPorts");

# Apply the configuration.
print "Apply configuration\n";
$stc->apply();

# Initialize generator/analyzer.
my $hGenerator = $stc->get($hPortTx, "children-Generator");
my $currentState = $stc->get($hGenerator, "state");
print "Stopping Generator -current state $currentState\n";
$stc->perform("GeneratorStop", GeneratorList=>$hGenerator);
  
my $hAnalyzer = $stc->get($hPortRx, "children-Analyzer");
my $analyzerState = $stc->get($hAnalyzer, "state");
print "Stopping Analyzer -current state $analyzerState\n";
$stc->perform("AnalyzerStop", AnalyzerList=>$hAnalyzer);

# Create a stream block. FrameConfig with blank double quotes clears the frame out.
print "Configuring stream block ...\n";
my $hStreamBlock = $stc->create("streamBlock", under=>$hPortTx, insertSig=>"true", frameConfig=>"", frameLengthMode=>"FIXED", maxFrameLength=>"1200", FixedFrameLength=>"256");

# Add an EthernetII Protocol Data Unit (PDU).
print "Adding headers\n";
$stc->create("ethernet:EthernetII", under=>$hStreamBlock, name=>"sb1_eth", srcMac=>"00:00:20:00:00:00", dstMac=>"00:00:00:00:00:00"); 

# Use modifier to generate multiple streams.
print "Creating Modifier on Stream Block ...\n";
my $hRangeModifier = $stc->create("RangeModifier", under=>$hStreamBlock, ModifierMode=>"INCR", Mask=>"0000FFFFFFFF", StepValue=>"000000000001", Data=>"000000000000", RecycleCount=>"4294967295", RepeatCount=>"0", DataType=>"BYTE", EnableStream=>"FALSE", Offset=>"0", OffsetReference=>"sb1_eth.dstMac");

# Update just the streamblock.
  
  #### comment this out. John not sure what this does. Does not apply config to hardware.
  ####stc::perform StreamBlockUpdate -StreamBlock "$hStreamBlock"

## Display stream block information.
#print "\n\nStreamBlock information\n";
#my @lstStreamBlockInfo = $stc->perform("StreamBlockGetInfo", StreamBlock=>$hStreamBlock);
#my $getInfo = "";
#foreach $getInfo (@lstStreamBlockInfo)
#{
#	print "\t$getInfo\n";
#}

# Configure generator
print "Configuring Generator\n";
my $hGeneratorConfig = $stc->get($hGenerator, "children-GeneratorConfig");
  
$stc->config($hGeneratorConfig, DurationMode=>"SECONDS", BurstSize=>"1", Duration=>"100", LoadMode=>"FIXED", FixedLoad=>"25", LoadUnit=>"PERCENT_LINE_RATE", SchedulingMode=>"PORT_BASED");

# Analyzer Configuration
print "Configuring Analyzer\n";
my $hAnalyzerConfig = $stc->get($hAnalyzer, "children-AnalyzerConfig");

# Subscribe to realtime results
print "Subscribe to results\n";
$stc->subscribe(Parent=>$hProject, ConfigType=>"Analyzer", resulttype=>"AnalyzerPortResults", filenameprefix=>"Analyzer_Port_Results");
$stc->subscribe(Parent=>$hProject, ConfigType=>"Generator", resulttype=>"GeneratorPortResults", filenameprefix=>"Generator_Port_Counter", Interval=>"2");

# Configure Capture.
my $hCapture = "";
if ($ENABLE_CAPTURE)
{
	print "\nStarting Capture...\n";
  
	# Create a capture object. Automatically created.
	$hCapture = $stc->get($hPortRx, "children-capture");
	$stc->config($hCapture, mode=>"REGULAR_MODE", srcMode=>"TX_RX_MODE");
	$stc->perform("CaptureStart", captureProxyId=>$hCapture);
}

# Apply configuration.  
print "Apply configuration\n";
$stc->apply();

# Save the configuration as an XML file for later import into the GUI.
print "\nSave configuration as an XML file.\n";
$stc->perform("SaveAsXml");

# Start the analyzer and generator.
print "Start Analyzer\n";
$stc->perform("AnalyzerStart", AnalyzerList=>$hAnalyzer);
$analyzerState = $stc->get($hAnalyzer, "state");
print "Current analyzer state $analyzerState\n";
  
$stc->sleep(2);
  
print "Start Generator\n";
$stc->perform("GeneratorStart", GeneratorList=>$hGenerator);
my $generatorState = $stc->get($hGenerator, "state");
print "Current generator state generatorState\n";

print "Wait 5 seconds ...\n";
sleep(5);

$analyzerState = $stc->get($hAnalyzer, "state");
$generatorState = $stc->get($hGenerator, "state");
print "Current analyzer state $analyzerState\n";
print "Current generator state $generatorState\n";
print "Stop Analyzer\n";

# Stop the analyzer.  
$stc->perform("AnalyzerStop", AnalyzerList=>$hAnalyzer);
$stc->sleep(1);

# Display some statistics.

print "Frames Counts:\n";
# Example of Direct-Descendant Notation ( DDN ) syntax. ( DDN starts with an object reference )
my $sigFrames = $stc->get("$hAnalyzer.AnalyzerPortResults(1)", "sigFrameCount");
my $totFrames = $stc->get("$hAnalyzer.AnalyzerPortResults(1)", "totalFrameCount");
print "\tSignature frames: $sigFrames\n";
print "\tTotal frames: $totFrames\n";

# Example of Descendant-Attribute Notation ( DAN ) syntax. ( using explicit indeces )
my $minFrameLen = $stc->get($hPortRx, "Analyzer(1).AnalyzerPortResults(1).minFrameLength");
# Notice indexing is not necessary since there is only 1 child.
my $maxFrameLen = $stc->get($hPortRx, "Analyzer.AnalyzerPortResults.maxFrameLength");
print "\tMinFrameLength: $minFrameLen\n";
print "\tMaxFrameLength: $maxFrameLen\n";

if ($ENABLE_CAPTURE)
{
	my $StartTime = localtime(time);
	print "$StartTime Retrieving Captured frames...\n";
    
	$stc->perform("CaptureStop", captureProxyId=>$hCapture);
    
	# Save captured frames to a file.
	$stc->perform("CaptureDataSave", captureProxyId=>$hCapture, FileName=>"capture.pcap", FileNameFormat=>"PCAP", IsScap=>"FALSE");
	my $capCount = $stc->get($hCapture, "PktCount");
	print "Captured frames:\t$capCount\n";
}

# Disconnect from chassis, release ports, and reset configuration.
print "Release ports and disconnect from chassis\n";
$stc->perform("ChassisDisconnectAll");
$stc->perform("ResetConfig");

# Delete configuration
print "Deleting project\n";
$stc->delete($hProject);
