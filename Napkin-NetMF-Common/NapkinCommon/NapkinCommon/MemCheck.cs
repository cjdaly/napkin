using System;
using System.Text;
using Microsoft.SPOT;

namespace NapkinCommon
{
    public class MemCheck : LongSampler
    {
        protected override long SampleImpl()
        {
            return Debug.GC(false);
        }

        public string GetStatus(string headline = null)
        {
            return GetStatus("memory", headline);
        }
    }
}
