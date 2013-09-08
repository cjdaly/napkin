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

            // barometer.StopContinuousMeasurements();
            // barometer.MeasurementComplete += new Barometer.MeasurementCompleteEventHandler(barometer_MeasurementComplete);

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

        //private double _temperature = 0;
        //private double _pressure = 0;
        //void barometer_MeasurementComplete(Barometer sender, Barometer.SensorData sensorData)
        //{
        //    _pressure = sensorData.Pressure;
        //    _temperature = sensorData.Temperature;
        //}

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
            _cycleCount++;
            Debug.Print("Cycle: " + _cycleCount);

            led7c.SetColor(LED7C.LEDColor.Blue);

            StringBuilder sb = new StringBuilder();
            sb.AppendLine("state.vitalsAndSensorsUpdated=false");

            sb.AppendLine("vitals.id=" + DeviceId);
            sb.AppendLine("vitals.currentCycle~i=" + _cycleCount);

            //_temperature = 0; _pressure = 0;
            //barometer.RequestMeasurement();
            Thread.Sleep(1000);
            //sb.AppendLine("sensor.barometer.temperature~f=" + _temperature.ToString());
            //sb.AppendLine("sensor.barometer.pressure~f=" + _pressure.ToString());

            long memoryBytesFree = Debug.GC(false);
            sb.AppendLine("vitals.memoryBytesFree~i=" + memoryBytesFree);

            _lightSensorPercentage = lightSensor.ReadLightSensorPercentage();
            sb.AppendLine("sensor.lightSensor.lightSensorPercentage~f=" + _lightSensorPercentage.ToString());

            sb.AppendLine("sensor.lastLine=" + _lastLine);

            sb.AppendLine("state.vitalsAndSensorsUpdated=true");

            string chatterText = sb.ToString();
            _bone3.Write(chatterText);

            //char_Display.Clear();
            //char_Display.SetCursor(0, 0);
            //char_Display.PrintString("temp:" + Chop(_temperature.ToString()));
            //char_Display.SetCursor(1, 0);
            //char_Display.PrintString("pres:" + Chop(_pressure.ToString()));

            led7c.SetColor(LED7C.LEDColor.Green);

            //Thread.Sleep(4 * 1000);
            char_Display.Clear();
            char_Display.SetCursor(0, 0);
            char_Display.PrintString("lite:" + Chop(_lightSensorPercentage.ToString()));
            char_Display.SetCursor(1, 0);
            char_Display.PrintString("line:" + Chop(_lastLine));

            Thread.Sleep(8 * 1000);
        }

        private string Chop(string text, int max = 7)
        {
            if (text.Length > max)
            {
                text = text.Substring(0, 7);
            }
            return text;
        }
    }
}
