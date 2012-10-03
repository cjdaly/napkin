using System;
using Microsoft.SPOT;

namespace NapkinCommon
{
    public class MemCheck
    {
        private uint memTotal = 0;
        private uint memLow = 0xFFFFFFFF;
        private uint memHigh = 0;
        private uint checkCount = 0;

        public void Check()
        {
            uint mem = Debug.GC(false);
            memTotal += mem;

            if (mem < memLow) memLow = mem;
            if (mem > memHigh) memHigh = mem;

            checkCount++;
        }

        public uint MemAverage { get { return memTotal / checkCount; } }

        public uint MemHigh { get { return memHigh; } }

        public uint MemLow { get { return memLow; } }

        public void Reset()
        {
            memTotal = 0;
            memLow = 0xFFFFFFFF;
            memHigh = 0;
            checkCount = 0;
        }
    }
}
