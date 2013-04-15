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
using System.Net;
using System.Net.Sockets;
using System.Threading;
using Microsoft.SPOT;
using Microsoft.SPOT.Hardware;
using SecretLabs.NETMF.Hardware;
using SecretLabs.NETMF.Hardware.NetduinoPlus;

using napkin.devices.serial.SerLCD;

namespace napkin.systems.netduino.ndp1
{
    public class Program
    {
        public static void Main()
        {
            SerLCDDevice serLcd = new SerLCDDevice();
            serLcd.Clear();
            serLcd.Write("hello", "world");
        }
    }
}
