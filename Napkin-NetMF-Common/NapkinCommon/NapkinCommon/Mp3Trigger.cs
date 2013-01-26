using System;
using System.IO.Ports;
using Microsoft.SPOT;

namespace NapkinCommon
{
    public class Mp3Trigger : ThreadedSerialDevice
    {
        public Mp3Trigger(string serialPortName = Serial.COM2)
            : base(serialPortName)
        {
        }

        private void SendCommand(byte[] commandBytes)
        {
            Write(commandBytes);
        }

        public void StatusVersion()
        {
            SendCommand(new byte[] { (byte)'S', (byte)'0' });
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
