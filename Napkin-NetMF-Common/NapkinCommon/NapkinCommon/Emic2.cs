using System;
using System.IO.Ports;
using Microsoft.SPOT;

namespace NapkinCommon
{
    // Parallax Emic 2 Text to Speech module
    public class Emic2
    {

        private SerialPort _serialPort;

        public Emic2(string serialPortName = Serial.COM2)
        {
            _serialPort = new SerialPort(serialPortName, 9600, Parity.None, 8, StopBits.One);
            _serialPort.Open();
        }

        public void Say(string message)
        {
            WriteEmic2Command('S', message);
        }

        public void Info()
        {
            WriteEmic2Command('I');
        }

        public void WriteEmic2Command(char command, String message = "")
        {
            // TODO: 1023 limit to message length (Emic2 doc)
            // TODO: read response to commands

            byte[] _buffer = new byte[1 + message.Length + 1];
            int i = 0;

            _buffer[i++] = (byte)(command);

            foreach (char c in message)
            {
                _buffer[i++] = (byte)c;
            }

            _buffer[i++] = (byte)('\n');

            _serialPort.Write(_buffer, 0, i);
        }
    }
}
