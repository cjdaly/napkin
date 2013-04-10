using System;
using System.IO.Ports;
using System.Net;
using System.Net.Sockets;
using System.Threading;
using Microsoft.SPOT;
using Microsoft.SPOT.Hardware;
using SecretLabs.NETMF.Hardware;
using SecretLabs.NETMF.Hardware.Netduino;

using napkin.devices.serial.common;
using napkin.devices.serial.MidiMusicShield;
using napkin.devices.serial.uLcd144;
using napkin.devices.spi.DeadOnRTC;

namespace napkin.systems.netduino.nd2_1
{
    public class Program
    {
        private static ThreadedSerialDevice _cerbee2;
        private static MidiDriver _midiDriver;
        private static ULcd144Device _uLcd144;
        private static DeadOnRTCDriver _deadOnRtc;

        public static void Main()
        {
            Debug.Print("Hello!   mem: " + Debug.GC(false));

            _cerbee2 = new ThreadedSerialDevice();
            _cerbee2.ReadLine += new ThreadedSerialDevice.ReadHandler(_cerbee2_ReadLine);

            _midiDriver = new MidiDriver(Pins.GPIO_PIN_D4);
            _midiDriver.Reset();

            _uLcd144 = new ULcd144Device(Pins.GPIO_PIN_D9, Serial.COM3);
            _uLcd144.Reset();
            _uLcd144.Clear();
            _uLcd144.WriteMessage("Hello", 0, 0);
            _uLcd144.WriteMessage("World!", 0, 1);

            _deadOnRtc = new DeadOnRTCDriver(Pins.GPIO_PIN_D10, SPI_Devices.SPI1);

            for (int i = 0; i < 4; i++)
            {
                DeadOnRTCData rtcData = _deadOnRtc.ReadData();
                DateTime dt = rtcData.GetDateTime();
                Debug.Print("DateTime: " + dt.ToString());
                _uLcd144.ConsoleWriteLine(dt.ToString());
                Thread.Sleep(5000);
            }

            Debug.Print("Goodbye!   mem: " + Debug.GC(false));
        }

        static void _cerbee2_ReadLine(string line)
        {
            _midiDriver.Test(1);
            Thread.Sleep(500);
            _uLcd144.ConsoleWriteLine(line);
            _cerbee2.WriteLine(">>> " + line);
            Thread.Sleep(500);
            _midiDriver.Test(2);
        }

    }
}
