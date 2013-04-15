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
using System.Text;
using System.Threading;
using Microsoft.SPOT;
using Microsoft.SPOT.Hardware;
using SecretLabs.NETMF.Hardware;
using SecretLabs.NETMF.Hardware.Netduino;

using napkin.devices.serial.common;
using napkin.devices.serial.uLcd144;

namespace napkin.systems.netduino.nd2
{
    public class Program
    {
        public static void Main()
        {
            Debug.Print("hello");

            ULcd144Device uLcd144 = new ULcd144Device(Pins.GPIO_PIN_D13, Serial.COM2);
            uLcd144.ReadLine += new ThreadedSerialDevice.ReadHandler(uLcd144_ReadLine);
            uLcd144.Reset();
            Thread.Sleep(3000);
            Debug.Print("test");

            uLcd144.Test();

            Debug.Print("goodbye");
        }

        static void uLcd144_ReadLine(string line)
        {
            StringBuilder sb = new StringBuilder("uLcd144: ");
            foreach (char c in line) {
                if (c < 32)
                {
                    sb.Append("[");
                    sb.Append(((int)c).ToString());
                    sb.Append("]");
                }
                else sb.Append(c);
            }
            Debug.Print(sb.ToString());
        }

    }
}
