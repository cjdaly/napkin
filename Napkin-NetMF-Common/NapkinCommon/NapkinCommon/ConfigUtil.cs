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
            // Thread.Sleep(NetworkDelayMilliseconds);

            if ((responseText == null) || (responseText == ""))
            {
                responseText = HttpUtil.DoHttpMethod("PUT", uri, credential, defaultValue);
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
            string responseText = HttpUtil.DoHttpMethod("PUT", uri, credential, value);
        }

        public static void PostConfigNode(string uri, string sub, NetworkCredential credential)
        {
            uri = uri + "?sub=" + sub;
            string responseText = HttpUtil.DoHttpMethod("POST", uri, credential, null);
        }
    }
}
