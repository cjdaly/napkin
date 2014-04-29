/*
  xadowDfs.h
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

#ifndef __XADOWDFS_H__
#define __XADOWDFS_H__

#define __Debug             1

// PIN define
#define PINBAT              A4
#define PINCHRGDONE         A3
#define PINCHRGING          A2

// about charge
#define CHRGbit 0x10
#define DONEbit 0x20
#define CHRGdir DDRF
#define DONEdir DDRF
#define CHRGpin PINF
#define DONEpin PINF
#define CHRGport PORTF
#define DONEport PORTF

// led pin or reg
#define rLEDbit  0x01
#define gLEDbit  0x80
#define rLEDdir  DDRB
#define gLEDdir  DDRB
#define rLEDport PORTB
#define gLEDport PORTB
#define rLEDpin  PINB
#define gLEDpin  PINB

// charge state
#define NOCHARGE            0
#define CHARGING            1
#define CHARGDONE           2

// led state
#define LEDON               1               // led on
#define LEDOFF              2               // led off
#define LEDCHG              3               // change led state

#endif
/*********************************************************************************************************
  END FILE
*********************************************************************************************************/