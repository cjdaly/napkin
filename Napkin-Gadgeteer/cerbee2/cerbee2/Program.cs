using System;
using System.IO;
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

namespace cerbee2
{
    public partial class Program
    {
        void ProgramStarted()
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
    }
}
