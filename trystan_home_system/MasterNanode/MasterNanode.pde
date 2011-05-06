//--------------------------------------------------------------------------------------
// MASTER ETHERNET RELAY UNIT for relaying data from PV unit and SHW Emon unit
// Last updated 6 May 2011

// Author: Trystan Lea
// Licence: GNU GPL openenergymonitor.org V3
//--------------------------------------------------------------------------------------

//-------------------------------------------------------------------------------------
// Do this sequestially:

// 1) Select PV unit and read:
//     - register 26 : current A
//     - register 27 : current B
//     - register 28 : voltage

// 2) Select SHW+emon unit and read:
//     - register 26 : COL
//     - register 27 : CYLB
//     - register 28 : CYLT
//     - register 29 : pumpState
//     - register 30 : realPower
//     - register 31 : powerFactor
// calculate wh increment from realPower value.

// Do this every 10 seconds:

// 1) Create a JSON string with all the above variables in it.

// 2) Send the string via ethernet to the logging and visualisation web app
//--------------------------------------------------------------------------------------

#include <OneWire.h>
#include <DallasTemperature.h>

// Data wire is plugged into port 2 on the Arduino
#define ONE_WIRE_BUS 6

// Setup a oneWire instance to communicate with any OneWire devices (not just Maxim/Dallas temperature ICs)
OneWire oneWire(ONE_WIRE_BUS);

// Pass our oneWire reference to Dallas Temperature. 
DallasTemperature sensors(&oneWire);

// arrays to hold device address
DeviceAddress ta,tb,tc;

//--------------------------------------------------------------------------------------
// ETHERNET
//--------------------------------------------------------------------------------------
#include "EtherShield.h"

byte mac[] = {0x54,0x52,0x58,0x10,0x00,0x18};         //Ethernet shield mac address
byte ip[] = {192,168,1,25};                            //Ethernet shield ip address
byte gateway[] = {192,168,1,1};                       //Gateway ip
byte server[] = {192, 168, 1, 5};
#define port 80

char str[240];

//--------------------------------------------------------------------------------------
// NETWORK 
//--------------------------------------------------------------------------------------
#include "Network.h";                                 //Load Network Library
Network net;                                          //Instance of Network

int pv = 43;                                          //PV unit ID
int house = 11;                                       //House unit ID

//--------------------------------------------------------------------------------------
// Variables to be transfered
//--------------------------------------------------------------------------------------
  double currentA=0,
         currentB=0,
         voltage=0,
         COL=0,
         CYLB=0,
         CYLT=0,
         pumpState=0,
         realPower=0,
         powerFactor=0;
         
double whInc;                                          //energy calc from realPower
unsigned long tmillis, lmillis, lastupdate;

//--------------------------------------------------------------------------------------
// Laptop serial connection
//--------------------------------------------------------------------------------------
#include <NewSoftSerial.h>
NewSoftSerial laptop(3, 4);

//--------------------------------------------------------------------------------------
// SETUP
//--------------------------------------------------------------------------------------
void setup()
{
  Serial.begin(9600);
  laptop.begin(9600);
  
  
    sensors.getAddress(ta, 0); 
  sensors.getAddress(tb, 1); 
  sensors.getAddress(tc, 2); 
  
  sensors.setResolution(ta, 12);
  sensors.setResolution(tb, 12);
  sensors.setResolution(tc, 12);
  
  client_setup(mac,ip,gateway,server);    //Setup ethernet client
  client_timeout(2,2000);                 //Set timeout variables
}

