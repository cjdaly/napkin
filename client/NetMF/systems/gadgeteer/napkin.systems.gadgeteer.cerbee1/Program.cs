using System;
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

using napkin.util.http;

namespace napkin.systems.gadgeteer.cerbee1
{
    public partial class Program
    {
        public readonly string DeviceId = "cerbee1";
        public readonly string NapkinServerUri = "http://192.168.2.159:4567";
        private NetworkCredential _credential;

        private Thread _cycleThread;

        void ProgramStarted()
        {
            Debug.Print("Hello from: " + DeviceId);

            _credential = new NetworkCredential(DeviceId, DeviceId);

            temperatureHumidity.MeasurementComplete += new TemperatureHumidity.MeasurementCompleteEventHandler(temperatureHumidity_MeasurementComplete);

            _cycleThread = new Thread(CycleDriver);
            _cycleThread.Start();
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

            string configUri = NapkinServerUri + "/config";
            string responseText = HttpUtil.DoHttpMethod("GET", configUri, _credential, null);
            Debug.Print("GOT: " + responseText);

            StringBuilder sb = new StringBuilder();
            sb.AppendLine("napkin.device.cycleCount~i=" + _cycleCount);

            long memoryBytesFree = Debug.GC(false);
            sb.AppendLine("napkin.device.memoryBytesFree~i=" + memoryBytesFree);

            temperatureHumidity.RequestMeasurement();
            Thread.Sleep(1000);
            sb.AppendLine("temperatureHumidity.temperature~f=" + _temperature.ToString());
            sb.AppendLine("temperatureHumidity.relativeHumidity~f=" + _relativeHumidity.ToString());

            double lightSensorPercentage = lightSensor.ReadLightSensorPercentage();
            sb.AppendLine("lightSensor.lightSensorPercentage~f=" + lightSensorPercentage.ToString());

            Thread.Sleep(1000);

            string chatterRequestText = sb.ToString();
            string chatterUri = NapkinServerUri + "/chatter?format=napkin_kv";
            HttpUtil.DoHttpMethod("POST", chatterUri, _credential, chatterRequestText, false);

            Thread.Sleep(10 * 1000);
        }
    }
}
