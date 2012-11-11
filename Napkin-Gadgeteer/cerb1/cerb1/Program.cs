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
using Microsoft.SPOT.Touch;

using Gadgeteer.Networking;
using GT = Gadgeteer;
using GTM = Gadgeteer.Modules;
using Gadgeteer.Modules.GHIElectronics;
using Gadgeteer.Modules.Seeed;

using NapkinCommon;
using NapkinGadgeteerCommon;
using NapkinGadgeteerCommon.SensorUtil;

namespace cerb1
{
    public partial class Program
    {
        public readonly string DeviceId = "cerb1";
        public readonly string NapkinServerUri = "http://192.168.2.50:4567";
        private NetworkCredential _credential;

        private SamplerBag _samplers = new SamplerBag();
        private readonly int _cycleDelayMillisecondsInitial = 15 * 1000;
        private Thread _cycleThread;
        private readonly int _configCycle = 3;

        private DeviceVitals _vitals;

        void ProgramStarted()
        {
            Debug.Print("Hello from: " + DeviceId);

            _credential = new NetworkCredential(DeviceId, DeviceId);

            new TemperatureHumiditySampler(temperatureHumidity, _samplers);
            new LightSensorSampler(lightsensor, _samplers);

            _vitals = new DeviceVitals(NapkinServerUri, DeviceId, _credential);

            _cycleThread = new Thread(CycleDriver);
            _cycleThread.Start();
        }

        private void CycleDriver()
        {
            Debug.Print("cycle thread starting!");
            Thread.Sleep(_cycleDelayMillisecondsInitial);

            int cycleCount = _vitals.CycleCount;
            Debug.Print("Starting cycle: " + cycleCount + " on device: " + DeviceId);
            _samplers.Sample("memory");

            UpdateLed7R(cycleCount);
            _samplers.Sample("memory");

            _vitals.UpdateDeviceStarts();
            _vitals.UpdateDeviceLocation();
            _vitals.InitPostCycle();
            _vitals.InitCycleDelayMilliseconds();
            _samplers.Sample("memory");

            bool exit = false;
            while (!exit)
            {
                Thread.Sleep(_vitals.CycleDelayMilliseconds);
                Cycle();
            }

        }

        private void Cycle()
        {
            _vitals.IncrementCycleCount();
            int cycleCount = _vitals.CycleCount;
            Debug.Print("Starting cycle: " + cycleCount + " on device: " + DeviceId + " with postCycle: " + _vitals.PostCycle);

            _samplers.Sample("memory");
            UpdateLed7R(cycleCount);
            _samplers.Sample("memory");

            if (cycleCount % _configCycle == 0)
            {
                UpdateMulticolorLed();
                _samplers.Sample("memory");
            }

            if (cycleCount % _vitals.PostCycle == 0)
            {
                StringBuilder sb = new StringBuilder();
                _vitals.AppendStatus(sb);
                _samplers.AppendStatus(sb);
                string chatterRequestText = sb.ToString();

                string chatterUri = NapkinServerUri + "/chatter";
                HttpUtil.DoHttpMethod("POST", chatterUri, _credential, chatterRequestText, false);

                _samplers.Reset();
                _samplers.Sample("memory");
            }

            _samplers.Sample("light_sensor_percentage");
            _samplers.Sample("light_sensor_voltage");
            _samplers.Sample("memory");

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
    }
}
