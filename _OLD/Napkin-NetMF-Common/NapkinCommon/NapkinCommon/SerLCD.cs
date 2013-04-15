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
using System.IO.Ports;
using Microsoft.SPOT;

namespace NapkinCommon
{
    public class SerLCD
    {
        private SerialPort _serialPort;

        public SerLCD(string serialPortName = Serial.COM1)
        {
            _serialPort = new SerialPort(serialPortName, 9600, Parity.None, 8, StopBits.One);
            _serialPort.Open();
        }

        public void Clear()
        {
            _serialPort.Write(new byte[] { 0xFE, 0x01 }, 0, 2);
        }

        public void Write(string line1, string line2 = "")
        {
            Clear();
            WriteSerLcd(line1);
            WriteSerLcd(line2, 64);
        }

        private byte[] _serLcdBuffer = new byte[40];
        private void WriteSerLcd(String message, int position = 0)
        {
            int i = 0;
            if (position != 0)
            {
                _serLcdBuffer[i++] = (byte)(0xFE);
                _serLcdBuffer[i++] = (byte)(0x80 + position);
            }

            foreach (char c in message)
            {
                _serLcdBuffer[i++] = (byte)c;
            }
            _serialPort.Write(_serLcdBuffer, 0, i);
        }
    }
}
