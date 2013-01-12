using System;
using System.IO.Ports;
using Microsoft.SPOT;

namespace NapkinCommon
{
    public class Mp3Trigger
    {
        private SerialPort _serialPort;

        public Mp3Trigger(string serialPortName = Serial.COM2)
        {
            _serialPort = new SerialPort(serialPortName, 9600, Parity.None, 8, StopBits.One);
            _serialPort.Open();
        }

        public void SendCommand(string command)
        {
            byte[] _buffer = new byte[command.Length];
            int i = 0;
            foreach (char c in command)
            {
                _buffer[i++] = (byte)c;
            }
            _serialPort.Write(_buffer, 0, i);
        }
    }
}
