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
        // This method is run when the mainboard is powered up or reset.   
        void ProgramStarted()
        {
            /*******************************************************************************************
            Modules added in the Program.gadgeteer designer view are used by typing 
            their name followed by a period, e.g.  button.  or  camera.
            
            Many modules generate useful events. Type +=<tab><tab> to add a handler to an event, e.g.:
                button.ButtonPressed +=<tab><tab>
            
            If you want to do something periodically, use a GT.Timer and handle its Tick event, e.g.:
                GT.Timer timer = new GT.Timer(1000); // every second (1000ms)
                timer.Tick +=<tab><tab>
                timer.Start();
            *******************************************************************************************/
            // Use Debug.Print to show messages in Visual Studio's "Output" window during debugging.
            Debug.Print("Hello!");

            _credential = new NetworkCredential(DeviceId, DeviceId);

            _sensors = new SensorCombo(SampleLightSensorPercentage, SampleLightSensorVoltage);

            temperatureHumidity.MeasurementComplete += new TemperatureHumidity.MeasurementCompleteEventHandler(temperatureHumidity_MeasurementComplete);

            GT.Timer timer = new GT.Timer(_cycleDelayMilliseconds);
            timer.Tick += new GT.Timer.TickEventHandler(timer_Tick);
            timer.Start();
        }

        public readonly string DeviceId = "cerb1";
        public readonly string NapkinServerUri = "http://192.168.2.50:4567";
        private NetworkCredential _credential;

        private int _cycleCount = 0;
        private readonly int _postCycle = 6;
        private readonly int _cycleDelayMilliseconds = 10 * 1000;

        private SensorCombo _sensors;

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
            _cycleCount++;
            if (_cycleCount % _postCycle == 0)
            {
                Debug.Print("YO 1");
                _sensors.MemCheck.Sample();

                Debug.Print("YO 2");
                string chatterUri = NapkinServerUri + "/chatter";
                string chatterRequestText = _sensors.GetStatus("Status from " + DeviceId + " on cycle " + _cycleCount);

                Debug.Print("YO 3");
                Thread.Sleep(2000);
                _sensors.MemCheck.Sample();
                Debug.Print("YO 3a");
                string chatterResponseText = HttpUtil.DoHttpMethod("POST", chatterUri, _credential, chatterRequestText);
                Debug.Print("YO 4");

                _sensors.ResetAll();

                Debug.Print("YO 5");
                _sensors.MemCheck.Sample();
            }

            _sensors.LightSensorPercentageSampler.Sample();
            _sensors.LightSensorVoltageSampler.Sample();
            _sensors.MemCheck.Sample();

            Debug.Print(_sensors.GetStatus("Status for cycle: " + _cycleCount));

            temperatureHumidity.RequestMeasurement();
        }

        void temperatureHumidity_MeasurementComplete(TemperatureHumidity sender, double temperature, double relativeHumidity)
        {
            _sensors.MemCheck.Sample();
            _sensors.TemperatureSampler.Sample(temperature);
            _sensors.HumiditySampler.Sample(relativeHumidity);
            _sensors.MemCheck.Sample();
        }

    }
}
