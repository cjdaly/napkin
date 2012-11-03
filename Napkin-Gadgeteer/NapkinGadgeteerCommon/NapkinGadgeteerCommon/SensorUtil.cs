using System;
using Microsoft.SPOT;

using GT = Gadgeteer;
using GTM = Gadgeteer.Modules;

using NapkinCommon;

namespace NapkinGadgeteerCommon
{
    namespace SensorUtil
    {

        public class ButtonSampler
        {
            private LongSampler _buttonPressedSampler;
            private LongSampler _buttonReleasedSampler;

            public ButtonSampler(GTM.GHIElectronics.Button button, SamplerBag samplers)
            {
                _buttonPressedSampler = new LongSampler(null, "button_pressed");
                samplers.Add(_buttonPressedSampler);
                _buttonReleasedSampler = new LongSampler(null, "button_released");
                samplers.Add(_buttonReleasedSampler);

                button.ButtonPressed += new GTM.GHIElectronics.Button.ButtonEventHandler(button_ButtonPressed);
                button.ButtonReleased += new GTM.GHIElectronics.Button.ButtonEventHandler(button_ButtonReleased);
            }

            void button_ButtonPressed(GTM.GHIElectronics.Button sender, GTM.GHIElectronics.Button.ButtonState state)
            {
                _buttonPressedSampler.Sample(1);
            }
            void button_ButtonReleased(GTM.GHIElectronics.Button sender, GTM.GHIElectronics.Button.ButtonState state)
            {
                _buttonReleasedSampler.Sample(1);
            }
        }


        public class LightSensorSampler
        {
            private DoubleSampler _lightSensorPercentageSampler;
            private DoubleSampler _lightSensorVoltageSampler;
            
            private GTM.GHIElectronics.LightSensor _lightSensor;

            public LightSensorSampler(GTM.GHIElectronics.LightSensor lightSensor, SamplerBag samplers)
            {
                _lightSensor = lightSensor;

                _lightSensorPercentageSampler = new DoubleSampler(SampleLightSensorPercentage, "light_sensor_percentage");
                samplers.Add(_lightSensorPercentageSampler);
                _lightSensorVoltageSampler = new DoubleSampler(SampleLightSensorVoltage, "light_sensor_voltage");
                samplers.Add(_lightSensorVoltageSampler);
            }

            double SampleLightSensorPercentage()
            {
                return _lightSensor.ReadLightSensorPercentage();
            }

            double SampleLightSensorVoltage()
            {
                return _lightSensor.ReadLightSensorVoltage();
            }
        }

        public class BarometerSampler
        {
            private GTM.Seeed.Barometer _barometer;

            private DoubleSampler _pressureSampler;
            private DoubleSampler _temperatureSampler;

            public BarometerSampler(GTM.Seeed.Barometer barometer, SamplerBag samplers)
            {
                _barometer = barometer;

                _pressureSampler = new DoubleSampler(null, "barometer_pressure");
                samplers.Add(_pressureSampler);

                _temperatureSampler = new DoubleSampler(null, "barometer_temperature");
                samplers.Add(_temperatureSampler);

                _barometer.MeasurementComplete += new GTM.Seeed.Barometer.MeasurementCompleteEventHandler(_barometer_MeasurementComplete);
            }

            void _barometer_MeasurementComplete(GTM.Seeed.Barometer sender, GTM.Seeed.Barometer.SensorData sensorData)
            {
                _pressureSampler.Sample(sensorData.Pressure);
                _temperatureSampler.Sample(sensorData.Temperature);
            }
        }

    }
}
