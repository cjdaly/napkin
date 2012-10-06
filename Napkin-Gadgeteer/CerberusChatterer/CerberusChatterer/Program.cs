using System;
using System.IO;
using System.Collections;
using System.Net;
using System.Net.Sockets;
using System.Text;
using System.Threading;
using Microsoft.SPOT;
using Microsoft.SPOT.Presentation;
using Microsoft.SPOT.Presentation.Controls;
using Microsoft.SPOT.Presentation.Media;
using Microsoft.SPOT.Net.NetworkInformation;
using Microsoft.SPOT.Touch;

using Gadgeteer.Networking;
using GT = Gadgeteer;
using GTM = Gadgeteer.Modules;
using Gadgeteer.Modules.GHIElectronics;
using Gadgeteer.Modules.Seeed;

using NapkinCommon;

namespace CerberusChatterer
{
    public partial class Program
    {
        // This method is run when the mainboard is powered up or reset.   
        void ProgramStarted()
        {
            /*******************************************************************************************
            Modules added in the Program.gadgeteer designer view are used by typing 
            their name followed by a period, e.g.  button.  or  camera.
            
            Many modules generate useful events. Type +=<tab><tab> to add a handler to an event, e.g.:
                button.ButtonPressed +=<tab><tab>
            
            If you want to do something periodically, use a GT.Timer and handle its Tick event, e.g.:
                GT.Timer timer = new GT.Timer(1000); // every second (1000ms)
                timer.Tick +=<tab><tab>
                timer.Start();
            *******************************************************************************************/
            // Use Debug.Print to show messages in Visual Studio's "Output" window during debugging.
            Debug.Print("Hello!");

            NetworkInterface[] nifs = NetworkInterface.GetAllNetworkInterfaces();
            foreach (NetworkInterface nif in nifs)
            {
                Debug.Print("ip: " + nif.IPAddress + ", dhcp: " + nif.IsDhcpEnabled);
                if (!nif.IsDhcpEnabled) nif.EnableDhcp();
            }

            uint mem = Debug.GC(false);
            Debug.Print("mem: " + mem);

            GT.Timer timer = new GT.Timer(10 * 1000);
            timer.Tick += new GT.Timer.TickEventHandler(timer_Tick);
            timer.Start();
        }

        void timer_Tick(GT.Timer timer)
        {
            Mainboard.SetDebugLED(true);

            NetworkInterface[] nifs = NetworkInterface.GetAllNetworkInterfaces();
            foreach (NetworkInterface nif in nifs)
            {
                Debug.Print("TICK! ip: " + nif.IPAddress + ", dhcp: " + nif.IsDhcpEnabled);
            }

            try
            {
                NetworkCredential credential = new NetworkCredential("cerb1", "cerb1");
                string uri = "http://192.168.2.50:4567/napkin/starts";
                string responseText = HttpUtil.DoHttpMethod("GET", uri, credential, null);
                Debug.Print(responseText);
            }
            catch (Exception ex)
            {
                Debug.Print(ex.Message);
            }
            finally
            {
                Mainboard.SetDebugLED(false);
            }
        }
    }
}
