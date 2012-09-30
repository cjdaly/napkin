using System;
using System.IO;
using System.Net;
using System.Net.Sockets;
using System.Text;
using System.Threading;
using Microsoft.SPOT;
using Microsoft.SPOT.Hardware;
using SecretLabs.NETMF.Hardware;
using SecretLabs.NETMF.Hardware.NetduinoPlus;

namespace NetduinoPlusChatterer
{
    public class Program
    {
        public static void Main()
        {
            Debug.Print("Hello!");

            NetworkCredential credential = new NetworkCredential("ndp1", "ndp1");
            string uri = "http://192.168.2.50:4567/napkin/starts";
            string responseText = DoHttpMethod("GET", uri, credential, null);
            Debug.Print(responseText);

            Debug.Print("Goodbye!");
        }

        private static string DoHttpMethod(string method, string uri, NetworkCredential credential, string requestText)
        {
            string responseText = null;

            using (HttpWebRequest request = (HttpWebRequest)WebRequest.Create(uri))
            {
                request.Method = method;
                request.Credentials = credential;

                if (requestText != null)
                {
                    byte[] buffer = Encoding.UTF8.GetBytes(requestText);
                    request.ContentLength = buffer.Length;
                    request.ContentType = "text/plain";

                    Stream stream = request.GetRequestStream();
                    stream.Write(buffer, 0, buffer.Length);
                }

                responseText = GetResponseText(request);
            }

            return responseText;
        }

        private static string GetResponseText(HttpWebRequest request)
        {
            string responseText = "";

            using (HttpWebResponse response = (HttpWebResponse)request.GetResponse())
            {
                int contentLength = (int)response.ContentLength;
                byte[] buffer = new byte[contentLength];
                Stream stream = response.GetResponseStream();
                int i = 0;
                while (i < contentLength)
                {
                    int readCount = stream.Read(buffer, i, contentLength - i);
                    i += readCount;
                }

                char[] responseChars = Encoding.UTF8.GetChars(buffer);
                responseText = new string(responseChars);
            }

            return responseText;
        }

    }
}
