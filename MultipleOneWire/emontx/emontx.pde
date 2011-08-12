#include <Ports.h>
#include <RF12.h>

int myNodeID;                //to be picked randomy in void setup()
#define network     212      //default network group (can be in the range 1-250). All nodes required to communigate together must be on the same network group
#define freq RF12_433MHZ     //Frequency of RF12B module can be RF12_433MHZ, RF12_868MHZ or RF12_915MHZ. You should use the one matching the module you have.

// set the sync mode to 2 if the fuses are still the Arduino default
// mode 3 (full powerdown) can only be used with 258 CK startup fuses
#define RADIO_SYNC_MODE 2

#define COLLECT 0x20 // collect mode, i.e. pass incoming without sending acks

typedef struct
{
  uint8_t address[16][2];
  int value[16];
} Sensor;


Sensor emontx;



#include <OneWire.h>
#include <DallasTemperature.h>

// Data wire is plugged into port 2 on the Arduino
#define ONE_WIRE_BUS 4

// Setup a oneWire instance to communicate with any OneWire devices (not just Maxim/Dallas temperature ICs)
OneWire oneWire(ONE_WIRE_BUS);

// Pass our oneWire reference to Dallas Temperature. 
DallasTemperature sensors(&oneWire);
int numberOfDevices; // Number of temperature devices found
// arrays to hold device address
DeviceAddress tempDeviceAddress;


void setup() {
  Serial.begin(9600);
  
  myNodeID = 1;                  // NodeID Must be in the range of 1-39 (reserve node 30 for Base Station)
  rf12_initialize(myNodeID,freq,network);   //Initialize RFM12 with settings defined above 
  
  
  sensors.begin();
  
  numberOfDevices = sensors.getDeviceCount();
  for(int i=0;i<numberOfDevices; i++)
  {
    if (sensors.getAddress(tempDeviceAddress, i)) sensors.setResolution(tempDeviceAddress, 12);
    Serial.println(sensors.getAddress(tempDeviceAddress, i));
  }
}

void loop()
{  
  sensors.requestTemperatures(); // Send the command to get temperatures
  
  for(int i=0;i<numberOfDevices; i++)
  {
    if(sensors.getAddress(tempDeviceAddress, i))
    {
      for (uint8_t p = 1; p < 3; p++)  // Shorten the 64-bit unique ID to 16-bits
      {
         emontx.address[i][p-1] = tempDeviceAddress[p];
      } 
      emontx.value[i] = sensors.getTempC(tempDeviceAddress)*100;
    }
  }
 
    rf12_sleep(-1);     //wake up RF module
    while (!rf12_canSend())
    rf12_recvDone();
    rf12_sendStart(rf12_hdr, &emontx, sizeof emontx, RADIO_SYNC_MODE); 
    rf12_sleep(0);    //put RF module to sleep
    
    delay(5000);
}
