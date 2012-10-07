using System;
using System.Text;
using Microsoft.SPOT;

namespace NapkinCommon
{
    public abstract class Sampler
    {
        public Sampler()
        {
            Reset();
        }

        protected int _samples = 0;
        public int Samples { get { return _samples; } }

        public abstract void Sample();
        public abstract void Reset();
        public abstract string GetStatus(string keyPrefix, string headline = null);
    }

    public abstract class LongSampler : Sampler
    {
        private long _total;
        private long _low;
        private long _high;

        public long Average { get { return _total / _samples; } }

        public override void Reset()
        {
            _samples = 0;
            _total = 0;
            _low = long.MaxValue;
            _high = long.MinValue;
        }

        public override void Sample()
        {
            long sample = SampleImpl();
            _total += sample;
            if (sample < _low) _low = sample;
            if (sample > _high) _high = sample;
            _samples++;
        }

        protected abstract long SampleImpl();

        public override string GetStatus(string keyPrefix, string headline = null)
        {
            StringBuilder sb = new StringBuilder();
            if (headline != null) sb.AppendLine(headline);
            sb.Append(keyPrefix).AppendLine("_samples=" + Samples);
            sb.Append(keyPrefix).AppendLine("_average=" + Average);
            sb.Append(keyPrefix).AppendLine("_high=" + _high);
            sb.Append(keyPrefix).AppendLine("_low=" + _low);
            return sb.ToString();
        }
    }

    public abstract class DoubleSampler : Sampler
    {
        private double _total;
        private double _low;
        private double _high;

        public double Average { get { return _total / _samples; } }

        public override void Reset()
        {
            _samples = 0;
            _total = 0;
            _low = double.MaxValue;
            _high = double.MinValue;
        }

        public override void Sample()
        {
            double sample = SampleImpl();
            _total += sample;
            if (sample < _low) _low = sample;
            if (sample > _high) _high = sample;
            _samples++;
        }

        protected abstract double SampleImpl();

        public override string GetStatus(string keyPrefix, string headline = null)
        {
            StringBuilder sb = new StringBuilder();
            if (headline != null) sb.AppendLine(headline);
            sb.Append(keyPrefix).AppendLine("_samples=" + Samples);
            sb.Append(keyPrefix).AppendLine("_average=" + Average);
            sb.Append(keyPrefix).AppendLine("_high=" + _high);
            sb.Append(keyPrefix).AppendLine("_low=" + _low);
            return sb.ToString();
        }
    }
}
