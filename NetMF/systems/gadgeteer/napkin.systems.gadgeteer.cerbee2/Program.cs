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

using napkin.devices.serial.common;

namespace napkin.systems.gadgeteer.cerbee2
{
    public partial class Program
    {
        private ThreadedSerialDevice _nd2_1;

        void ProgramStarted()
        {
            Debug.Print("Program Started");

            rfid.CardIDReceived += new RFID.CardIDReceivedEventHandler(rfid_CardIDReceived);

            _nd2_1 = new ThreadedSerialDevice(Serial.COM3);
            _nd2_1.ReadLine += new ThreadedSerialDevice.ReadHandler(_nd2_1_ReadLine);
        }

        void _nd2_1_ReadLine(string line)
        {
            Debug.Print("line: " + line);
            BumpLed7r();
            BumpLed7r();
        }

        void rfid_CardIDReceived(RFID sender, string ID)
        {
            Debug.Print("RFID: " + ID);
            BumpLed7r();
            _nd2_1.WriteLine("hello!");
            BumpLed7r();
        }

        private int _led7rCounter = 0;
        private void BumpLed7r()
        {
            _led7rCounter++;
            _led7rCounter %= 7;
            led7r.TurnLightOn(_led7rCounter, true);
        }
    }
}
