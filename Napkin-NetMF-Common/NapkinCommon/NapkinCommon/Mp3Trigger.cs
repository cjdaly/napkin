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

        private void SendCommand(byte[] commandBytes)
        {
            _serialPort.Write(commandBytes, 0, commandBytes.Length);
        }

        public void StartStop()
        {
            SendCommand(new byte[] { (byte)'O' });
        }

        public void Forward()
        {
            SendCommand(new byte[] { (byte)'F' });
        }

        public void Reverse()
        {
            SendCommand(new byte[] { (byte)'R' });
        }

        public void SetVolume(byte volume)
        {
            SendCommand(new byte[] { (byte)'v', volume });
        }
    }
}
