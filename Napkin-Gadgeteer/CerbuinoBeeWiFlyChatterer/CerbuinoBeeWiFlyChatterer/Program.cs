using System;
using System.Collections;
using System.Threading;
using System.IO.Ports;
using Microsoft.SPOT;
using Microsoft.SPOT.Hardware;
using Microsoft.SPOT.Presentation;
using Microsoft.SPOT.Presentation.Controls;
using Microsoft.SPOT.Presentation.Media;
using Microsoft.SPOT.Touch;

using Gadgeteer.Networking;
using GT = Gadgeteer;
using GTM = Gadgeteer.Modules;

using Toolbox.NETMF.Hardware;
using Toolbox.NETMF.NET;
using Gadgeteer.Modules.Seeed;

using NapkinCommon;

namespace CerbuinoBeeWiFlyChatterer
{
    public partial class Program
    {
        public readonly string DeviceId = "cerbee2";

        void ProgramStarted()
        {
            MemCheck.Sample();

            Debug.Print("Hello from: " + DeviceId + " ... MemCheck:\n" + MemCheck.GetStatus());

            MemCheck.Sample();

            barometer.MeasurementComplete += new Barometer.MeasurementCompleteEventHandler(barometer_MeasurementComplete);

            MemCheck.Sample();

            InitSerLcd();

            _cycleThread = new Thread(CycleDriver);
            _cycleThread.Start();

            MemCheck.Sample();
        }

        private readonly int _cycleDelayMillisecondsInitial = 15 * 1000;
        private readonly int _cycleDelayMilliseconds = 5 * 1000;
        private Thread _cycleThread;

        private int _cycleCount = 0;

        private WiFlyGSX _wifly;

        private void CycleDriver()
        {
            MemCheck.Sample();

            Debug.Print("cycle thread starting!" + " ... MemCheck:\n" + MemCheck.GetStatus());
            Thread.Sleep(_cycleDelayMillisecondsInitial);

            TestSerLcd("Marah is 5");

            MemCheck.Sample();
            Debug.Print("Starting cycle: " + _cycleCount + " on device: " + DeviceId + " ... MemCheck:\n" + MemCheck.GetStatus());
            //JoinNetwork();

            MemCheck.Reset();
            MemCheck.Sample();
            bool exit = false;
            while (!exit)
            {
                Thread.Sleep(_cycleDelayMilliseconds);
                Cycle();
            }
        }

        private void Cycle()
        {
            MemCheck.Sample();
            _cycleCount++;
            Debug.Print("Starting cycle: " + _cycleCount + " on device: " + DeviceId + " ... MemCheck:\n" + MemCheck.GetStatus());
            MemCheck.Reset();

            int moisture = moistureSensor.GetMoistureReading();

            ClearSerLcd();
            WriteSerLcd("cycle: " + _cycleCount);
            WriteSerLcd("moisture: " + moisture, 64);

            MemCheck.Sample();
            barometer.RequestMeasurement();

            MemCheck.Sample();
            // PingServer();

            MemCheck.Sample();
        }

        private void JoinNetwork()
        {
            try
            {
                _wifly = new WiFlyGSX();
                _wifly.EnableDHCP();
                _wifly.JoinNetwork("WIFI24Gb", 0, WiFlyGSX.AuthMode.WPA1, "Batty$nackH0g");

                Debug.Print("joined network");
            }
            catch (Exception ex)
            {
                Debug.Print("Exception in JoinNetwork: " + ex.Message);
            }
        }

        private void PingServer()
        {
            try
            {
                // WiFlySocket socket = new WiFlySocket("192.168.2.50", 4567, _wifly);
                WiFlySocket socket = new WiFlySocket("google.com", 80, _wifly);
                HTTP_Client client = new HTTP_Client(socket);
                // client.Authenticate(DeviceId, DeviceId);
                HTTP_Client.HTTP_Response response = client.Get("/");

                Debug.Print("got from server:");
                Debug.Print(response.ResponseBody);
            }
            catch (Exception ex)
            {
                Debug.Print("Exception in PingServer: " + ex.Message);
            }
        }

        void barometer_MeasurementComplete(Barometer sender, Barometer.SensorData sensorData)
        {
            Debug.Print("barometer pressure: " + sensorData.Pressure + ", temperature: " + sensorData.Temperature);
        }

        //
        // SerLCD ?
        //

        private SerialPort _serLcdPort;
        private readonly string _portName = Serial.COM3;

        private void InitSerLcd()
        {
            _serLcdPort = new SerialPort(_portName, 9600, Parity.None, 8, StopBits.One);
            _serLcdPort.Open();
        }

        public void ClearSerLcd()
        {
            _serLcdPort.Write(new byte[] { 0xFE, 0x01 }, 0, 2);
        }

        public bool TestSerLcd(String message)
        {
            ClearSerLcd();

            WriteSerLcd("Hello World");
            WriteSerLcd(message, 64);

            return true;
        }

        private byte[] _serLcdBuffer = new byte[40];
        private void WriteSerLcd(String message, int position = 0)
        {
            int i = 0;
            if (position != 0)
            {
                _serLcdBuffer[i++] = (byte)(0xFE);
                _serLcdBuffer[i++] = (byte)(0x80 + position);
            }

            foreach (char c in message)
            {
                _serLcdBuffer[i++] = (byte)c;
            }
            _serLcdPort.Write(_serLcdBuffer, 0, i);
        }


        //
        //
        //

        private readonly LongSampler MemCheck = CreateMemCheck();
        private static long TakeMemorySample()
        {
            return Debug.GC(false);
        }
        private static LongSampler CreateMemCheck(string statusKeyPrefix = "memory")
        {
            LongSampler sampler = new LongSampler(TakeMemorySample, statusKeyPrefix);
            return sampler;
        }
    }
}
