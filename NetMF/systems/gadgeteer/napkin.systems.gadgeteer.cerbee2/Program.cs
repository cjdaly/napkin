using System;
using System.IO.Ports;
using System.Collections;
using System.Threading;
using Microsoft.SPOT;
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

using napkin.devices.serial.common;

namespace napkin.systems.gadgeteer.cerbee2
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

        //
        //
        //

        private Thread _wiflyThread;
        private WiFlyGSX _wifly;

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

                    Debug.Print("mem: " + Debug.GC(false));

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
        //
        //

        private ThreadedSerialDevice _nd2_1;

        void ProgramStarted()
        {
            Debug.Print("Program Started");

            rfid.CardIDReceived += new RFID.CardIDReceivedEventHandler(rfid_CardIDReceived);

            _nd2_1 = new ThreadedSerialDevice(Serial.COM3);
            _nd2_1.ReadLine += new ThreadedSerialDevice.ReadHandler(_nd2_1_ReadLine);

            Debug.Print("mem: " + Debug.GC(false));
            _wiflyThread = new Thread(WiFlyDriver);
            _wiflyThread.Start();
            Debug.Print("mem: " + Debug.GC(false));
        }

        void _nd2_1_ReadLine(string line)
        {
            Debug.Print("line: " + line);
            BumpLed7r();
            BumpLed7r();
        }

        void rfid_CardIDReceived(RFID sender, string ID)
        {
            Debug.Print("mem: " + Debug.GC(false));
            Debug.Print("RFID: " + ID);
            BumpLed7r();
            _nd2_1.WriteLine("hello!");
            BumpLed7r();
        }

        private int _led7rCounter = 0;
        private void BumpLed7r()
        {
            Debug.Print("mem: " + Debug.GC(false));
            _led7rCounter++;
            _led7rCounter %= 7;
            led7r.TurnLightOn(_led7rCounter, true);
        }
    }
}
