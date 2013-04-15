/****
 * Copyright (c) 2013 Chris J Daly (github user cjdaly)
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 * 
 * Contributors:
 *   cjdaly - initial API and implementation
 ****/
using System;
using System.IO;
using System.IO.Ports;
using System.Text;
using System.Collections;
using System.Threading;
using Microsoft.SPOT;
using Microsoft.SPOT.IO;
using Microsoft.SPOT.Presentation;
using Microsoft.SPOT.Presentation.Controls;
using Microsoft.SPOT.Presentation.Media;
using Microsoft.SPOT.Touch;

using Gadgeteer.Networking;
using GT = Gadgeteer;
using GTM = Gadgeteer.Modules;

using Toolbox.NETMF.Hardware;
using Toolbox.NETMF.NET;

using NapkinCommon;
using Gadgeteer.Modules.GHIElectronics;

namespace cerbee2
{
    public partial class Program
    {
        public readonly string DeviceId = "cerbee2";
        public readonly string NapkinServerName = "192.168.2.50";
        public readonly ushort NapkinServerPort = 4567;
        public string NapkinServerUri
        {
            get { return "http://" + NapkinServerName + ":" + NapkinServerPort.ToString(); }
        }

        void ProgramStarted()
        {
            Thread.Sleep(1000);

            rfid.CardIDReceived += new RFID.CardIDReceivedEventHandler(rfid_CardIDReceived);

            _wiflyThread = new Thread(WiFlyDriver);
            _wiflyThread.Start();

            _cycleThread = new Thread(CycleDriver);
            _cycleThread.Start();

        }

        private int _led7rVal = 0;
        void rfid_CardIDReceived(RFID sender, string ID)
        {
            _led7rVal++;
            if (_led7rVal >= 8) {
                _led7rVal = 0;
            }

            led7r.TurnLightOn(_led7rVal, true);
        }

        private readonly int _cycleDelayMillisecondsInitial = 15 * 1000;
        private readonly int _cycleDelayMilliseconds = 5 * 1000;
        private Thread _cycleThread;

        private int _cycleCount = 0;

        private Thread _wiflyThread;
        private WiFlyGSX _wifly;

        private void CycleDriver()
        {

            Debug.Print("cycle thread starting!");
            Thread.Sleep(_cycleDelayMillisecondsInitial);

            SDCardTest();

            Debug.Print("Starting cycle: " + _cycleCount + " on device: " + DeviceId);

            bool exit = false;
            while (!exit)
            {
                Thread.Sleep(_cycleDelayMilliseconds);
                Cycle();
            }
        }

        private void Cycle()
        {

            _cycleCount++;
            Debug.Print("Starting cycle: " + _cycleCount + " on device: " + DeviceId);
            Debug.Print("mem: " + Debug.GC(false));
        }

        //
        //

        private void WiFlyDriver()
        {
            // Note: WiFly is pre-configured for SSID, passphrase, etc, using 3.3V FTDI basic (pins 1,2,3,10)

            try
            {

                _wifly = new WiFlyGSX();

                string ver = _wifly.ModuleVersion;
                string mac = _wifly.MacAddress;

                Debug.Print("WiFly version: " + ver + ", mac: " + mac);

                while (true)
                {
                    string ip = _wifly.LocalIP;
                    Debug.Print("IP: " + ip);

                    if (ip != "0.0.0.0")
                    {
                        string conf = NapkinGet("/config/cerbee2");
                        Debug.Print("CONF: ");
                        Debug.Print(conf);
                    }

                    Thread.Sleep(8000);
                }
            }
            catch (Exception ex)
            {
                Debug.Print("Exception in WiFlyDriver: " + ex.Message);
            }
        }

        private string NapkinGet(string path)
        {
            try
            {
                WiFlySocket socket = new WiFlySocket(NapkinServerName, NapkinServerPort, _wifly);
                HTTP_Client client = new HTTP_Client(socket);
                client.Authenticate(DeviceId, DeviceId);
                HTTP_Client.HTTP_Response response = client.Get(path);
                return response.ResponseBody;
            }
            catch (Exception ex)
            {
                Debug.Print("Exception in PingServer: " + ex.Message);
                return null;
            }
        }

        //
        // SD Card
        //

        private void SDCardTest()
        {
            Debug.Print("MEM: " + Debug.GC(false));

            string[] vols = Mainboard.GetStorageDeviceVolumeNames();
            foreach (string vol in vols)
            {
                Debug.Print("volume: " + vol);
                bool result = Mainboard.MountStorageDevice(vol);
                Debug.Print("mounted: " + result);
            }
            Debug.Print("MEM: " + Debug.GC(false));

            VolumeInfo[] volInfos = VolumeInfo.GetVolumes();
            foreach (VolumeInfo volInfo in volInfos)
            {
                Thread.Sleep(50);
                Debug.Print("MEM: " + Debug.GC(false));

                string rootDir = volInfo.RootDirectory;
                Debug.Print("root dir: " + rootDir);

                string[] fileNames = Directory.GetFiles(rootDir);
                foreach (string fileName in fileNames)
                {
                    Thread.Sleep(50);
                    Debug.Print("MEM: " + Debug.GC(false));

                    Debug.Print("file name: " + fileName);

                    String filePath = Path.Combine(rootDir, fileName);
                    Debug.Print("file path: " + fileName);

                    Thread.Sleep(50);
                    Debug.Print("MEM: " + Debug.GC(false));

                    string fileText = GetFileText(filePath);
                    Debug.Print(">>>");
                    Debug.Print(fileText);
                    Debug.Print("<<<");
                }
            }

            Debug.Print("Program Started");
        }

        private string GetFileText(string filePath)
        {
            byte[] bytes = File.ReadAllBytes(filePath);
            char[] chars = Encoding.UTF8.GetChars(bytes);
            string fileText = new String(chars);
            return fileText;
        }

    }
}
