using System;
using System.Collections;
using System.Threading;
using Microsoft.SPOT;

using Gadgeteer.Modules.GHIElectronics;

namespace NapkinGadgeteerCommon
{
    public class JoystickDriver
    {
        public enum Position
        {
            UNKNOWN = 0,
            DOWN_LEFT = 1,
            DOWN = 2,
            DOWN_RIGHT = 3,
            LEFT = 4,
            CENTER = 5,
            RIGHT = 6,
            UP_LEFT =  7,
            UP =  8,
            UP_RIGHT = 9
        }

        public delegate void JoystickMotionHandler(Position position, Position oldPosition);
        public event JoystickMotionHandler JoystickMotion;

        private Thread _joystickThread;

        private Joystick _joystick;

        public JoystickDriver(Joystick joystick)
        {
            _joystick = joystick;
            joystick.JoystickPressed += new Joystick.JoystickEventHandler(joystick_JoystickPressed);
            joystick.JoystickReleased += new Joystick.JoystickEventHandler(joystick_JoystickReleased);

            _joystickThread = new Thread(DriverLoop);
            _joystickThread.Start();
        }

        private void DriverLoop()
        {
            while (true)
            {
                ReadJoystick();
                Thread.Sleep(50);
            }
        }

        private Position _position = Position.UNKNOWN;
        private long _joystickHoldTicks = DateTime.MinValue.Ticks;
        private readonly long _joystickHoldTimeMillis = 500;

        private void ReadJoystick()
        {
            DateTime now = DateTime.Now;
            Joystick.Position pos = _joystick.GetJoystickPosition();

            // note: X/Y values munged to account for physical joystick orientation
            // TODO: pull this configuration out for subclassing
            int x = scaleJoystickValue(pos.X);
            int y = scaleJoystickValue(pos.Y);

            Position position = GetPosition(x, y);

            if (position == _position)
            {
                long ticks = now.Ticks - _joystickHoldTicks;
                long millis = ticks / TimeSpan.TicksPerMillisecond;
                if (millis >= _joystickHoldTimeMillis)
                {
                    _joystickHoldTicks = now.Ticks;
                    JoystickMotion.Invoke(position, _position);
                }
            }
            else
            {
                _position = position;
                _joystickHoldTicks = now.Ticks;
            }
        }

        private Position GetPosition(int x, int y)
        {
            if (x > 0)
            {
                if (y > 0) return Position.UP_RIGHT;
                else if (y < 0) return Position.DOWN_RIGHT;
                else return Position.RIGHT;
            }
            else if (x < 0)
            {
                if (y > 0) return Position.UP_LEFT;
                else if (y < 0) return Position.DOWN_LEFT;
                else return Position.LEFT;
            }
            else
            {
                if (y > 0) return Position.UP;
                else if (y < 0) return Position.DOWN;
                else return Position.CENTER;
            }
        }

        private int scaleJoystickValue(double val)
        {
            if (val < .2) return -1;
            if (val > .8) return 1;
            return 0;
        }

        void joystick_JoystickPressed(Joystick sender, Joystick.JoystickState state)
        {   
        }

        void joystick_JoystickReleased(Joystick sender, Joystick.JoystickState state)
        {
        }
    }
}
