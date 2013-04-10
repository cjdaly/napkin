using System;
using System.Threading;
using Microsoft.SPOT;
using Microsoft.SPOT.Hardware;

namespace napkin.devices.spi.DeadOnRTC
{
    // sparkfun: https://www.sparkfun.com/products/10160
    // datasheet: http://www.sparkfun.com/datasheets/BreakoutBoards/DS3234.pdf
    // tutorial: http://bradsduino.blogspot.com/2012/12/sparkfun-deadon-rtc-ds3234-breakout_30.html
    // netduino SPI: http://wiki.netduino.com/SPI.ashx , http://wiki.netduino.com/SPI-Configuration.ashx
    public class DeadOnRTCDriver
    {
        private SPI.Configuration _spiConfig;
        private SPI _spi;

        public DeadOnRTCDriver(Cpu.Pin ssPin, SPI.SPI_module spiModule = SPI.SPI_module.SPI1)
        {
            _spiConfig = new SPI.Configuration(ssPin, false, 0, 0, true, true, 1000, spiModule);
            _spi = new SPI(_spiConfig);
        }

        public void SetTime(byte seconds, byte minutes, byte hour)
        {
            byte[] writeBuffer = new byte[] { 0x80, seconds, minutes, hour};
            _spi.Write(writeBuffer);
        }

        public void SetDate(byte date, byte month, byte year)
        {
            byte[] writeBuffer = new byte[] { 0x84, date, month, year };
            _spi.Write(writeBuffer);
        }

        public DeadOnRTCData ReadData()
        {
            byte[] writeBuffer = new byte[] { 0 };
            byte[] readBuffer = new byte[0x14];

            _spi.WriteRead(writeBuffer, readBuffer);
            DeadOnRTCData data = new DeadOnRTCData(readBuffer);
            return data;
        }

    }

    public struct DeadOnRTCData
    {
        private byte[] _data;

        public static int BCDToInt(byte bcdByte)
        {
            int hi = GetHighNibble(bcdByte);
            int lo = GetLowNibble(bcdByte);
            return hi * 10 + lo;
        }

        public static int GetHighNibble(byte bcdByte)
        {
            return bcdByte >> 4;
        }

        public static int GetLowNibble(byte bcdByte)
        {
            return bcdByte & 0x0F;
        }

        public DeadOnRTCData(byte[] data)
        {
            _data = data;
        }

        public void Dump()
        {
            for (int i = 0; i < _data.Length; i++)
            {
                Debug.Print(">>> " + i + ": " + _data[i].ToString("X"));
            }
        }

        public DateTime GetDateTime()
        {
            int year = BCDToInt(_data[7]) + 2000;
            int month = BCDToInt((byte)(_data[6] & 0x7F));
            int day = BCDToInt(_data[5]);
            int hour = BCDToInt(_data[3]);
            int minute = BCDToInt(_data[2]);
            int second = BCDToInt(_data[1]);

            DateTime dt = new DateTime(year, month, day, hour, minute, second);
            return dt;
        }
    }
}
