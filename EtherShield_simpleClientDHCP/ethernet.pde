byte* mymac;
static uint8_t myip[4] =      { 0,0,0,0 };
static uint8_t mynetmask[4] = { 0,0,0,0 };
byte* websrvip;
static uint8_t gwip[4] =      { 0,0,0,0 };
static uint8_t dnsip[4] =     { 0,0,0,0 };
static uint8_t dhcpsvrip[4] = { 0,0,0,0 };

EtherShield es=EtherShield();

#define BUFFER_SIZE 500
static uint8_t buf[BUFFER_SIZE+1];
uint16_t dat_p;
int plen = 0;

int port;

void printIP( uint8_t *buf ) {
  for( int i = 0; i < 4; i++ ) {
    Serial.print( buf[i], DEC );
    if( i<3 )
      Serial.print( "." );
  }
}

void ethernet_setup(byte* mymac,byte* myip,byte* gateway,byte* server, int port)
{
  es.ES_enc28j60SpiInit();
  es.ES_enc28j60Init(mymac);
  es.ES_init_ip_arp_udp_tcp(mymac, myip, port);
  es.ES_client_set_gwip(gateway);
  es.ES_client_set_wwwip(server);
}

void ethernet_setup_dhcp(byte* in_mymac,byte* in_websrvip, int in_port)
{
  mymac = in_mymac;
  websrvip = in_websrvip;
  
  es.ES_enc28j60SpiInit();
  es.ES_enc28j60Init(mymac);
  es.ES_client_set_wwwip(websrvip);  // target web server
  port = in_port;
}

int ethernet_ready()
{
  plen = es.ES_enc28j60PacketReceive(BUFFER_SIZE, buf);
  dat_p=es.ES_packetloop_icmp_tcp(buf,plen);
  if (dat_p==0) return 1; else return 0;
}

int ethernet_ready_dhcp()
{
  if (es.ES_dhcp_state() == DHCP_STATE_OK ) 
  {
    plen = es.ES_enc28j60PacketReceive(BUFFER_SIZE, buf);
    dat_p=es.ES_packetloop_icmp_tcp(buf,plen);
    if (dat_p==0) return 1; else return 0;
  }
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
            es.ES_init_ip_arp_udp_tcp(mymac, myip, port);

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

void ethernet_send(char * domainname, char * string)
{
  es.ES_client_browse_url(PSTR(""),string, domainname, &browserresult_callback);
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
