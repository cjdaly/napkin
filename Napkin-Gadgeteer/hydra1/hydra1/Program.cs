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


            Font font = Resources.GetFont(Resources.FontResources.NinaB);
            oledDisplay.SimpleGraphics.DisplayText("Hello World!", font, GT.Color.White, 0, 0);
            oledDisplay.SimpleGraphics.DisplayText("Hello Marah!", font, GT.Color.Orange, 0, 20);
            oledDisplay.SimpleGraphics.DisplayText("Hello Sage!", font, GT.Color.Red, 0, 40);

            //

            GT.StorageDevice sd = sdCard.GetStorageDevice();
            string[] dirs = sd.ListDirectories("music");
            foreach (string dir in dirs)
            {
                Debug.Print("dir: " + dir);
            }

            string[] files = sd.ListFiles("music");
            foreach (string file in files)
            {
                Debug.Print("file: " + file);
            }

            Debug.Print("Mem: " + Debug.GC(false));
            byte[] songBytes = sd.ReadFile("music\\majesty.mp3");
            //byte[] songBytes = sd.ReadFile("music\\maggie.mp3");
            //byte[] songBytes = sd.ReadFile("music\\dig-it.mp3");
            Debug.Print("song bytes: " + songBytes.Length);
            Debug.Print("Mem: " + Debug.GC(false));
            music.Play(songBytes);
        }
    }
}
