#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>
#include <Wire.h>
#include <Thinary_AHT10.h>
#define I2C_SDA 23
#define I2C_SCL 19
#define cellPin A0

AHT10Class AHT10;

BLEServer* pServer = NULL;
BLECharacteristic* pCharacteristic = NULL;
bool deviceConnected = false;
bool oldDeviceConnected = false;
uint32_t value = 0;
int value2 = 0;
float prev_temp;
float prev_humidity;



#define SERVICE_UUID        "4fafc201-1fb5-459e-8fcc-c5c9c331914b"
#define CHARACTERISTIC_UUID "beb5483e-36e1-4688-b7f5-ea07361b26a8"


class MyServerCallbacks: public BLEServerCallbacks {
    void onConnect(BLEServer* pServer) {
      deviceConnected = true;
      BLEDevice::startAdvertising();
    };

    void onDisconnect(BLEServer* pServer) {
      deviceConnected = false;
    }
};
 
void updateTemp(float temp){
  if(prev_temp != temp){

    String tempString = "";
    tempString += (int)temp;
    tempString += "C";
    prev_temp = temp;
  }
}

void updateHumidity(float humidity){
  if(prev_humidity != humidity){
    String humidityString ="";
    humidityString += (int)humidity;
    humidityString += "%";
    prev_humidity = humidity;
  }
  
}



void setup() {
  // put your setup code here, to run once:
  /*Wire.begin();
  if(AHT10.begin(eAHT10Address_Low))
    Serial.println("Init AHT10 Sucess.");
  else
    Serial.println("Init AHT10 Failure.");*/
   // AHT10.begin();
   Serial.begin(9600);
  Wire.begin(I2C_SDA, I2C_SCL);
  if(AHT10.begin(eAHT10Address_Low))
    Serial.println("Init AHT10 Sucess.");
  else
    Serial.println("Init AHT10 Failure.");

     // Create the BLE Device
  BLEDevice::init("SWU Smart Mask");

  // Create the BLE Server
  pServer = BLEDevice::createServer();
  pServer->setCallbacks(new MyServerCallbacks());

  // Create the BLE Service
  BLEService *pService = pServer->createService(SERVICE_UUID);

   pCharacteristic = pService->createCharacteristic(
                      CHARACTERISTIC_UUID,
                      BLECharacteristic::PROPERTY_READ   |
                      BLECharacteristic::PROPERTY_WRITE  |
                      BLECharacteristic::PROPERTY_NOTIFY |
                      BLECharacteristic::PROPERTY_INDICATE
                    );
  // Create a BLE Descriptor
  pCharacteristic->addDescriptor(new BLE2902());
  // Start the service
  pService->start();

  // Start advertising
  BLEAdvertising *pAdvertising = BLEDevice::getAdvertising();
  pAdvertising->addServiceUUID(SERVICE_UUID);
  pAdvertising->setScanResponse(false);
  pAdvertising->setMinPreferred(0x0);  // set value to 0x00 to not advertise this parameter
  BLEDevice::startAdvertising();
  Serial.println("Waiting a client connection to notify...");
}

void loop() {
  // put your main code here, to run repeatedly:
 
 //Serial.println(String("")+"Humidity(%RH):\t\t"+AHT10.GetHumidity()+"%");
 //Serial.println(String("")+"Temperature(℃):\t"+AHT10.GetTemperature()+"℃");
 //Serial.println(String("")+"Dewpoint(℃):\t\t"+AHT10.GetDewPoint()+"℃");
 //delay(3500);

 updateTemp(AHT10.GetTemperature());
 updateHumidity(AHT10.GetHumidity());


 if(deviceConnected){
  // time duration check ex 10 second
  String str = "";
  str += prev_temp;
  str += ",";
  str += prev_humidity;
  pCharacteristic->setValue((char*)str.c_str());
 pCharacteristic->notify();

 

  /* Serial.println(String("")+"Humidity(%RH):\t\t"+AHT10.GetHumidity()+"%");
  Serial.println(String("")+"Temperature(℃):\t"+AHT10.GetTemperature()+"℃");
  Serial.println(String("")+"Dewpoint(℃):\t\t"+AHT10.GetDewPoint()+"℃");
  delay(2000);*/
  
  Serial.println(F("% Temperature: "));
  Serial.println(prev_temp);
  Serial.println(prev_humidity);
 


  
  delay(500);
 }
 //disconnecting
  oldDeviceConnected = deviceConnected;
  if(!deviceConnected && oldDeviceConnected){
    
    pServer->startAdvertising();
  }
  //connecting
  if (deviceConnected && !oldDeviceConnected){
    oldDeviceConnected = deviceConnected;
  }
}
