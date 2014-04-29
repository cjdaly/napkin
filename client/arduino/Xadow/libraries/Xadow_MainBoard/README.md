Xadow - Main Board
---------------------------------------------------------

[![Xadow - Main Board](http://www.seeedstudio.com/depot/images/product/Xadow%20Main%20Board.jpg)](http://www.seeedstudio.com/depot/xadow-main-board-p-1524.html?cPath=6_7)


The module is a microcontroller board based on the controller ATmega32U4 with 32k flash. Board can be powered either from the USB connection or a Lithium battery(80mA output current). And the board can charge for the Lithium battery through the USB port. The USB port on the board can be also used for upload program.When you upload program to the Xadow Main Board as you do with other Arduino boards, please select "Arduino Leonardo " from the Tools > Board menu. It is a indispensable part in the Xadow Kit.


<br>

# Usage:
This library is written for manage Xadow, include :

* user led
* charge state read
* battery voltage read
* sleep mode operation


you can use the folowing function, it's useful in some way.

### Initialization
	void init();

### Get Voltage of battery
	float getBatVol();

### Get Charge State
	unsigned char getChrgState(); 

it'll return the folowing value:

	#define NOCHARGE            0
	#define CHARGING            1
	#define CHARGDONE           2
		
### User Led
there'are two user led that you can use, a green one and a read one.

	void greenLed(unsigned char state);             // green Led drive
	void redLed(unsigned char state);               // red led drive
		
about the input value, you can use:

	#define LEDON               1               	// led on
	#define LEDOFF              2               	// led off
	#define LEDCHG              3               	// change led state		

### Power Manage
of curse, sometimes you want your xadow goto sleep to save some power, then you can use this function:

	void pwrDown(unsigned long tSleep);             // power down, tSleep ms

it'll let your xadow goto sleep for sSleep ms, then it'll wake, you shourld use the folowing function to awake it:

	void wakeUp();                                  // wake up


APPLICATION
-------------------------------------------------------------------------------------------------------------------
there'are some application here, for more applicaton you can refer to examples

### POWER DOWN MODE

	#include <Wire.h>

	#include "xadow.h"

	void setup()
	{

		Serial.begin(115200);
		// while(!Serial);
		Xadow.init();
			
		delay(2000);
		cout << "init over" << endl;
	}

	void loop()
	{
		cout << "begin to sleep for 1s" << endl;
		Xadow.pwrDown(1000);                        // sleep for 1000ms
		Xadow.wakeUp();                             // wake up
		cout << "wake up" << endl;
		delay(500);                                 // delay 500 ms
	}


### READ VOLTAGE OF BATTERY

	#include <Wire.h>

	#include "xadow.h"

	void setup()
	{
		Serial.begin(115200);
			
		while(!Serial);
		Xadow.init();
			
		delay(1000);
		cout << "init over" << endl;
	}

	void loop()
	{
		cout << "vol: " << Xadow.getBatVol() << endl;
		delay(500);
	}

### USER LED

	#include <Wire.h>

	#include "xadow.h"

	void setup()
	{
		Xadow.init();
	}


	void loop()
	{
		Xadow.greenLed(LEDON);					// green led on
		Xadow.redLed(LEDOFF);                   // red led off
		delay(200);
		Xadow.redLed(LEDON);                	// red led on
		Xadow.greenLed(LEDOFF);              	// green led off
		delay(200);
	}
		


<br>
For more information, please refer to [wiki page](http://www.seeedstudio.com/wiki/Xadow_Main_Board).


----


This software is written by loovee [luweicong@seeedstudio.com](luweicong@seeedstudio.com "luweicong@seeedstudio.com") for seeed studio<br>
and is licensed under [The MIT License](http://opensource.org/licenses/mit-license.php). Check License.txt for more information.<br>

Contributing to this software is warmly welcomed. You can do this basically by<br>
[forking](https://help.github.com/articles/fork-a-repo), committing modifications and then [pulling requests](https://help.github.com/articles/using-pull-requests) (follow the links above<br>
for operating guide). Adding change log and your contact into file header is encouraged.<br>
Thanks for your contribution.

Seeed Studio is an open hardware facilitation company based in Shenzhen, China. <br>
Benefiting from local manufacture power and convenient global logistic system, <br>
we integrate resources to serve new era of innovation. Seeed also works with <br>
global distributors and partners to push open hardware movement.<br>


[![Analytics](https://ga-beacon.appspot.com/UA-46589105-3/Xadow_MainBoard)](https://github.com/igrigorik/ga-beacon)
