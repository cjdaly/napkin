using System;
using System.IO.Ports;
using System.Collections;
using System.Text;
using System.Threading;
using Microsoft.SPOT;
using Microsoft.SPOT.Presentation;
using Microsoft.SPOT.Presentation.Controls;
using Microsoft.SPOT.Presentation.Media;
using Microsoft.SPOT.Presentation.Shapes;
using Microsoft.SPOT.Touch;

using Gadgeteer.Networking;
using GT = Gadgeteer;
using GTM = Gadgeteer.Modules;
using Gadgeteer.Modules.GHIElectronics;
using Gadgeteer.Modules.Seeed;

using napkin.devices.serial.common;

namespace napkin.systems.gadgeteer.cerb2_pcduino1
{
    public partial class Program
    {
        public readonly string DeviceId = "cerb2";

        private Thread _cycleThread;
        private ThreadedSerialDevice _pcduino1;

        void ProgramStarted()
        {
            Thread.Sleep(1000);

            Debug.Print("Hello from: " + DeviceId);

            _pcduino1 = new ThreadedSerialDevice(Serial.COM3);
            _pcduino1.ReadLine += new ThreadedSerialDevice.ReadHandler(_pcduino1_ReadLine);

            temperatureHumidity.MeasurementComplete += new TemperatureHumidity.MeasurementCompleteEventHandler(temperatureHumidity_MeasurementComplete);

            barometer.StopContinuousMeasurements();
            barometer.MeasurementComplete += new Barometer.MeasurementCompleteEventHandler(barometer_MeasurementComplete);

            gasSense.SetHeatingElement(true);

            Thread.Sleep(1000);

            _cycleThread = new Thread(CycleDriver);
            _cycleThread.Start();
        }

        private double _temperature2 = 0;
        private double _relativeHumidity = 0;
        void temperatureHumidity_MeasurementComplete(TemperatureHumidity sender, double temperature, double relativeHumidity)
        {
            _temperature2 = temperature;
            _relativeHumidity = relativeHumidity;
        }

        private double _temperature = 0;
        private double _pressure = 0;
        void barometer_MeasurementComplete(Barometer sender, Barometer.SensorData sensorData)
        {
            _pressure = sensorData.Pressure;
            _temperature = sensorData.Temperature;
        }

        private string _lastLine = "";
        void _pcduino1_ReadLine(string line)
        {
            if (line == null) line = "";
            _lastLine = line;
            Debug.Print("line: " + line);
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

        private void RefreshLcd(string line1, string line2 = "")
        {
            char_Display.Clear();
            char_Display.CursorHome();
            char_Display.PrintString(line1);
            char_Display.SetCursor(1, 0);
            char_Display.PrintString(line2);
        }

        private void Cycle()
        {
            _cycleCount++;
            Debug.Print("Cycle: " + _cycleCount);

            RefreshLcd("cycle: " + _cycleCount);

            StringBuilder sb = new StringBuilder();
            sb.AppendLine("state.vitalsAndSensorsUpdated=false");

            sb.AppendLine("vitals.id=" + DeviceId);
            sb.AppendLine("vitals.currentCycle~i=" + _cycleCount);

            _temperature2 = 0; _relativeHumidity = 0;
            temperatureHumidity.RequestMeasurement();
            Thread.Sleep(500);
            sb.AppendLine("sensor.temperatureHumidity.temperature~f=" + _temperature2.ToString());
            sb.AppendLine("sensor.temperatureHumidity.relativeHumidity~f=" + _relativeHumidity.ToString());
            RefreshLcd("t:" + _temperature2, "h:" + _relativeHumidity);

            _temperature = 0; _pressure = 0;
            barometer.RequestMeasurement();
            Thread.Sleep(1500);
            sb.AppendLine("sensor.barometer.temperature~f=" + _temperature.ToString());
            sb.AppendLine("sensor.barometer.pressure~f=" + _pressure.ToString());
            RefreshLcd("t:" + _temperature, "p:" + _pressure);

            Thread.Sleep(2500);
            double gasSenseVoltage = gasSense.ReadVoltage();
            sb.AppendLine("sensor.gasSense.MQ-3.voltage~f=" + gasSenseVoltage.ToString());

            double lightSensorPercentage = lightSensor.ReadLightSensorPercentage();
            sb.AppendLine("sensor.lightSensor.lightSensorPercentage~f=" + lightSensorPercentage.ToString());

            RefreshLcd("g:" + gasSenseVoltage, "l:" + lightSensorPercentage);

            long memoryBytesFree = Debug.GC(false);
            sb.AppendLine("vitals.memoryBytesFree~i=" + memoryBytesFree);

            sb.AppendLine("sensor.lastLine=" + _lastLine);
            sb.AppendLine("state.vitalsAndSensorsUpdated=true");

            string chatterText = sb.ToString();
            _pcduino1.Write(chatterText);

            Debug.Print(chatterText);
            Thread.Sleep(3000);
        }
    }
}
