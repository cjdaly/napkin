/*
  xadow.h
  2013 Copyright (c) Seeed Technology Inc.  All right reserved.

  Author:Loovee
  2013-6-17
 
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

#ifndef __XADOW_H__
#define __XADOW_H__

#include "xadowDfs.h"
#include "debug_x.h"
#include "Sleep_x.h"

class xadow{

private:

    int getAnalog(int pin);
    Sleep sleep;

public:

    void init();
    float getBatVol();                                  // read voltage of battery
    unsigned char getChrgState();                       // get charge state: 
    void pwrDown(unsigned long tSleep);                 // power down, tSleep ms
    void wakeUp();                                      // wake up
    void greenLed(unsigned char state);                 // green Led drive
    void redLed(unsigned char state);                   // red led drive
};

extern xadow Xadow;

#endif

/*********************************************************************************************************
  END FILE
*********************************************************************************************************/