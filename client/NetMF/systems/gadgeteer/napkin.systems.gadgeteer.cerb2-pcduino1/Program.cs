﻿using System;
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
            led7c.SetColor(LED7C.LEDColor.Yellow);
            Thread.Sleep(1000);

            Debug.Print("Hello from: " + DeviceId);

            _pcduino1 = new ThreadedSerialDevice(Serial.COM3);
            _pcduino1.ReadLine += new ThreadedSerialDevice.ReadHandler(_pcduino1_ReadLine);

            barometer.StopContinuousMeasurements();
            barometer.MeasurementComplete += new Barometer.MeasurementCompleteEventHandler(barometer_MeasurementComplete);

            gasSense.SetHeatingElement(true);

            button.ButtonPressed += new Button.ButtonEventHandler(button_ButtonPressed);
            button.ButtonReleased += new Button.ButtonEventHandler(button_ButtonReleased);

            led7c.SetColor(LED7C.LEDColor.Green);
            Thread.Sleep(1000);

            _cycleThread = new Thread(CycleDriver);
            _cycleThread.Start();

        }

        private double _temperature = 0;
        private double _pressure = 0;
        void barometer_MeasurementComplete(Barometer sender, Barometer.SensorData sensorData)
        {
            _pressure = sensorData.Pressure;
            _temperature = sensorData.Temperature;
        }

        void button_ButtonPressed(Button sender, Button.ButtonState state)
        {
            button.TurnLEDOn();
        }

        void button_ButtonReleased(Button sender, Button.ButtonState state)
        {
            button.TurnLEDOff();
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

        // private double _lightSensorPercentage;

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
            led7c.SetColor(LED7C.LEDColor.Blue);
            _cycleCount++;
            Debug.Print("Cycle: " + _cycleCount);

            RefreshLcd("cycle: " + _cycleCount);

            StringBuilder sb = new StringBuilder();
            sb.AppendLine("state.vitalsAndSensorsUpdated=false");

            sb.AppendLine("vitals.id=" + DeviceId);
            sb.AppendLine("vitals.currentCycle~i=" + _cycleCount);

            //_lightSensorPercentage = lightSensor.ReadLightSensorPercentage();
            //sb.AppendLine("sensor.lightSensor.lightSensorPercentage~f=" + _lightSensorPercentage.ToString());

            _temperature = 0; _pressure = 0;
            barometer.RequestMeasurement();
            Thread.Sleep(1500);
            sb.AppendLine("sensor.barometer.temperature~f=" + _temperature.ToString());
            sb.AppendLine("sensor.barometer.pressure~f=" + _pressure.ToString());
            RefreshLcd("t:" + _temperature, "p:" + _pressure);

            Thread.Sleep(2500);
            double gasSenseVoltage = gasSense.ReadVoltage();
            sb.AppendLine("sensor.gasSense.MQ-3.voltage~f=" + gasSenseVoltage.ToString());

            long memoryBytesFree = Debug.GC(false);
            sb.AppendLine("vitals.memoryBytesFree~i=" + memoryBytesFree);

            RefreshLcd("g:" + gasSenseVoltage, "b:" + memoryBytesFree);

            sb.AppendLine("sensor.lastLine=" + _lastLine);
            sb.AppendLine("state.vitalsAndSensorsUpdated=true");

            string chatterText = sb.ToString();
            _pcduino1.Write(chatterText);

            Debug.Print(chatterText);

            Thread.Sleep(1000);
            led7c.SetColor(LED7C.LEDColor.Green);
            Thread.Sleep(3000);
        }
    }
}
