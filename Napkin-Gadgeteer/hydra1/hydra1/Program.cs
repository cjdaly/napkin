using System;
using System.Collections;
using System.Threading;
using Microsoft.SPOT;
using Microsoft.SPOT.Presentation;
using Microsoft.SPOT.Presentation.Controls;
using Microsoft.SPOT.Presentation.Media;
using Microsoft.SPOT.Touch;

using Gadgeteer.Networking;
using GT = Gadgeteer;
using GTM = Gadgeteer.Modules;
using Gadgeteer.Modules.GHIElectronics;
using Gadgeteer.Modules.Seeed;

namespace hydra1
{
    public partial class Program
    {

        private Thread _joystickThread;

        private Font _font0;
        private Font _font1;

        private string[] _soundFiles;
        private int _soundFileSelection = 0;

        void ProgramStarted()
        {
            _font0 = Resources.GetFont(Resources.FontResources.small);
            _font1 = Resources.GetFont(Resources.FontResources.NinaB);

            button.ButtonPressed += new Button.ButtonEventHandler(button_ButtonPressed);
            button.ButtonReleased += new Button.ButtonEventHandler(button_ButtonReleased);

            joystick.JoystickPressed += new Joystick.JoystickEventHandler(joystick_JoystickPressed);
            joystick.JoystickReleased += new Joystick.JoystickEventHandler(joystick_JoystickReleased);

            rfid.CardIDReceived += new RFID.CardIDReceivedEventHandler(rfid_CardIDReceived);

            music.musicFinished += new Music.MusicFinishedPlayingEventHandler(music_musicFinished);

            //oledDisplay.SimpleGraphics.DisplayText("Hello World!", _font1, GT.Color.White, 0, 0);
            //oledDisplay.SimpleGraphics.DisplayText("Hello Marah!", _font1, GT.Color.Orange, 0, 16);
            //oledDisplay.SimpleGraphics.DisplayText("Hello Sage!", _font1, GT.Color.Red, 0, 32);

            //

            GT.StorageDevice sd = sdCard.GetStorageDevice();
            _soundFiles = sd.ListFiles("NoAgenda");

            _joystickThread = new Thread(JoystickDriver);
            _joystickThread.Start();
        }

        private void JoystickDriver()
        {
            while (true)
            {
                ReadJoystick();
                Thread.Sleep(10);
            }
        }

        private int _joystickPosition = 0;
        private long _joystickHoldTicks = DateTime.MinValue.Ticks;
        private readonly long _joystickHoldTimeMillis = 500;

        private void ReadJoystick()
        {
            DateTime now = DateTime.Now;
            Joystick.Position pos = joystick.GetJoystickPosition();

            int x = scaleJoystickValue(pos.X);
            int y = scaleJoystickValue(pos.Y);

            int ordinal = PositionToOrdinal(x, y);

            if (ordinal == _joystickPosition)
            {
                long ticks = now.Ticks - _joystickHoldTicks;
                long millis = ticks / TimeSpan.TicksPerMillisecond;
                if (millis >= _joystickHoldTimeMillis)
                {
                    IssueJoystickCommand(_joystickPosition);
                    _joystickHoldTicks = now.Ticks;
                }
            }
            else
            {
                _joystickPosition = ordinal;
                _joystickHoldTicks = now.Ticks;
            }            
        }

        private void IssueJoystickCommand(int joystickPosition)
        {
            switch (joystickPosition)
            {
                case 1:
                    break;
                case 2:
                    _soundFileSelection--;
                    if (_soundFileSelection < 0) _soundFileSelection = _soundFiles.Length - 1;
                    RefreshDisplay(_soundFiles[_soundFileSelection]);
                    break;
                case 3:
                    break;
                case 4:
                    break;
                case 5:
                    break;
                case 6:
                    break;
                case 7:
                    break;
                case 8:
                    _soundFileSelection++;
                    if (_soundFileSelection >= _soundFiles.Length) _soundFileSelection = 0;
                    RefreshDisplay(_soundFiles[_soundFileSelection]);
                    break;
                case 9:
                    break;
                default:
                    break;
            }
        }

        private int PositionToOrdinal(int x, int y)
        {
            int ordinal = 0;
            if (x > 0)
            {
                if (y > 0) { ordinal = 9; }
                else if (y < 0) { ordinal = 3; }
                else { ordinal = 6; }
            }
            else if (x < 0)
            {
                if (y > 0) { ordinal = 7; }
                else if (y < 0) { ordinal = 1; }
                else { ordinal = 4; }
            }
            else
            {
                if (y > 0) { ordinal = 8; }
                else if (y < 0) { ordinal = 2; }
                else { ordinal = 5; }
            }
            return ordinal;
        }

        private int scaleJoystickValue(double val)
        {
            if (val < .2) return -1;
            if (val > .8) return 1;
            return 0;
        }

        void RefreshDisplay(string text)
        {
            oledDisplay.SimpleGraphics.Clear();
            oledDisplay.SimpleGraphics.DisplayText(text, _font1, GT.Color.White, 0, 0);
            //oledDisplay.SimpleGraphics.DisplayText("x: " + _x, _font1, GT.Color.Orange, 0, 16);
            //oledDisplay.SimpleGraphics.DisplayText("y: " + _y, _font1, GT.Color.Orange, 0, 32);
        }

        void joystick_JoystickPressed(Joystick sender, Joystick.JoystickState state)
        {
            Mainboard.SetDebugLED(true);
        }

        void joystick_JoystickReleased(Joystick sender, Joystick.JoystickState state)
        {
            Mainboard.SetDebugLED(false);
        }

        void button_ButtonPressed(Button sender, Button.ButtonState state)
        {
            if (!_playingSound)
            {
                string soundFileName = _soundFiles[_soundFileSelection];
                PlaySound(soundFileName);
            }
        }

        void button_ButtonReleased(Button sender, Button.ButtonState state)
        {
        }

        private bool _playingSound = false;
        private void PlaySound(string path)
        {
            _playingSound = true;
            button.TurnLEDOn();

            GT.StorageDevice sd = sdCard.GetStorageDevice();
            byte[] bytes = sd.ReadFile(path);
            music.Play(bytes);

        }

        void music_musicFinished(Music sender)
        {
            _playingSound = false;
            button.TurnLEDOff();
        }

        void rfid_CardIDReceived(RFID sender, string ID)
        {
            oledDisplay.SimpleGraphics.Clear();
            oledDisplay.SimpleGraphics.DisplayText("RFID", _font1, GT.Color.White, 0, 0);
            oledDisplay.SimpleGraphics.DisplayText(ID, _font0, GT.Color.Orange, 0, 16);
        }
    }
}
