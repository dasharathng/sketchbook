EtherShield es=EtherShield();

#define BUFFER_SIZE 500
static uint8_t buf[BUFFER_SIZE+1];
uint16_t dat_p;
int plen = 0;

void ethernet_setup(byte* mymac,byte* myip,byte* gateway,byte* server, int port)
{
  es.ES_enc28j60SpiInit();
  es.ES_enc28j60Init(mymac);
  es.ES_init_ip_arp_udp_tcp(mymac, myip, port);
  es.ES_client_set_gwip(gateway);
  es.ES_client_set_wwwip(server);
}

int ethernet_ready()
{
  plen = es.ES_enc28j60PacketReceive(BUFFER_SIZE, buf);
  dat_p=es.ES_packetloop_icmp_tcp(buf,plen);
  if (dat_p==0) return 1; else return 0;
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
