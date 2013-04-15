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
using System.IO.Ports;
using System.Collections;
using System.Threading;
using Microsoft.SPOT;
using Microsoft.SPOT.Presentation;
using Microsoft.SPOT.Presentation.Controls;
using Microsoft.SPOT.Presentation.Media;
using Microsoft.SPOT.Touch;

using Toolbox.NETMF.Hardware;
using Toolbox.NETMF.NET;

using Gadgeteer.Networking;
using GT = Gadgeteer;
using GTM = Gadgeteer.Modules;
using Gadgeteer.Modules.GHIElectronics;
using Gadgeteer.Modules.Seeed;

using NapkinCommon;
using NapkinGadgeteerCommon;

namespace hydra1
{
    public partial class Program
    {
        public readonly string DeviceId = "hydra1";
        public readonly string NapkinServerName = "192.168.2.50";
        public readonly ushort NapkinServerPort = 4567;
        public string NapkinServerUri
        {
            get { return "http://" + NapkinServerName + ":" + NapkinServerPort.ToString(); }
        }

        private Emic2 _emic2;
        private Mp3Trigger _mp3Trigger;

        private Thread _wiflyThread;

        JoystickDriver _joystickDriver;
        OledDisplayDriver _oledDriver;

        private string[] _soundFiles;
        private Hashtable _soundBuffer = new Hashtable();
        private int _soundFileSelection = 0;

        private WiFlyGSX _wifly;

        private string GetCurrentSoundName()
        {
            string soundFilePath = _soundFiles[_soundFileSelection];
            string soundFileName = Path.GetFileNameWithoutExtension(soundFilePath);
            return soundFileName;
        }

        void ProgramStarted()
        {
            Font fontTitle = Resources.GetFont(Resources.FontResources.NinaB);
            Font fontBody = Resources.GetFont(Resources.FontResources.MirB64);
            Font fontStatus = Resources.GetFont(Resources.FontResources.small);
            _oledDriver = new OledDisplayDriver(oledDisplay, fontTitle, fontBody, fontStatus);
            _oledDriver.SetTitle("Hello");
            _oledDriver.SetBody("Foo");

            _joystickDriver = new JoystickDriver(joystick);
            _joystickDriver.JoystickMotion += new JoystickDriver.JoystickMotionHandler(_joystickDriver_JoystickMotion);

            _emic2 = new Emic2(Serial.COM1);
            _emic2.ReadLine += new ThreadedSerialDevice.ReadHandler(_emic2_ReadLine);
            _emic2.Version();

            _mp3Trigger = new Mp3Trigger(Serial.COM2);
            _mp3Trigger.ReadLine += new ThreadedSerialDevice.ReadHandler(_mp3Trigger_ReadLine);
            _mp3Trigger.SetVolume(40);
            _mp3Trigger.StatusVersion();

            button1.ButtonPressed += new Button.ButtonEventHandler(button1_ButtonPressed);
            button1.ButtonReleased += new Button.ButtonEventHandler(button1_ButtonReleased);

            button.ButtonPressed += new Button.ButtonEventHandler(button_ButtonPressed);
            button.ButtonReleased += new Button.ButtonEventHandler(button_ButtonReleased);

            music.SetVolume(250);
            music.musicFinished += new Music.MusicFinishedPlayingEventHandler(music_musicFinished);

            GT.StorageDevice sd = sdCard.GetStorageDevice();
            _soundFiles = sd.ListFiles("NoAgenda");

            _wiflyThread = new Thread(WiFlyDriver);
            _wiflyThread.Start();
        }

        void _joystickDriver_JoystickMotion(JoystickDriver.Position position, JoystickDriver.Position oldPosition)
        {
            switch (position)
            {
                case JoystickDriver.Position.UP:
                    _soundFileSelection++;
                    if (_soundFileSelection >= _soundFiles.Length) _soundFileSelection = 0;
                    Message("joystick: UP");
                    break;
                case JoystickDriver.Position.DOWN:
                    _soundFileSelection--;
                    if (_soundFileSelection < 0) _soundFileSelection = _soundFiles.Length - 1;
                    Message("joystick: DOWN");
                    break;
                case JoystickDriver.Position.LEFT:
                    _mp3Trigger.Reverse();
                    Message("joystick: LEFT");
                    break;
                case JoystickDriver.Position.RIGHT:
                    _mp3Trigger.Forward();
                    Message("joystick: RIGHT");
                    break;
            }
        }

        //

        private void Message(string message = "")
        {
            if (message != null)
            {
                Debug.Print(message);
                _oledDriver.AddLine(message);
            }
        }
        
        //

        void _mp3Trigger_ReadLine(string line)
        {
            Message("mp3:" + line);
        }

        //

        void _emic2_ReadLine(string line)
        {
            Message("emic:" + line);
        }

        //

        void button1_ButtonPressed(Button sender, Button.ButtonState state)
        {
            if (!_playingSound)
            {
                button1.TurnLEDOn();
                string soundFileName = _soundFiles[_soundFileSelection];
                PlaySound(soundFileName);
            }
        }

        void button1_ButtonReleased(Button sender, Button.ButtonState state)
        {
            _emic2.Say("hello hello");
        }

        //

        void button_ButtonPressed(Button sender, Button.ButtonState state)
        {
            if (!_playingSound)
            {
                button.TurnLEDOn();
                string soundFileName = _soundFiles[_soundFileSelection];
                PlaySound(soundFileName, true);
            }
        }

        void button_ButtonReleased(Button sender, Button.ButtonState state)
        {
            _emic2.Say("goodbye dude");
        }

        //

        private bool _playingSound = false;
        private void PlaySound(string path, bool forceRead = false)
        {
            _playingSound = true;

            byte[] soundBytes = (byte[])_soundBuffer[path];
            if ((soundBytes == null) || forceRead)
            {
                GT.StorageDevice sd = sdCard.GetStorageDevice();
                soundBytes = sd.ReadFile(path);
                _soundBuffer[path] = soundBytes;
            }

            music.Play(soundBytes);
        }

        void music_musicFinished(Music sender)
        {
            _playingSound = false;
            button1.TurnLEDOff();
            button.TurnLEDOff();
        }

        //
        //

        private void WiFlyDriver()
        {
            // Note: WiFly is pre-configured for SSID, passphrase, etc, using 3.3V FTDI basic (pins 1,2,3,10)

            try
            {

                _wifly = new WiFlyGSX("COM4");

                string ver = _wifly.ModuleVersion;
                string mac = _wifly.MacAddress;

                Debug.Print("WiFly version: " + ver + ", mac: " + mac);

                Message("MAC: " + mac);

                while (true)
                {
                    string ip = _wifly.LocalIP;
                    Debug.Print("IP: " + ip);
                    Message("IP: " + ip);

                    if (ip != "0.0.0.0")
                    {
                        string conf = NapkinGet("/config/hydra1");
                        Debug.Print("CONF: ");
                        Debug.Print(conf);
                    }

                    Thread.Sleep(8000);
                }
            }
            catch (Exception ex)
            {
                Debug.Print("Exception in WiFlyDriver: " + ex.Message);
            }
        }

        private string NapkinGet(string path)
        {
            try
            {
                WiFlySocket socket = new WiFlySocket(NapkinServerName, NapkinServerPort, _wifly);
                HTTP_Client client = new HTTP_Client(socket);
                client.Authenticate(DeviceId, DeviceId);
                HTTP_Client.HTTP_Response response = client.Get(path);
                return response.ResponseBody;
            }
            catch (Exception ex)
            {
                Debug.Print("Exception in PingServer: " + ex.Message);
                return null;
            }
        }
    }
}
