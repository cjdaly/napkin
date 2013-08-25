/****
 * Copyright (c) 2013 Chris J Daly (github user cjdaly)
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 * 
 * Contributors:
 *   cjdaly - initial API and implementation
 ****/
using System;
using System.Collections;
using System.IO.Ports;
using System.Text;
using System.Threading;
using Microsoft.SPOT;

namespace napkin.devices.serial.common
{
    public class ThreadedSerialDevice
    {
        private string _serialPortName;
        private SerialPort _serialPort;

        private Thread _readThread;
        private Queue _readData;

        private Thread _writeThread;
        private Queue _writeData;

        public delegate void ReadHandler(string line);
        public event ReadHandler ReadLine = delegate { };

        public ThreadedSerialDevice(string serialPortName = Serial.COM1)
        {
            _serialPortName = serialPortName;

            Init();
        }

        public void WriteLine(string text)
        {
            Write(text + "\r\n");
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
            StringBuilder readBuffer = new StringBuilder();
            while (true)
            {
                try
                {
                    int data = _serialPort.ReadByte();
                    if (data != -1)
                    {
                        char c = (char)data;
                        if (IsNewline(c) && (readBuffer.Length > 0))
                        {
                            ReadLine(readBuffer.ToString());
                            readBuffer.Clear();
                        }
                        else
                        {
                            readBuffer.Append(c);
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
