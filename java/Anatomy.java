// Copyright (c) 2010 by Spirent Communications, Inc.
// All Rights Reserved
//
// By accessing or executing this software, you agree to be bound 
// by the terms of this agreement.
// 
// Redistribution and use of this software in source and binary forms,
// with or without modification, are permitted provided that the 
// following conditions are met:
//   1.  Redistribution of source code must contain the above copyright 
//       notice, this list of conditions, and the following disclaimer.
//   2.  Redistribution in binary form must reproduce the above copyright
//       notice, this list of conditions and the following disclaimer
//       in the documentation and/or other materials provided with the
//       distribution.
//   3.  Neither the name Spirent Communications nor the names of its
//       contributors may be used to endorse or promote products derived
//       from this software without specific prior written permission.
//
// This software is provided by the copyright holders and contributors 
// [as is] and any express or implied warranties, including, but not 
// limited to, the implied warranties of merchantability and fitness for
// a particular purpose are disclaimed.  In no event shall Spirent
// Communications, Inc. or its contributors be liable for any direct, 
// indirect, incidental, special, exemplary, or consequential damages
// (including, but not limited to: procurement of substitute goods or
// services; loss of use, data, or profits; or business interruption)
// however caused and on any theory of liability, whether in contract, 
// strict liability, or tort (including negligence or otherwise) arising
// in any way out of the use of this software, even if advised of the
// possibility of such damage.

// File Name:                 Anatomy.java
// Description:               This script demonstrates basic features 
//                            such as creating streams, generating traffic,
//                            enabling capture, saving realtime results
//                            to files, and retrieving results.

import java.util.HashMap;
import java.util.Map;

import com.spirent.stc;

public class Anatomy {
	
