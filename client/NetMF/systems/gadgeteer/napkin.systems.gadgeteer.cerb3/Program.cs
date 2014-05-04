using System;
using System.IO.Ports;
using System.Collections;
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

using napkin.devices.serial.common;
using Gadgeteer.Modules.Seeed;

namespace napkin.systems.gadgeteer.cerb3
{
    public partial class Program
    {
        public readonly string DeviceId = "cerb3";

        private Thread _cycleThread;
        private ThreadedSerialDevice _bone3;

        void ProgramStarted()
        {

            led7c.SetColor(LED7C.LEDColor.Yellow);
            Thread.Sleep(500);

            Debug.Print("Hello from: " + DeviceId);

            temperatureHumidity.MeasurementComplete += new TemperatureHumidity.MeasurementCompleteEventHandler(temperatureHumidity_MeasurementComplete);

            barometer.StopContinuousMeasurements();
            barometer.MeasurementComplete += new Barometer.MeasurementCompleteEventHandler(barometer_MeasurementComplete);

            _bone3 = new ThreadedSerialDevice(Serial.COM3);
            _bone3.ReadLine += new ThreadedSerialDevice.ReadHandler(_bone3_ReadLine);

            Thread.Sleep(500);
            char_Display.SetBacklight(true);
            char_Display.Clear();
            char_Display.CursorHome();
            char_Display.PrintString("Hello World!");
            Thread.Sleep(500);

            led7c.SetColor(LED7C.LEDColor.Green);
            Thread.Sleep(500);


            _cycleThread = new Thread(CycleDriver);
            _cycleThread.Start();
        }

        private double _temperature2 = 0;
        private double _temperature2F = 0;
        private double _relativeHumidity = 0;
        void temperatureHumidity_MeasurementComplete(TemperatureHumidity sender, double temperature, double relativeHumidity)
        {
            _temperature2 = temperature;
            _temperature2F = _temperature2 * 1.8 + 32.0;
            _relativeHumidity = relativeHumidity;
        }

        private double _temperature = 0;
        private double _temperatureF = 0;
        private double _pressure = 0;
        void barometer_MeasurementComplete(Barometer sender, Barometer.SensorData sensorData)
        {
            _pressure = sensorData.Pressure;
            _temperature = sensorData.Temperature;
            _temperatureF = _temperature * 1.8 + 32.0;
        }

        private string _lastLine = "";
        void _bone3_ReadLine(string line)
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

        private double _lightSensorPercentage;
        private void Cycle()
        {
            led7c.SetColor(LED7C.LEDColor.Blue);
            _cycleCount++;
            Debug.Print("sensor cycle: " + _cycleCount);
            UpdateDisplay("sensor cycle: " + _cycleCount);

            StringBuilder sb = new StringBuilder();
            sb.AppendLine("state.vitalsAndSensorsUpdated=false");

            sb.AppendLine("vitals.id=" + DeviceId);
            sb.AppendLine("vitals.currentCycle~i=" + _cycleCount);

            _temperature2 = 0; _relativeHumidity = 0;
            temperatureHumidity.RequestMeasurement();
            Thread.Sleep(500);
            sb.AppendLine("sensor.temperatureHumidity.temperature~f=" + _temperature2.ToString());
            sb.AppendLine("sensor.temperatureHumidity.relativeHumidity~f=" + _relativeHumidity.ToString());

            _temperature = 0; _pressure = 0;
            barometer.RequestMeasurement();
            Thread.Sleep(500);
            sb.AppendLine("sensor.barometer.temperature~f=" + _temperature.ToString());
            sb.AppendLine("sensor.barometer.pressure~f=" + _pressure.ToString());

            long memoryBytesFree = Debug.GC(false);
            sb.AppendLine("vitals.memoryBytesFree~i=" + memoryBytesFree);

            _lightSensorPercentage = lightSensor.ReadLightSensorPercentage();
            sb.AppendLine("sensor.lightSensor.lightSensorPercentage~f=" + _lightSensorPercentage.ToString());

            sb.AppendLine("sensor.lastLine=" + _lastLine);

            sb.AppendLine("state.vitalsAndSensorsUpdated=true");

            string chatterText = sb.ToString();
            _bone3.Write(chatterText);

            led7c.SetColor(LED7C.LEDColor.Green);

            UpdateDisplay("temperature 1", _temperatureF.ToString("g4") + "F / " + _temperature.ToString("g4") + "C");
            Thread.Sleep(2 * 1000);

            UpdateDisplay("temperature 2", _temperature2F.ToString("g4") + "F / " + _temperature2.ToString("g4") + "C");
            Thread.Sleep(2 * 1000);

            UpdateDisplay("humidity", _relativeHumidity.ToString("g4") + "%");
            Thread.Sleep(2 * 1000);

            UpdateDisplay("barometer", _pressure.ToString("g4") + " hPa");
            Thread.Sleep(2 * 1000);

            UpdateDisplay("lightness", _lightSensorPercentage.ToString("g4") + "%");
            Thread.Sleep(2 * 1000);

        }

        private void UpdateDisplay(string line1, string line2 = "")
        {
            char_Display.Clear();
            char_Display.SetCursor(0, 0);
            char_Display.PrintString(Chop(line1));
            char_Display.SetCursor(1, 0);
            char_Display.PrintString(Chop(line2));
        }

        private string Chop(string text, int max = 16)
        {
            if (text.Length > max)
            {
                text = text.Substring(0, max);
            }
            return text;
        }
    }
}
