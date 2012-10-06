using System;
using System.Net;
using System.Net.Sockets;
using Microsoft.SPOT;

namespace NapkinCommon
{
    public class ConfigUtil
    {
        public static string getConfigValue(string uri, string key, NetworkCredential credential)
        {
            uri = uri + "?key=" + key;
            string responseText = HttpUtil.DoHttpMethod("GET", uri, credential, null);
            return responseText;
        }

        public static void putConfigValue(string uri, string key, string value, NetworkCredential credential)
        {
            uri = uri + "?key=" + key;
            string responseText = HttpUtil.DoHttpMethod("PUT", uri, credential, value);
        }

        public static void postConfigNode(string uri, string sub, NetworkCredential credential)
        {
            uri = uri + "?sub=" + sub;
            string responseText = HttpUtil.DoHttpMethod("POST", uri, credential, null);
        }
    }
}
