using System;
using System.Threading;
using System.IO.Ports;
using Microsoft.SPOT;
using Microsoft.SPOT.Hardware;
using napkin.devices.serial.common;

namespace napkin.devices.serial.uLcd144
{
    public class ULcd144Device : ThreadedSerialDevice
    {
        private OutputPort _resetPinPort;

        public ULcd144Device(Cpu.Pin resetPin, string serialPortName = Serial.COM1) : base(serialPortName)
        {
            _resetPinPort = new OutputPort(resetPin, true);
        }

        public override bool AutoFlushReads()
        {
            return false;
        }

        public void Reset()
        {
            _resetPinPort.Write(false);
            Thread.Sleep(100);
            _resetPinPort.Write(true);
            Thread.Sleep(2000);

            // autobaud
            WriteCommand(new byte[] { (byte)'U' });
        }

        public void WriteCommand(byte[] commandBytes)
        {
            Debug.Print("ULcd144 write: " + commandBytes.Length);
            Write(commandBytes);
            string status = Read(true);
            Debug.Print("ULcd144 status: " + status.Length);
        }

        public void Test()
        {
            // autobaud
            // WriteCommand(new byte[] { (byte)'U' });

            // set screen background
            WriteCommand(new byte[] { (byte)'B', 0x00, 0xFF });

            // write "Hello"
            byte[] hello = new byte[] { (byte)'s', 0x01, 0x01, 0x02, 0xff, 0xff,
                (byte)'H', (byte)'e', (byte)'l', (byte)'l', (byte)'o', 0x00 };
            WriteCommand(hello);

            // draw circle
            byte[] circle = new byte[] { (byte)'C', 30, 50, 20, 0xf0, 0x0f };
            WriteCommand(circle);

            // write "World"
            byte[] world = new byte[] { (byte)'s', 0x03, 0x06, 0x02, 0x03, 0xa0,
                (byte)'W', (byte)'o', (byte)'r', (byte)'l', (byte)'d', 0x00 };
            WriteCommand(world);

            // scroll left
            byte[] scroll = new byte[] { (byte)'c', 4, 0, 0, 0, 124, 128 };
            byte[] fill = new byte[] { (byte)'r', 124, 0, 127, 127, 0x00, 0x00 };

            byte[] ticker1 = new byte[] { (byte)'s', 15, 15, 1, 0xff, 0xff,
                (byte)'A', 0x00 };
            byte[] ticker2 = new byte[] { (byte)'s', 15, 14, 1, 0xff, 0xff,
                (byte)'B', 0x00 };

            WriteCommand(ticker1);

            WriteCommand(scroll);
            WriteCommand(fill);

            WriteCommand(ticker2);

            WriteCommand(scroll);
            WriteCommand(fill);

            WriteCommand(scroll);
            WriteCommand(fill);

            WriteCommand(scroll);
            WriteCommand(fill);

            WriteCommand(ticker1);

            WriteCommand(scroll);
            WriteCommand(fill);

            WriteCommand(scroll);
            WriteCommand(fill);
        }
    }
}
