using System;
using System.IO;
using System.Collections;
using System.Net;
using System.Net.Sockets;
using System.Text;
using System.Threading;
using Microsoft.SPOT;
using Microsoft.SPOT.Presentation;
using Microsoft.SPOT.Presentation.Controls;
using Microsoft.SPOT.Presentation.Media;
using Microsoft.SPOT.Net.NetworkInformation;
using Microsoft.SPOT.Touch;

using Gadgeteer.Networking;
using GT = Gadgeteer;
using GTM = Gadgeteer.Modules;
using Gadgeteer.Modules.GHIElectronics;
using Gadgeteer.Modules.Seeed;

using NapkinCommon;
using NapkinGadgeteerCommon;

namespace CerberusChatterer
{
    public partial class Program
    {
        public readonly string DeviceId = "cerb1";
        public readonly string NapkinServerUri = "http://192.168.2.50:4567";
        private NetworkCredential _credential;

        void ProgramStarted()
        {
            Debug.Print("Hello from: " + DeviceId);

            _credential = new NetworkCredential(DeviceId, DeviceId);

            _sensors = new SensorCombo(SampleLightSensorPercentage, SampleLightSensorVoltage);
            _vitals = new DeviceVitals(NapkinServerUri, DeviceId, _credential);

            temperatureHumidity.MeasurementComplete += new TemperatureHumidity.MeasurementCompleteEventHandler(temperatureHumidity_MeasurementComplete);

            GT.Timer timer = new GT.Timer(_cycleDelayMilliseconds);
            timer.Tick += new GT.Timer.TickEventHandler(timer_Tick);
            timer.Start();
        }

        private readonly int _postCycle = 300;
        private readonly int _configCycle = 33;
        private readonly int _cycleDelayMilliseconds = 1 * 1000;

        private SensorCombo _sensors;
        private DeviceVitals _vitals;

        private double SampleLightSensorPercentage()
        {
            return lightsensor.ReadLightSensorPercentage();
        }

        private double SampleLightSensorVoltage()
        {
            return lightsensor.ReadLightSensorVoltage();
        }

        void timer_Tick(GT.Timer timer)
        {
            _vitals.IncrementCycleCount();
            int cycleCount = _vitals.CycleCount;
            Debug.Print("Starting cycle: " + cycleCount + " on device: " + DeviceId);

            _vitals.MemCheck.Sample();
            UpdateLed7R(cycleCount);
            _vitals.MemCheck.Sample();

            if (cycleCount % _configCycle == 0)
            {
                _vitals.UpdateDeviceStarts();
                _vitals.MemCheck.Sample();
                _vitals.UpdateDeviceLocation();
                _vitals.MemCheck.Sample();
                UpdateMulticolorLed();
                _vitals.MemCheck.Sample();
            }

            if (cycleCount % _postCycle == 0)
            {
                StringBuilder sb = new StringBuilder();
                _vitals.AppendStatus(sb);
                _sensors.AppendStatus(sb);
                string chatterRequestText = sb.ToString();

                string chatterUri = NapkinServerUri + "/chatter";
                HttpUtil.DoHttpMethod("POST", chatterUri, _credential, chatterRequestText, false);

                _sensors.ResetAll();
                _vitals.MemCheck.Reset();
                _vitals.MemCheck.Sample();
            }

            _sensors.LightSensorPercentageSampler.Sample();
            _sensors.LightSensorVoltageSampler.Sample();
            _vitals.MemCheck.Sample();

            temperatureHumidity.RequestMeasurement();
        }

        private void UpdateLed7R(int cycleCount)
        {
            led7r.TurnLightOn(cycleCount % 8);
            led7r.TurnLightOff((cycleCount - 1) % 8);
        }

        private void UpdateMulticolorLed()
        {
            string defaultRgbText = "0,0,64";
            string rgbText = ConfigUtil.GetOrInitConfigValue(NapkinServerUri, DeviceId, "MulticolorLed_rBg", defaultRgbText, _credential);

            string[] rgbArray = rgbText.Split(',');
            if ((rgbArray == null) || (rgbArray.Length != 3))
            {
                Debug.Print("Badly formed RGB data: " + rgbText);
                rgbText = defaultRgbText;
            }

            try
            {
                byte red = (byte)int.Parse(rgbArray[0]);
                byte green = (byte)int.Parse(rgbArray[1]);
                byte blue = (byte)int.Parse(rgbArray[2]);
                multicolorLed.SetRedIntensity(red);
                multicolorLed.SetGreenIntensity(green);
                multicolorLed.SetBlueIntensity(blue);
            }
            catch (Exception)
            {
                Debug.Print("Error parsing RGB data: " + rgbText);
            }
        }

        void temperatureHumidity_MeasurementComplete(TemperatureHumidity sender, double temperature, double relativeHumidity)
        {
            _vitals.MemCheck.Sample();
            _sensors.TemperatureSampler.Sample(temperature);
            _sensors.HumiditySampler.Sample(relativeHumidity);
            _vitals.MemCheck.Sample();
        }

    }
}