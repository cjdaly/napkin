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
        private readonly int _postCycle = 300;
        private readonly int _configCycle = 33;
        private readonly int _cycleDelayMilliseconds = 1 * 1000;

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
            Debug.Print("cycle: " + _cycleCount);

            _sensors.MemCheck.Sample();
            UpdateLed7R();
            _sensors.MemCheck.Sample();

            if (_cycleCount % _configCycle == 0)
            {
                UpdateDeviceStarts();
                _sensors.MemCheck.Sample();
                UpdateDeviceLocation();
                _sensors.MemCheck.Sample();
                UpdateMulticolorLed();
                _sensors.MemCheck.Sample();
            }

            if (_cycleCount % _postCycle == 0)
            {
                StringBuilder sb = new StringBuilder();
                sb.Append("device_id=").AppendLine(DeviceId);
                sb.Append("device_start_count=").AppendLine(_deviceStartCountCurrent.ToString());
                sb.Append("device_cycle=").AppendLine(_cycleCount.ToString());
                sb.Append("device_location=").AppendLine(_deviceLocation);
                string chatterRequestText = _sensors.GetStatus(sb);
                _sensors.MemCheck.Sample();

                string chatterUri = NapkinServerUri + "/chatter";
                HttpUtil.DoHttpMethod("POST", chatterUri, _credential, chatterRequestText, false);

                _sensors.ResetAll();
                _sensors.MemCheck.Sample();
            }

            _sensors.LightSensorPercentageSampler.Sample();
            _sensors.LightSensorVoltageSampler.Sample();
            _sensors.MemCheck.Sample();

            // Debug.Print(_sensors.GetStatus());

            temperatureHumidity.RequestMeasurement();
        }

        private void UpdateLed7R()
        {
            led7r.TurnLightOn(_cycleCount % 8);
            led7r.TurnLightOff((_cycleCount - 1) % 8);
        }

        private int _deviceStartCountCurrent = -1;
        private void UpdateDeviceStarts()
        {
            if (_deviceStartCountCurrent > -1) return;

            string deviceStartsText = ConfigUtil.GetOrInitConfigValue(NapkinServerUri, DeviceId, "device_start_count", "0", _credential);

            try
            {
                int deviceStartCountPrevious = int.Parse(deviceStartsText);
                _deviceStartCountCurrent = deviceStartCountPrevious + 1;

                ConfigUtil.PutConfigValue(NapkinServerUri + "/config/" + DeviceId, "device_start_count", _deviceStartCountCurrent.ToString(), _credential);
                Debug.Print("UpdateDeviceStarts updated device_start_count: " + _deviceStartCountCurrent);
            }
            catch (Exception)
            {
                Debug.Print("Error in UpdateDeviceStarts: " + deviceStartsText);
            }
        }

        private string _deviceLocation = "???";
        private void UpdateDeviceLocation()
        {
            if (_deviceLocation != "???") return;

            _deviceLocation = ConfigUtil.GetOrInitConfigValue(NapkinServerUri, DeviceId, "device_location", "???", _credential);
            Debug.Print("Got device_location: " + _deviceLocation);
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
            _sensors.MemCheck.Sample();
            _sensors.TemperatureSampler.Sample(temperature);
            _sensors.HumiditySampler.Sample(relativeHumidity);
            _sensors.MemCheck.Sample();
        }

    }
}