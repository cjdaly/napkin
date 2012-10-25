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

            WiFlyGSX wifly = new WiFlyGSX();
            wifly.EnableDHCP();
            wifly.JoinNetwork("WIFI24Gb", 0, WiFlyGSX.AuthMode.WPA2_PSK, "Batty$nackH0g");

            Debug.Print("joined network");

            WiFlySocket socket = new WiFlySocket("192.168.2.50", 4567, wifly);
            HTTP_Client client = new HTTP_Client(socket);
            client.Authenticate(DeviceId, DeviceId);
            HTTP_Client.HTTP_Response response = client.Get("/config/cerbee2");

            Debug.Print("got from server:");
            Debug.Print(response.ResponseBody);
        }
    }
}
