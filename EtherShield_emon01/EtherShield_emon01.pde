//--------------------------------------------------------
// EtherShield examples: emon01
// An basic example of posting data to a local webserver running emoncms
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

static uint8_t mymac[6] = { 0x54,0x55,0x38,0x12,0x01,0x23};
static uint8_t myip[4] =    { 192,168,1,73 };
static uint8_t server[4] =  { 192,168,1,5 };
static uint8_t gateway[4] = { 192,168,1,1 };

EtherShield es=EtherShield();

#define BUFFER_SIZE 500
static uint8_t buf[BUFFER_SIZE+1];
uint16_t dat_p;
int plen = 0;

unsigned long lastupdate;

void setup()
{
  Serial.begin(9600);
  Serial.println("EtherShield_emon01");
  
  es.ES_enc28j60SpiInit();
  es.ES_enc28j60Init(mymac);
  es.ES_init_ip_arp_udp_tcp(mymac, myip, 80);
  es.ES_client_set_gwip(gateway);
  es.ES_client_set_wwwip(server);
}

void browserresult_callback(uint8_t statuscode,uint16_t datapos) {}

void loop()
{
  plen = es.ES_enc28j60PacketReceive(BUFFER_SIZE, buf);
  dat_p=es.ES_packetloop_icmp_tcp(buf,plen);
  
  if (dat_p==0)
  {
     if ((millis()-lastupdate)>5000)
     {
       lastupdate = millis(); Serial.println("sending");
       
       es.ES_client_browse_url(PSTR(""),"/emoncms/api/api.php?json={newtest:41.5}", PSTR(""), &browserresult_callback);
     }
  }
  
}
