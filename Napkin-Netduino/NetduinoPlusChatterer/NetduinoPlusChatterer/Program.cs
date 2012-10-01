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

namespace NetduinoPlusChatterer
{
    public class Program
    {
        public static void Main()
        {
            Init();
            Cycle();
        }

        private static void Init()
        {
            OutputPort led = new OutputPort(Pins.ONBOARD_LED, false);

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

            Thread.Sleep(3000);
            BlinkMCommand.FadeToHSB.Execute(i2cDevice, blinkM_D, 0, saturation, brightness);
            Thread.Sleep(1000);
            BlinkMCommand.FadeToHSB.Execute(i2cDevice, blinkM_D, 0, saturation, 0);
            BlinkMCommand.FadeToHSB.Execute(i2cDevice, blinkM_E, 48, saturation, brightness);
            Thread.Sleep(1000);
            BlinkMCommand.FadeToHSB.Execute(i2cDevice, blinkM_E, 48, saturation, 0);
            BlinkMCommand.FadeToHSB.Execute(i2cDevice, blinkM_F, 82, saturation, brightness);
            Thread.Sleep(1000);
            BlinkMCommand.FadeToHSB.Execute(i2cDevice, blinkM_F, 82, saturation, 0);
        }

        private static void InitBlinkM(I2CDevice i2cDevice, I2CDevice.Configuration blinkM)
        {
            BlinkMCommand.StopScript.Execute(i2cDevice, blinkM);
            BlinkMCommand.GetAddress.Execute(i2cDevice, blinkM);
            BlinkMCommand.GetVersion.Execute(i2cDevice, blinkM);
            BlinkMCommand.SetFadeSpeed.Execute(i2cDevice, blinkM, 255);
        }

        private static void Cycle()
        {
            int cycle = 0;
            int cycleDelayMilliseconds = 10 * 1000;

            Debug.Print("Hello!");

            NetworkCredential credential = new NetworkCredential("ndp1", "ndp1");
            string uri = "http://192.168.2.50:4567/chatter";

            while (true)
            {
                Debug.Print("cycle: " + cycle++);
                uint mem = Debug.GC(false);
                string requestText = "Hello from NetduinoPlus!\nmem: " + mem;

                string responseText = DoHttpMethod("POST", uri, credential, requestText);

                Debug.Print(responseText);
                Thread.Sleep(cycleDelayMilliseconds);
            }
        }

        private static string DoHttpMethod(string method, string uri, NetworkCredential credential, string requestText)
        {
            string responseText = null;

            using (HttpWebRequest request = (HttpWebRequest)WebRequest.Create(uri))
            {
                request.Method = method;
                request.Credentials = credential;

                if (requestText != null)
                {
                    byte[] buffer = Encoding.UTF8.GetBytes(requestText);
                    request.ContentLength = buffer.Length;
                    request.ContentType = "text/plain";

                    Stream stream = request.GetRequestStream();
                    stream.Write(buffer, 0, buffer.Length);
                }

                responseText = GetResponseText(request);
            }

            return responseText;
        }

        private static string GetResponseText(HttpWebRequest request)
        {
            string responseText = "";

            using (HttpWebResponse response = (HttpWebResponse)request.GetResponse())
            {
                int contentLength = (int)response.ContentLength;
                byte[] buffer = new byte[contentLength];
                Stream stream = response.GetResponseStream();
                int i = 0;
                while (i < contentLength)
                {
                    int readCount = stream.Read(buffer, i, contentLength - i);
                    i += readCount;
                }

                char[] responseChars = Encoding.UTF8.GetChars(buffer);
                responseText = new string(responseChars);
            }

            return responseText;
        }

    }
}
