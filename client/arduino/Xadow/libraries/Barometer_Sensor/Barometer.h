/*
  Barometer library V1.0
  2010 Copyright (c) Seeed Technology Inc.  All right reserved.
 
  Original Author: LG
  
  This library is free software; you can redistribute it and/or
  modify it under the terms of the GNU Lesser General Public
  License as published by the Free Software Foundation; either
  version 2.1 of the License, or (at your option) any later version.

  This library is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
  Lesser General Public License for more details.

  You should have received a copy of the GNU Lesser General Public
  License along with this library; if not, write to the Free Software
  Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
*/
#ifndef __BAROMETER_H__
#define __BAROMETER_H__

#include <Arduino.h>
#include <Wire.h>

const unsigned char OSS = 0;
#define BMP085_ADDRESS 0x77
class Barometer
{
public: 
  void init(void);
  long PressureCompensate;
  float bmp085GetTemperature(unsigned int ut);
  long bmp085GetPressure(unsigned long up);
  float calcAltitude(float pressure);
  unsigned int bmp085ReadUT(void);
  unsigned long bmp085ReadUP(void);
 
private:
  int ac1;
  int ac2;
  int ac3;
  unsigned int ac4;
  unsigned int ac5;
  unsigned int ac6;
  int b1;
  int b2;
  int mb;
  int mc;
  int md;
  char bmp085Read(unsigned char address);
  int bmp085ReadInt(unsigned char address);
  void writeRegister(int deviceAddress, byte address, byte val);
  int readRegister(int deviceAddress, byte address);
};

#endif
