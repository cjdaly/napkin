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

            Debug.Print("Program Started");

            display_HD44780.Clear();
            display_HD44780.CursorHome();
            display_HD44780.PrintString("Hello World!");


            //
            Font font = Resources.GetFont(Resources.FontResources.NinaB);
            oledDisplay.SimpleGraphics.DisplayText("Hello World!", font, GT.Color.White, 0, 0);
            oledDisplay.SimpleGraphics.DisplayText("Hello Marah!", font, GT.Color.Orange, 0, 20);
            oledDisplay.SimpleGraphics.DisplayText("Hello Sage!", font, GT.Color.Red, 0, 40);


            button.ButtonPressed += new Button.ButtonEventHandler(button_ButtonPressed);
            button.ButtonReleased += new Button.ButtonEventHandler(button_ButtonReleased);

            Debug.Print("MEM: " + Debug.GC(false));
        }

        void button_ButtonReleased(Button sender, Button.ButtonState state)
        {
            Mainboard.SetDebugLED(false);
            button.TurnLEDOff();
        }

        void button_ButtonPressed(Button sender, Button.ButtonState state)
        {
            Mainboard.SetDebugLED(true);
            button.TurnLEDOn();
        }
    }
}
