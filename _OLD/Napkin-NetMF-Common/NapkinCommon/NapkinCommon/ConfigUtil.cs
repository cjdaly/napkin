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
using Microsoft.SPOT;

namespace NapkinCommon
{
    public class ConfigUtil
    {
        public static string GetOrInitConfigValue(string napkinServerUri, string devicePath, string key, string defaultValue, NetworkCredential credential)
        {
            string uri = napkinServerUri + "/config/" + devicePath + "?key=" + key;
            string responseText = HttpUtil.DoHttpMethod("GET", uri, credential, null);
            Debug.Print("GOT " + key + "=" + responseText);
            if ((responseText == null) || (responseText == ""))
            {
                HttpUtil.DoHttpMethod("PUT", uri, credential, defaultValue, false);
                return defaultValue;
            }
            else
            {
                return responseText;
            }
        }

        public static string GetConfigValue(string uri, string key, NetworkCredential credential)
        {
            uri = uri + "?key=" + key;
            string responseText = HttpUtil.DoHttpMethod("GET", uri, credential, null);
            return responseText;
        }

        public static void PutConfigValue(string uri, string key, string value, NetworkCredential credential)
        {
            uri = uri + "?key=" + key;
            HttpUtil.DoHttpMethod("PUT", uri, credential, value, false);
        }

        public static void PostConfigNode(string uri, string sub, NetworkCredential credential)
        {
            uri = uri + "?sub=" + sub;
            HttpUtil.DoHttpMethod("POST", uri, credential, null, false);
        }
    }
}
