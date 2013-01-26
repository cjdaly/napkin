using System;
using System.IO.Ports;
using Microsoft.SPOT;

namespace NapkinCommon
{
    // Parallax Emic 2 Text to Speech module
    public class Emic2 : ThreadedSerialDevice
    {

        public Emic2(string serialPortName = Serial.COM2)
            : base(serialPortName)
        {
        }

        public void Say(string message)
        {
            WriteLine("S" + message);
        }

        private int _voice = 0;
        public int Voice
        {
            get { return _voice; }
            set
            {
                _voice = value % 9;
                WriteLine("N" + _voice.ToString());
            }
        }
        public void IncrementVoice()
        {
            Voice = Voice + 1;
        }

        public void Version()
        {
            WriteLine("I");
        }

        public void Settings()
        {
            WriteLine("C");
        }

        public void Help()
        {
            WriteLine("H");
        }
    }
}
