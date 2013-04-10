using System;
using System.IO;
using System.IO.Ports;
using System.Threading;
using Microsoft.SPOT;
using Microsoft.SPOT.Hardware;
using SecretLabs.NETMF.Hardware;
using SecretLabs.NETMF.Hardware.Netduino;

using NapkinCommon;

namespace nd2
{
    public class Program
    {
        private static SerialBridge _serialBridge;

        public static void Main()
        {
            Debug.Print("mem: " + Debug.GC(false));

            I2CDevice i2cDevice = new I2CDevice(null);
            Ds1307 ds1307 = new Ds1307(200);
            ds1307.Test(i2cDevice);

            Thread.Sleep(1000);

            OutputPort uLcd144_reset = new OutputPort(Pins.GPIO_PIN_D13, true);
            ULcd144 uLcd144 = new ULcd144();
            uLcd144.Test(uLcd144_reset);
            Thread.Sleep(1000);

            _serialBridge = new SerialBridge(Serial.COM1);
            _serialBridge.ReadLine += new ThreadedSerialDevice.ReadHandler(_serialBridge_ReadLine);

            while (true)
            {
                Thread.Sleep(100);
            }

        }

        static void _serialBridge_ReadLine(string line)
        {
            if (line == "ping") line = "pong";
            _serialBridge.WriteLine("echo -> " + line);
        }

        public class ULcd144
        {
            public void Test(OutputPort uLcd144_reset)
            {
                uLcd144_reset.Write(false);
                Thread.Sleep(100);
                uLcd144_reset.Write(true);
                Thread.Sleep(2000);

                SerialPort com2 = new SerialPort(Serial.COM2, 9600, Parity.None, 8, StopBits.One);
                com2.Open();

                // autobaud
                ULcd144Command(com2, new byte[] { (byte)'U' });

                // set screen background
                ULcd144Command(com2, new byte[] { (byte)'B', 0x00, 0xFF });

                // write "Hello"
                byte[] hello = new byte[] { (byte)'s', 0x01, 0x01, 0x02, 0xff, 0xff,
                (byte)'H', (byte)'e', (byte)'l', (byte)'l', (byte)'o', 0x00 };
                ULcd144Command(com2, hello);

                // draw circle
                byte[] circle = new byte[] { (byte)'C', 30, 50, 20, 0xf0, 0x0f };
                ULcd144Command(com2, circle);

                // write "World"
                byte[] world = new byte[] { (byte)'s', 0x03, 0x06, 0x02, 0x03, 0xa0,
                (byte)'W', (byte)'o', (byte)'r', (byte)'l', (byte)'d', 0x00 };
                ULcd144Command(com2, world);

                // scroll left
                byte[] scroll = new byte[] { (byte)'c', 4, 0, 0, 0, 124, 128 };
                byte[] fill = new byte[] { (byte)'r', 124, 0, 127, 127, 0x00, 0x00 };

                byte[] ticker1 = new byte[] { (byte)'s', 15, 15, 1, 0xff, 0xff,
                (byte)'A', 0x00 };
                byte[] ticker2 = new byte[] { (byte)'s', 15, 14, 1, 0xff, 0xff,
                (byte)'B', 0x00 };

                ULcd144Command(com2, ticker1);

                ULcd144Command(com2, scroll);
                ULcd144Command(com2, fill);

                ULcd144Command(com2, ticker2);

                ULcd144Command(com2, scroll);
                ULcd144Command(com2, fill);

                ULcd144Command(com2, scroll);
                ULcd144Command(com2, fill);

                ULcd144Command(com2, scroll);
                ULcd144Command(com2, fill);

                ULcd144Command(com2, ticker1);

                ULcd144Command(com2, scroll);
                ULcd144Command(com2, fill);

                ULcd144Command(com2, scroll);
                ULcd144Command(com2, fill);
            }

            private static void ULcd144Command(SerialPort com, byte[] command)
            {
                com.Write(command, 0, command.Length);
                byte[] ack = new byte[1];
                com.Read(ack, 0, 1);
                Debug.Print("ULcd144 Command: " + command[0] + " ack: " + ack[0]);
            }
        }

        public class Ds1307
        {
            public readonly ushort I2CAddress = 0x68;

            private I2CDevice.Configuration _config;

            public Ds1307(int clockRateKhz)
            {
                _config = new I2CDevice.Configuration(I2CAddress, clockRateKhz);
            }

            private byte IntToBcdByte(int value)
            {
                return 0;
            }

            public void Test(I2CDevice i2cDevice)
            {
                // byte[] initData = new byte[] { 0, 0, 0, 1, 1, 1, };

                byte[] rtcData = Read(i2cDevice, 0, 64);
                foreach (byte b in rtcData)
                {
                    Debug.Print("RTC data: " + b);
                }
            }

            public void Write(I2CDevice i2cDevice, byte address, byte[] data)
            {
                i2cDevice.Config = _config;

                I2CDevice.I2CTransaction[] transactions = new I2CDevice.I2CTransaction[] {
                    I2CDevice.CreateWriteTransaction(data),
                };

                i2cDevice.Execute(transactions, 1000);
            }

            public byte[] Read(I2CDevice i2cDevice, byte address, int length)
            {
                byte[] data = new byte[length];

                i2cDevice.Config = _config;

                I2CDevice.I2CTransaction[] transactions = new I2CDevice.I2CTransaction[] {
                    I2CDevice.CreateWriteTransaction(new byte[] { 1 }),
                    I2CDevice.CreateReadTransaction(data)
                };

                i2cDevice.Execute(transactions, 1000);

                return data;
            }
        }
    }
}