//--------------------------------------------------------------------------------------
// MAIN LOOP
//--------------------------------------------------------------------------------------
void loop()
{
  
  //---------------------------------------------------------------------------------------------------------------------------------------------
  // Select PV unit
  //---------------------------------------------------------------------------------------------
  if (net.open(pv))
  {
   laptop.print("net open : r,26,27,28 : ");                   //Verbose output to serial monitor
   //To send multi arg read:  
   Serial.println("r,26,27,28");                               //Send read command to unit
   if (net.waitForData())                                      //wait until reply is recieved:
   {
     currentA = net.readArgD();                                //read returned argument register 26
     currentB = net.readArgD();                                //read returned argument register 27
     voltage = net.readArgD();                                 //read returned argument register 28
     
     Serial.println("q");                                      //Close connection with pv unit
     
     //---------------------------------------------------------------------------------------------
     // Print variables to serial monitor
     //---------------------------------------------------------------------------------------------
     laptop.print(currentA); laptop.print(' ');
     laptop.print(currentB); laptop.print(' ');
     laptop.println(voltage);
     
   }
  }
  else { laptop.println("could not open net"); }
  
  //----------------------------------------------------------------------------------------------------------------------------------------------
  // Select Solar Hot water + energy monitor unit in house-
  //---------------------------------------------------------------------------------------------
  if (net.open(house))
  {
    laptop.print("house open : r,26,27,28,29,30,31 : ");       //Verbose output to serial monitor

    Serial.println("r,26,27,28,29,30,31");                     //Send read command to unit
    if (net.waitForData())                                     //wait until reply is recieved:
    {
      COL = net.readArgD();                                    //read returned argument register 26
      CYLB = net.readArgD();                                   //read returned argument register 27
      CYLT = net.readArgD();                                   //read returned argument register 28
      pumpState = net.readArgD();                              //read returned argument register 29
      realPower = net.readArgD();                              //read returned argument register 30
      powerFactor = net.readArgD();                            //read returned argument register 31
      
      Serial.println("q");                                     //Close connection with house unit
   
      //---------------------------------------------------------------------------------------------
      // wh increment calculation from realPower value
      //---------------------------------------------------------------------------------------------
      lmillis = tmillis;                                       //timing to determine amount of time since last call
      tmillis= millis();                                       
      whInc += (realPower * (tmillis-lmillis)) / 3600000.0;    //energy calc
   
      //---------------------------------------------------------------------------------------------
      // Print variables to serial monitor
      //---------------------------------------------------------------------------------------------
      laptop.print(COL);   laptop.print(' ');
      laptop.print(CYLB);  laptop.print(' ');
      laptop.print(CYLT);  laptop.print(' ');
      laptop.print(pumpState);  laptop.print(' ');
      laptop.print(realPower);  laptop.print(' ');
      laptop.println(powerFactor);
      
    }
  }
  else { laptop.println("could not open house"); }

   //----------------------------------------------------------------------------------------------------------------------------------------------
   // Ethernet posting
   //---------------------------------------------------------------------------------------------
   if ((millis()-lastupdate)>5000)  //Every 10 seconds
   {
     lastupdate = millis();
     
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
        
         tempa = sensors.getTempC(ta);
         tempb = sensors.getTempC(tb);
         tempc = sensors.getTempC(tc);
       }
       
       laptop.println(tempc);

      strcpy(str,"/emoncms/api/api.php?json=");                //URL domain only needed if shared server

      //-------------------------------------------------------------------------------------------
      // Construct JSON string
      //-------------------------------------------------------------------------------------------
      srtJSON(str);                                  
        addJSON(str,"ogo_currentA",  currentA); 
        addJSON(str,"ogo_currentB",  currentB); 
        addJSON(str,"ogo_voltage",  voltage);   
        addJSON(str,"ogo_COL",  COL);  
        addJSON(str,"ogo_CYLB",  CYLB);  
        addJSON(str,"ogo_CYLT",  CYLT);
        addJSON(str,"ogo_pump",  pumpState);
        addJSON(str,"ogo_realPower",  realPower);
        addJSON(str,"ogo_wh",  whInc);
        addJSON(str,"ogo_ta",  tempa);
        addJSON(str,"ogo_tb",  tempb);
        addJSON(str,"ogo_tc",  tempc);
      endJSON(str);
    
    //-------------------------------------------------------------------------------------------
    // Send the string to the server
    //-------------------------------------------------------------------------------------------
    if (ethernet_send(PSTR(""),str))                     //Try to send the string
    { laptop.println("Data sent");  whInc = 0;} 
    else
    { laptop.println("Failed to send"); }
  
   }
 
}

