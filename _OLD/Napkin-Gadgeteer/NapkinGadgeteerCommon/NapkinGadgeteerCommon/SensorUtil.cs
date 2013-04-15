/****
 * Copyright (c) 2013 Chris J Daly (github user cjdaly)
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 * 
 * Contributors:
 *   cjdaly - initial API and implementation
 ****/
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

        public class TemperatureHumiditySampler
        {
            private Gadgeteer.Modules.Seeed.TemperatureHumidity _temperatureHumidity;

            private DoubleSampler _temperatureSampler;
            private DoubleSampler _humiditySampler;

            public TemperatureHumiditySampler(Gadgeteer.Modules.Seeed.TemperatureHumidity temperatureHumidity, SamplerBag samplers)
            {
                _temperatureHumidity = temperatureHumidity;

                _temperatureSampler = new DoubleSampler(null, "temperature");
                samplers.Add(_temperatureSampler);

                _humiditySampler = new DoubleSampler(null, "humidity");
                samplers.Add(_humiditySampler);

                _temperatureHumidity.MeasurementComplete += new GTM.Seeed.TemperatureHumidity.MeasurementCompleteEventHandler(_temperatureHumidity_MeasurementComplete);
            }

            void _temperatureHumidity_MeasurementComplete(GTM.Seeed.TemperatureHumidity sender, double temperature, double relativeHumidity)
            {
                _temperatureSampler.Sample(temperature);
                _humiditySampler.Sample(relativeHumidity);
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


        public class AnalogSampler
        {
            private readonly string _id;
            private GT.Interfaces.AnalogInput _analogInputPin3;
            private GT.Interfaces.AnalogInput _analogInputPin4;
            private GT.Interfaces.AnalogInput _analogInputPin5;

            private DoubleSampler _pin3ProportionSampler;
            private DoubleSampler _pin4ProportionSampler;
            private DoubleSampler _pin5ProportionSampler;

            public AnalogSampler(string id, GT.Socket socket_A, SamplerBag samplers)
            {
                _id = id;
                _analogInputPin3 = new GT.Interfaces.AnalogInput(socket_A, GT.Socket.Pin.Three, null);
                _analogInputPin4 = new GT.Interfaces.AnalogInput(socket_A, GT.Socket.Pin.Four, null);
                _analogInputPin5 = new GT.Interfaces.AnalogInput(socket_A, GT.Socket.Pin.Five, null);

                _analogInputPin3.Active = true;
                _analogInputPin4.Active = true;
                _analogInputPin5.Active = true;

                _pin3ProportionSampler = new DoubleSampler(null, _id + "_pin3_proportion");
                samplers.Add(_pin3ProportionSampler);

                _pin4ProportionSampler = new DoubleSampler(null, _id + "_pin4_proportion");
                samplers.Add(_pin4ProportionSampler);

                _pin5ProportionSampler = new DoubleSampler(null, _id + "_pin5_proportion");
                samplers.Add(_pin5ProportionSampler);
            }

            public void Sample()
            {   
                _pin3ProportionSampler.Sample(_analogInputPin3.ReadProportion());
                _pin4ProportionSampler.Sample(_analogInputPin4.ReadProportion());
                _pin5ProportionSampler.Sample(_analogInputPin5.ReadProportion());
            }
        }

    }
}
