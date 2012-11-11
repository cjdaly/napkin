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
using Gadgeteer.Modules.GHIElectronics;

using Toolbox.NETMF.Hardware;
using Toolbox.NETMF.NET;

using NapkinCommon;

namespace cerbee2
{
    public partial class Program
    {
        public readonly string DeviceId = "cerbee2";
        public readonly string NapkinServerUri = "http://192.168.2.50:4567";

        void ProgramStarted()
        {
            SDCardTest();

            InitSerLcd();

            _cycleThread = new Thread(CycleDriver);
            _cycleThread.Start();

        }

        private readonly int _cycleDelayMillisecondsInitial = 15 * 1000;
        private readonly int _cycleDelayMilliseconds = 5 * 1000;
        private Thread _cycleThread;

        private int _cycleCount = 0;

        private WiFlyGSX _wifly;

        private void CycleDriver()
        {

            Debug.Print("cycle thread starting!");
            Thread.Sleep(_cycleDelayMillisecondsInitial);

            TestSerLcd("Marah is 5");
            
            Debug.Print("Starting cycle: " + _cycleCount + " on device: " + DeviceId);
            JoinNetwork();

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

            double potentiometerPercentage = potentiometer.ReadPotentiometerPercentage();
            double potentiometerVoltage = potentiometer.ReadPotentiometerVoltage();

            ClearSerLcd();
            WriteSerLcd("cycle: " + _cycleCount);
            int intPotPct = (int)(potentiometerPercentage * 100);
            WriteSerLcd("pot: " + intPotPct, 64);
            
            PingServer();
        }

        private void JoinNetwork()
        {
            try
            {
                _wifly = new WiFlyGSX();
                _wifly.EnableDHCP();
                //_wifly.JoinNetwork("WIFI24G", 0, WiFlyGSX.AuthMode.WPA2_PSK, "???");
                _wifly.JoinNetwork("linksys-dd", 0, WiFlyGSX.AuthMode.Open);

                for (int i = 0; i < 4; i++)
                {
                    string ip = _wifly.LocalIP;
                    string mac = _wifly.MacAddress;
                    Debug.Print("IP: " + ip + ", mac: " + mac);
                    Thread.Sleep(5000);
                }

                Debug.Print("joined network");
            }
            catch (Exception ex)
            {
                Debug.Print("Exception in JoinNetwork: " + ex.Message);
            }
        }

        private void PingServer()
        {
            try
            {
                WiFlySocket socket = new WiFlySocket("192.168.2.50", 4567, _wifly);
                //WiFlySocket socket = new WiFlySocket("www.google.com", 80, _wifly);
                HTTP_Client client = new HTTP_Client(socket);
                client.Authenticate(DeviceId, DeviceId);
                HTTP_Client.HTTP_Response response = client.Get("/config");

                Debug.Print("got from server:");
                Debug.Print(response.ResponseBody);
            }
            catch (Exception ex)
            {
                Debug.Print("Exception in PingServer: " + ex.Message);
            }
        }

        //
        // SD Card
        //

        private void SDCardTest()
        {
            string[] vols = Mainboard.GetStorageDeviceVolumeNames();
            foreach (string vol in vols)
            {
                Debug.Print("volume: " + vol);
                bool result = Mainboard.MountStorageDevice(vol);
                Debug.Print("mounted: " + result);
            }

            VolumeInfo[] volInfos = VolumeInfo.GetVolumes();
            foreach (VolumeInfo volInfo in volInfos)
            {
                string rootDir = volInfo.RootDirectory;
                Debug.Print("root dir: " + rootDir);

                string[] fileNames = Directory.GetFiles(rootDir);
                foreach (string fileName in fileNames)
                {
                    Debug.Print("file name: " + fileName);

                    String filePath = Path.Combine(rootDir, fileName);
                    Debug.Print("file path: " + fileName);

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


        //
        // SerLCD ?
        //

        private SerialPort _serLcdPort;
        private readonly string _portName = Serial.COM3;

        private void InitSerLcd()
        {
            _serLcdPort = new SerialPort(_portName, 9600, Parity.None, 8, StopBits.One);
            _serLcdPort.Open();
        }

        public void ClearSerLcd()
        {
            _serLcdPort.Write(new byte[] { 0xFE, 0x01 }, 0, 2);
        }

        public bool TestSerLcd(String message)
        {
            ClearSerLcd();

            WriteSerLcd("Hello World");
            WriteSerLcd(message, 64);

            return true;
        }

        private byte[] _serLcdBuffer = new byte[40];
        private void WriteSerLcd(String message, int position = 0)
        {
            int i = 0;
            if (position != 0)
            {
                _serLcdBuffer[i++] = (byte)(0xFE);
                _serLcdBuffer[i++] = (byte)(0x80 + position);
            }

            foreach (char c in message)
            {
                _serLcdBuffer[i++] = (byte)c;
            }
            _serLcdPort.Write(_serLcdBuffer, 0, i);
        }

    }
}
