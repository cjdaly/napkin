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
using System.Collections;
using System.Threading;
using Microsoft.SPOT;
using Gadgeteer.Modules.Seeed;
using SGI = Gadgeteer.Modules.Module.DisplayModule.SimpleGraphicsInterface;

namespace NapkinGadgeteerCommon
{
    public class OledDisplayDriver
    {
        private OledDisplay _oledDisplay;

        private Font _fontTitle;
        private Font _fontBody;
        private Font _fontStatus;

        //private Thread _thread;

        public OledDisplayDriver(OledDisplay oledDisplay, Font fontTitle, Font fontBody, Font fontStatus)
        {
            _oledDisplay = oledDisplay;
            _fontTitle = fontTitle;
            _fontBody = fontBody;
            _fontStatus = fontStatus;

            //_thread = new Thread(DriverLoop);
            //_thread.Start();
        }

        //
        //

        private Gadgeteer.Color _titleBackgroundColor = Gadgeteer.Color.DarkGray;
        private Gadgeteer.Color _titleColor = Gadgeteer.Color.Orange;

        private string _title = "";
        public void SetTitle(string title)
        {
            _title = title;
            SGI sgi = _oledDisplay.SimpleGraphics;
            sgi.DisplayRectangle(_titleBackgroundColor, 0, _titleBackgroundColor, 0, 0, sgi.Width, 16);
            sgi.DisplayText(_title, _fontTitle, _titleColor, 0, 0);
        }

        //
        //

        private Gadgeteer.Color _bodyBackgroundColor = Gadgeteer.Color.Brown;
        private Gadgeteer.Color _bodyColor = Gadgeteer.Color.Yellow;

        private string _body = "";
        public void SetBody(string body)
        {
            _body = body;
            SGI sgi = _oledDisplay.SimpleGraphics;
            sgi.DisplayRectangle(_bodyBackgroundColor, 0, _bodyBackgroundColor, 0, 20, sgi.Width, 64);
            sgi.DisplayText(_body, _fontBody, _bodyColor, 0, 20);
        }

        //
        //

        private Gadgeteer.Color _statusBackgroundColor = Gadgeteer.Color.Purple;
        private Gadgeteer.Color _statusColor = Gadgeteer.Color.White;

        private ArrayList _statusLines = new ArrayList();
        private readonly int _statusLineCount = 4;

        public void AddLine(string message = "")
        {
            _statusLines.Add(message);
            if (_statusLines.Count > _statusLineCount)
            {
                _statusLines.RemoveAt(0);
            }

            SGI sgi = _oledDisplay.SimpleGraphics;

            uint height = sgi.Height;
            uint width = sgi.Width;

            if (_statusLines.Count == 1)
            {
                _statusLines.Add("DISPLAY x: " + width + ", y: " + height);
            }

            uint yStart = 88;
            sgi.DisplayRectangle(_statusBackgroundColor, 0, _statusBackgroundColor, 0, yStart, width, height - yStart);
            int lineNum = 0;
            foreach (string line in _statusLines)
            {
                uint lineY = (uint)(yStart + (lineNum * 10) - 2);
                sgi.DisplayText(line, _fontStatus, _statusColor, 0, lineY);
                lineNum++;
            }
        }

        //
        //

        private void DriverLoop()
        {
            while (true)
            {
                Thread.Sleep(200);
            }
        }

    }
}
