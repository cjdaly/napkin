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
using Gadgeteer.Modules.GHIElectronics;

namespace CerbuinoBeeWiFlyChatterer
{
    public partial class Program
    {
        public readonly string DeviceId = "cerbee2";

        void ProgramStarted()
        {
            Debug.Print("Hello from: " + DeviceId);

            barometer.MeasurementComplete += new Barometer.MeasurementCompleteEventHandler(barometer_MeasurementComplete);
            motion_Sensor.Motion_Sensed += new Motion_Sensor.Motion_SensorEventHandler(motion_Sensor_Motion_Sensed);

            InitSerLcd();

            _cycleThread = new Thread(CycleDriver);
            _cycleThread.Start();
        }

        private readonly int _cycleDelayMillisecondsInitial = 15 * 1000;
        private readonly int _cycleDelayMilliseconds = 15 * 1000;
        private Thread _cycleThread;

        private int _cycleCount = 0;

        private WiFlyGSX _wifly;

        private void CycleDriver()
        {
            Debug.Print("cycle thread starting!");
            Thread.Sleep(_cycleDelayMillisecondsInitial);

            TestSerLcd("Marah is 5");

            Debug.Print("Starting cycle: " + _cycleCount + " on device: " + DeviceId);
            JoinNetwork();

            bool exit = false;
            while (!exit)
            {
                Thread.Sleep(_cycleDelayMilliseconds);
                Cycle();
            }
        }

        private void Cycle()
        {
            _cycleCount++;
            Debug.Print("Starting cycle: " + _cycleCount + " on device: " + DeviceId);

            WriteSerLcd("cycle: " + _cycleCount + "\n");

            barometer.RequestMeasurement();

            PingServer();
        }

        private void JoinNetwork()
        {
            try
            {
                _wifly = new WiFlyGSX();
                _wifly.EnableDHCP();
                _wifly.JoinNetwork("WIFI24Gb", 0, WiFlyGSX.AuthMode.WPA2_PSK, "Batty$nackH0g");

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

        void motion_Sensor_Motion_Sensed(Motion_Sensor sender, Motion_Sensor.Motion_SensorState state)
        {
            Debug.Print("motion: " + state + ", active: " + sender.SensorStillActive);
        }

        //
        // SerLCD ?
        //

        private SerialPort _serLcdPort;
        private readonly string _portName = Serial.COM1;

        private void InitSerLcd()
        {
            _serLcdPort = new SerialPort(_portName, 9600, Parity.None, 8, StopBits.One);
            _serLcdPort.Open();
        }

        public bool TestSerLcd(String message)
        {
            // clear screen
            _serLcdPort.Write(new byte[] { 0xFE, 0x01 }, 0, 2);

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
    }
}
