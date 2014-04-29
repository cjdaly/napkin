/*-----------------------------------------------------------------------------------
** demo of read state of charge
** loovee 2013-6-19
** https://github.com/reeedstudio/xadow
**
** This library is free software; you can redistribute it and/or
** modify it under the terms of the GNU Lesser General Public
** License as published by the Free Software Foundation; either
** version 2.1 of the License, or (at your option) any later version.
**
** This library is distributed in the hope that it will be useful,
** but WITHOUT ANY WARRANTY; without even the implied warranty of
** MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
** Lesser General Public License for more details.
**
** You should have received a copy of the GNU Lesser General Public
** License along with this library; if not, write to the Free Software
** Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
**--------------------------------------------------------------------------------*/
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
    unsigned char tmp = Xadow.getChrgState();
    
    switch(tmp)
    {
        case NOCHARGE:
        
        cout << "no charge" << endl;
        
        break;
        
        case CHARGING:
        
        cout << "charging...." << endl;
        break;
        
        case CHARGDONE:
        
        cout << "charge done!" << endl;
        break;
        
        default:
        ;
    }
    
    delay(1000);
}

/*********************************************************************************************************
  END FILE
*********************************************************************************************************/