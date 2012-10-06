using System;
using System.IO;
using System.Net;
using System.Net.Sockets;
using System.Text;
using System.Threading;
using Microsoft.SPOT;
using Microsoft.SPOT.Hardware;
using SecretLabs.NETMF.Hardware;
using SecretLabs.NETMF.Hardware.NetduinoPlus;
using NapkinCommon;

namespace NetduinoPlusChatterer
{
    public class Program
    {
        // TODO: read these values from config properties file
        public const string DeviceId = "ndp1";
        public const string NapkinServerUri = "http://192.168.2.50:4567";
        public const int NetworkDelayMilliseconds = 2000;

        public static void Main()
        {
            Init();
            Cycle();
        }

        private static OutputPort _led;
        private static InterruptPort _button;

        private static I2CDevice _i2cDevice;
        private static I2CDevice.Configuration _blinkM_D;
        private static I2CDevice.Configuration _blinkM_E;
        private static I2CDevice.Configuration _blinkM_F;

        private static void Init()
        {
            _led = new OutputPort(Pins.ONBOARD_LED, false);
            _button = new InterruptPort(Pins.ONBOARD_SW1, false, Port.ResistorMode.Disabled, Port.InterruptMode.InterruptEdgeBoth);
            _button.OnInterrupt += new NativeEventHandler(button_OnInterrupt);

            _i2cDevice = new I2CDevice(null);
            _blinkM_D = new I2CDevice.Configuration(0x0D, BlinkMCommand.DefaultClockRateKhz);
            _blinkM_E = new I2CDevice.Configuration(0x0E, BlinkMCommand.DefaultClockRateKhz);
            _blinkM_F = new I2CDevice.Configuration(0x0F, BlinkMCommand.DefaultClockRateKhz);

            InitBlinkM(_i2cDevice, _blinkM_D);
            InitBlinkM(_i2cDevice, _blinkM_E);
            InitBlinkM(_i2cDevice, _blinkM_F);

            byte brightness = 0;
            byte saturation = 255;

            BlinkMCommand.FadeToHSB.Execute(_i2cDevice, _blinkM_D, 0, saturation, brightness);
            BlinkMCommand.FadeToHSB.Execute(_i2cDevice, _blinkM_E, 48, saturation, brightness);
            BlinkMCommand.FadeToHSB.Execute(_i2cDevice, _blinkM_F, 82, saturation, brightness);

            brightness = 42;

            Thread.Sleep(1000);
            BlinkMCommand.FadeToHSB.Execute(_i2cDevice, _blinkM_D, 0, saturation, brightness);
            Thread.Sleep(1000);
            BlinkMCommand.FadeToHSB.Execute(_i2cDevice, _blinkM_D, 0, saturation, 0);
            BlinkMCommand.FadeToHSB.Execute(_i2cDevice, _blinkM_E, 35, saturation, brightness);
            Thread.Sleep(1000);
            BlinkMCommand.FadeToHSB.Execute(_i2cDevice, _blinkM_E, 35, saturation, 0);
            BlinkMCommand.FadeToHSB.Execute(_i2cDevice, _blinkM_F, 82, saturation, brightness);
            Thread.Sleep(2000);
            BlinkMCommand.FadeToHSB.Execute(_i2cDevice, _blinkM_F, 82, saturation, 0);
        }

        static void button_OnInterrupt(uint data1, uint data2, DateTime time)
        {
            Debug.Print("BUTTON PRESS!");
            _led.Write(true);
            _keepCycling = false;
        }

        private static void InitBlinkM(I2CDevice i2cDevice, I2CDevice.Configuration blinkM)
        {
            BlinkMCommand.StopScript.Execute(i2cDevice, blinkM);
            BlinkMCommand.GetAddress.Execute(i2cDevice, blinkM);
            BlinkMCommand.GetVersion.Execute(i2cDevice, blinkM);
            BlinkMCommand.SetFadeSpeed.Execute(i2cDevice, blinkM, 255);
        }

        private static bool _keepCycling = true;

        private static void Cycle()
        {
            int cycle = 0;
            int postCycle = 12;

            int cycleDelayMilliseconds = 5 * 1000;

            Debug.Print("Hello!");

            NetworkCredential credential = new NetworkCredential(DeviceId, DeviceId);
            string chatterUri = NapkinServerUri + "/chatter";

            MemCheck memCheck = new MemCheck();

            while (_keepCycling)
            {
                Debug.Print("cycle: " + ++cycle);
                Thread.Sleep(cycleDelayMilliseconds);
                memCheck.Check();

                UpdateBlinkM(_blinkM_D, _i2cDevice, credential);
                memCheck.Check();
                UpdateBlinkM(_blinkM_E, _i2cDevice, credential);
                memCheck.Check();
                UpdateBlinkM(_blinkM_F, _i2cDevice, credential);
                memCheck.Check();

                if (cycle % postCycle == 0)
                {
                    Thread.Sleep(cycleDelayMilliseconds);
                    memCheck.Check();
                    string chatterRequestText = memCheck.GetStatus("MemCheck for " + DeviceId);
                    memCheck.Reset();
                    memCheck.Check();
                    string chatterResponseText = HttpUtil.DoHttpMethod("POST", chatterUri, credential, chatterRequestText);
                    memCheck.Check();
                    Debug.Print(chatterResponseText);
                }

                
            }
        }

        private static void UpdateBlinkM(I2CDevice.Configuration blinkM, I2CDevice i2cDevice, NetworkCredential credential)
        {
            string deviceAddressText = blinkM.Address.ToString();
            string defaultHsbText = "38,255,42";
            string hsbText = GetOrInitBlinkMValue("blinkM_" + deviceAddressText + "_hsb", defaultHsbText, credential);
            string[] hsbArray = hsbText.Split(',');
            if ((hsbArray == null) || (hsbArray.Length != 3))
            {
                Debug.Print("Badly formed HSB data: " + hsbText);
                hsbText = defaultHsbText;
            }

            try
            {
                byte hue = (byte)int.Parse(hsbArray[0]);
                byte saturation = (byte)int.Parse(hsbArray[1]);
                byte brightness = (byte)int.Parse(hsbArray[2]);
                BlinkMCommand.FadeToHSB.Execute(i2cDevice, blinkM, hue, saturation, brightness);
            }
            catch (Exception)
            {
                Debug.Print("Error parsing HSB data: " + hsbText);
            }
        }

        private static string GetOrInitBlinkMValue(string key, string defaultValue, NetworkCredential credential)
        {
            string uri = NapkinServerUri + "/config/" + DeviceId + "?key=" + key;
            string responseText = HttpUtil.DoHttpMethod("GET", uri, credential, null);
            Debug.Print("GOT " + key + "=" + responseText);
            // Thread.Sleep(NetworkDelayMilliseconds);

            if ((responseText == null) || (responseText == ""))
            {
                responseText = HttpUtil.DoHttpMethod("PUT", uri, credential, defaultValue);
                return defaultValue;
            }
            else
            {
                return responseText;
            }
        }

    }
}
