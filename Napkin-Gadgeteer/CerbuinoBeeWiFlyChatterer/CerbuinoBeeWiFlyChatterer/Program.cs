using System;
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

using Toolbox.NETMF.Hardware;
using Toolbox.NETMF.NET;

namespace CerbuinoBeeWiFlyChatterer
{
    public partial class Program
    {
        public readonly string DeviceId = "cerbee2";

        void ProgramStarted()
        {
            Debug.Print("Hello from: " + DeviceId);

            _cycleThread = new Thread(CycleDriver);
            _cycleThread.Start();
        }

        private readonly int _cycleDelayMillisecondsInitial = 15 * 1000;
        private readonly int _cycleDelayMilliseconds = 15 * 1000;
        private Thread _cycleThread;

        private int _cycleCount = 0;

        private WiFlyGSX _wifly;

        private void CycleDriver()
        {
            Debug.Print("cycle thread starting!");
            Thread.Sleep(_cycleDelayMillisecondsInitial);

            JoinNetwork();

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

            PingServer();
        }

        private void JoinNetwork()
        {
            _wifly = new WiFlyGSX();
            _wifly.EnableDHCP();
            _wifly.JoinNetwork("WIFI24Gb", 0, WiFlyGSX.AuthMode.WPA2_PSK, "Batty$nackH0g");

            Debug.Print("joined network");
        }

        private void PingServer()
        {
            // WiFlySocket socket = new WiFlySocket("192.168.2.50", 4567, _wifly);
            WiFlySocket socket = new WiFlySocket("google.com", 80, _wifly);
            HTTP_Client client = new HTTP_Client(socket);
            // client.Authenticate(DeviceId, DeviceId);
            HTTP_Client.HTTP_Response response = client.Get("/");

            Debug.Print("got from server:");
            Debug.Print(response.ResponseBody);
        }
    }
}
