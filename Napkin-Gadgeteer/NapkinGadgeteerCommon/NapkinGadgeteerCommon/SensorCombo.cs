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
            LightSensorPercentageSampler = new DoubleSampler(lightSensorPercentageSampler, "light_sensor_percentage");
            LightSensorVoltageSampler = new DoubleSampler(lightSensorVoltageSampler, "light_sensor_voltage");
            TemperatureSampler = new DoubleSampler(null, "temperature");
            HumiditySampler = new DoubleSampler(null, "humidity");
        }

        public readonly DoubleSampler LightSensorPercentageSampler;
        public readonly DoubleSampler LightSensorVoltageSampler;
        public readonly DoubleSampler TemperatureSampler;
        public readonly DoubleSampler HumiditySampler;

        public StringBuilder AppendStatus(StringBuilder sb = null)
        {
            if (sb == null) sb = new StringBuilder();
            sb.Append(LightSensorPercentageSampler.GetStatus());
            sb.Append(LightSensorVoltageSampler.GetStatus());
            sb.Append(TemperatureSampler.GetStatus());
            sb.Append(HumiditySampler.GetStatus());
            return sb;
        }

        public void ResetAll()
        {
            LightSensorPercentageSampler.Reset();
            LightSensorVoltageSampler.Reset();
            TemperatureSampler.Reset();
            HumiditySampler.Reset();
        }
    }
}
