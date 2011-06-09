//--------------------------------------------------------
// EtherShield examples: dhcp 2
// An basic example of posting data to a local webserver running emoncms
// with browseresult_callback
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
static uint8_t myip[4] =      { 0,0,0,0 };
static uint8_t mynetmask[4] = { 0,0,0,0 };
static uint8_t websrvip[4] =  { 192,168,1,5 };
static uint8_t gwip[4] =      { 0,0,0,0 };
static uint8_t dnsip[4] =     { 0,0,0,0 };
static uint8_t dhcpsvrip[4] = { 0,0,0,0 };

#define PORT 80                   

EtherShield es=EtherShield();

#define BUFFER_SIZE 500
static uint8_t buf[BUFFER_SIZE+1];
uint16_t dat_p;
int plen = 0;

unsigned long lastupdate;

void setup()
{
  Serial.begin(9600);
  Serial.println("EtherShield_emon02");
  
  es.ES_enc28j60SpiInit();
  es.ES_enc28j60Init(mymac);
  es.ES_client_set_wwwip(websrvip);  // target web server

}

void browserresult_callback(uint8_t statuscode,uint16_t datapos) 
{
  if (datapos != 0)
  {
    uint16_t pos = datapos;
    while (buf[pos])
    {
      Serial.print(buf[pos]);
      pos++;
    }
  }
}

void printIP( uint8_t *buf ) {
  for( int i = 0; i < 4; i++ ) {
    Serial.print( buf[i], DEC );
    if( i<3 )
      Serial.print( "." );
  }
}

void loop()
{

  
  if (es.ES_dhcp_state() == DHCP_STATE_OK ) 
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
  else
  {
    long lastDnsRequest = 0L;
    long lastDhcpRequest = millis();
    uint8_t dhcpState = 0;
    boolean gotIp = false;
    
    es.ES_dhcp_start( buf, mymac, myip, mynetmask,gwip, dnsip, dhcpsvrip );    
    while( !gotIp ) 
    {
      //dns_state=DNS_STATE_INIT;
      
      plen = es.ES_enc28j60PacketReceive(BUFFER_SIZE, buf);
      dat_p=es.ES_packetloop_icmp_tcp(buf,plen);
      
      if(dat_p==0) {
        
        int retstat = es.ES_check_for_dhcp_answer( buf, plen);
        dhcpState = es.ES_dhcp_state();
        
        // we are idle here
        if( dhcpState != DHCP_STATE_OK ) {
          if (millis() > (lastDhcpRequest + 10000L) ){
            lastDhcpRequest = millis();
            // send dhcp
            #ifdef DEBUG
            Serial.println("Sending DHCP Request");
            #endif
            es.ES_dhcp_start( buf, mymac, myip, mynetmask,gwip, dnsip, dhcpsvrip );
          }
        } 
        else {
          if( !gotIp ) {

            // Display the results:
            Serial.print( "My IP: " );
            printIP( myip );
            Serial.println();

            Serial.print( "Netmask: " );
            printIP( mynetmask );
            Serial.println();

            Serial.print( "DNS IP: " );
            printIP( dnsip );
            Serial.println();

            Serial.print( "GW IP: " );
            printIP( gwip );
            Serial.println();

            gotIp = true;

            //init the ethernet/ip layer:
            es.ES_init_ip_arp_udp_tcp(mymac, myip, PORT);

            // Set the Router IP
            es.ES_client_set_gwip(gwip);  // e.g internal IP of dsl router

            // Set the DNS server IP address if required, or use default
            es.ES_dnslkup_set_dnsip( dnsip );
          }
        }
      }
    }
  }
  
}
