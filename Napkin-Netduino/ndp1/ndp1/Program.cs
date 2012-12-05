using System;
using System.IO;
using System.IO.Ports;
using System.Net;
using System.Net.Sockets;
using System.Text;
using System.Threading;
using Microsoft.SPOT;
using Microsoft.SPOT.Hardware;
using SecretLabs.NETMF.Hardware;
using SecretLabs.NETMF.Hardware.NetduinoPlus;

using NapkinCommon;

namespace ndp1
{
    public class Program
    {
        public static readonly string DeviceId = "ndp1";
        public static readonly string NapkinServerUri = "http://192.168.2.50:4567";
        private static NetworkCredential _credential;

        private static SamplerBag _samplers = new SamplerBag();

        public static void Main()
        {
            Debug.Print("Hello from: " + DeviceId);
            _credential = new NetworkCredential(DeviceId, DeviceId);

            // TestSDCard();

            _serLcd = new SerLCD();
            _serLcd.Write("hello", "world");

            _emic2 = new Emic2();

            Thread.Sleep(500);
            _emic2.Say("hello");

            Thread.Sleep(2000);
            _emic2.Say("this is radio free chris");

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

            _vitals = new DeviceVitals(NapkinServerUri, DeviceId, _credential);

            _cycleThread = new Thread(CycleDriver);
            _cycleThread.Start();
        }

        private static void button_OnInterrupt(uint data1, uint data2, DateTime time)
        {
            Debug.Print("BUTTON PRESS!");
            _led.Write(true);
            _exit = true;
        }

        private static void InitBlinkM(I2CDevice i2cDevice, I2CDevice.Configuration blinkM)
        {
            BlinkMCommand.StopScript.Execute(i2cDevice, blinkM);
            // BlinkMCommand.GetAddress.Execute(i2cDevice, blinkM);
            // BlinkMCommand.GetVersion.Execute(i2cDevice, blinkM);
            BlinkMCommand.SetFadeSpeed.Execute(i2cDevice, blinkM, 255);
            BlinkMCommand.FadeToHSB.Execute(i2cDevice, blinkM, 0, 0, 0);
        }

        private static readonly int _cycleDelayMillisecondsInitial = 15 * 1000;
        private static Thread _cycleThread;

        private static readonly int _blinkM_D_Cycle = 1;
        private static readonly int _blinkM_E_Cycle = 3;
        private static readonly int _blinkM_F_Cycle = 5;

        private static readonly int _blinkM_Cycle_Mod = 7;

        private static DeviceVitals _vitals;

        private static SerLCD _serLcd;
        private static Emic2 _emic2;

        private static OutputPort _led;
        private static InterruptPort _button;

        private static I2CDevice _i2cDevice;
        private static I2CDevice.Configuration _blinkM_D;
        private static I2CDevice.Configuration _blinkM_E;
        private static I2CDevice.Configuration _blinkM_F;

        private static bool _exit = false;

        private static void CycleDriver()
        {
            Debug.Print("cycle thread starting!");
            Thread.Sleep(_cycleDelayMillisecondsInitial);

            Debug.Print("Starting cycle: " + _vitals.CycleCount + " on device: " + DeviceId);
            _samplers.Sample("memory");

            _serLcd.Write("cycle: " + _vitals.CycleCount);
            _emic2.Say("cycle " + _vitals.CycleCount);

            _vitals.UpdateDeviceStarts();
            _vitals.UpdateDeviceLocation();

            _vitals.InitPostCycle();
            _vitals.InitCycleDelayMilliseconds();

            while (!_exit)
            {
                Thread.Sleep(_vitals.CycleDelayMilliseconds);
                Cycle();
            }

        }

        private static void Cycle()
        {
            _samplers.Sample("memory");

            _vitals.IncrementCycleCount();
            int cycleCount = _vitals.CycleCount;
            Debug.Print("Starting cycle: " + cycleCount + " on device: " + DeviceId + " with postCycle: " + _vitals.PostCycle);

            _serLcd.Write("cycle: " + _vitals.CycleCount);
            _emic2.Say("cycle " + _vitals.CycleCount);
            _samplers.Sample("memory");

            if (cycleCount % _blinkM_Cycle_Mod == _blinkM_D_Cycle)
            {
                UpdateBlinkM(_blinkM_D, _i2cDevice, _credential);
            }
            if (cycleCount % _blinkM_Cycle_Mod == _blinkM_E_Cycle)
            {
                UpdateBlinkM(_blinkM_E, _i2cDevice, _credential);
            }
            if (cycleCount % _blinkM_Cycle_Mod == _blinkM_F_Cycle)
            {
                UpdateBlinkM(_blinkM_F, _i2cDevice, _credential);
            }
            _samplers.Sample("memory");

            if (cycleCount % _vitals.PostCycle == 0)
            {
                StringBuilder sb = new StringBuilder();
                _vitals.AppendStatus(sb);
                _samplers.AppendStatus(sb);
                string chatterRequestText = sb.ToString();

                string chatterUri = NapkinServerUri + "/chatter?format=keyset";
                HttpUtil.DoHttpMethod("POST", chatterUri, _credential, chatterRequestText, false);

                _samplers.Reset();
                _samplers.Sample("memory");
            }

        }

        private static void TestSDCard()
        {
            if (File.Exists(@"\SD\FOO.TXT"))
            {
                StreamReader reader = new StreamReader(@"\SD\FOO.TXT");
                String text = reader.ReadToEnd();
                reader.Close();

                Debug.Print(text);
            }
        }

        private static void UpdateBlinkM(I2CDevice.Configuration blinkM, I2CDevice i2cDevice, NetworkCredential credential)
        {
            string deviceAddressText = blinkM.Address.ToString();
            string defaultHsbText = "38,255,42";
            string hsbText = ConfigUtil.GetOrInitConfigValue(NapkinServerUri, DeviceId, "blinkM_" + deviceAddressText + "_hsb", defaultHsbText, credential);
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
    }
}
