using System;
using System.IO.Ports;
using System.Collections;
using System.Net;
using System.Text;
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

using napkin.devices.serial.common;

namespace napkin.systems.gadgeteer.cerbee1
{
    public partial class Program
    {
        public readonly string DeviceId = "cerbee1";

        private Thread _cycleThread;
        private ThreadedSerialDevice _bone2;

        void ProgramStarted()
        {
            Debug.Print("Hello from: " + DeviceId);

            _bone2 = new ThreadedSerialDevice(Serial.COM3);
            _bone2.ReadLine += new ThreadedSerialDevice.ReadHandler(_bone2_ReadLine);
            _bone2.WriteLine("Hello from: " + DeviceId);

            temperatureHumidity.MeasurementComplete += new TemperatureHumidity.MeasurementCompleteEventHandler(temperatureHumidity_MeasurementComplete);

            _cycleThread = new Thread(CycleDriver);
            _cycleThread.Start();
        }

        void _bone2_ReadLine(string line)
        {
            Debug.Print("line: " + line);
        }


        private double _temperature = 0;
        private double _relativeHumidity = 0;
        void temperatureHumidity_MeasurementComplete(TemperatureHumidity sender, double temperature, double relativeHumidity)
        {
            _temperature = temperature;
            _relativeHumidity = relativeHumidity;
        }


        private int _cycleCount = 0;
        private void CycleDriver()
        {
            bool exit = false;
            while (!exit)
            {
                Thread.Sleep(5000);
                Cycle();
            }
        }

        private void Cycle()
        {
            _cycleCount++;
            Debug.Print("Cycle: " + _cycleCount);
            _bone2.WriteLine("Cycle: " + _cycleCount);

            StringBuilder sb = new StringBuilder();
            sb.AppendLine("vitals.id=" + DeviceId);
            sb.AppendLine("vitals.currentCycle~i=" + _cycleCount);

            long memoryBytesFree = Debug.GC(false);
            sb.AppendLine("vitals.memoryBytesFree~i=" + memoryBytesFree);

            temperatureHumidity.RequestMeasurement();
            Thread.Sleep(1000);
            sb.AppendLine("sensor.temperatureHumidity.temperature~f=" + _temperature.ToString());
            sb.AppendLine("sensor.temperatureHumidity.relativeHumidity~f=" + _relativeHumidity.ToString());

            double lightSensorPercentage = lightSensor.ReadLightSensorPercentage();
            sb.AppendLine("sensor.lightSensor.lightSensorPercentage~f=" + lightSensorPercentage.ToString());

            string chatterRequestText = sb.ToString();
            _bone2.Write(chatterRequestText);

            Thread.Sleep(10 * 1000);
        }
    }
}
