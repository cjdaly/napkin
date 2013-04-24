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
using System.IO;
using System.Net;
using System.Net.Sockets;
using System.Text;
using System.Threading;
using Microsoft.SPOT;

namespace napkin.util.http
{
    public class HttpUtil
    {

        public static string DoHttpMethod(string method, string uri, NetworkCredential credential, string requestText, bool readResponse = true)
        {
            string responseText = null;

            try
            {
                using (HttpWebRequest request = (HttpWebRequest)WebRequest.Create(uri))
                {
                    request.Method = method;
                    request.Credentials = credential;

                    // stayin' alive?
                    // http://forums.netduino.com/index.php?/topic/2964-every-2nd-webrequest-fails/
                    request.KeepAlive = false;

                    if (requestText != null)
                    {
                        byte[] buffer = Encoding.UTF8.GetBytes(requestText);
                        request.ContentLength = buffer.Length;
                        request.ContentType = "text/plain";

                        Stream stream = request.GetRequestStream();
                        stream.Write(buffer, 0, buffer.Length);
                    }

                    if (readResponse)
                    {
                        // PollHaveResponse(request);

                        // http://www.tinyclr.com/forum/topic?id=3793   (start at comment 7)
                        Thread.Sleep(100);

                        responseText = GetResponseText(request);
                    }
                }
            }
            catch (Exception ex)
            {
                Debug.Print("Exception in DoHttpMethod: " + ex.Message);
            }

            return responseText;
        }

        private static string GetResponseText(HttpWebRequest request)
        {
            string responseText = "";

            try
            {
                using (HttpWebResponse response = (HttpWebResponse)request.GetResponse())
                {
                    // PollHaveResponse(request);

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
            }
            catch (Exception ex)
            {
                Debug.Print("Exception in GetResponseText: " + ex.Message);
            }

            // PollHaveResponse(request);

            return responseText;
        }

        private static void PollHaveResponse(HttpWebRequest request, int timeoutMilliseconds = 2000)
        {
            DateTime start = DateTime.Now;
            DateTime timeout = start.AddMilliseconds(timeoutMilliseconds);
            while (!request.HaveResponse && (DateTime.Now < timeout))
            {
                Thread.Sleep(10);
            }
            DateTime finish = DateTime.Now;
            TimeSpan consumed = finish.Subtract(start);
            Debug.Print("HaveResponse: " + request.HaveResponse + " after: " + consumed);
        }
    }
}
