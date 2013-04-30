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

namespace napkin.util.http
{
    public class StartupUtil
    {
        public static void StartSequence(string napkinServerUri, string deviceId, NetworkCredential credential)
        {
            Thread.Sleep(5000);

            string deviceConfigUri = napkinServerUri + "/config/" + deviceId;
            string responseText = HttpUtil.DoHttpMethod("GET", deviceConfigUri, credential, null);
            Debug.Print("Config: " + responseText);

            Thread.Sleep(2000);

            string deviceConfigPostUri = napkinServerUri + "/config?sub=" + deviceId;
            HttpUtil.DoHttpMethod("POST", deviceConfigPostUri, credential, "", false);

            Thread.Sleep(2000);

            int start_count = ConfigUtil.IncrementCounter(napkinServerUri, deviceId, "napkin.systems.start_count~i", credential);
            Debug.Print("Starts: " + start_count);
        }
    }
}