	public static void main(String[] args)
	{
		try {

			stc.Init();
		
			boolean ENABLE_CAPTURE = true;
			
			String stcVersion = stc.Get("system1", "Version");
			System.out.println("SpirentTestCenter system version:\t" + stcVersion);

			// Physical topology
			String szChassisIp1 = "10.29.0.49";
			String szChassisIp2 = "10.29.0.45";
			String txPortLoc = String.format("//%s/%s/%s", szChassisIp1, 1, 1);
			String rxPortLoc = String.format("//%s/%s/%s", szChassisIp2, 1, 1);
		
			// Create the root project object
			System.out.println("Creating project ...");
			String hProject = stc.Create("project", "system1");

			// Create ports
			System.out.println("Creating ports ...");
			String hPortTx = stc.Create("port", hProject);
			String hPortRx = stc.Create("port", hProject);

			Map<String, String> sm = new HashMap<String, String>();
			sm.clear();
			sm.put("location", txPortLoc);
			sm.put("useDefaultHost", "False");
			stc.Config(hPortTx, sm);

			sm.clear();
			sm.put("location", rxPortLoc);
			sm.put("useDefaultHost", "False");
			stc.Config(hPortRx, sm);

			// Configure ethernet Fiber interface.
			stc.Create("EthernetCopper", hPortTx);

			// Attach ports. 
			// Connects to chassis, reserves ports and sets up port mappings all in one step.
			// By default, connects to all previously created ports.			
			System.out.println(String.format("Attaching ports %s %s", txPortLoc, rxPortLoc));
			stc.Perform("AttachPorts");
			
			// Apply the configuration.
			System.out.println("Apply configuration");
			stc.Apply();

			// Initialize generator/analyzer.
			String hGenerator = stc.Get(hPortTx, "children-Generator");
			String generatorState = stc.Get(hGenerator, "state");
			System.out.println("Stopping Generator -current state " + generatorState);
			sm.clear();
			sm.put("generatorList", hGenerator);
			stc.Perform("generatorStop", sm);

			String hAnalyzer = stc.Get(hPortRx, "children-Analyzer");
			String analyzerState = stc.Get(hAnalyzer, "state");
			System.out.println("Stopping Analyzer -current state " + analyzerState);
			sm.clear();
			sm.put("analyzerList", hAnalyzer);
			stc.Perform("analyzerStop", sm);

			// Create a stream block. FrameConfig with blank double quotes clears the frame out.
			System.out.println("Configuring stream block ...");
			String hStreamBlock = stc.Create("streamBlock", hPortTx);
			sm.clear();
			sm.put("insertSig", "true");
			sm.put("frameConfig", "");
			sm.put("frameLengthMode", "FIXED");
			sm.put("maxFrameLength", "1200");
			sm.put("FixedFrameLength", "256");
			stc.Config(hStreamBlock, sm);

			// Add an EthernetII Protocol Data Unit (PDU).
			System.out.println("Adding headers");
			String ethPDU = stc.Create("ethernet:EthernetII", hStreamBlock);
			sm.clear();
			sm.put("name", "sb1_eth");
			sm.put("srcMac", "00:00:20:00:00:00");
			sm.put("dstMac", "00:00:00:00:00:00");
			stc.Config(ethPDU, sm);

			// Use modifier to generate multiple streams.
			System.out.println("Creating Modifier on Stream Block ...");
			String hRangeModifier = stc.Create("RangeModifier", hStreamBlock);
			sm.clear();
			sm.put("ModifierMode", "INCR");
			sm.put("Mask", "0000FFFFFFFF");
			sm.put("StepValue", "000000000001");
			sm.put("Data", "000000000000");
			sm.put("RecycleCount", "4294967295");
			sm.put("RepeatCount", "0");
			sm.put("DataType", "BYTE");
			sm.put("EnableStream", "FALSE");
			sm.put("Offset", "0");
			sm.put("OffsetReference", "sb1_eth.dstMac");
			stc.Config(hRangeModifier, sm);
			
			// Configure generator
			System.out.println("Configuring Generator");
			String hGeneratorConfig = stc.Get(hGenerator, "children-GeneratorConfig");

			sm.clear();
			sm.put("DurationMode", "SECONDS");
			sm.put("BurstSize", "1");
			sm.put("Duration", "100");
			sm.put("LoadMode", "FIXED");
			sm.put("FixedLoad", "25");
			sm.put("LoadUnit", "PERCENT_LINE_RATE");
			sm.put("SchedulingMode", "PORT_BASED");
			stc.Config(hGeneratorConfig, sm);

			// Analyzer Configuration
			System.out.println("Configuring Analyzer");
			String hAnalyzerConfig = stc.Get(hAnalyzer, "children-AnalyzerConfig");

			// Subscribe to realtime results
			System.out.println("Subscribe to results");
			sm.clear();
			sm.put("Parent", hProject);
			sm.put("ConfigType", "Analyzer");
			sm.put("resulttype", "AnalyzerPortResults");
			sm.put("filenameprefix", "Analyzer_Port_Results");
			stc.Subscribe(sm);

			sm.clear();
			sm.put("Parent", hProject);
			sm.put("ConfigType", "Generator");
			sm.put("resulttype", "Generator");
			sm.put("filenameprefix", "Generator_Port_Counter");
			stc.Subscribe(sm);

			// Configure Capture.
			String hCapture = "";
			if (ENABLE_CAPTURE)
			{
				System.out.println("\nStarting Capture...");
  
				// Create a capture object. Automatically created.
				hCapture = stc.Get(hPortRx, "children-capture");
				sm.clear();
				sm.put("mode", "REGULAR_MODE");
				sm.put("srcMode", "TX_RX_MODE");
				stc.Config(hCapture, sm);
				sm.clear();
				sm.put("captureProxyId", hCapture);
				stc.Perform("CaptureStart", sm);
			}

			// Apply configuration.  
			System.out.println("Apply configuration");
			stc.Apply();

			// Save the configuration as an XML file for later import into the GUI.
			System.out.println("\nSave configuration as an XML file.");
			stc.Perform("SaveAsXml");

			// Start the analyzer and generator.
			System.out.println("Start Analyzer");
			sm.clear();
			sm.put("AnalyzerList", hAnalyzer);
			stc.Perform("AnalyzerStart", sm);
			analyzerState = stc.Get(hAnalyzer, "state");
			System.out.println("Current analyzer state " + analyzerState);

			Thread.sleep(2000);

			System.out.println("Start Generator");
			sm.clear();
			sm.put("GeneratorList", hGenerator);
			stc.Perform("GeneratorStart", sm);
			generatorState = stc.Get(hGenerator, "state");
			System.out.println("Current generator state " + generatorState);

			System.out.println("Wait 5 seconds ...");
			Thread.sleep(5000);

			analyzerState = stc.Get(hAnalyzer, "state");
			generatorState = stc.Get(hGenerator, "state");
			System.out.println("Current analyzer state " + analyzerState);
			System.out.println("Current generator state " + generatorState);
			
			// Stop the analyzer.  
			System.out.println("Stop Analyzer");
			sm.clear();
			sm.put("AnalyzerList", hAnalyzer);
			stc.Perform("AnalyzerStop", sm);
			Thread.sleep(1000);

			// Display some statistics.

			System.out.println("Frames Counts:");
			// Example of Direct-Descendant Notation ( DDN ) syntax. ( DDN starts with an object reference )  
			String sigFrameCount = stc.Get(String.format("%s.AnalyzerPortResults(1)", hAnalyzer), "sigFrameCount");
			String totalFrameCount = stc.Get(String.format("%s.AnalyzerPortResults(1)", hAnalyzer), "totalFrameCount");
			System.out.println("\tSignature frames: " + sigFrameCount);
			System.out.println("\tTotal frames: " + totalFrameCount);

			// Example of Descendant-Attribute Notation ( DAN ) syntax. ( using explicit indeces )
			String minFrameLength = stc.Get(hPortRx, "Analyzer(1).AnalyzerPortResults(1).minFrameLength");
			System.out.println("\tMinFrameLength: " + minFrameLength);
			// Notice indexing is not necessary since there is only 1 child. 
			String maxFrameLength = stc.Get(hPortRx, "Analyzer.AnalyzerPortResults.maxFrameLength");
			System.out.println("\tMaxFrameLength: " + maxFrameLength);
			
			if (ENABLE_CAPTURE)
			{
				System.out.println("Retrieving Captured frames...");
				sm.clear();
				sm.put("captureProxyId", hCapture);
				stc.Perform("CaptureStop", sm);
    
				// Save captured frames to a file.
				sm.clear();
				sm.put("captureProxyId", hCapture);
				sm.put("FileName", "capture.pcap");
				sm.put("FileNameFormat", "PCAP");
				sm.put("IsScap", "FALSE");
				stc.Perform("CaptureDataSave", sm);
				
				String capPackets = stc.Get(hCapture, "PktCount");
				System.out.println("Captured frames:\t" + capPackets);
			}

			// Disconnect from chassis, release ports, and reset configuration.
			System.out.println("Release ports and disconnect from chassis");		
			stc.Perform("ChassisDisconnectAll");			
			stc.Perform("ResetConfig");
			
			// Delete configuration
			System.out.println("Deleting project");
			stc.Delete(hProject);

		} catch (Exception catchEx) {
			System.out.println("Exception: " + catchEx);
		}
	}
}
