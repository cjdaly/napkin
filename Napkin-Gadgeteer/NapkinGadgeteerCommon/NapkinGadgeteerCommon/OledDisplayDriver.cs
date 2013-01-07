using System;
using System.Collections;
using System.Threading;
using Microsoft.SPOT;
using Gadgeteer.Modules.Seeed;

namespace NapkinGadgeteerCommon
{
    public class OledDisplayDriver
    {
        private OledDisplay _oledDisplay;

        private ArrayList _lines = new ArrayList();
        private readonly int _linesMax = 8;
        private Boolean _refresh = false;

        private Font _fontSmall;
        private Font _fontNinaB;

        private Gadgeteer.Color _textColor;

        private Thread _thread;

        public OledDisplayDriver(OledDisplay oledDisplay, Font fontSmall, Font fontNinaB)
        {
            _oledDisplay = oledDisplay;
            _fontSmall = fontSmall;
            _fontNinaB = fontNinaB;

            _textColor = Gadgeteer.Color.White;

            _thread = new Thread(DriverLoop);
            _thread.Start();
        }

        public void AddLine(string line)
        {
            lock (this)
            {
                _lines.Add(line);
                if (_lines.Count > _linesMax)
                {
                    _lines.RemoveAt(0);
                }
                _refresh = true;
            }
        }

        private void DriverLoop()
        {
            while (true)
            {
                lock (this)
                {
                    if (_refresh)
                    {
                        Refresh();
                    }
                    _refresh = false;
                }
                Thread.Sleep(200);
            }
        }

        private void Refresh()
        {
            uint x = 0;
            uint y = 60;
            _oledDisplay.SimpleGraphics.Clear();
            foreach (string line in _lines)
            {
                _oledDisplay.SimpleGraphics.DisplayText(line, _fontSmall, _textColor, x, y);
                y += 8;
            }
        }

    }
}
