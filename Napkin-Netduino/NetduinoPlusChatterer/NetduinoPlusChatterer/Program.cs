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
        public static void Main()
        {
            Init();
            Cycle();
        }

        private static OutputPort _led;
        private static InterruptPort _button;

        private static void Init()
        {
            _led = new OutputPort(Pins.ONBOARD_LED, false);
            _button = new InterruptPort(Pins.ONBOARD_SW1, false, Port.ResistorMode.Disabled, Port.InterruptMode.InterruptEdgeBoth);
            _button.OnInterrupt += new NativeEventHandler(button_OnInterrupt);

            I2CDevice i2cDevice = new I2CDevice(null);
            I2CDevice.Configuration blinkM_D = new I2CDevice.Configuration(0x0D, BlinkMCommand.DefaultClockRateKhz);
            I2CDevice.Configuration blinkM_E = new I2CDevice.Configuration(0x0E, BlinkMCommand.DefaultClockRateKhz);
            I2CDevice.Configuration blinkM_F = new I2CDevice.Configuration(0x0F, BlinkMCommand.DefaultClockRateKhz);

            InitBlinkM(i2cDevice, blinkM_D);
            InitBlinkM(i2cDevice, blinkM_E);
            InitBlinkM(i2cDevice, blinkM_F);

            byte brightness = 0;
            byte saturation = 255;

            BlinkMCommand.FadeToHSB.Execute(i2cDevice, blinkM_D, 0, saturation, brightness);
            BlinkMCommand.FadeToHSB.Execute(i2cDevice, blinkM_E, 48, saturation, brightness);
            BlinkMCommand.FadeToHSB.Execute(i2cDevice, blinkM_F, 82, saturation, brightness);

            brightness = 42;

            Thread.Sleep(1000);
            BlinkMCommand.FadeToHSB.Execute(i2cDevice, blinkM_D, 0, saturation, brightness);
            Thread.Sleep(2000);
            BlinkMCommand.FadeToHSB.Execute(i2cDevice, blinkM_D, 0, saturation, 0);
            BlinkMCommand.FadeToHSB.Execute(i2cDevice, blinkM_E, 35, saturation, brightness);
            Thread.Sleep(2000);
            BlinkMCommand.FadeToHSB.Execute(i2cDevice, blinkM_E, 35, saturation, 0);
            BlinkMCommand.FadeToHSB.Execute(i2cDevice, blinkM_F, 82, saturation, brightness);
            Thread.Sleep(3000);
            BlinkMCommand.FadeToHSB.Execute(i2cDevice, blinkM_F, 82, saturation, 0);
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

            int cycleEndDelayMilliseconds = 5 * 1000;
            int cyclePostDelayMilliseconds = 2 * 1000;

            Debug.Print("Hello!");

            NetworkCredential credential = new NetworkCredential("ndp1", "ndp1");
            string chatterUri = "http://192.168.2.50:4567/chatter";
            string configUri = "http://192.168.2.50:4567/config";

            uint mem1 = Debug.GC(false);
            uint mem2 = Debug.GC(false);

            MemCheck memCheck = new MemCheck();

            while (_keepCycling)
            {
                Debug.Print("cycle: " + ++cycle);
                memCheck.Check();

                string configResponseText = HttpUtil.DoHttpMethod("GET", configUri, credential, null);
                Debug.Print(configResponseText);

                if (cycle % postCycle == 0) {
                    memCheck.Check();
                    Thread.Sleep(cyclePostDelayMilliseconds);
                    memCheck.Check();

                    string chatterRequestText = "Hello from NetduinoPlus!\nBytes available: average=" + memCheck.MemAverage + ", high=" + memCheck.MemHigh + ", low=" + memCheck.MemLow;
                    memCheck.Reset();
                    string chatterResponseText = HttpUtil.DoHttpMethod("POST", chatterUri, credential, chatterRequestText);
                    Debug.Print(chatterResponseText);
                }

                memCheck.Check();
                Thread.Sleep(cycleEndDelayMilliseconds);
            }
        }

    }
}
