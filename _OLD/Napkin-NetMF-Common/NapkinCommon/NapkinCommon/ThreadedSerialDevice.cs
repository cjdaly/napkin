using System;
using System.Collections;
using System.IO.Ports;
using System.Text;
using System.Threading;
using Microsoft.SPOT;

namespace NapkinCommon
{
    public abstract class ThreadedSerialDevice
    {
        private string _serialPortName;
        private SerialPort _serialPort;

        private Thread _readThread;
        private Queue _readData;
        private StringBuilder _readBuffer;

        private Thread _writeThread;
        private Queue _writeData;

        public delegate void ReadHandler(string line);
        public event ReadHandler ReadLine;

        public ThreadedSerialDevice(string serialPortName = Serial.COM1)
        {
            _serialPortName = serialPortName;

            Init();
        }

        public void WriteLine(string text)
        {
            Write(text + "\n");
        }

        public void Write(string text)
        {
            byte[] data = Encoding.UTF8.GetBytes(text);
            Write(data);
        }

        public void Write(byte[] data)
        {
            lock (_writeData)
            {
                _writeData.Enqueue(data);
            }
        }

        private void Init()
        {
            _serialPort = new SerialPort(_serialPortName, 9600, Parity.None, 8, StopBits.One);
            _serialPort.Open();

            _readData = new Queue();
            _readBuffer = new StringBuilder();
            _readThread = new Thread(ReadLoop);
            _readThread.Start();

            _writeData = new Queue();
            _writeThread = new Thread(WriteLoop);
            _writeThread.Start();
        }

        public virtual bool IsNewline(char c)
        {
            return ((c == '\r') || (c == '\n'));
        }

        private void ReadLoop()
        {
            while (true)
            {
                try
                {
                    lock (_readBuffer)
                    {
                        while (_serialPort.BytesToRead > 0)
                        {
                            int data = _serialPort.ReadByte();
                            char c = (char)data;
                            if (IsNewline(c))
                            {
                                break;
                            }
                            else if (data < 32)
                            {
                                _readBuffer.Append("[" + data.ToString() + "]");
                            }
                            else
                            {
                                _readBuffer.Append(c);
                            }
                        }
                        if (_readBuffer.Length > 0)
                        {
                            ReadLine(_readBuffer.ToString());
                            _readBuffer.Clear();
                        }
                    }
                    Thread.Sleep(20);
                }
                catch (Exception ex)
                {
                    Debug.Print("ReadLoop: " + ex.Message);
                    Thread.Sleep(1000);
                }
            }
        }

        private void WriteLoop()
        {
            while (true)
            {
                lock (_writeData)
                {
                    if (_writeData.Count > 0)
                    {
                        byte[] data = (byte[])_writeData.Dequeue();
                        _serialPort.Write(data, 0, data.Length);
                        _serialPort.Flush();
                    }
                }
                Thread.Sleep(20);
            }
        }

    }
}
