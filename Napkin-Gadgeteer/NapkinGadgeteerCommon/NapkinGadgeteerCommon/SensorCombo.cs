using System;
using System.Text;
using Microsoft.SPOT;

using NapkinCommon;

namespace NapkinGadgeteerCommon
{
    public class SensorCombo
    {
        public SensorCombo(
            DoubleSampler.TakeDoubleSample lightSensorPercentageSampler,
            DoubleSampler.TakeDoubleSample lightSensorVoltageSampler)
        {
            MemCheck = Sampler.CreateMemCheck();
            LightSensorPercentageSampler = new DoubleSampler(lightSensorPercentageSampler, "light_sensor_percentage");
            LightSensorVoltageSampler = new DoubleSampler(lightSensorVoltageSampler, "light_sensor_voltage");
            TemperatureSampler = new DoubleSampler(null, "temperature");
            HumiditySampler = new DoubleSampler(null, "humidity");
        }

        public readonly LongSampler MemCheck;
        public readonly DoubleSampler LightSensorPercentageSampler;
        public readonly DoubleSampler LightSensorVoltageSampler;
        public readonly DoubleSampler TemperatureSampler;
        public readonly DoubleSampler HumiditySampler;

        public string GetStatus(string headline = null)
        {
            StringBuilder sb = new StringBuilder();
            if (headline != null) sb.AppendLine(headline);
            sb.Append(MemCheck.GetStatus());
            sb.Append(LightSensorPercentageSampler.GetStatus());
            sb.Append(LightSensorVoltageSampler.GetStatus());
            sb.Append(TemperatureSampler.GetStatus());
            sb.Append(HumiditySampler.GetStatus());
            return sb.ToString();
        }

        public void ResetAll()
        {
            MemCheck.Reset();
            LightSensorPercentageSampler.Reset();
            LightSensorVoltageSampler.Reset();
            TemperatureSampler.Reset();
            HumiditySampler.Reset();
        }
    }
}
