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

        public void DumpRTCData()
        {
            byte[] writeBuffer = new byte[1];
            byte[] readBuffer = new byte[1];

            for (byte i = 0; i < 0x14; i++)
            {
                writeBuffer[0] = i;
                _spi.WriteRead(writeBuffer, readBuffer);
                Debug.Print("RTC " + i + ": " + readBuffer[0]);
                Thread.Sleep(100);
            }
        }
    }
}
