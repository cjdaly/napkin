using System;
using System.Collections;
using System.Net;
using System.Text;
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
using Gadgeteer.Modules.Seeed;

using napkin.util.http;

namespace napkin.systems.gadgeteer.cerbee1
{
    public partial class Program
    {
        public readonly string DeviceId = "cerbee1";
        public readonly string NapkinServerUri = "http://192.168.2.50:4567";
        private NetworkCredential _credential;

        private Thread _cycleThread;

        void ProgramStarted()
        {
            Debug.Print("Hello from: " + DeviceId);

            _credential = new NetworkCredential(DeviceId, DeviceId);

            _cycleThread = new Thread(CycleDriver);
            _cycleThread.Start();
        }

        private void CycleDriver()
        {
            bool exit = false;
            while (!exit)
            {
                Thread.Sleep(5000);
                Cycle();
            }
        }

        private void Cycle()
        {
            Debug.Print("Cycle");

            StringBuilder sb = new StringBuilder();
            sb.AppendLine("foo.1=hello");
            sb.AppendLine("foo.2=world");
            string chatterRequestText = sb.ToString();

            string configUri = NapkinServerUri + "/config";
            string responseText = HttpUtil.DoHttpMethod("GET", configUri, _credential, null);
            Debug.Print("GOT: " + responseText);

            Thread.Sleep(3000);

            string chatterUri = NapkinServerUri + "/chatter?format=keyset";
            HttpUtil.DoHttpMethod("POST", chatterUri, _credential, chatterRequestText, false);
        }
    }
}
