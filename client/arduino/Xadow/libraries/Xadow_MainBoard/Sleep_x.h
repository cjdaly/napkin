/************************************************************************************
 *
 *     Name    : Sleep_n0m1.h
 *     Author  : Noah Shibley / NoMi Design
 *     Date    : July 10th 2011
 *     Version : 0.1
 *     Notes   : Some of this code comes from "Cloudy" on the arduino forum
 *              http://www.arduino.cc/cgi-bin/yabb2/YaBB.pl?num=1292898715
 *
 *    Modify: loovee
 *            2013-6-20  
 *
 *     Copyright (c) 2012 NoMi Design (http://n0m1.com) All right reserved.
 *
 *     This file is part of Triggertrap. See Triggertrap.com for more information.
 *
 *             Triggertrap is free software: you can redistribute it and/or modify
 *             it under the terms of the GNU General Public License as published by
 *             the Free Software Foundation, either version 3 of the License, or
 *             (at your option) any later version.
 *
 *             Triggertrap is distributed in the hope that it will be useful,
 *             but WITHOUT ANY WARRANTY; without even the implied warranty of
 *             MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *             GNU General Public License for more details.
 *
 *             You should have received a copy of the GNU General Public License
 *             along with Triggertrap.  If not, see <http://www.gnu.org/licenses/>.
 *
 ***********************************************************************************/

#ifndef __SLEEP_X_H__
#define __SLEEP_X_H__

#include <avr/sleep.h>
#include <avr/wdt.h>
#include <Arduino.h>

// for sleep
#if defined(__AVR_ATmega32U4__)
#define power_adc_enable()      (PRR0 &= (uint8_t)~(1 << PRADC))
#define power_adc_disable()     (PRR0 |= (uint8_t)(1 << PRADC))

#define power_usart0_enable()   (PRR0 &= (uint8_t)~(1 << PRUSART0))
#define power_usart0_disable()  (PRR0 |= (uint8_t)(1 << PRUSART0))

#define power_spi_enable()      (PRR0 &= (uint8_t)~(1 << PRSPI))
#define power_spi_disable()     (PRR0 |= (uint8_t)(1 << PRSPI))

#define power_twi_enable()      (PRR0 &= (uint8_t)~(1 << PRTWI))
#define power_twi_disable()     (PRR0 |= (uint8_t)(1 << PRTWI))

#define power_timer0_enable()   (PRR0 &= (uint8_t)~(1 << PRTIM0))
#define power_timer0_disable()  (PRR0 |= (uint8_t)(1 << PRTIM0))

#define power_timer1_enable()   (PRR0 &= (uint8_t)~(1 << PRTIM1))
#define power_timer1_disable()  (PRR0 |= (uint8_t)(1 << PRTIM1))

#define power_timer2_enable()   (PRR0 &= (uint8_t)~(1 << PRTIM2))
#define power_timer2_disable()  (PRR0 |= (uint8_t)(1 << PRTIM2))

#define power_timer3_enable()   (PRR1 &= (uint8_t)~(1 << PRTIM3))
#define power_timer3_disable()  (PRR1 |= (uint8_t)(1 << PRTIM3))

#define power_usart1_enable()   (PRR1 &= (uint8_t)~(1 << PRUSART1))
#define power_usart1_disable()  (PRR1 |= (uint8_t)(1 << PRUSART1))

#define power_usb_enable()      (PRR1 &= (uint8_t)~(1 << PRUSB))
#define power_usb_disable()     (PRR1 |= (uint8_t)(1 << PRUSB))

#endif

extern "C" void WDT_vect(void) __attribute__ ((signal));
extern "C" void sleepHandler(void) __attribute__ ((signal));

class Sleep {

    public:

    friend void WDT_vect(void);
    friend void sleepHandler(void);

    Sleep();

    /*
    modes of sleep
    SLEEP_MODE_IDLE
    SLEEP_MODE_ADC
    SLEEP_MODE_PWR_SAVE
    SLEEP_MODE_EXT_STANDBY
    SLEEP_MODE_STANDBY
    SLEEP_MODE_PWR_DOWN
    */

    void idleMode() { setSleepMode(SLEEP_MODE_IDLE);}
    void adcMode() {setSleepMode(SLEEP_MODE_ADC);}
    void pwrSaveMode() {setSleepMode(SLEEP_MODE_PWR_SAVE);}
    void extStandbyMode(){setSleepMode(SLEEP_MODE_EXT_STANDBY);}
    void standbyMode(){setSleepMode(SLEEP_MODE_STANDBY);}
    void pwrDownMode(){setSleepMode(SLEEP_MODE_PWR_DOWN);}

    //WatchDog Sleep Functions: Sleep for a specfic length of time
    void sleepDelay(unsigned long sleepTime);
    void sleepDelay(unsigned long sleepTime,boolean &abortCycle);
    void setCalibrationInterval(int interval){ sleepCycleInterval = interval; }

    //Interrupt Sleep Function: Sleep till something interrupts sleep
    void sleepInterrupt(int interrupt,int mode);

    private:

    int sleepMode_;
    unsigned long timeSleep;
    float calibv;
    volatile byte isrcalled;
    static Sleep* pSleep; //static ptr to Sleep class for the ISR
    int sleepCycleCount;
    int sleepCycleInterval;

    void setSleepMode(int mode);
    void WDT_Off();
    void WDT_On(byte psMask);
    int sleepWDT(unsigned long remainTime,boolean &abortCycle);
    void calibrateTime(unsigned long sleepTime,boolean &abortCycle); //calibrate the time keeping difference between WDT and Timer0
    unsigned long WDTMillis();    // Estimated millis is real clock + calibrated sleep time

};

#endif