
//--------------------------------------------------------------------------------------
// One wire temperature example
//--------------------------------------------
// Setup to detect 3 temperature sensors
// and to reconnect to them if they disconnect
//
// Licence: GNU GPL openenergymonitor.org V3
//--------------------------------------------------------------------------------------

#include <OneWire.h>
#include <DallasTemperature.h>


// Data wire is plugged into port 2 on the Arduino
#define ONE_WIRE_BUS 3

// Setup a oneWire instance to communicate with any OneWire devices (not just Maxim/Dallas temperature ICs)
OneWire oneWire(ONE_WIRE_BUS);

// Pass our oneWire reference to Dallas Temperature. 
DallasTemperature sensors(&oneWire);

// arrays to hold device address
DeviceAddress ta,tb,tc;


void setup(void)
{
  // start serial port
  Serial.begin(9600);

  sensors.begin();
  
  sensors.getAddress(ta, 0); 
  sensors.getAddress(tb, 1); 
  sensors.getAddress(tc, 2); 
  
  delay(100);
  
  sensors.setResolution(ta, 12);
  sensors.setResolution(tb, 12);
  sensors.setResolution(tc, 12);
  
  delay(100);
}

void loop(void)
{ 
  sensors.requestTemperatures(); // Send the command to get temperatures
 
  double tempa = sensors.getTempC(ta);
  double tempb = sensors.getTempC(tb);
  double tempc = sensors.getTempC(tc);
  
  if (tempa == DEVICE_DISCONNECTED)
  {
    sensors.begin();
    sensors.getAddress(ta, 0); 
    sensors.getAddress(tb, 1); 
    sensors.getAddress(tc, 2); 
    Serial.println("problem");
  }

  Serial.print(tempa);
  Serial.print(' ');
  Serial.print(tempb);
  Serial.print(' ');
  Serial.println(tempc); 
}

