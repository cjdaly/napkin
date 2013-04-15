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
using System.Threading;
using System.IO.Ports;
using Microsoft.SPOT;
using Microsoft.SPOT.Hardware;
using napkin.devices.serial.common;

namespace napkin.devices.serial.uLcd144
{
    // http://www.4dsystems.com.au/prod.php?id=120
    // http://www.4dsystems.com.au/downloads/Semiconductors/GOLDELOX-SGC/Docs/GOLDELOX-SGC-COMMANDS-SIS-rev6.pdf
    //
    public class ULcd144Device : ThreadedSerialDevice
    {
        private OutputPort _resetPinPort;

        public ULcd144Device(Cpu.Pin resetPin, string serialPortName = Serial.COM1) : base(serialPortName)
        {
            _resetPinPort = new OutputPort(resetPin, true);
        }

        public override bool AutoFlushReads()
        {
            return false;
        }

        public void Reset()
        {
            _resetPinPort.Write(false);
            Thread.Sleep(100);
            _resetPinPort.Write(true);
            Thread.Sleep(2000);

            // autobaud
            WriteCommand(new byte[] { (byte)'U' });
        }

        public void WriteCommand(byte[] commandBytes, byte[] dataBytes = null)
        {
            Write(commandBytes);
            if (dataBytes != null) Write(dataBytes);
            string status = Read(true);
        }

        public void Clear()
        {
            // set screen background
            WriteCommand(new byte[] { (byte)'B', 0x00, 0x00 });

            // clear screen
            WriteCommand(new byte[] { (byte)'E' });
        }

        public void WriteMessage(string message, byte column = 0, byte row = 0, byte font = 1)
        {
            byte[] messageBytes = new byte[message.Length + 1];
            int i = 0;
            foreach (char c in message)
            {
                messageBytes[i++] = (byte)c;
            }
            messageBytes[i++] = 0;

            byte[] commandBytes = new byte[] { (byte)'s', column, row, font, 0xff, 0xff };
            WriteCommand(commandBytes, messageBytes);
        }


        public void ConsoleWriteLine(string line)
        {
            byte[] scroll = new byte[] { (byte)'c', 0, 8 * 9, 0, 8 * 8, 128, 8 * 8 };
            WriteCommand(scroll);

            byte[] fill = new byte[] { (byte)'r', 0, 119, 127, 127, 0x00, 0x00 };
            WriteCommand(fill);

            WriteMessage(line, 0, 15);
        }

        public void Test()
        {
            // autobaud
            // WriteCommand(new byte[] { (byte)'U' });

            // set screen background
            WriteCommand(new byte[] { (byte)'B', 0x00, 0xFF });

            // write "Hello"
            byte[] hello = new byte[] { (byte)'s', 0x01, 0x01, 0x02, 0xff, 0xff,
                (byte)'H', (byte)'e', (byte)'l', (byte)'l', (byte)'o', 0x00 };
            WriteCommand(hello);

            // draw circle
            byte[] circle = new byte[] { (byte)'C', 30, 50, 20, 0xf0, 0x0f };
            WriteCommand(circle);

            // write "World"
            byte[] world = new byte[] { (byte)'s', 0x03, 0x06, 0x02, 0x03, 0xa0,
                (byte)'W', (byte)'o', (byte)'r', (byte)'l', (byte)'d', 0x00 };
            WriteCommand(world);

            // scroll left
            byte[] scroll = new byte[] { (byte)'c', 4, 0, 0, 0, 124, 128 };
            byte[] fill = new byte[] { (byte)'r', 124, 0, 127, 127, 0x00, 0x00 };

            byte[] ticker1 = new byte[] { (byte)'s', 15, 15, 1, 0xff, 0xff,
                (byte)'A', 0x00 };
            byte[] ticker2 = new byte[] { (byte)'s', 15, 14, 1, 0xff, 0xff,
                (byte)'B', 0x00 };

            WriteCommand(ticker1);

            WriteCommand(scroll);
            WriteCommand(fill);

            WriteCommand(ticker2);

            WriteCommand(scroll);
            WriteCommand(fill);

            WriteCommand(scroll);
            WriteCommand(fill);

            WriteCommand(scroll);
            WriteCommand(fill);

            WriteCommand(ticker1);

            WriteCommand(scroll);
            WriteCommand(fill);

            WriteCommand(scroll);
            WriteCommand(fill);
        }
    }
}
