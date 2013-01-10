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
            _joystickDriver = new JoystickDriver(joystick);
            _joystickDriver.JoystickMotion += new JoystickDriver.JoystickMotionHandler(_joystickDriver_JoystickMotion);

            _emic2 = new Emic2(Serial.COM1);

            Font fontTitle = Resources.GetFont(Resources.FontResources.NinaB);
            Font fontBody = Resources.GetFont(Resources.FontResources.MirB64);
            Font fontStatus = Resources.GetFont(Resources.FontResources.small);
            _oledDriver = new OledDisplayDriver(oledDisplay, fontTitle, fontBody, fontStatus);
            _oledDriver.SetTitle("Hello");
            _oledDriver.SetBody("Foo");

            button1.ButtonPressed += new Button.ButtonEventHandler(button1_ButtonPressed);
            button1.ButtonReleased += new Button.ButtonEventHandler(button1_ButtonReleased);

            button.ButtonPressed += new Button.ButtonEventHandler(button_ButtonPressed);
            button.ButtonReleased += new Button.ButtonEventHandler(button_ButtonReleased);

            rfid.CardIDReceived += new RFID.CardIDReceivedEventHandler(rfid_CardIDReceived);

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
                    Message("joystick: LEFT");
                    break;
                case JoystickDriver.Position.RIGHT:
                    Message("joystick: RIGHT");
                    break;
            }
        }

        //

        private void Message(string message = "")
        {
            _oledDriver.AddLine(message);
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
            _emic2.Say("hello");
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
            _emic2.Say("goodbye");
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

        void rfid_CardIDReceived(RFID sender, string ID)
        {
            Message("RFID: " + ID);
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
