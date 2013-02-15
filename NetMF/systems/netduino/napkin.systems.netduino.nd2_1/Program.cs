using System;
using System.Net;
using System.Net.Sockets;
using System.Threading;
using Microsoft.SPOT;
using Microsoft.SPOT.Hardware;
using SecretLabs.NETMF.Hardware;
using SecretLabs.NETMF.Hardware.Netduino;

using napkin.devices.serial.common;
using napkin.devices.serial.MidiMusicShield;

namespace napkin.systems.netduino.nd2_1
{
    public class Program
    {
        private static ThreadedSerialDevice _cerbee2;

        public static void Main()
        {
            Debug.Print("Hello!   mem: " + Debug.GC(false));

            _cerbee2 = new ThreadedSerialDevice();
            _cerbee2.ReadLine += new ThreadedSerialDevice.ReadHandler(_cerbee2_ReadLine);

            //MidiDriver midiDriver = new MidiDriver(Pins.GPIO_PIN_D4);
            //midiDriver.Reset();
            //midiDriver.Test();

            Debug.Print("Goodbye!   mem: " + Debug.GC(false));
        }

        static void _cerbee2_ReadLine(string line)
        {
            Thread.Sleep(200);
            _cerbee2.WriteLine(">>> " + line);
        }

    }
}
