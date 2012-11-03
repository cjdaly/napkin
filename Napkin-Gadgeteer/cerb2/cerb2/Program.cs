using System;
using System.Net;
using System.Net.Sockets;
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

using NapkinCommon;
using NapkinGadgeteerCommon;
using NapkinGadgeteerCommon.SensorUtil;
using Gadgeteer.Modules.Seeed;

namespace cerb2
{
    public partial class Program
    {
        public readonly string DeviceId = "cerb2";
        public readonly string NapkinServerUri = "http://192.168.2.50:4567";
        private NetworkCredential _credential;

        private SamplerBag _samplers = new SamplerBag();

        void ProgramStarted()
        {

            Debug.Print("Hello from: " + DeviceId);

            _credential = new NetworkCredential(DeviceId, DeviceId);

            new ButtonSampler(button, _samplers);
            new LightSensorSampler(lightsensor, _samplers);
            new BarometerSampler(barometer, _samplers);

            _vitals = new DeviceVitals(NapkinServerUri, DeviceId, _credential);

            _cycleThread = new Thread(CycleDriver);
            _cycleThread.Start();
        }


        private readonly int _cycleDelayMillisecondsInitial = 15 * 1000;
        private Thread _cycleThread;

        private DeviceVitals _vitals;

        private void CycleDriver()
        {
            Debug.Print("cycle thread starting!");
            Thread.Sleep(_cycleDelayMillisecondsInitial);

            Debug.Print("Starting cycle: " + _vitals.CycleCount + " on device: " + DeviceId);
            _samplers.Sample("memory");

            _vitals.UpdateDeviceStarts();
            _vitals.UpdateDeviceLocation();

            _vitals.InitPostCycle();
            _vitals.InitCycleDelayMilliseconds();

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

            if (cycleCount % 2 == 0)
            {
                string button_led = ConfigUtil.GetOrInitConfigValue(NapkinServerUri, DeviceId, "button_led", "off", _credential);
                if (button_led == "on") button.TurnLEDOn();
                else button.TurnLEDOff();
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

            barometer.RequestMeasurement();
            _samplers.Sample("memory");
        }
    }
}
