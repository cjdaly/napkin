####
# Copyright (c) 2014 Chris J Daly (github user cjdaly)
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html
#
# Contributors:
#   cjdaly - initial API and implementation
####

#include <Wire.h>
#include <SeeedOLED.h>
#include <Barometer.h>
#include <xadow.h>
#include <SoftwareSerial.h>

Barometer _barometer;
SoftwareSerial _serialPort(0, 1);

void setup(){
  Wire.begin();
  
  Xadow.init();
  Xadow.greenLed(LEDON);
  
  _barometer.init();
  
  _serialPort.begin(9600);
  _serialPort.println("Hello, world?");
  
  SeeedOled.init();  //initialze SEEED OLED display
  DDRB|=0x21;        //digital pin 8, LED glow indicates Film properly Connected .
  PORTB |= 0x21;

  SeeedOled.clearDisplay();
  SeeedOled.setNormalDisplay();
  SeeedOled.setPageMode();
  SeeedOled.deactivateScroll();

  delay(500);
  Xadow.greenLed(LEDOFF);
}

void clearOled() {
  for (int line = 0; line < 8; line++) { 
    SeeedOled.setTextXY(line,0);
    SeeedOled.putString("                ");
  }
}

void loop()
{
  Xadow.greenLed(LEDON);
  
  float temperature = _barometer.bmp085GetTemperature(_barometer.bmp085ReadUT());
  float raw_pressure = (float)_barometer.bmp085GetPressure(_barometer.bmp085ReadUP());
  float altitude = _barometer.calcAltitude(raw_pressure);
  float pressure = raw_pressure / 101.325;
  
  _serialPort.print("sensor.barometer.temperature~f=");
  _serialPort.print(temperature);
  _serialPort.println();

  _serialPort.print("sensor.barometer.pressure.raw~f=");
  _serialPort.print(raw_pressure);
  _serialPort.println();

  _serialPort.print("sensor.barometer.pressure~f=");
  _serialPort.print(pressure, 4);
  _serialPort.println();

  _serialPort.print("sensor.barometer.altitude~f=");
  _serialPort.print(altitude);
  _serialPort.println();

  clearOled();
  Xadow.greenLed(LEDOFF);

  char buffer[16];

  SeeedOled.setTextXY(0,0);
  SeeedOled.putString("Temp: ");
  dtostrf(temperature, 5, 2, buffer);
  SeeedOled.putString(buffer);
  //SeeedOled.putFloat(temperature, 2);

  SeeedOled.setTextXY(2,0);
  SeeedOled.putString("Pres: ");
  dtostrf(raw_pressure, 10, 2, buffer);
  SeeedOled.putString(buffer);
  //SeeedOled.putFloat(raw_pressure, 2);

  SeeedOled.setTextXY(4,0);
  SeeedOled.putString("Atm: ");
  dtostrf(pressure, 8, 3, buffer);
  SeeedOled.putString(buffer);
  //SeeedOled.putFloat(pressure, 4);

  SeeedOled.setTextXY(6,0);
  SeeedOled.putString("Alt: ");
  dtostrf(altitude, 8, 2, buffer);
  SeeedOled.putString(buffer);
  //SeeedOled.putFloat(altitude, 2);

  /////
  
  delay(5000);
}
