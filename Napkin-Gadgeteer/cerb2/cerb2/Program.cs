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

namespace cerb2
{
    public partial class Program
    {
        public readonly string DeviceId = "cerb2";
        public readonly string NapkinServerUri = "http://192.168.2.50:4567";
        private NetworkCredential _credential;

        void ProgramStarted()
        {

            Debug.Print("Hello from: " + DeviceId);

            _credential = new NetworkCredential(DeviceId, DeviceId);

            _sensors = new SensorCombo(SampleLightSensorPercentage, SampleLightSensorVoltage);
            _vitals = new DeviceVitals(NapkinServerUri, DeviceId, _credential);

            _cycleThread = new Thread(CycleDriver);
            _cycleThread.Start();
        }

        private readonly int _cycleDelayMillisecondsInitial = 15 * 1000;
        private Thread _cycleThread;

        private readonly int _configCycle = 3;

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

        private void CycleDriver()
        {
            Debug.Print("cycle thread starting!");
            Thread.Sleep(_cycleDelayMillisecondsInitial);

            Debug.Print("Starting cycle: " + _vitals.CycleCount + " on device: " + DeviceId);
            _vitals.MemCheck.Sample();

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

            _vitals.MemCheck.Sample();

            if (cycleCount % _vitals.PostCycle == 0)
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
        }
    }
}
