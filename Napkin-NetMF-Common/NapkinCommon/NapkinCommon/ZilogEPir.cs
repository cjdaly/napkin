using System;
using System.Text;
using System.IO.Ports;
using Microsoft.SPOT;

namespace NapkinCommon
{
    public class ZilogEPir
    {
        private SerialPort _serialPort;

        public ZilogEPir(string serialPortName = Serial.COM1)
        {
            _serialPort = new SerialPort(serialPortName, 9600, Parity.None, 8, StopBits.One);
            _serialPort.Open();
        }

        public void Refresh()
        {
            ReadCommand('a');
            ReadCommand('i', 2);
        }

        private byte[] ReadCommand(char command, int responseLength = 1)
        {
            byte[] commandBytes = new byte[] { (byte)command };
            _serialPort.Write(commandBytes, 0, commandBytes.Length);
            _serialPort.Flush();

            byte[] response = new byte[responseLength];
            _serialPort.Read(response, 0, responseLength);

            String responseText = new String(Encoding.UTF8.GetChars(response));

            Debug.Print("ZilogEPir command: " + command + ", response: " + responseText);
            return response;
        }
    }
}
