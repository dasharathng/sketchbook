//--------------------------------------------------------
// EtherShield examples: emon03
// An basic example of posting data to a local webserver running emoncms
// with browseresult_callback
// With added simple code layer:
//
// - ethernet_setup(mac,ip,gateway,server,port)
// - ethernet_ready() - check this before sending
// - ethernet_send(domainname, api arguments);
// 
// All hard ethershield library building work done by: Andrew D Lindsay
// http://blog.thiseldo.co.uk
//
// OpenEnergyMonitor.org
// Example by Trystan Lea
//
// Licence: GPL GNU v3
//--------------------------------------------------------

#include <EtherShield.h>

byte mac[6] =     { 0x54,0x55,0x38,0x12,0x01,0x23};
byte ip[4] =      { 192,168,1,73 };
byte server[4] =  { 192,168,1,5 };
byte gateway[4] = { 192,168,1,1 };

unsigned long lastupdate;

void setup()
{
  Serial.begin(9600);
  Serial.println("EtherShield_emon03");
  
  ethernet_setup(mac,ip,gateway,server,80);
}

void loop()
{
  if (ethernet_ready() && (millis()-lastupdate)>5000)
  {
    lastupdate = millis(); Serial.println("sending");
    
    // If your sending to a shared server add the domain name inside the PSTR("") brackets
    ethernet_send(PSTR(""),"/emoncms/api/api.php?json={newtest:41.5}");
  }
}


