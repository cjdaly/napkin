using System;
using System.Threading;
using Microsoft.SPOT;
using Microsoft.SPOT.Hardware;

namespace NapkinCommon
{
    public class BlinkMCommand
    {
        public static readonly int DefaultClockRateKhz = 200;

        public static readonly BlinkMCommand GoToRGB = new BlinkMCommand("Go to RGB Color Now", 'n', 3, 0);
        public static readonly BlinkMCommand FadeToRGB = new BlinkMCommand("Fade to RGB Color", 'c', 3, 0);
        public static readonly BlinkMCommand FadeToHSB = new BlinkMCommand("Fade to HSB Color", 'h', 3, 0);
        public static readonly BlinkMCommand FadeToRandomRGB = new BlinkMCommand("Fade to Random RGB Color", 'C', 3, 0);
        public static readonly BlinkMCommand FadeToRandomHSB = new BlinkMCommand("Fade to Random HSB Color", 'H', 3, 0);

        public static readonly BlinkMCommand PlayScript = new BlinkMCommand("Play Light Script", 'p', 3, 0);
        public static readonly BlinkMCommand StopScript = new BlinkMCommand("Stop Script", 'o', 0, 0);

        public static readonly BlinkMCommand SetFadeSpeed = new BlinkMCommand("Set Fade Speed", 'f', 1, 0);
        public static readonly BlinkMCommand SetTimeAdjust = new BlinkMCommand("Set Time Adjust", 't', 1, 0);

        public static readonly BlinkMCommand GetRGB = new BlinkMCommand("Get Current RGB Color", 'g', 0, 3);

        public static readonly BlinkMCommand SetAddress = new BlinkMCommand("Set BlinkM Address", 'A', 4, 0, 500);
        public static readonly BlinkMCommand GetAddress = new BlinkMCommand("Get BlinkM Address", 'a', 0, 1);
        public static readonly BlinkMCommand GetVersion = new BlinkMCommand("Get BlinkM Firmware Version", 'Z', 0, 2);

        //
        //

        private const int _timeout = 250;
        private int _postExecuteDelayMillis;

        private String _name;
        private char _command;
        private int _argCount;
        private int _retValCount;

        private byte[] _args;
        private byte[] _retVals;

        private byte[] _flushBuffer = new byte[4];

        private I2CDevice.I2CTransaction[] _transactions;

        private int _bytesTransferred;
        private int _expectedBytesTransferred;

        private I2CDevice.I2CTransaction[] _flushTransaction;
        private int _bytesFlushed;

        public BlinkMCommand(String name, char command, int argCount, int retValCount, int postExecuteDelayMillis = 0)
        {
            _postExecuteDelayMillis = postExecuteDelayMillis;

            _name = name;
            _command = command;
            _argCount = argCount;
            _retValCount = retValCount;

            _args = new byte[_argCount + 1];
            _args[0] = (byte)_command;
            _retVals = new byte[_retValCount];

            _transactions = new I2CDevice.I2CTransaction[_retValCount == 0 ? 1 : 2];
            _transactions[0] = I2CDevice.CreateWriteTransaction(_args);

            if (_retValCount > 0)
            {
                _transactions[1] = I2CDevice.CreateReadTransaction(_retVals);
            }

            _expectedBytesTransferred = _args.Length + _retVals.Length;

            _flushTransaction = new I2CDevice.I2CTransaction[] {
                I2CDevice.CreateReadTransaction(_flushBuffer)
            };
        }

        public bool Execute(I2CDevice device, I2CDevice.Configuration config, params byte[] args)
        {
            for (int i = 0; i < args.Length; i++)
            {
                _args[i + 1] = args[i];
            }
            for (int i = 0; i < _retValCount; i++)
            {
                _retVals[i] = 0;
            }

            device.Config = config;

            // Flush(device);
            _bytesTransferred = device.Execute(_transactions, _timeout);
            Debug.Print("I2C device at addr: " + config.Address + "\n executing " + ToString());

            if (_postExecuteDelayMillis > 0)
            {
                Thread.Sleep(_postExecuteDelayMillis);
            }

            return (_bytesTransferred == _expectedBytesTransferred);
        }

        // this seems to lock the device
        private void Flush(I2CDevice device)
        {
            String flushed = "";
            int flushCycles = 0;

            _bytesFlushed = device.Execute(_flushTransaction, _timeout);
            while (_bytesFlushed > 0 && flushCycles < 4)
            {
                for (int i = 0; i < _bytesFlushed; i++)
                {
                    flushed += _flushBuffer[i] + ", ";
                }
                _bytesFlushed = device.Execute(_flushTransaction, _timeout);
                flushCycles++;
            }

            if (flushed.Length > 0)
            {
                Debug.Print("flushed: " + flushed);
            }
        }

        public override String ToString()
        {
            String message = "BlinkM command '" + _command + "' (" + _name + ") ";
            message += "transferred " + _bytesTransferred + " bytes, expected:" + _expectedBytesTransferred + ", flushed: " + _bytesFlushed;
            message += "\n  args: ";
            for (int i = 1; i < _args.Length; i++)
            {
                message += _args[i];
                if (i + 1 < _args.Length) message += ", ";
            }

            message += "\n  retVals: ";

            for (int i = 0; i < _retVals.Length; i++)
            {
                message += _retVals[i];
                if (i + 1 < _retVals.Length) message += ", ";
            }

            return message;
        }

        public byte[] Args
        {
            get { return _args; }
        }

        public byte[] RetVals
        {
            get { return _retVals; }
        }

    }
}
