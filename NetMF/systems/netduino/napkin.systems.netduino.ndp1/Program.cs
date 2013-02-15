using System;
using System.Net;
using System.Net.Sockets;
using System.Threading;
using Microsoft.SPOT;
using Microsoft.SPOT.Hardware;
using SecretLabs.NETMF.Hardware;
using SecretLabs.NETMF.Hardware.NetduinoPlus;

using napkin.devices.serial.SerLCD;

namespace napkin.systems.netduino.ndp1
{
    public class Program
    {
        public static void Main()
        {
            SerLCDDevice serLcd = new SerLCDDevice();
            serLcd.Clear();
            serLcd.Write("hello", "world");
        }
    }
}
