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
using Gadgeteer.Modules.GHIElectronics;
using Gadgeteer.Modules.Seeed;

namespace hydra1
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
            Debug.Print("Program Started");

            display_HD44780_a.TurnBacklightOn();
            display_HD44780_a.Clear();
            display_HD44780_a.CursorHome();
            display_HD44780_a.PrintString("Hello World!");

            //

            display_HD44780_b.TurnBacklightOn();
            display_HD44780_b.Clear();
            display_HD44780_b.CursorHome();
            display_HD44780_b.PrintString("Test 1 2 3 ...");


            //
            Font font = Resources.GetFont(Resources.FontResources.NinaB);
            oledDisplay.SimpleGraphics.DisplayText("Hello World!", font, GT.Color.White, 0, 0);
            oledDisplay.SimpleGraphics.DisplayText("Hello Marah!", font, GT.Color.Orange, 0, 20);
            oledDisplay.SimpleGraphics.DisplayText("Hello Sage!", font, GT.Color.Red, 0, 40);
        }
    }
}
