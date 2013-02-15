﻿using System;
using System.IO;
using System.IO.Ports;
using System.Threading;
using Microsoft.SPOT;
using Microsoft.SPOT.Hardware;

namespace napkin.devices.serial.MidiMusicShield
{
    public class MidiDriver
    {
        private SerialPort _serialPort;
        private OutputPort _resetPinPort;

        public MidiDriver(Cpu.Pin resetPin, string serialPortName = Serial.COM2)
        {
            _resetPinPort = new OutputPort(resetPin, false);

            _serialPort = new SerialPort(serialPortName, 31250, Parity.None, 8, StopBits.One);
            _serialPort.Open();
        }

        public void Test()
        {
            // http://www.sparkfun.com/Code/MIDI_Example.pde
            Write(new byte[] { 0xb0, 0x07, 100 });
            Write(new byte[] { 0xb0, 0, 0 });

            for (byte instrument = 0; instrument < 127; instrument++)
            {
                Write(new byte[] { 0xc0, instrument });
                for (byte note = 30; note < 40; note++)
                {
                    Write(new byte[] { 0x90, note, 60 });
                    Thread.Sleep(50);

                    Write(new byte[] { 0x80, note, 60 });
                    Thread.Sleep(50);
                }
            }
        }

        public void Reset()
        {
            _resetPinPort.Write(false);
            Thread.Sleep(100);
            _resetPinPort.Write(true);
            Thread.Sleep(100);
        }

        public void Write(byte[] midiData)
        {
            _serialPort.Write(midiData, 0, midiData.Length);
        }
    }
}
