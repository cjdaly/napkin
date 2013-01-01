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
    public class Nexus
    {
        private ControlButton _button_Red;
        private ControlButton _button_Green;
        private ControlButton _button_Blue;
        private ControlButton _button_Yellow;

        private BlinkMArray _blinkMs;

        private Emic2 _emic2;

        private SerLCD _serLcd;

        private int _count = 0;

        public Nexus()
        {
            _serLcd = new SerLCD();
            _serLcd.Write("hello", "world");

            _blinkMs = new BlinkMArray();

            _emic2 = new Emic2();
            _emic2.Say("hello");

            _button_Red = new ControlButton(Pins.GPIO_PIN_D5, "Red", 0, this);
            _button_Green = new ControlButton(Pins.GPIO_PIN_D6, "Green", 80, this);
            _button_Blue = new ControlButton(Pins.GPIO_PIN_D9, "Blue", 160, this);
            _button_Yellow = new ControlButton(Pins.GPIO_PIN_D10, "Yellow", 42, this);
        }

        public void HandleButtonPress(ControlButton button)
        {
            if (button.Color == "Red")
            {
                _count--;
            }
            else if (button.Color == "Green")
            {
                _count++;
            }
            else if (button.Color == "Blue")
            {
                //
            }
            else if (button.Color == "Yellow")
            {
                _emic2.IncrementVoice();
                Thread.Sleep(200);
            }

            _serLcd.Write(button.Color, PadCount());
            _emic2.Say(_count.ToString());
            _blinkMs.UpdateBlinkMs(button.Hue);
        }

        private string PadCount()
        {
            string countText = _count.ToString();
            string padText = new String(' ', 16 - countText.Length);
            return padText + countText;
        }
    }

    public class ControlButton
    {
        private InterruptPort _interruptPort;

        private string _color;
        public string Color { get { return _color; } }

        private byte _hue;
        public byte Hue { get { return _hue; } }

        private Nexus _nexus;
        private long _lastInterruptTicks = DateTime.MinValue.Ticks;
        private long _debounceTimeMillis = 400;
        public ControlButton(Cpu.Pin interruptPin, string color, byte hue, Nexus nexus)
        {
            _interruptPort = new InterruptPort(interruptPin, false, Port.ResistorMode.PullUp, Port.InterruptMode.InterruptEdgeLow);
            _interruptPort.OnInterrupt += new NativeEventHandler(ControlButton_OnInterrupt);
            _color = color;
            _hue = hue;
            _nexus = nexus;
        }

        private void ControlButton_OnInterrupt(uint data1, uint data2, DateTime time)
        {
            long ticks = time.Ticks - _lastInterruptTicks;
            long millis = ticks / TimeSpan.TicksPerMillisecond;
            if (millis >= _debounceTimeMillis)
            {
                _nexus.HandleButtonPress(this);
                _lastInterruptTicks = time.Ticks;
            }
        }
    }

    public class BlinkMArray
    {
        private I2CDevice _i2cDevice;
        private I2CDevice.Configuration _blinkM_D;
        private I2CDevice.Configuration _blinkM_E;
        private I2CDevice.Configuration _blinkM_F;

        public BlinkMArray()
        {
            _i2cDevice = new I2CDevice(null);
            _blinkM_D = new I2CDevice.Configuration(0x0D, BlinkMCommand.DefaultClockRateKhz);
            _blinkM_E = new I2CDevice.Configuration(0x0E, BlinkMCommand.DefaultClockRateKhz);
            _blinkM_F = new I2CDevice.Configuration(0x0F, BlinkMCommand.DefaultClockRateKhz);

            InitBlinkM(_i2cDevice, _blinkM_D);
            InitBlinkM(_i2cDevice, _blinkM_E);
            InitBlinkM(_i2cDevice, _blinkM_F);
        }

        public void UpdateBlinkMs(byte hue)
        {
            byte saturation = 255;
            byte brightness = 128;
            BlinkMCommand.FadeToHSB.Execute(_i2cDevice, _blinkM_D, hue, saturation, brightness);
            BlinkMCommand.FadeToHSB.Execute(_i2cDevice, _blinkM_E, hue, saturation, brightness);
            BlinkMCommand.FadeToHSB.Execute(_i2cDevice, _blinkM_F, hue, saturation, brightness);
        }

        private void InitBlinkM(I2CDevice i2cDevice, I2CDevice.Configuration blinkM)
        {
            BlinkMCommand.StopScript.Execute(i2cDevice, blinkM);
            // BlinkMCommand.GetAddress.Execute(i2cDevice, blinkM);
            // BlinkMCommand.GetVersion.Execute(i2cDevice, blinkM);
            BlinkMCommand.SetFadeSpeed.Execute(i2cDevice, blinkM, 255);
            BlinkMCommand.FadeToHSB.Execute(i2cDevice, blinkM, 0, 0, 0);
        }
    }

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

            _nexus = new Nexus();

            _led = new OutputPort(Pins.ONBOARD_LED, false);
            _button = new InterruptPort(Pins.ONBOARD_SW1, false, Port.ResistorMode.Disabled, Port.InterruptMode.InterruptEdgeBoth);
            _button.OnInterrupt += new NativeEventHandler(button_OnInterrupt);

            _vitals = new DeviceVitals(NapkinServerUri, DeviceId, _credential);

            _cycleThread = new Thread(CycleDriver);
            _cycleThread.Start();
        }

        private static void button_OnInterrupt(uint data1, uint data2, DateTime time)
        {
            Debug.Print("EXIT BUTTON PRESS!");
            _led.Write(true);
            _exit = true;
        }

        private static readonly int _cycleDelayMillisecondsInitial = 15 * 1000;
        private static Thread _cycleThread;

        private static DeviceVitals _vitals;

        private static Nexus _nexus;

        private static OutputPort _led;
        private static InterruptPort _button;

        private static bool _exit = false;

        private static void CycleDriver()
        {
            Debug.Print("cycle thread starting!");
            Thread.Sleep(_cycleDelayMillisecondsInitial);

            Debug.Print("Starting cycle: " + _vitals.CycleCount + " on device: " + DeviceId);
            _samplers.Sample("memory");

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
