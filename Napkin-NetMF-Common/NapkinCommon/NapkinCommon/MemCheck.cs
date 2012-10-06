using System;
using System.Text;
using Microsoft.SPOT;

namespace NapkinCommon
{
    public class MemCheck
    {
        private uint memTotal = 0;
        private uint memLow = 0xFFFFFFFF;
        private uint memHigh = 0;
        private uint samples = 0;

        public void Check()
        {
            uint mem = Debug.GC(false);
            memTotal += mem;

            if (mem < memLow) memLow = mem;
            if (mem > memHigh) memHigh = mem;

            samples++;
        }

        public uint Samples { get { return samples; } }

        public uint MemAverage { get { return memTotal / samples; } }

        public uint MemHigh { get { return memHigh; } }

        public uint MemLow { get { return memLow; } }

        public string GetStatus(string headline = null)
        {
            StringBuilder sb = new StringBuilder();
            if (headline != null) sb.AppendLine(headline);
            sb.AppendLine("memory_samples=" + Samples);
            sb.AppendLine("memory_average=" + MemAverage);
            sb.AppendLine("memory_high=" + MemHigh);
            sb.AppendLine("memory_low=" + MemLow);
            return sb.ToString();
        }

        public void Reset()
        {
            memTotal = 0;
            memLow = 0xFFFFFFFF;
            memHigh = 0;
            samples = 0;
        }
    }
}
