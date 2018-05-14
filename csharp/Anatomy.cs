// Copyright (c) 2012 by Spirent Communications, Inc.
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

// File Name:                 Anatomy.cs
// Description:               This script demonstrates basic features 
//                            such as creating streams, generating traffic,
//                            enabling capture, saving realtime results
//                            to files, and retrieving results.

using StcCSharp;
using System;
using System.Collections.Generic;
using System.Threading;


public class Anatomy
{
    public void Run()
    {
        Stc.Init();       

        const bool ENABLE_CAPTURE = true;

        string StcVersion = Stc.Get("system1", "Version");
        Console.WriteLine("SpirentTestCenter system version:\t" + StcVersion);

        // Physical topology
        string szChassisIp1 = "10.29.0.49";
        string szChassisIp2 = "10.29.0.45";
        string txPortLoc = String.Format("//{0}/1/1", szChassisIp1);
        string rxPortLoc = String.Format("//{0}/1/1", szChassisIp2);

        // Create the root project object
        Console.WriteLine("Creating project ...");
        string hProject = Stc.Create("project", "system1");

        // Create ports
        Console.WriteLine("Creating ports ...");
        string hPortTx = Stc.Create("port", hProject);
        string hPortRx = Stc.Create("port", hProject);

        Dictionary<string, string> sm = new Dictionary<string, string>();
        sm.Clear();
        sm["location"] = txPortLoc;
        sm["useDefaultHost"] = "False";
        Stc.Config(hPortTx, sm);

        sm.Clear();
        sm["location"] = rxPortLoc;
        sm["useDefaultHost"] = "False";
        Stc.Config(hPortRx, sm);

        // Configure ethernet Fiber interface.
        Stc.Create("EthernetCopper", hPortTx);

        // Attach to ports.
        Console.WriteLine("Attaching to ports {0} and {1}", txPortLoc, rxPortLoc);
        Stc.Perform("AttachPorts");

        // Apply the configuration.
        Console.WriteLine("Apply configuration");
        Stc.Apply();

        // Initialize generator/analyzer.
        string hGenerator = Stc.Get(hPortTx, "children-Generator");
        string generatorState = Stc.Get(hGenerator, "state");
        Console.WriteLine("Stopping Generator -current state " + generatorState);
        sm.Clear();
        sm["generatorList"] = hGenerator;
        Stc.Perform("generatorStop", sm);

        string hAnalyzer = Stc.Get(hPortRx, "children-Analyzer");
        string analyzerState = Stc.Get(hAnalyzer, "state");
        Console.WriteLine("Stopping Analyzer -current state " + analyzerState);
        sm.Clear();
        sm["analyzerList"] = hAnalyzer;
        Stc.Perform("analyzerStop", sm);

        // Create a stream block. FrameConfig with blank double quotes Clears the frame out.
        Console.WriteLine("Configuring stream block ...");
        string hStreamBlock = Stc.Create("streamBlock", hPortTx);
        sm.Clear();
        sm["insertSig"] = "true";
        sm["frameConfig"] = "";
        sm["frameLengthMode"] = "FIXED";
        sm["maxFrameLength"] = "1200";
        sm["FixedFrameLength"] = "256";
        Stc.Config(hStreamBlock, sm);

        // Add an EthernetII Protocol Data Unit (PDU).
        Console.WriteLine("Adding headers");
        string ethPDU = Stc.Create("ethernet:EthernetII", hStreamBlock);
        sm.Clear();
        sm["name"] = "sb1_eth";
        sm["srcMac"] = "00:00:20:00:00:00";
        sm["dstMac"] = "00:00:00:00:00:00";
        Stc.Config(ethPDU, sm);

        // Use modifier to generate multiple streams.
        Console.WriteLine("Creating Modifier on Stream Block ...");
        string hRangeModifier = Stc.Create("RangeModifier", hStreamBlock);
        sm.Clear();
        sm["ModifierMode"] = "INCR";
        sm["Mask"] = "0000FFFFFFFF";
        sm["StepValue"] = "000000000001";
        sm["Data"] = "000000000000";
        sm["RecycleCount"] = "4294967295";
        sm["RepeatCount"] = "0";
        sm["DataType"] = "BYTE";
        sm["EnableStream"] = "FALSE";
        sm["Offset"] = "0";
        sm["OffsetReference"] = "sb1_eth.dstMac";
        Stc.Config(hRangeModifier, sm);

        // Configure generator
        Console.WriteLine("Configuring Generator");
        string hGeneratorConfig = Stc.Get(hGenerator, "children-GeneratorConfig");

        sm.Clear();
        sm["DurationMode"] = "SECONDS";
        sm["BurstSize"] = "1";
        sm["Duration"] = "100";
        sm["LoadMode"] = "FIXED";
        sm["FixedLoad"] = "25";
        sm["LoadUnit"] = "PERCENT_LINE_RATE";
        sm["SchedulingMode"] = "PORT_BASED";
        Stc.Config(hGeneratorConfig, sm);

        // Analyzer Configuration
        Console.WriteLine("Configuring Analyzer");
        string hAnalyzerConfig = Stc.Get(hAnalyzer, "children-AnalyzerConfig");

        // Subscribe to realtime results
        Console.WriteLine("Subscribe to results");
        sm.Clear();
        sm["Parent"] = hProject;
        sm["ConfigType"] = "Analyzer";
        sm["resulttype"] = "AnalyzerPortResults";
        sm["filenameprefix"] = "Analyzer_Port_Results";
        Stc.Subscribe(sm);

        sm.Clear();
        sm["Parent"] = hProject;
        sm["ConfigType"] = "Generator";
        sm["resulttype"] = "Generator";
        sm["filenameprefix"] = "Generator_Port_Counter";
        Stc.Subscribe(sm);

        // Configure Capture.
        string hCapture = "";
        if (ENABLE_CAPTURE)
        {
            Console.WriteLine("\nStarting Capture...");

            // Create a capture object. Automatically created.
            hCapture = Stc.Get(hPortRx, "children-capture");
            sm.Clear();
            sm["mode"] = "REGULAR_MODE";
            sm["srcMode"] = "TX_RX_MODE";
            Stc.Config(hCapture, sm);
            sm.Clear();
            sm["captureProxyId"] = hCapture;
            Stc.Perform("CaptureStart", sm);
        }

        // Apply configuration.  
        Console.WriteLine("Apply configuration");
        Stc.Apply();

        // Save the configuration as an XML file for later import into the GUI.
        Console.WriteLine("\nSave configuration as an XML file.");
        Stc.Perform("SaveAsXml");

        // Start the analyzer and generator.
        Console.WriteLine("Start Analyzer");
        sm.Clear();
        sm["AnalyzerList"] = hAnalyzer;
        Stc.Perform("AnalyzerStart", sm);
        analyzerState = Stc.Get(hAnalyzer, "state");
        Console.WriteLine("Current analyzer state " + analyzerState);

        Thread.Sleep(2000);

        Console.WriteLine("Start Generator");
        sm.Clear();
        sm["GeneratorList"] = hGenerator;
        Stc.Perform("GeneratorStart", sm);
        generatorState = Stc.Get(hGenerator, "state");
        Console.WriteLine("Current generator state " + generatorState);

        Console.WriteLine("Wait 5 seconds ...");
        Thread.Sleep(5000);

        analyzerState = Stc.Get(hAnalyzer, "state");
        generatorState = Stc.Get(hGenerator, "state");
        Console.WriteLine("Current analyzer state " + analyzerState);
        Console.WriteLine("Current generator state " + generatorState);

        // Stop the analyzer.  
        Console.WriteLine("Stop Analyzer");
        sm.Clear();
        sm["AnalyzerList"] = hAnalyzer;
        Stc.Perform("AnalyzerStop", sm);
        Thread.Sleep(1000);

        // Display some statistics.

        Console.WriteLine("Frames Counts:");
        // Example of Direct-Descendant Notation ( DDN ) syntax. ( DDN starts with an object reference )  
        string sigFrameCount = Stc.Get(String.Format("{0}.AnalyzerPortResults(1)", hAnalyzer), "sigFrameCount");
        string totalFrameCount = Stc.Get(String.Format("{0}.AnalyzerPortResults(1)", hAnalyzer), "totalFrameCount");        
        Console.WriteLine("\tSignature frames: {0}", sigFrameCount);
        Console.WriteLine("\tTotal frames: {0}", totalFrameCount);

        // Example of Descendant-Attribute Notation ( DAN ) syntax. ( using explicit indeces )
        string minFrameLength = Stc.Get(hPortRx, "Analyzer(1).AnalyzerPortResults(1).minFrameLength");
        Console.WriteLine("\tMinFrameLength: {0}", minFrameLength);
        // Notice indexing is not necessary since there is only 1 child. 
        string maxFrameLength = Stc.Get(hPortRx, "Analyzer.AnalyzerPortResults.maxFrameLength");
        Console.WriteLine("\tMaxFrameLength: {0}", maxFrameLength);

        if (ENABLE_CAPTURE)
        {
            Console.WriteLine("Retrieving Captured frames...");
            sm.Clear();
            sm["captureProxyId"] = hCapture;
            Stc.Perform("CaptureStop", sm);

            // Save captured frames to a file.
            sm.Clear();
            sm["captureProxyId"] = hCapture;
            sm["FileName"] = "capture.pcap";
            sm["FileNameFormat"] = "PCAP";
            sm["IsScap"] = "FALSE";
            Stc.Perform("CaptureDataSave", sm);

            string capPackets = Stc.Get(hCapture, "PktCount");
            Console.WriteLine("Captured frames:\t" + capPackets);
        }

        // Disconnect from chassis, release ports, and reset configuration.
        Console.WriteLine("Release ports and disconnect from chassis");
        Stc.Perform("ChassisDisconnectAll");
        Stc.Perform("ResetConfig");

        // Delete configuration
        Console.WriteLine("Deleting project");
        Stc.Delete(hProject);
    }

    static void Main(string[] args)
    {
        try
        {            
            new Anatomy().Run();
        }
        catch (Exception ex)
        {
            Console.WriteLine(ex.Message);            
        }
    }
}
